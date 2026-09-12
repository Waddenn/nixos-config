import re
import subprocess
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
ARGON2_HASH = re.compile(r"\$argon2(?:id|i|d)\$v=\d+\$m=\d+,t=\d+,p=\d+\$[^\s\"']+\$[^\s\"']+")


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
        self.assertIn('config.sops.templates."authelia-users-database.yml".path', module)
        self.assertIn("config.sops.placeholder.${user.hashSecret}", module)

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


if __name__ == "__main__":
    unittest.main()
