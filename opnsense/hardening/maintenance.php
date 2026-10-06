<?php
require_once 'config.inc';
$mode = $argv[1] ?? '';
if ($mode === 'status') {
    $c = OPNsense\Core\Config::getInstance()->toArray();
    $ref = $c['system']['webgui']['ssl-certref'] ?? '';
    $certs = $c['cert'] ?? [];
    if (isset($certs['refid'])) $certs = [$certs];
    $expires = null;
    foreach ($certs as $cert) if (($cert['refid'] ?? '') === $ref) {
        $expires = openssl_x509_parse(base64_decode($cert['crt']))['validTo_time_t'] ?? null;
    }
    $audit = [];
    exec('/usr/local/sbin/pkg audit 2>&1', $audit, $rc);
    $problems = null;
    $auditValid = !preg_match('/Invalid|cannot process|unable to open/i', implode("\n", $audit));
    foreach ($audit as $line) if (preg_match('/(\d+) problem\(s\) in (\d+) package/', $line, $m)) $problems = (int)$m[1];
    if ($rc === 0) $problems = 0;
    echo json_encode(['version' => trim(shell_exec('/usr/local/sbin/opnsense-version')),
        'config_sha256' => hash_file('sha256', '/conf/config.xml'),
        'audit_valid' => $auditValid, 'vulnerability_advisories' => $problems,
        'certificate_expires' => $expires, 'captured_at' => gmdate('c')]) . "\n";
    exit;
}
if ($mode === 'vulnerability-db') {
    $input = stream_get_contents(STDIN, 33554433);
    $xml = strlen($input) <= 33554432 ? simplexml_load_string($input, 'SimpleXMLElement', LIBXML_NONET) : false;
    if (!$xml || $xml->getName() !== 'vuxml' || count($xml->vuln) < 1) {
        throw new RuntimeException('Invalid or oversized vulnerability database');
    }
    $temp = tempnam('/var/db/pkg', 'vuln-audit-');
    try {
        file_put_contents($temp, $input);
        chmod($temp, 0444);
        if (!rename($temp, '/var/db/pkg/vuln.xml')) throw new RuntimeException('Database install failed');
    } finally { if (file_exists($temp)) unlink($temp); }
    echo "Vulnerability database refreshed\n";
    exit;
}
if ($mode !== 'certificate') exit(126);
$input = stream_get_contents(STDIN, 131073);
if (strlen($input) > 131072) throw new RuntimeException('Certificate bundle too large');
$bundle = json_decode($input, true, 16, JSON_THROW_ON_ERROR);
$crt = $bundle['certificate'] ?? '';
$key = $bundle['private_key'] ?? '';
$parsed = openssl_x509_parse($crt);
$san = array_map('trim', explode(',', $parsed['extensions']['subjectAltName'] ?? ''));
if (!in_array('DNS:opnsense.hexaflare.net', $san, true) ||
    ($parsed['validTo_time_t'] ?? 0) < time() + 86400 ||
    ($parsed['validFrom_time_t'] ?? PHP_INT_MAX) > time() ||
    !openssl_x509_check_private_key($crt, $key)) throw new RuntimeException('Invalid domain, validity or key');
// Verify the leaf and supplied chain against the appliance trust store.
if (!preg_match_all('/-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----/s', $crt, $parts) || count($parts[0]) < 2) {
    throw new RuntimeException('Missing certificate chain');
}
$chain = tempnam('/tmp', 'opnsense-chain-');
try {
    chmod($chain, 0600);
    file_put_contents($chain, implode("\n", array_slice($parts[0], 1)));
    if (openssl_x509_checkpurpose($parts[0][0], X509_PURPOSE_SSL_SERVER, [], $chain) !== true) {
        throw new RuntimeException('Untrusted certificate chain');
    }
} finally { unlink($chain); }
if (($argv[2] ?? '') === '--check') { echo "Certificate bundle verified\n"; exit; }
$cnf = OPNsense\Core\Config::getInstance();
$cnf->lock();
try {
    $transaction = '/root/opnsense-hardening/20261006';
    if (file_exists($transaction . '/active')) throw new RuntimeException('Certificate renewal deferred until transaction confirmation');
    $config = $cnf->toArray(array_fill_keys(['cert'], true));
    $ref = 'opnsense-private-administration';
    $config['cert'] = array_values(array_filter($config['cert'] ?? [], fn($c) => ($c['refid'] ?? '') !== $ref));
    $config['cert'][] = ['refid' => $ref, 'descr' => 'Private OPNsense ACME certificate',
        'crt' => base64_encode($crt), 'prv' => base64_encode($key)];
    if (($config['system']['webgui']['ssl-certref'] ?? '') === $ref) {
        $old = OPNsense\Core\Config::getInstance()->object()->xpath("//cert[refid='$ref']/crt");
        if (!empty($old) && openssl_x509_fingerprint(base64_decode((string)$old[0])) === openssl_x509_fingerprint($crt)) {
            echo "Certificate unchanged\n"; exit;
        }
    }
    $config['system']['webgui']['ssl-certref'] = $ref;
    $config['system']['webgui']['althostnames'] = 'opnsense.hexaflare.net';
    if (!is_array(write_config('Renew private OPNsense administration certificate'))) throw new RuntimeException('Certificate save failed');
} finally { $cnf->unlock(); }
passthru('/usr/local/sbin/configctl webgui restart', $rc);
if ($rc !== 0) throw new RuntimeException('Web GUI restart failed');
echo "Certificate installed\n";
