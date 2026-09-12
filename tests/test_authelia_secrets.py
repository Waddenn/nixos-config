import grp
import json
import os
import pwd
import re
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
ARGON2_HASH = re.compile(r"\$argon2(?:id|i|d)\$v=\d+\$m=\d+,t=\d+,p=\d+\$[^\s\"']+\$[^\s\"']+")
INIT_SCRIPT = REPO_ROOT / "scripts/init-authelia-users.sh"


class AutheliaSecretsTests(unittest.TestCase):
    def test_password_hashes_are_not_committed_as_plaintext(self):
        tracked = subprocess.run(
            ["git", "ls-files", "-z"],
            cwd=REPO_ROOT,
            check=True,
            capture_output=True,
        ).stdout.decode().split("\0")
        candidates = [REPO_ROOT / name for name in tracked if name]
        leaked = [
            str(path.relative_to(REPO_ROOT))
            for path in candidates
            if ARGON2_HASH.search(path.read_text(errors="ignore"))
        ]
        self.assertEqual([], leaked, f"plaintext Argon2 hashes found in: {', '.join(leaked)}")

    def test_authelia_users_reference_runtime_sops_secrets(self):
        host = (REPO_ROOT / "hosts/authelia/default.nix").read_text()
        module = (REPO_ROOT / "modules/services/auth/authelia.nix").read_text()

        self.assertNotRegex(host, r"(?m)^\s*password\s*=")
        self.assertIn('hashSecret = "authelia_user_admin_password_hash";', host)
        self.assertIn('hashSecret = "authelia_user_tom_password_hash";', host)
        self.assertIn("usersDatabaseFile = cfg.usersFile;", module)
        self.assertIn("password_change.disable = false;", module)
        self.assertIn("config.sops.placeholder.${user.hashSecret}", module)
        self.assertIn("authelia-users-setup", module)
        self.assertIn(".users-database-migrated-v1", module)
        self.assertNotIn('then config.sops.templates."authelia-users-database.yml".path', module)

    def test_password_hash_secrets_are_sops_encrypted(self):
        secrets = (REPO_ROOT / "secrets/secrets.yaml").read_text()
        for name in (
            "authelia_user_admin_password_hash",
            "authelia_user_tom_password_hash",
        ):
            self.assertRegex(secrets, rf"(?m)^{name}: ENC\[AES256_GCM,")

    def test_forward_auth_domains_have_an_explicit_authelia_policy(self):
        caddy = (REPO_ROOT / "modules/services/networking/caddy.nix").read_text()
        authelia = (REPO_ROOT / "hosts/authelia/default.nix").read_text()

        virtual_host = re.compile(r'^\s*"(?P<domain>[^"\s]+)"\s*=\s*\{', re.MULTILINE)
        matches = list(virtual_host.finditer(caddy))
        protected_domains = {
            match.group("domain")
            for index, match in enumerate(matches)
            if "forward_auth"
            in caddy[
                match.end() : matches[index + 1].start()
                if index + 1 < len(matches)
                else len(caddy)
            ]
        }

        active_authelia = "\n".join(line.split("#", 1)[0] for line in authelia.splitlines())
        policy_blocks = re.findall(
            r"\{[^{}]*domain\s*=\s*\[(.*?)\];[^{}]*policy\s*=\s*\"(?!bypass\b)[^\"]+\";[^{}]*\}",
            active_authelia,
            re.DOTALL,
        )
        policy_domains = {
            domain
            for domains in policy_blocks
            for domain in re.findall(r'\"([^\"]+)\"', domains)
        }

        self.assertTrue(protected_domains, "no Caddy forward_auth domain found")
        self.assertEqual(set(), protected_domains - policy_domains)

    def _fake_yq(self, directory):
        fake = directory / "yq"
        fake.write_text(
            """#!/usr/bin/env python3
import json
import sys

paths = [arg for arg in sys.argv[1:] if not arg.startswith('-') and arg not in ('eval', 'eval-all', '.', '.users | type == "!!map" and length > 0', 'yaml', '2')]
if sys.argv[1] == 'eval-all':
    seed, existing = (json.load(open(path)) for path in paths[-2:])
    merged = seed
    merged.setdefault('users', {}).update(existing.get('users', {}))
    json.dump(merged, sys.stdout)
elif '-e' in sys.argv:
    data = json.load(open(paths[-1]))
    raise SystemExit(0 if isinstance(data.get('users'), dict) and data['users'] else 1)
else:
    json.dump(json.load(open(paths[-1])), sys.stdout)
"""
        )
        fake.chmod(0o700)
        return fake

    def _run_initializer(self, seed, target, marker, yq, validator="/bin/true"):
        owner = pwd.getpwuid(os.getuid()).pw_name
        group = grp.getgrgid(os.getgid()).gr_name
        return subprocess.run(
            [
                str(INIT_SCRIPT),
                str(seed),
                str(target),
                str(marker),
                owner,
                group,
                str(yq),
                validator,
            ],
            check=False,
            capture_output=True,
            text=True,
        )

    def test_writable_database_is_seeded_once_and_preserves_user_changes(self):
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            seed = directory / "seed.json"
            target = directory / "state/users_database.yml"
            marker = directory / "state/.users-database-migrated-v1"
            yq = self._fake_yq(directory)
            seed.write_text(json.dumps({"users": {"tom": {"password": "a"}}}))

            result = self._run_initializer(seed, target, marker, yq)
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertEqual("a", json.loads(target.read_text())["users"]["tom"]["password"])
            self.assertEqual(0o600, stat.S_IMODE(target.stat().st_mode))
            self.assertEqual(os.getuid(), target.stat().st_uid)
            self.assertEqual(os.getgid(), target.stat().st_gid)
            self.assertNotIn("/nix/store", str(target))
            self.assertNotIn("/run/secrets", str(target))

            changed = {"users": {"tom": {"password": "b"}}}
            target.write_text(json.dumps(changed))
            seed.write_text(json.dumps({"users": {"tom": {"password": "c"}}}))
            result = self._run_initializer(seed, target, marker, yq)
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertEqual(changed, json.loads(target.read_text()))

    def test_first_migration_merges_missing_users_without_overwriting_existing(self):
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            seed = directory / "seed.json"
            target = directory / "state/users_database.yml"
            marker = directory / "state/.users-database-migrated-v1"
            target.parent.mkdir()
            target.write_text(json.dumps({"users": {"tom": {"password": "a"}}}))
            seed.write_text(json.dumps({"users": {"tom": {"password": "b"}, "admin": {"password": "c"}}}))

            result = self._run_initializer(seed, target, marker, self._fake_yq(directory))
            self.assertEqual(0, result.returncode, result.stderr)
            users = json.loads(target.read_text())["users"]
            self.assertEqual("a", users["tom"]["password"])
            self.assertIn("admin", users)
            self.assertTrue(Path(f"{target}.pre-sops-migration").exists())

    def test_failed_validation_restores_existing_database(self):
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            seed = directory / "seed.json"
            target = directory / "state/users_database.yml"
            marker = directory / "state/.users-database-migrated-v1"
            target.parent.mkdir()
            original = {"users": {"tom": {"password": "a"}}}
            target.write_text(json.dumps(original))
            seed.write_text(json.dumps({"users": {"admin": {"password": "b"}}}))

            result = self._run_initializer(seed, target, marker, self._fake_yq(directory), "/bin/false")
            self.assertNotEqual(0, result.returncode)
            self.assertEqual(original, json.loads(target.read_text()))
            self.assertFalse(marker.exists())


if __name__ == "__main__":
    unittest.main()
