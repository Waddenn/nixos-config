#!/usr/bin/env python3
"""Bound system history without collecting the running or next-boot system."""
import fcntl
import os
from pathlib import Path
import re
import subprocess
import sys


def obsolete_generations(generations, protected, keep=3, current=None):
    newest = set(sorted(generations, reverse=True)[:keep])
    if current is not None:
        newest.add(current)
    for target in protected:
        matching = [n for n, value in generations.items() if value == target]
        if matching:
            newest.add(max(matching))
    return sorted(n for n in generations if n not in newest)


def main():
    if os.geteuid() != 0:
        raise RuntimeError('Storage maintenance requires root')
    if sys.argv[1:] not in ([], ['--prune']):
        raise RuntimeError('Supported argument: --prune')
    with open('/run/lock/nix-storage-cleanup.lock', 'w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        roots = Path('/nix/var/nix/gcroots/storage-maintenance')
        roots.mkdir(parents=True, exist_ok=True)
        protected = set()
        for name, source in [('active', '/run/current-system'),
                             ('boot', '/nix/var/nix/profiles/system')]:
            target = Path(source).resolve(strict=True)
            if not str(target).startswith('/nix/store/'):
                raise RuntimeError('Invalid protected system')
            protected.add(str(target))
            temporary = roots / (name + '.new')
            temporary.unlink(missing_ok=True)
            temporary.symlink_to(target)
            temporary.replace(roots / name)
        if sys.argv[1:] == ['--prune']:
            profile = Path('/nix/var/nix/profiles/system')
            generations = {}
            for path in profile.parent.glob('system-*-link'):
                match = re.fullmatch(r'system-(\d+)-link', path.name)
                if match:
                    generations[int(match[1])] = str(path.resolve(strict=True))
            current_link = os.readlink(profile)
            current_match = re.fullmatch(r"system-(\d+)-link", Path(current_link).name)
            if not current_match:
                raise RuntimeError("Invalid current generation link")
            obsolete = obsolete_generations(generations, protected, current=int(current_match[1]))
            if obsolete:
                subprocess.run(['nix-env', '--profile', str(profile), '--delete-generations',
                                *map(str, obsolete)], check=True)
        # Never deletes user profiles or application data. Referenced closures remain roots.
        subprocess.run(['nix-store', '--gc'], check=True)


if __name__ == '__main__':
    main()
