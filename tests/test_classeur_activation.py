import fcntl
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import tarfile
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('activation', ROOT / 'scripts/classeur-activate-release.py')
activation = importlib.util.module_from_spec(spec)
spec.loader.exec_module(activation)
OLD = 'a' * 40
NEW = 'b' * 40


def package(revision, sql='select 1;', extra=None):
    contents = {
        'release.json': json.dumps(dict(revision=revision, platform='linux', architecture='x64', rehearsal=False)),
        'package.json': '{}', 'build/server/index.js': 'fixture',
        'build/client/assets/main-abcdefgh.js': 'new chunk',
        'migrations/0000.sql': sql, 'migrations/meta/_journal.json': '{}',
    }
    contents.update(extra or {})
    stream = io.BytesIO()
    with tarfile.open(fileobj=stream, mode='w:gz') as tar:
        for name, value in contents.items():
            item = tarfile.TarInfo(name)
            data = value.encode()
            item.size = len(data)
            tar.addfile(item, io.BytesIO(data))
    return stream.getvalue()


class FakeActivation(activation.Activation):
    """Real archive, schema, flock and atomic links; mock only OS service/network boundaries."""
    def __init__(self, config):
        super().__init__(config)
        self.calls = []
        self.failure = None
        self.timer = True

    def permissions(self, directory):
        pass  # Tests run unprivileged; extraction and paths are real.

    def systemctl(self, *args, check=True):
        self.calls.append(args)
        return subprocess.CompletedProcess(args, 0 if self.timer else 3)

    def sharp(self, target):
        self.calls.append(('sharp', str(target)))
        if self.failure == 'sharp':
            raise ValueError('broken native module')

    def candidate(self, target):
        self.calls.append(('candidate', str(target)))

    def ready(self, port, revision, public=False):
        self.calls.append(('ready', port, revision, public))
        failure = 'candidate' if port == 8085 else 'public' if public else 'local'
        if self.failure == failure:
            raise ValueError('failed probe')

    def previous_health(self, revision, public=False):
        self.calls.append(('previous-health', revision, public))
        if self.failure == 'edge-before-switch':
            raise ValueError('pre-existing public outage')


class ActivationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.state = self.root / 'state'
        self.staging = self.root / 'staging'
        self.staging.mkdir()
        self.previous = self.state / 'releases' / OLD
        self.previous.mkdir(parents=True)
        with tarfile.open(fileobj=io.BytesIO(package(OLD)), mode='r:gz') as tar:
            tar.extractall(self.previous, filter='data')
        (self.previous / 'build/client/assets/old-12345678.js').write_text('old chunk')
        (self.state / 'current').symlink_to(self.previous)
        self.config = dict(state=str(self.state), staging=str(self.staging), receiver=str(ROOT / 'scripts/classeur-stage-release.py'))
        self.app = FakeActivation(self.config)
        self.digest = self.stage(package(NEW))

    def stage(self, data):
        digest = hashlib.sha256(data).hexdigest()
        self.app.receiver.stage(io.BytesIO(data), self.staging, NEW, digest)
        return digest

    def test_strict_command(self):
        self.assertEqual(activation.command(f'activate {NEW} {self.digest}'), (NEW, self.digest))
        for raw in ['', 'id', f'activate {NEW} {self.digest}; id', f'activate {NEW} {self.digest}\n', f'activate ../{NEW} {self.digest}']:
            with self.assertRaises(ValueError):
                activation.command(raw)

    def test_success_and_retry_are_idempotent_and_retain_old_assets(self):
        result = self.app.activate(NEW, self.digest)
        self.assertEqual(result, dict(status='activated', revision=NEW, sha256=self.digest))
        current = (self.state / 'current').resolve()
        self.assertEqual(current.name, NEW)
        self.assertEqual((current / 'build/client/assets/main-abcdefgh.js').read_text(), 'new chunk')
        self.assertEqual((current / 'build/client/assets/old-12345678.js').read_text(), 'old chunk')
        self.assertEqual(self.app.calls.count(('restart', 'le-classeur.service')), 1)
        self.assertIn(('start', 'le-classeur-cleanup.timer'), self.app.calls)
        result = self.app.activate(NEW, self.digest)
        self.assertEqual(result['status'], 'already-active')
        self.assertEqual(self.app.calls.count(('restart', 'le-classeur.service')), 1)

    def test_corrupt_archive_never_touches_running_services(self):
        archive = self.staging / f'{NEW}-{self.digest}' / 'package.tar.gz'
        archive.write_bytes(b'corrupted')
        with self.assertRaises(ValueError):
            self.app.activate(NEW, self.digest)
        self.assertEqual(self.app.calls, [])
        self.assertEqual((self.state / 'current').resolve(), self.previous)

    def test_staging_directory_symlink_rejected(self):
        staged = self.staging / f'{NEW}-{self.digest}'
        hidden = self.staging / 'hidden'
        staged.rename(hidden)
        staged.symlink_to(hidden)
        with self.assertRaises(OSError):
            self.app.activate(NEW, self.digest)
        self.assertEqual(self.app.calls, [])

    def test_changed_migration_or_journal_refuses_before_candidate(self):
        for data in [package(NEW, sql='select 2;'), package(NEW, extra={'migrations/meta/_journal.json': '{"new":true}'})]:
            with self.subTest(digest=hashlib.sha256(data).hexdigest()):
                digest = self.stage(data)
                with self.assertRaisesRegex(ValueError, 'Migration contract changed'):
                    self.app.activate(NEW, digest)
                self.assertEqual(self.app.calls, [])
                self.assertEqual((self.state / 'current').resolve(), self.previous)

    def test_prepared_release_cannot_bypass_second_schema_check(self):
        target = self.app.prepare(NEW, self.digest)
        (target / 'migrations/0000.sql').write_text('changed')
        with self.assertRaises(ValueError):
            self.app.activate(NEW, self.digest)
        self.assertEqual(self.app.calls, [])

    def test_candidate_native_module_and_preexisting_public_failures_preserve_current(self):
        for failure in ['candidate', 'sharp', 'edge-before-switch']:
            with self.subTest(failure=failure):
                self.app.failure = failure
                self.app.calls = []
                with self.assertRaises(ValueError):
                    self.app.activate(NEW, self.digest)
                self.assertEqual((self.state / 'current').resolve(), self.previous)
                self.assertNotIn(('restart', 'le-classeur.service'), self.app.calls)
                self.assertNotIn(('stop', 'le-classeur-cleanup.timer', 'le-classeur-cleanup.service'), self.app.calls)

    def test_local_and_public_failures_rollback_and_resume_cleanup(self):
        for failure in ['local', 'public']:
            with self.subTest(failure=failure):
                self.app.failure = failure
                self.app.calls = []
                with self.assertRaises(ValueError):
                    self.app.activate(NEW, self.digest)
                self.assertEqual((self.state / 'current').resolve(), self.previous)
                self.assertEqual(self.app.calls.count(('restart', 'le-classeur.service')), 2)
                self.assertIn(('previous-health', OLD, True), self.app.calls)
                self.assertEqual(self.app.calls[-1], ('start', 'le-classeur-cleanup.timer'))

    def test_preserves_deliberately_stopped_cleanup_timer(self):
        self.app.timer = False
        self.app.activate(NEW, self.digest)
        self.assertNotIn(('start', 'le-classeur-cleanup.timer'), self.app.calls)

    def test_interrupt_after_switch_rolls_back_and_resumes_cleanup(self):
        ready = self.app.ready

        def interrupt(port, revision, public=False):
            if port == 8083:
                raise InterruptedError('lost worker signal')
            return ready(port, revision, public)

        with patch.object(self.app, 'ready', side_effect=interrupt):
            with self.assertRaises(InterruptedError):
                self.app.activate(NEW, self.digest)
        self.assertEqual((self.state / 'current').resolve(), self.previous)
        self.assertIn(('start', 'le-classeur-cleanup.timer'), self.app.calls)

    def test_supervisor_detaches_worker_from_ssh_and_verifies_durable_result(self):
        report = dict(status='activated', revision=NEW, sha256=self.digest)
        activation.save_result(self.config, report)
        config = self.config | dict(systemdRun='/systemd-run', caBundle='/ca', python='/python', path='/bin')
        with patch.object(activation.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0)) as run:
            self.assertEqual(activation.supervise('/immutable/config', config, NEW, self.digest), report)
            args = run.call_args.args[0]
            self.assertIn('--property=StandardOutput=journal', args)
            self.assertNotIn('--pipe', args)
            self.assertNotIn('--pty', args)
            self.assertIn('--property=KillMode=mixed', args)
        activation.save_result(self.config, report | {'revision': OLD})
        with patch.object(activation.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0)):
            with self.assertRaises(ValueError):
                activation.supervise('/immutable/config', config, NEW, self.digest)

    def test_real_flock_refuses_concurrent_activation_before_work(self):
        with (self.state / 'deploy.lock').open('a') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            with self.assertRaises(BlockingIOError):
                self.app.activate(NEW, self.digest)
        self.assertEqual(self.app.calls, [])
        self.assertEqual((self.state / 'current').resolve(), self.previous)

    def test_health_validates_revision_homepage_static_and_artwork(self):
        app = activation.Activation(self.config | {'publicOrigin': 'https://classeur.hexaflare.net'})
        headers = {'X-Classeur-Revision': NEW}
        responses = [
            (b'{"status":"ok","runtime":"node"}', headers),
            (f'<link href="/assets/main-abcdefgh.js"><img src="/accueil/illustrations/{"a"*64}">'.encode(), {}),
            (b'javascript', {}), (b'RIFF0000WEBPpayload', {}),
        ]
        with patch.object(app, 'get', side_effect=responses) as get:
            app.health(8085, NEW)
            self.assertEqual(get.call_count, 4)
        with patch.object(app, 'get', return_value=(responses[0][0], {'X-Classeur-Revision': OLD})):
            with self.assertRaisesRegex(ValueError, 'revision mismatch'):
                app.health(8085, NEW)
        with patch.object(app, 'get', side_effect=responses[:3] + [(b'broken', {})]):
            with self.assertRaisesRegex(ValueError, 'illustration unavailable'):
                app.health(8085, NEW)

    def test_nix_account_has_no_database_role_or_arbitrary_sudo_command(self):
        source = (ROOT / 'provisioning/applications/classeur-cd-activation.nix').read_text()
        self.assertIn('command = \'\'${activate} ""\'\';', source)
        self.assertIn('ForceCommand ${forced}', source)
        self.assertIn('DisableForwarding yes', source)
        self.assertNotIn('SETENV', source)
        self.assertNotIn('extraGroups', source)
        self.assertNotIn('le_classeur_beta_owner', source)


if __name__ == '__main__':
    unittest.main()
