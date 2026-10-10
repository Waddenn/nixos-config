#!/usr/bin/env python3
"""Forced-command receiver: stage an archive only, never execute it or activate it."""
import hashlib
import fcntl
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import sys
import tarfile
import tempfile

MAX_ARCHIVE = 512 * 1024 * 1024
MAX_UNPACKED = 2 * 1024 * 1024 * 1024
MAX_STAGED = 2 * 1024 * 1024 * 1024


def safe_member(item):
    path = PurePosixPath(item.name)
    if path.is_absolute() or '..' in path.parts or not (item.isfile() or item.isdir() or item.issym() or item.islnk()):
        raise ValueError('Unsafe archive member')
    if item.issym() or item.islnk():
        link = PurePosixPath(item.linkname)
        if link.is_absolute():
            raise ValueError('Absolute archive link')
        parts = list(path.parent.parts) if item.issym() else []
        for part in link.parts:
            if part == '..':
                if not parts:
                    raise ValueError('Escaping archive link')
                parts.pop()
            elif part != '.':
                parts.append(part)


def command(raw):
    match = re.fullmatch(r'stage ([a-f0-9]{40}) ([a-f0-9]{64})', raw)
    if not match:
        raise ValueError('Only a stage command with exact SHA/digest is accepted')
    return match.groups()


def stage(source, root, revision, digest):
    root = Path(root)
    # This directory must be provisioned by the operator; never create a service root.
    if not root.is_dir() or root.is_symlink():
        raise ValueError('Operator-provisioned incoming directory required')
    descriptor = os.open(root, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        fcntl.flock(descriptor, fcntl.LOCK_EX | fcntl.LOCK_NB)
        existing = sum(p.stat().st_size for p in root.rglob('*') if p.is_file())
        if existing + MAX_ARCHIVE > MAX_STAGED or shutil.disk_usage(root).free < 1024 * 1024 * 1024:
            raise ValueError('Insufficient bounded staging space')
        return receive(source, root, revision, digest)
    finally:
        os.close(descriptor)


def receive(source, root, revision, digest):
    temporary = Path(tempfile.mkdtemp(prefix='.incoming-', dir=root))
    try:
        archive = temporary / 'package.tar.gz'
        sha = hashlib.sha256()
        size = 0
        with archive.open('xb') as output:
            while chunk := source.read(1024 * 1024):
                size += len(chunk)
                if size > MAX_ARCHIVE:
                    raise ValueError('Archive exceeds limit')
                sha.update(chunk)
                output.write(chunk)
        if sha.hexdigest() != digest:
            raise ValueError('Checksum mismatch')
        # Inspect metadata without extracting dependencies or following archive links.
        with tarfile.open(archive, mode='r:gz') as tar:
            total = count = 0
            release = None
            members = set()
            links = set()
            for item in tar:
                safe_member(item)
                member = PurePosixPath(item.name)
                if member in members:
                    raise ValueError('Duplicate archive member')
                members.add(member)
                if item.issym() or item.islnk():
                    links.add(member)
                count += 1
                total += item.size
                if count > 50000 or total > MAX_UNPACKED:
                    raise ValueError('Archive expanded limits exceeded')
                if item.name in ('release.json', './release.json'):
                    if release is not None or not item.isfile() or item.size > 8192:
                        raise ValueError('Invalid release metadata')
                    release = json.load(tar.extractfile(item))
            if any(parent in links for member in members for parent in member.parents):
                raise ValueError('Archive member below a link')
            if not isinstance(release, dict) or release.get('revision') != revision or release.get('rehearsal') is not False or release.get('platform') != 'linux' or release.get('architecture') != 'x64':
                raise ValueError('Release identity/platform/rehearsal mismatch')
        (temporary / 'review.json').write_text(json.dumps({'revision': revision, 'sha256': digest, 'activated': False}) + '\n')
        destination = root / f'{revision}-{digest}'
        if destination.exists():
            if not destination.is_dir() or destination.is_symlink() or (destination / 'review.json').read_text() != (temporary / 'review.json').read_text():
                raise ValueError('Conflicting staged release')
            return destination.name
        temporary.rename(destination)
        temporary = None
        return destination.name
    finally:
        if temporary is not None:
            shutil.rmtree(temporary)


if __name__ == '__main__':
    os.umask(0o077)
    try:
        revision, digest = command(os.environ.get('SSH_ORIGINAL_COMMAND', ''))
        name = stage(sys.stdin.buffer, '/var/lib/le-classeur-staging', revision, digest)
        print(f'Staged {name}; activation remains an operator operation')
    except (ValueError, OSError, tarfile.TarError, UnicodeDecodeError):
        print('Staging rejected', file=sys.stderr)
        sys.exit(1)
