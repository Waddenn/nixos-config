<?php
/* Native, root-only configuration transaction. Never changes NAT or other rules. */
require_once 'util.inc';
require_once 'config.inc';
const LINK_UUID = '50c4a6cd-6578-4a10-bd92-1741d6f379a7';
function link_rule(): array {
    return ['@attributes' => ['uuid' => LINK_UUID], 'type' => 'pass',
        'interface' => 'opt4', 'ipprotocol' => 'inet', 'protocol' => 'udp',
        'statetype' => 'keep state', 'direction' => 'in', 'quick' => '1',
        'source' => ['address' => '192.168.40.105/32', 'port' => '41641'],
        'destination' => ['address' => '192.168.1.159/32', 'port' => '41641'],
        'descr' => 'Classeur: direct encrypted Tailscale transport from Caddy'];
}
function update_link(array $config, bool $remove = false): array {
    $rules = $config['filter']['rule'] ?? [];
    $found = false;
    $kept = [];
    foreach ($rules as $rule) {
        if (($rule['@attributes']['uuid'] ?? '') === LINK_UUID) {
            if ($rule !== link_rule()) throw new RuntimeException('Managed rule changed; refuse overwrite');
            if ($found) throw new RuntimeException('Duplicate managed rule');
            $found = true;
        } else $kept[] = $rule;
    }
    $config['filter']['rule'] = $remove ? $kept : array_merge([link_rule()], $kept);
    return $config;
}
if (($argv[1] ?? '') === '--library') return;
if (trim(shell_exec('/usr/bin/id -u') ?? '') !== '0') throw new RuntimeException('Root required');
$mode = $argv[1] ?? '';
$state = $argv[2] ?? '';
if (!in_array($mode, ['prepare','apply','rollback'], true) ||
    !preg_match('#^/root/classeur-direct/[a-zA-Z0-9_-]+$#D', $state))
    throw new RuntimeException('Usage: configure.php prepare|apply|rollback /root/classeur-direct/TRANSACTION');
$cnf = OPNsense\Core\Config::getInstance();
$cnf->lock();
try {
    $hash = hash_file('sha256', '/conf/config.xml');
    $config = $cnf->toArray(listtags());
    if (($config['interfaces']['opt4']['ipaddr'] ?? '') !== '192.168.40.254' ||
        ($config['interfaces']['wan']['ipaddr'] ?? '') !== '192.168.1.4')
        throw new RuntimeException('Unexpected network topology');
    if ($mode === 'prepare') {
        if (file_exists($state)) throw new RuntimeException('Transaction already exists');
        if (!mkdir($state, 0700, true)) throw new RuntimeException('Cannot create transaction');
        copy('/conf/config.xml', "$state/before.xml");
        chmod("$state/before.xml",0600);
        file_put_contents("$state/expected.sha256", $hash);
        $cnf->fromArray(update_link($config));
        file_put_contents("$state/candidate.xml", (string)$cnf);
        chmod("$state/candidate.xml",0600);
        echo "Candidate prepared; live configuration unchanged\n";
    } else {
        if (!is_file("$state/validated")) throw new RuntimeException('Candidate not validated');
        if ($mode === 'apply' && !hash_equals(trim(file_get_contents("$state/expected.sha256")), $hash))
            throw new RuntimeException('Concurrent configuration change');
        // Rollback removes only our exact rule, preserving concurrent unrelated changes.
        $after = update_link($config, $mode === 'rollback');
        $beforeWithoutRules = $config;
        $afterWithoutRules = $after;
        unset($beforeWithoutRules['filter']['rule'],$afterWithoutRules['filter']['rule']);
        if ($beforeWithoutRules !== $afterWithoutRules) throw new RuntimeException('Unexpected configuration change');
        $cnf->fromArray($after);
        if (!is_array(write_config('Classeur direct Tailscale link: '.$mode)))
            throw new RuntimeException('Configuration save failed');
        file_put_contents("$state/$mode.sha256", hash_file('sha256','/conf/config.xml'));
        echo "Configuration saved: $mode\n";
    }
} finally { $cnf->unlock(); }
