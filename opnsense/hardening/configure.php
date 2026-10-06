<?php
/* Native OPNsense configuration: dry run by default, compare-before-write. */
function update_policy(array $cfg, array $policy, array $credentials = []): array
{
    foreach (['domain', 'controller_address', 'admin_addresses', 'non_public_networks', 'dns_interfaces', 'dns_client_networks'] as $key) {
        if (empty($policy[$key])) throw new RuntimeException("Missing policy field: $key");
    }
    if (($cfg['interfaces']['wan']['ipaddr'] ?? '') !== '192.168.1.4') {
        throw new RuntimeException('Unexpected WAN; refusing hard-coded controller access');
    }
    $aliases =& $cfg['OPNsense']['Firewall']['Alias']['aliases']['alias'];
    $found = false;
    foreach ($aliases as &$alias) {
        if (($alias['name'] ?? '') === 'PrivateNetworks') {
            $items = preg_split('/[\r\n,]+/', $alias['content']);
            $alias['content'] = implode("\n", array_unique(array_merge($items, $policy['non_public_networks'])));
            $found = true;
        }
    }
    unset($alias);
    if (!$found) throw new RuntimeException('PrivateNetworks alias missing');
    $aliases = array_values(array_filter($aliases, fn($a) => ($a['name'] ?? '') !== 'OPNsenseAdministrators'));
    $aliases[] = [
        '@attributes' => ['uuid' => 'd19430cf-0f24-49ab-9f93-20caf033eff1'],
        'enabled' => '1', 'name' => 'OPNsenseAdministrators', 'type' => 'network',
        'content' => implode("\n", $policy['admin_addresses']),
        'description' => 'Private OPNsense administration sources',
    ];
    $aliases = array_values(array_filter($aliases, fn($a) => ($a['name'] ?? '') !== 'OPNsenseDNSClients'));
    $aliases[] = ['@attributes' => ['uuid' => 'aa7af09d-7c26-4e10-8b8f-0c8f23e5707c'],
        'enabled' => '1', 'name' => 'OPNsenseDNSClients', 'type' => 'network',
        'content' => implode("\n", $policy['dns_client_networks']),
        'description' => 'Private OPNsense DNS clients'];
    $unbound =& $cfg['OPNsense']['unboundplus'];
    $unbound['general']['active_interface'] = implode(',', $policy['dns_interfaces']);
    $unbound['general']['dnssec'] = '1';
    $unbound['advanced']['hideidentity'] = '1';
    $unbound['advanced']['hideversion'] = '1';
    $unbound['advanced']['dnssecstripped'] = '1';
    $unbound['acls']['default_action'] = 'refuse';
    $unbound['acls']['acl'] = array_values(array_filter($unbound['acls']['acl'] ?? [], fn($a) => ($a['name'] ?? '') !== 'Private DNS clients'));
    $unbound['acls']['acl'][] = [
        '@attributes' => ['uuid' => '7e46ae87-8c9c-4136-b2a7-4915dd234806'],
        'enabled' => '1', 'name' => 'Private DNS clients', 'action' => 'allow',
        'networks' => implode(',', $policy['dns_client_networks']),
    ];
    $cfg['system']['webgui']['interfaces'] = 'lan,opt2';
    unset($cfg['system']['webgui']['nohttpreferercheck'], $cfg['system']['webgui']['nodnsrebindcheck']);
    $cfg['system']['webgui']['althostnames'] = $policy['domain'];
    $cfg['system']['ssh']['interfaces'] = 'lan,wan';
    unset($cfg['system']['ssh']['permitrootlogin'], $cfg['system']['ssh']['passwordauth']);
    /* WAN is an upstream PRIVATE LAN. Default deny remains; only the controller
       gets a new allow rule. The old rdr-pass already bypassed blockpriv. */
    unset($cfg['interfaces']['wan']['blockpriv']);
    $cfg['system']['webgui']['noantilockout'] = '1';
    $rules = array_values(array_filter($cfg['filter']['rule'] ?? [], fn($r) =>
        !str_starts_with($r['descr'] ?? '', 'OPNsense hardening:')));
    $adminRules = [];
    foreach (['lan', 'opt2'] as $interface) {
        $adminRules[] = [
            'type' => 'pass', 'interface' => $interface, 'ipprotocol' => 'inet',
            'protocol' => 'tcp', 'source' => ['address' => 'OPNsenseAdministrators'],
            'destination' => ['network' => '(self)', 'port' => '443'], 'log' => '1',
            'descr' => "OPNsense hardening: private HTTPS $interface",
        ];
    }
    $adminRules[] = [
        'type' => 'pass', 'interface' => 'lan', 'ipprotocol' => 'inet', 'protocol' => 'tcp/udp',
        'source' => ['address' => 'OPNsenseDNSClients'],
        'destination' => ['network' => 'lanip', 'port' => '53'],
        'descr' => 'OPNsense hardening: private LAN DNS',
    ];
    $adminRules[] = [
        'disablereplyto' => '1',
        'type' => 'pass', 'interface' => 'wan', 'ipprotocol' => 'inet', 'protocol' => 'tcp',
        'source' => ['address' => $policy['controller_address'] . '/32'],
        'destination' => ['network' => 'wanip', 'port' => '22'], 'log' => '1',
        'descr' => 'OPNsense hardening: restricted controller SSH',
    ];
    $cfg['filter']['rule'] = array_merge($adminRules, $rules);
    /* Never change DNAT Caddy or existing cross-segment exceptions here. */
    if (!empty($credentials)) {
        foreach (['tom_password_hash', 'tom_otp_seed', 'maintenance_public_key'] as $key) {
            if (empty($credentials[$key])) throw new RuntimeException("Missing credential field: $key");
        }
        $users =& $cfg['system']['user'];
        foreach ($users as $user) {
            if (in_array($user['name'], ['tom', 'opnsense-maint'], true)) {
                throw new RuntimeException('Account already exists; refuse credential replacement');
            }
        }
        $uid = max(2000, (int)($cfg['system']['nextuid'] ?? 2000));
        $users[] = ['name' => 'tom', 'descr' => 'Tom OPNsense administrator', 'scope' => 'user',
            'uid' => (string)$uid, 'password' => $credentials['tom_password_hash'],
            'otp_seed' => $credentials['tom_otp_seed'], 'disabled' => '0', 'priv' => ['page-all']];
        $users[] = ['name' => 'opnsense-maint', 'descr' => 'Restricted controller maintenance',
            'scope' => 'user', 'uid' => (string)($uid + 1), 'disabled' => '0', 'shell' => '/bin/sh',
            'password' => password_hash(bin2hex(random_bytes(48)), PASSWORD_BCRYPT),
            'authorizedkeys' => base64_encode('restrict,from="' . $policy['controller_address'] .
                '",command="/conf/opnsense-hardening/dispatch.sh" ' . $credentials['maintenance_public_key']),
        ];
        $cfg['system']['nextuid'] = (string)($uid + 2);
        foreach ($cfg['system']['group'] as &$group) {
            if ($group['name'] === 'admins') {
                $members = $group['member'] ?? [];
                if (!is_array($members)) $members = [$members];
                $group['member'] = array_values(array_unique(array_merge($members, [(string)$uid, (string)($uid + 1)])));
            }
        }
        unset($group);
        $cfg['system']['authserver'][] = ['name' => 'OPNsense MFA', 'type' => 'totp',
            'refid' => 'opnsense-hardening-mfa', 'otpLength' => '6', 'timeWindow' => '30',
            'graceperiod' => '10', 'passwordFirst' => '1'];
        /* Set ONLY this backend after human enrollment; local fallback would
           silently allow tom to bypass OTP. Root remains console/Tailscale rescue. */
    }
    return $cfg;
}

