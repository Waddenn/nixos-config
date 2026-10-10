import hashlib
import importlib.util
import io
import json
from pathlib import Path
import tarfile
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('receiver', Path(__file__).resolve().parents[1] / 'scripts/classeur-stage-release.py')
receiver = importlib.util.module_from_spec(spec)
spec.loader.exec_module(receiver)
SHA = 'a' * 40

def archive(**changes):
    meta = dict(revision=SHA, rehearsal=False, platform='linux', architecture='x64')
    meta.update(changes)
    stream = io.BytesIO()
    with tarfile.open(fileobj=stream, mode='w:gz') as tar:
        data = json.dumps(meta).encode()
        info = tarfile.TarInfo('./release.json')
        info.size = len(data)
        tar.addfile(info, io.BytesIO(data))
        link = tarfile.TarInfo('node_modules/sharp')
        link.type = tarfile.SYMTYPE
        link.linkname = '.pnpm/sharp/node_modules/sharp'
        tar.addfile(link)
    return stream.getvalue()

class StageTests(unittest.TestCase):
    def test_command_rejects_activation_and_injection(self):
        self.assertEqual(receiver.command(f'stage {SHA} {"b"*64}'), (SHA, 'b'*64))
        for cmd in ['activate ' + SHA, f'stage {SHA} {"b"*64}; reboot', '', f'stage {SHA} {"b"*64}\n']:
            with self.assertRaises(ValueError): receiver.command(cmd)

    def test_stages_opaque_archive_idempotently_without_extraction(self):
        with tempfile.TemporaryDirectory() as root:
            data = archive()
            digest = hashlib.sha256(data).hexdigest()
            name = receiver.stage(io.BytesIO(data), root, SHA, digest)
            self.assertEqual(receiver.stage(io.BytesIO(data), root, SHA, digest), name)
            staged = Path(root) / name
            self.assertEqual(sorted(p.name for p in staged.iterdir()), ['package.tar.gz', 'review.json'])
            self.assertFalse(json.loads((staged / 'review.json').read_text())['activated'])

    def test_member_safety_preserves_contained_pnpm_links(self):
        for name in ['/etc/passwd', '../release.json', 'node_modules/../../release.json']:
            with self.assertRaises(ValueError): receiver.safe_member(tarfile.TarInfo(name))
        link = tarfile.TarInfo('node_modules/package')
        link.type = tarfile.SYMTYPE
        for target in ['/etc/passwd', '../../outside']:
            link.linkname = target
            with self.assertRaises(ValueError): receiver.safe_member(link)
        link.linkname = '.pnpm/package/node_modules/package'
        receiver.safe_member(link)

    def test_rejects_corruption_rehearsal_platform_and_revision(self):
        with tempfile.TemporaryDirectory() as root:
            for overrides in [dict(rehearsal=True), dict(platform='darwin'), dict(revision='b'*40), dict(architecture='arm64')]:
                data = archive(**overrides)
                with self.assertRaises(ValueError): receiver.stage(io.BytesIO(data), root, SHA, hashlib.sha256(data).hexdigest())
                self.assertEqual(list(Path(root).iterdir()), [])
            with self.assertRaises(ValueError): receiver.stage(io.BytesIO(archive()), root, SHA, '0'*64)
            self.assertEqual(list(Path(root).iterdir()), [])

    def test_rejects_duplicate_paths_and_children_of_archive_links(self):
        for duplicate in [False, True]:
            stream = io.BytesIO()
            with tarfile.open(fileobj=stream, mode='w:gz') as tar:
                metadata = json.dumps(dict(revision=SHA, rehearsal=False, platform='linux', architecture='x64')).encode()
                item = tarfile.TarInfo('./release.json')
                item.size = len(metadata)
                tar.addfile(item, io.BytesIO(metadata))
                if duplicate:
                    tar.addfile(item, io.BytesIO(metadata))
                else:
                    link = tarfile.TarInfo('a')
                    link.type = tarfile.SYMTYPE
                    link.linkname = '.'
                    tar.addfile(link)
                    tar.addfile(tarfile.TarInfo('a/b'))
            data = stream.getvalue()
            with tempfile.TemporaryDirectory() as root:
                with self.assertRaises(ValueError): receiver.stage(io.BytesIO(data), root, SHA, hashlib.sha256(data).hexdigest())
                self.assertEqual(list(Path(root).iterdir()), [])

    def test_staging_budget_refuses_before_reading_input(self):
        with tempfile.TemporaryDirectory() as root:
            old = receiver.MAX_STAGED
            receiver.MAX_STAGED = 1
            try:
                with self.assertRaises(ValueError): receiver.stage(io.BytesIO(b'fixture'), root, SHA, '0'*64)
            finally: receiver.MAX_STAGED = old
            self.assertEqual(list(Path(root).iterdir()), [])

    def test_bounds_input_and_cleans_partial_files(self):
        with tempfile.TemporaryDirectory() as root:
            old = receiver.MAX_ARCHIVE
            receiver.MAX_ARCHIVE = 1
            try:
                with self.assertRaises(ValueError): receiver.stage(io.BytesIO(b'too much'), root, SHA, '0'*64)
            finally: receiver.MAX_ARCHIVE = old
            self.assertEqual(list(Path(root).iterdir()), [])

if __name__ == '__main__': unittest.main()
