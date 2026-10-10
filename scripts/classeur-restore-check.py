#!/usr/bin/env python3
"""Restore an off-host dump into an ephemeral CT database; never touch live data."""
import argparse
from datetime import datetime, timezone
import hashlib
import os
from pathlib import Path
import re
import shlex
import subprocess
import uuid

SSH_CONFIG = '/var/lib/proxmox-prototype/ssh_config'
CT = 'service-classeur'


def target_name():
    return 'classeur_restore_check_' + datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S') + '_' + uuid.uuid4().hex[:8]


def restore_script(database, path):
    if not re.fullmatch(r'classeur_restore_check_[0-9]{14}_[0-9a-f]{8}', database):
        raise ValueError('Restore target must be disposable')
    source = shlex.quote(path)
    return f'''set -eu
test "$(id -u)" = 0
test -f {source}
cleanup() {{
  runuser -u postgres -- dropdb --if-exists {database}
  rm -rf -- "$(dirname {source})"
}}
trap cleanup EXIT
runuser -u postgres -- createdb --template=template0 {database}
runuser -u postgres -- pg_restore --exit-on-error --single-transaction --no-owner --no-privileges --dbname={database} {source}
runuser -u postgres -- psql -X -v ON_ERROR_STOP=1 -d {database} <<'SQL'
SET statement_timeout = '120s';
REINDEX DATABASE {database};
ALTER DATABASE {database} REFRESH COLLATION VERSION;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_index i JOIN pg_class c ON c.oid=i.indexrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND NOT i.indisvalid) THEN
    RAISE EXCEPTION 'Invalid restored index';
  END IF;
  IF EXISTS (SELECT 1 FROM cards c WHERE c.circulation <> (SELECT count(*) FROM instances i WHERE i.card_id=c.id AND NOT i.test AND NOT i.recycled)) THEN
    RAISE EXCEPTION 'Restored circulation mismatch';
  END IF;
  IF EXISTS (SELECT 1 FROM cards c JOIN instances i ON i.card_id=c.id WHERE i.print_number > CASE WHEN i.test THEN c.last_test_print ELSE c.last_print END) THEN
    RAISE EXCEPTION 'Restored print counter mismatch';
  END IF;
  IF EXISTS (SELECT 1 FROM players WHERE dust < 0 OR boosters < 0) THEN
    RAISE EXCEPTION 'Restored negative balance';
  END IF;
END $$;
SELECT current_database() AS disposable_database, pg_size_pretty(pg_database_size(current_database())) AS size,
  (SELECT count(*) FROM pg_tables WHERE schemaname='public') AS tables,
  (SELECT count(*) FROM instances) AS instances,
  (SELECT count(*) FROM events) AS audit_events;
SELECT datcollversion, pg_database_collation_actual_version(oid) AS actual FROM pg_database WHERE datname=current_database();
SQL
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--dump', type=Path, required=True, help='Local off-host copy on dev-nixos')
    options = parser.parse_args()
    if os.geteuid() != 0:
        raise ValueError('Run only as root on dev-nixos')
    dump = options.dump.resolve(strict=True)
    if not re.fullmatch(r'[0-9]{8}T[0-9]{6}Z\.dump', dump.name):
        raise ValueError('Expected timestamped off-host dump')
    checksum_file = dump.with_name(dump.name + '.sha256')
    expected = checksum_file.read_text().split()[0]
    if not re.fullmatch(r'[0-9a-f]{64}', expected):
        raise ValueError('Invalid checksum')
    with dump.open('rb') as stream:
        actual = hashlib.file_digest(stream, 'sha256').hexdigest()
    if actual != expected:
        raise ValueError('Off-host dump checksum mismatch')
    remote = '/var/tmp/' + target_name()
    ssh = ['ssh', '-oBatchMode=yes', '-F', SSH_CONFIG, CT]
    subprocess.run(ssh + [f'install -d -o postgres -g postgres -m 0700 {remote}'], check=True)
    try:
        subprocess.run(['scp', '-q', '-oBatchMode=yes', '-F', SSH_CONFIG, str(dump), f'{CT}:{remote}/restore.dump'], check=True)
        subprocess.run(ssh + [f'chown postgres:postgres {remote}/restore.dump; chmod 0600 {remote}/restore.dump'], check=True)
        subprocess.run(ssh + ['bash -se'], input=restore_script(target_name(), remote + '/restore.dump'), text=True, check=True, timeout=600)
    finally:
        subprocess.run(ssh + [f'rm -rf -- {remote}'], check=True)
    print('Off-host dump restored, reindexed and reconciled; disposable database removed')


if __name__ == '__main__':
    main()
