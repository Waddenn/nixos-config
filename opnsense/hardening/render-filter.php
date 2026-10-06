<?php
/* Render native firewall rules in memory. Never call filter_configure_sync. */
require_once 'config.inc';
require_once 'util.inc';
require_once 'system.inc';
require_once 'interfaces.inc';
require_once 'filter.inc';
if (empty($argv[1])) exit(2);
$cnf = OPNsense\Core\Config::getInstance();
$config = $cnf->toArrayFromFile($argv[1], listtags());
$cnf->fromArray($config);
OPNsense\Firewall\Alias::flushCacheData();
$fw = filter_core_get_initialized_plugin_system();
filter_core_bootstrap($fw);
plugins_firewall($fw);
filter_core_rules_user($fw);
echo filter_generate_aliases() . "\n" . $fw->tablesToText() . "\n" . $fw->outputFilterRules();
