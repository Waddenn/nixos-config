import re
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
ARGON2_HASH = re.compile(r"\$argon2(?:id|i|d)\$v=\d+\$m=\d+,t=\d+,p=\d+\$[^\s\"']+\$[^\s\"']+")


class AutheliaSecretsTests(unittest.TestCase):
    def test_password_hashes_are_not_committed_as_plaintext(self):
        candidates = [
            *REPO_ROOT.glob("hosts/**/*.nix"),
            *REPO_ROOT.glob("modules/**/*.nix"),
            *REPO_ROOT.glob("docs/**/*.md"),
        ]
        leaked = [str(path.relative_to(REPO_ROOT)) for path in candidates if ARGON2_HASH.search(path.read_text())]
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


if __name__ == "__main__":
    unittest.main()
