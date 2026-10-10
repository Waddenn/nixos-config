#!/usr/bin/env python3
"""Fixed, root-owned code-only activation protocol. Never executes a migration."""
import fcntl
import grp
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys
import tarfile
import tempfile
import time
import urllib.request


def command(raw):
    match = re.fullmatch(r'activate ([a-f0-9]{40}) ([a-f0-9]{64})', raw)
    if not match:
        raise ValueError('Expected activate SHA40 SHA256')
    return match.groups()


def migrations(root):
    folder = root / 'migrations'
    if not folder.is_dir() or folder.is_symlink():
        raise ValueError('Missing migration contract')
    result = {}
    for path in sorted(folder.rglob('*')):
        if path.is_symlink() or not (path.is_dir() or path.is_file()):
            raise ValueError('Invalid migration contract')
        if path.is_file():
            result[str(path.relative_to(folder))] = hashlib.sha256(path.read_bytes()).hexdigest()
    if not result or 'meta/_journal.json' not in result:
        raise ValueError('Incomplete migration contract')
    return result


def atomic_current(state, release):
    link = state / 'current.next'
    link.unlink(missing_ok=True)
    link.symlink_to(release)
    link.replace(state / 'current')


class Activation:
    def __init__(self, config):
        self.config = config
        self.state = Path(config['state'])
        spec = importlib.util.spec_from_file_location('receiver', config['receiver'])
        self.receiver = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.receiver)

    def run(self, *args, check=True, timeout=90):
        # No inherited SSH/client environment and never a shell. Do not echo
        # subprocess errors, environment or output containing runtime secrets.
        return subprocess.run(args, check=check, timeout=timeout, capture_output=True,
                              env={'PATH': self.config['path'], 'LANG': 'C.UTF-8'})

    def systemctl(self, *args, check=True):
        return self.run(self.config['systemctl'], *args, check=check)

    def prepare(self, revision, digest):
        verified = self.state / 'verified-packages'
        verified.mkdir(mode=0o700, exist_ok=True)
        staged = Path(self.config['staging']) / f'{revision}-{digest}'
        directory = os.open(staged, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
        try:
            descriptor = os.open('package.tar.gz', os.O_RDONLY | os.O_NOFOLLOW, dir_fd=directory)
            with os.fdopen(descriptor, 'rb') as source:
                name = self.receiver.stage(source, verified, revision, digest)
        finally:
            os.close(directory)
        archive = verified / name / 'package.tar.gz'
        target = self.state / 'releases' / revision
        marker = {'revision': revision, 'sha256': digest}
        if target.exists() or target.is_symlink():
            if target.is_symlink() or json.loads((target / '.activation.json').read_text()) != marker:
                raise ValueError('Existing release has no matching verified provenance')
            return target
        temporary = Path(tempfile.mkdtemp(prefix='.activate-', dir=target.parent))
        try:
            with tarfile.open(archive, 'r:gz') as tar:
                tar.extractall(temporary, filter='data')
            for required in ['build/server/index.js', 'package.json', 'release.json']:
                path = temporary / required
                if path.is_symlink() or not path.is_file():
                    raise ValueError('Missing release entrypoint or identity')
            # Exact SQL and journal/snapshot bytes: new migrations require manual
            # maintenance. This also guarantees that N-1 rollback is compatible.
            previous = (self.state / 'current').resolve(strict=True)
            if migrations(previous) != migrations(temporary):
                raise ValueError('Migration contract changed; manual maintenance required')
            assets = temporary / 'build/client/assets'
            if assets.is_symlink() or not assets.is_dir():
                raise ValueError('Missing static assets')
            for source in sorted((previous / 'build/client/assets').iterdir()):
                if source.is_symlink() or not source.is_file():
                    continue
                if not re.fullmatch(r'[A-Za-z0-9_.-]+-[A-Za-z0-9_-]{8,}\.[A-Za-z0-9.]+', source.name):
                    continue
                destination = assets / source.name
                if not destination.exists() and not destination.is_symlink():
                    shutil.copyfile(source, destination)
            if (temporary / '.activation.json').exists() or (temporary / '.activation.json').is_symlink():
                raise ValueError('Archive supplied operator provenance')
            (temporary / '.activation.json').write_text(json.dumps(marker) + '\n')
            self.permissions(temporary)
            temporary.rename(target)
            return target
        finally:
            if temporary.exists():
                shutil.rmtree(temporary)

    def permissions(self, directory):
        gid = grp.getgrnam('le-classeur').gr_gid
        for path in [directory, *directory.rglob('*')]:
            os.chown(path, 0, gid, follow_symlinks=False)
            if not path.is_symlink():
                path.chmod(0o750 if path.is_dir() or path.stat().st_mode & 0o111 else 0o640)

    def candidate(self, target):
        runtime = [
            'User=le_classeur_app', 'Group=le-classeur', f'WorkingDirectory={target}',
            f'EnvironmentFile={self.config["environmentFile"]}', 'NoNewPrivileges=yes',
            'ProtectSystem=strict', 'ProtectHome=yes', 'PrivateTmp=yes',
            'ProtectKernelTunables=yes', 'ProtectKernelModules=yes', 'ProtectControlGroups=yes',
            'RestrictSUIDSGID=yes', 'RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6',
            'UMask=0077', 'LimitNOFILE=4096', 'MemoryMax=2G', 'RuntimeMaxSec=180s',
            'TimeoutStopSec=30s',
        ]
        arguments = [self.config['systemdRun'], '--unit=le-classeur-candidate', '--collect']
        arguments += [f'--property={item}' for item in runtime]
        arguments += [f'--setenv={key}={value}' for key, value in self.config['environment'].items()]
        # env arguments override the secret EnvironmentFile's optional old PORT.
        arguments += [self.config['env'], 'PORT=8085', 'MIGRATION_FROZEN=false',
                      self.config['node'], str(target / 'build/server/index.js')]
        self.run(*arguments)

    def sharp(self, target):
        code = "const sharp=require('module').createRequire(" + json.dumps(str(target / 'package.json')) + ")('sharp'); sharp({create:{width:2,height:2,channels:3,background:'#ffffff'}}).webp().toBuffer().then(b=>sharp(b).stats()).catch(()=>process.exit(1));"
        self.run(self.config['runuser'], '-u', 'le_classeur_app', '--', self.config['env'],
                 f'LD_LIBRARY_PATH={self.config["environment"]["LD_LIBRARY_PATH"]}',
                 self.config['node'], '-e', code, timeout=30)

    def get(self, base, path, revision, limit=2 * 1024 * 1024):
        request = urllib.request.Request(base + path, headers={
            'Host': 'classeur.hexaflare.net', 'Cache-Control': 'no-cache',
            'User-Agent': 'Le-classeur-delivery-health/1',
        })
        # Redirects must not turn a failed origin into an unrelated healthy page.
        with urllib.request.urlopen(request, timeout=4) as response:
            if response.url != request.full_url or response.status != 200:
                raise ValueError('Unexpected health response')
            data = response.read(limit + 1)
            if len(data) > limit:
                raise ValueError('Health response too large')
            return data, response.headers

    def health(self, port, revision, public=False):
        base = self.config['publicOrigin'] if public else f'http://127.0.0.1:{port}'
        body, headers = self.get(base, '/health', revision)
        health = json.loads(body)
        if health.get('status') != 'ok' or health.get('runtime') != 'node':
            raise ValueError('Application unhealthy')
        if headers.get('X-Classeur-Revision') != revision:
            raise ValueError('Application revision mismatch')
        body, _ = self.get(base, '/', revision)
        html = body.decode('utf-8')
        assets = re.findall(r'(?:src|href)="(/assets/[A-Za-z0-9_.-]+)"', html)
        if not assets:
            raise ValueError('Homepage contains no static assets')
        self.get(base, assets[0], revision)
        artwork = re.search(r'(/accueil/illustrations/[a-f0-9]{64})', html)
        if artwork:
            image, _ = self.get(base, artwork[1], revision)
            if image[:4] != b'RIFF' or image[8:12] != b'WEBP':
                raise ValueError('Homepage illustration unavailable')

    def ready(self, port, revision, public=False):
        for attempt in range(15):
            try:
                self.health(port, revision, public)
                return
            except (OSError, ValueError):
                if attempt == 14:
                    raise
                time.sleep(1)

    def previous_health(self, revision, public=False):
        base = self.config['publicOrigin'] if public else 'http://127.0.0.1:8083'
        for attempt in range(15):
            try:
                body, headers = self.get(base, '/health', revision)
                health = json.loads(body)
                if health.get('status') != 'ok' or health.get('runtime') != 'node':
                    raise ValueError('Previous application unhealthy')
                if headers.get('X-Classeur-Revision', revision) != revision:
                    raise ValueError('Previous revision mismatch')
                return
            except (OSError, ValueError):
                if attempt == 14:
                    raise
                time.sleep(1)

    def activate(self, revision, digest):
        with (self.state / 'deploy.lock').open('a') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            previous = (self.state / 'current').resolve(strict=True)
            old_revision = json.loads((previous / 'release.json').read_text())['revision']
            target = self.prepare(revision, digest)
            if migrations(previous) != migrations(target):
                raise ValueError('Migration contract changed; manual maintenance required')
            if previous == target:
                self.ready(8083, revision, public=True)
                return {'revision': revision, 'sha256': digest, 'status': 'already-active'}
            paused = switched = False
            timer_active = self.systemctl('is-active', '--quiet', 'le-classeur-cleanup.timer', check=False).returncode == 0
            try:
                # A stale candidate is ours; never touch unrelated Node services.
                self.systemctl('stop', 'le-classeur-candidate.service', check=False)
                self.sharp(target)
                self.candidate(target)
                self.ready(8085, revision)
                # An existing edge outage must reject before switching code.
                self.previous_health(old_revision, public=True)
                paused = True
                self.systemctl('stop', 'le-classeur-cleanup.timer', 'le-classeur-cleanup.service')
                self.systemctl('stop', 'le-classeur-candidate.service')
                atomic_current(self.state, target)
                switched = True
                self.systemctl('restart', 'le-classeur.service')
                self.ready(8083, revision)
                self.ready(8083, revision, public=True)
                return {'revision': revision, 'sha256': digest, 'status': 'activated'}
            except BaseException:
                if switched:
                    atomic_current(self.state, previous)
                    self.systemctl('restart', 'le-classeur.service')
                    # Old releases may predate the revision header; still verify
                    # local health and the selected immutable filesystem identity.
                    self.previous_health(old_revision)
                    self.previous_health(old_revision, public=True)
                raise
            finally:
                self.systemctl('stop', 'le-classeur-candidate.service', check=False)
                if paused and timer_active:
                    self.systemctl('start', 'le-classeur-cleanup.timer')


def interrupted(_signal, _frame):
    raise InterruptedError('Activation interrupted')


def save_result(config, result):
    state = Path(config['state'])
    temporary = state / 'activation-result.next'
    temporary.write_text(json.dumps(result) + '\n')
    temporary.chmod(0o600)
    temporary.replace(state / 'activation-result.json')


def supervise(config_path, config, revision, digest):
    # The worker belongs to systemd, not the SSH connection. Closing the SSH
    # channel cannot kill it between symlink replacement and rollback/finally.
    result = subprocess.run([
        config['systemdRun'], '--quiet', '--collect', '--wait',
        '--unit=le-classeur-activation', '--property=Type=oneshot',
        '--property=TimeoutStartSec=480s', '--property=TimeoutStopSec=120s',
        '--property=KillMode=mixed', '--property=StandardOutput=journal',
        '--property=StandardError=journal', '--property=UMask=0077',
        f'--setenv=SSL_CERT_FILE={config["caBundle"]}',
        config['python'], str(Path(__file__).resolve()), config_path,
        '--worker', revision, digest,
    ], capture_output=True, timeout=620, check=False,
        env={'PATH': config['path'], 'LANG': 'C.UTF-8'})
    if result.returncode:
        raise RuntimeError('Activation unit rejected or rolled back')
    report = json.loads((Path(config['state']) / 'activation-result.json').read_text())
    if report.get('revision') != revision or report.get('sha256') != digest or report.get('status') not in ['activated', 'already-active']:
        raise ValueError('Activation result mismatch')
    return report


if __name__ == '__main__':
    os.umask(0o027)
    try:
        if os.getuid() != 0 or len(sys.argv) not in [2, 5]:
            raise ValueError('Root fixed wrapper required')
        config = json.loads(Path(sys.argv[1]).read_text())
        if len(sys.argv) == 2:
            revision, digest = command(sys.stdin.read(160))
            result = supervise(sys.argv[1], config, revision, digest)
        else:
            if sys.argv[2] != '--worker':
                raise ValueError('Invalid worker mode')
            revision, digest = command(f'activate {sys.argv[3]} {sys.argv[4]}')
            for event in [signal.SIGTERM, signal.SIGINT, signal.SIGHUP]:
                signal.signal(event, interrupted)
            try:
                result = Activation(config).activate(revision, digest)
                save_result(config, result)
            except BaseException as error:
                save_result(config, dict(status='rejected-or-rolled-back', revision=revision,
                                         sha256=digest, error=type(error).__name__))
                raise
        print(json.dumps(result))
    except Exception as error:
        # No exception payload: libraries can include URLs/env/secrets.
        print(json.dumps({'status': 'rejected-or-rolled-back', 'error': type(error).__name__}), file=sys.stderr)
        sys.exit(1)
