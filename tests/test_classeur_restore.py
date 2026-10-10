import importlib.util
from pathlib import Path
import re
import unittest

SPEC = importlib.util.spec_from_file_location('classeur_restore', Path(__file__).resolve().parents[1] / 'scripts/classeur-restore-check.py')
RESTORE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RESTORE)


class ClasseurRestoreTests(unittest.TestCase):
    def test_live_or_injected_target_cannot_be_restored_or_dropped(self):
        for value in ['le_classeur_beta', 'postgres', 'template1', 'classeur_restore_check_x;id', '']:
            with self.subTest(value=value), self.assertRaises(ValueError):
                RESTORE.restore_script(value, '/tmp/restore.dump')

    def test_generated_target_is_unique_and_scoped(self):
        first, second = RESTORE.target_name(), RESTORE.target_name()
        self.assertNotEqual(first, second)
        self.assertTrue(re.fullmatch(r'classeur_restore_check_[0-9]{14}_[0-9a-f]{8}', first))

    def test_restore_preserves_live_schema_and_cleans_up_on_failure(self):
        target = RESTORE.target_name()
        script = RESTORE.restore_script(target, '/var/tmp/private directory/restore.dump')
        self.assertIn('trap cleanup EXIT', script)
        self.assertIn('--single-transaction --no-owner --no-privileges', script)
        self.assertIn('--template=template0', script)
        self.assertIn(f'REINDEX DATABASE {target}', script)
        self.assertNotIn('-d le_classeur_beta', script)
        self.assertIn("'/var/tmp/private directory/restore.dump'", script)
