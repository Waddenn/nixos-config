#!/usr/bin/env python3
"""Controller-only pull of verified logical dumps, without sharing controller keys."""
import hashlib
import os
from pathlib import Path
import re
import subprocess
import tempfile

DESTINATION = Path('/var/backup/le-classeur-offhost')
SSH_CONFIG = '/var/lib/proxmox-prototype/ssh_config'
CT = 'service-classeur'
STORE = 'root@terraform'
STORE_DIR = '/root/le-classeur-backups'


def run(args):
    result = subprocess.run(args, capture_output=True, text=True, timeout=900)
    if result.returncode:
        # SSH diagnostics may contain infrastructure details. Never print payloads.
        raise RuntimeError(f'{Path(args[0]).name} failed ({result.returncode})')
    return result.stdout.strip()


def ct(command):
    return run(['ssh', '-oBatchMode=yes', '-F', SSH_CONFIG, CT, command])


def store(command):
    return run(['ssh', '-oBatchMode=yes', '-oStrictHostKeyChecking=yes', STORE, command])


def dump_name(value):
    if not re.fullmatch(r'[0-9]{8}T[0-9]{6}Z\.dump', value):
        raise ValueError('Unexpected backup name')
    return value


def verify(path, expected):
    if not re.fullmatch(r'[0-9a-f]{64}', expected):
        raise ValueError('Invalid checksum')
    with path.open('rb') as source:
        digest = hashlib.file_digest(source, 'sha256').hexdigest()
    if digest != expected:
        raise ValueError('Backup checksum differs')


def main():
    os.umask(0o077)
    # Initial enablement requires a tested application/restore. Routine backups
    # remain possible when HTTP is down, as long as PostgreSQL can produce a dump.
    ct('systemctl start le-classeur-backup.service')
    name = dump_name(ct("find /var/backup/le-classeur -maxdepth 1 -type f -name '*.dump' -printf '%f\\n' | sort | tail -1"))
    checksum = ct(f'sha256sum /var/backup/le-classeur/{name}').split()[0]
    DESTINATION.mkdir(mode=0o700, parents=True, exist_ok=True)
    if DESTINATION.stat().st_uid != 0 or DESTINATION.stat().st_mode & 0o077:
        raise ValueError('Local backup directory must be private and root-owned')
    fd, temporary = tempfile.mkstemp(dir=DESTINATION, suffix='.partial')
    os.close(fd)
    temporary = Path(temporary)
    try:
        run(['scp', '-q', '-oBatchMode=yes', '-F', SSH_CONFIG,
             f'{CT}:/var/backup/le-classeur/{name}', str(temporary)])
        verify(temporary, checksum)
        temporary.replace(DESTINATION / name)
    finally:
        temporary.unlink(missing_ok=True)
    (DESTINATION / (name + '.sha256')).write_text(f'{checksum}  {name}\n')
    store(f'umask 077; mkdir -p {STORE_DIR}; chmod 700 {STORE_DIR}')
    run(['scp', '-q', '-oBatchMode=yes', '-oStrictHostKeyChecking=yes',
         str(DESTINATION / name), f'{STORE}:{STORE_DIR}/{name}.partial'])
    remote_checksum = store(f'sha256sum {STORE_DIR}/{name}.partial').split()[0]
    if remote_checksum != checksum:
        raise ValueError('Off-host backup checksum differs; final file not published')
    store(f'mv {STORE_DIR}/{name}.partial {STORE_DIR}/{name}; chmod 600 {STORE_DIR}/{name}')
    run(['scp', '-q', '-oBatchMode=yes', '-oStrictHostKeyChecking=yes',
         str(DESTINATION / (name + '.sha256')), f'{STORE}:{STORE_DIR}/'])
    # No automatic deletion: enable a bounded retention only after restore validation.
    print('Le classeur dump verified on controller and separate storage host')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, RuntimeError, OSError, IndexError, subprocess.SubprocessError) as error:
        raise SystemExit(f'Le classeur off-host backup failed: {type(error).__name__}')
