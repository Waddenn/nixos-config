<?php
require_once 'config.inc';
$state = $argv[1] ?? '';
if (!preg_match('#^/root/classeur-direct/[a-zA-Z0-9_-]+$#D', $state)) exit(2);
$argv[1] = '--library';
require_once __DIR__.'/configure.php';
$cnf = OPNsense\Core\Config::getInstance();
$hash = hash_file('sha256', '/conf/config.xml');
if (!hash_equals(trim(file_get_contents("$state/expected.sha256")), $hash))
    throw new RuntimeException('Concurrent configuration change');
$before = $cnf->toArrayFromFile("$state/before.xml", listtags());
$candidate = $cnf->toArrayFromFile("$state/candidate.xml", listtags());
if ($candidate !== update_link($before)) throw new RuntimeException('Unexpected candidate diff');
if (update_link($candidate) !== $candidate) throw new RuntimeException('Not idempotent');
if (update_link($candidate,true) !== $before) throw new RuntimeException('Rollback mismatch');
$changed = $candidate;
$changed['system']['hostname'] = 'concurrent-change';
if (update_link($changed,true)['system']['hostname'] !== 'concurrent-change')
    throw new RuntimeException('Rollback lost unrelated change');
$edited = $candidate;
$edited['filter']['rule'][0]['destination']['port']='22';
$rejected=false;
try { update_link($edited); } catch (RuntimeException $e) { $rejected=true; }
if (!$rejected) throw new RuntimeException('Altered rule accepted');
if ($hash !== hash_file('sha256','/conf/config.xml')) throw new RuntimeException('Live config modified');
echo "Native checks passed: exact diff, preserved config/NAT, idempotence, rollback and conflict refusal\n";
