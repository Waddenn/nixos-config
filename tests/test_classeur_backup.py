import hashlib
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest import mock

SPEC = importlib.util.spec_from_file_location('classeur_backup', Path(__file__).resolve().parents[1] / 'scripts/classeur-offhost-backup.py')
BACKUP = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(BACKUP)


class ClasseurBackupTests(unittest.TestCase):
    def test_remote_names_cannot_escape_destination_or_inject_commands(self):
        self.assertEqual(BACKUP.dump_name('20261010T072000Z.dump'), '20261010T072000Z.dump')
        for name in ['../backup.dump', '20261010T072000Z.dump;id', '20261010T072000Z.dump\nother', '']:
            with self.subTest(name=name), self.assertRaises(ValueError):
                BACKUP.dump_name(name)

    def test_changed_dump_is_rejected_before_remote_publish(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'backup.dump'
            path.write_bytes(b'private dump bytes')
            checksum = hashlib.sha256(path.read_bytes()).hexdigest()
            BACKUP.verify(path, checksum)
            path.write_bytes(b'changed dump bytes')
            with self.assertRaises(ValueError):
                BACKUP.verify(path, checksum)

    def test_failed_database_dump_prevents_copy(self):
        with mock.patch.object(BACKUP, 'ct', side_effect=RuntimeError('dump failed')) as ct, \
                mock.patch.object(BACKUP, 'run') as run:
            with self.assertRaises(RuntimeError):
                BACKUP.main()
            ct.assert_called_once_with('systemctl start le-classeur-backup.service')
            run.assert_not_called()
