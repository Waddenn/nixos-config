import importlib.util
import json
import sys
import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch, Mock

SOURCE = Path(__file__).resolve().parents[1] / 'opnsense/hardening/collect.py'
spec = importlib.util.spec_from_file_location('opnsense_collect', SOURCE)
collect = importlib.util.module_from_spec(spec)
spec.loader.exec_module(collect)


class MaintenanceTests(unittest.TestCase):
    def test_invalid_audit_and_expiring_certificate_are_failures(self):
        status = {'audit_valid': False, 'vulnerability_advisories': None, 'certificate_expires': 100}
        self.assertEqual(len(collect.health_issues(status, 100)), 3)

    def test_advisories_remain_visible(self):
        status = {'audit_valid': True, 'vulnerability_advisories': 35, 'certificate_expires': 5000000}
        self.assertEqual(collect.health_issues(status, 100), ['35 vulnerability advisories'])
        status['vulnerability_advisories'] = 0
        self.assertEqual(collect.health_issues(status, 100), [])

    def test_native_ssh_pins_host_and_identity(self):
        with patch.object(collect.subprocess, 'run', return_value=Mock(stdout=b'ok')) as run:
            collect.ssh('opnsense-maint@192.168.1.4', 'status', Path('/key'), native=True)
        args = run.call_args.args[0]
        for flag in ('StrictHostKeyChecking=yes', 'BatchMode=yes', 'HostKeyAlias=opnsense-native', 'IdentitiesOnly=yes'):
            self.assertIn(flag, args)
        self.assertEqual(args[-2:], ['opnsense-maint@192.168.1.4', 'status'])

    def test_failed_backup_does_not_remove_previous_archives(self):
        with tempfile.TemporaryDirectory() as tmp:
            state = Path(tmp)
            (state / 'id_ed25519').touch()
            old = state / 'backup-old.cms'
            old.write_bytes(b'recoverable')
            with patch.object(sys, 'argv', ['collect', '--state-dir', tmp]), patch.object(collect, 'ssh', return_value=b''):
                with self.assertRaisesRegex(RuntimeError, 'truncated'):
                    collect.main()
            self.assertEqual(old.read_bytes(), b'recoverable')
            self.assertFalse((state / 'status.json').exists())

    def test_forced_dispatch_denies_shell_injection_and_other_commands(self):
        dispatch = SOURCE.with_name('dispatch.sh')
        for command in ('', 'sh', 'status; id', 'backup /conf/config.xml', 'certificate\nsh'):
            result = subprocess.run(['sh', str(dispatch)], env={**os.environ, 'SSH_ORIGINAL_COMMAND': command}, capture_output=True)
            self.assertEqual(result.returncode, 126, command)

    def test_atomic_outputs_are_private_and_complete(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / 'status.json'
            collect.atomic(output, b'{"ok": true}')
            self.assertEqual(json.loads(output.read_text()), {'ok': True})
            self.assertEqual(output.stat().st_mode & 0o777, 0o600)


if __name__ == '__main__':
    unittest.main()