if (realpath($_SERVER['SCRIPT_FILENAME'] ?? '') !== __FILE__) return;
require_once 'config.inc';
require_once 'auth.inc';
require_once 'certs.inc';
$opts = getopt('', ['policy:', 'credentials:', 'expected:', 'apply', 'candidate:', 'certificate:', 'mfa-enrolled']);
if (empty($opts['policy']) || empty($opts['expected'])) throw new RuntimeException('Require --policy and --expected SHA256');
$cnf = OPNsense\Core\Config::getInstance();
$cnf->lock();
try {
    $before = hash_file('sha256', '/conf/config.xml');
    if (!hash_equals($opts['expected'], $before)) throw new RuntimeException('Configuration changed since review');
    $policy = json_decode(file_get_contents($opts['policy']), true, 512, JSON_THROW_ON_ERROR);
    $credentials = empty($opts['credentials']) ? [] : json_decode(file_get_contents($opts['credentials']), true, 512, JSON_THROW_ON_ERROR);
    $config = update_policy($cnf->toArray(array_fill_keys(['alias', 'rule', 'user', 'group', 'authserver', 'acl', 'member'], true)), $policy, $credentials);
    if (!empty($opts['certificate'])) {
        $bundle = json_decode(file_get_contents($opts['certificate']), true, 16, JSON_THROW_ON_ERROR);
        $ref = 'opnsense-private-administration';
        $certs = $config['cert'] ?? [];
        if (isset($certs['refid'])) $certs = [$certs];
        $config['cert'] = array_values(array_filter($certs, fn($c) => ($c['refid'] ?? '') !== $ref));
        $config['cert'][] = ['refid' => $ref, 'descr' => 'Private OPNsense ACME certificate',
            'crt' => base64_encode($bundle['certificate']), 'prv' => base64_encode($bundle['private_key'])];
        $config['system']['webgui']['ssl-certref'] = $ref;
    }
    $cnf->fromArray($config);
    foreach ([new OPNsense\Unbound\Unbound(), new OPNsense\Firewall\Alias()] as $model) {
        if (count($model->performValidation()) > 0) {
            foreach ($model->performValidation() as $error) fwrite(STDERR, (string)$error . "\n");
            throw new RuntimeException('Native model validation failed');
        }
    }
    if (isset($opts['mfa-enrolled'])) $config['system']['webgui']['authmode'] = 'OPNsense MFA';
    if (isset($opts['candidate'])) {
        $cnf->fromArray($config);
        file_put_contents($opts['candidate'], (string)$cnf);
        chmod($opts['candidate'], 0600);
    }
    echo json_encode(['before_sha256' => $before, 'domain' => $policy['domain'],
        'private_web_interfaces' => $config['system']['webgui']['interfaces'],
        'dnssec' => true, 'existing_nat_preserved' => true,
        'credentials_staged' => !empty($credentials), 'mfa_activated' => isset($opts['mfa-enrolled']),
        'apply' => isset($opts['apply'])], JSON_PRETTY_PRINT) . "\n";
    if (isset($opts['apply'])) {
        if (empty($credentials) || empty($opts['certificate']) || !isset($opts['mfa-enrolled'])) throw new RuntimeException('Require verified MFA enrollment and prepared accounts before activation');
        if (!is_array(write_config('OPNsense hardening: private administration, DNS and network boundaries'))) {
            throw new RuntimeException('Configuration save failed');
        }
        file_put_contents('/root/opnsense-hardening/20261006/applied.sha256', hash_file('sha256', '/conf/config.xml') . "\n");
        local_sync_accounts();
    }
} finally { $cnf->unlock(); }
