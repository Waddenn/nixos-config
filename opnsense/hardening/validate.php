<?php
/* Read-only candidate verification on the actual appliance. */
require_once 'config.inc';
require_once 'auth.inc';
require_once __DIR__ . '/configure.php';
$cnf = OPNsense\Core\Config::getInstance();
$beforeHash = hash_file('sha256', '/conf/config.xml');
$before = $cnf->toArray(array_fill_keys(['alias', 'rule', 'user', 'group', 'authserver', 'acl', 'member'], true));
$after = $cnf->toArrayFromFile($argv[1], array_fill_keys(['alias', 'rule', 'user', 'group', 'authserver', 'acl', 'member'], true));
function verify($condition, $message) { if (!$condition) throw new RuntimeException($message); }
verify($before['nat'] === $after['nat'], 'Existing NAT changed');
$oldRules = array_values(array_filter($before['filter']['rule'], fn($r) => !str_starts_with($r['descr'] ?? '', 'OPNsense hardening:')));
$newRules = array_values(array_filter($after['filter']['rule'], fn($r) => !str_starts_with($r['descr'] ?? '', 'OPNsense hardening:')));
verify($oldRules === $newRules, 'Existing exceptions changed');
verify(!empty($after['system']['webgui']['noantilockout']), 'Anti-lockout bypass still enabled');
verify($after['system']['webgui']['authmode'] === 'OPNsense MFA', 'MFA fallback bypass');
verify($after['OPNsense']['unboundplus']['acls']['default_action'] === 'refuse', 'Open resolver ACL');
$rootBefore = array_values(array_filter($before['system']['user'], fn($u) => $u['name'] === 'root'));
$rootAfter = array_values(array_filter($after['system']['user'], fn($u) => $u['name'] === 'root'));
verify($rootBefore === $rootAfter, 'Root rescue account changed');
$cnf->fromArray($after);
$factory = new OPNsense\Auth\AuthenticationFactory();
$auth = $factory->get('OPNsense MFA');
verify($auth instanceof OPNsense\Auth\LocalTOTP, 'Invalid native MFA backend');
verify(userIsAdmin('opnsense-maint'), 'Native SSH maintenance shell privilege missing');
$password = trim(stream_get_contents(STDIN));
if ($password !== '') {
    $credentials = json_decode(file_get_contents(__DIR__ . '/credentials.json'), true);
    $token = $auth->testToken($credentials['tom_otp_seed']);
    verify($auth->authenticate('tom', $password . $token), 'Native MFA login failed');
    verify(!$auth->authenticate('tom', $password), 'Password-only MFA bypass');
    verify(!$auth->authenticate('tom', 'incorrect' . $token), 'Wrong password accepted');
}
verify($beforeHash === hash_file('sha256', '/conf/config.xml'), 'Validation modified live configuration');
echo "Native candidate checks passed; live configuration unchanged\n";
