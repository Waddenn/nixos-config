import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FILES = {
    "caddy": ("caddy", {"cf_api_token"}),
    "authelia": (
        "authelia",
        {
            "authelia_jwt_secret",
            "authelia_storage_encryption_key",
            "authelia_session_secret",
            "authelia_immich_oidc_client_secret_digest",
            "authelia_oidc_hmac_secret",
            "authelia_oidc_jwk_private_key",
            "authelia_user_admin_password_hash",
            "authelia_user_tom_password_hash",
        },
    ),
    "immich": ("immich", {"immich_oauth_client_secret"}),
    "controller": ("dev-nixos", {"discord-webhook"}),
    "gatus": ("gatus", {"discord-webhook"}),
    "operator": (None, {"gh-token", "cachix-auth-token"}),
}
SHARED_FILES = {
    "classeur-origin": ({"caddy", "classeur", "dev-nixos"}, {"classeur-origin-token"}),
    "classeur-turnstile": ({"classeur"}, {"turnstile-secret-key"}),
    "classeur-session": ({"classeur"}, {"session-secret"}),
}
PENDING_FILES = {
    "classeur": ({"classeur"}, {"classeur-environment"}),
}


class SopsIsolationTests(unittest.TestCase):
    def setUp(self):
        self.policy = (ROOT / ".sops.yaml").read_text()
        self.aliases = dict(re.findall(r"&([\w-]+)\s+(age1[\w]+)", self.policy))

    def test_encrypted_files_have_only_their_own_secrets_and_recipients(self):
        recovery = {self.aliases["primary"], self.aliases["workstation"]}
        self.assertNotEqual(self.aliases["primary"], self.aliases["workstation"])
        for service, (host, keys) in FILES.items():
            with self.subTest(service=service):
                text = (ROOT / "secrets" / f"{service}.yaml").read_text()
                actual_keys = set(re.findall(r"^([\w-]+):", text, re.MULTILINE)) - {"sops"}
                self.assertEqual(keys, actual_keys)
                for key in keys:
                    self.assertRegex(text, rf"(?m)^{re.escape(key)}: ENC\[AES256_GCM,")
                recipients = re.findall(r"recipient:\s+(age1[\w]+)", text)
                expected = recovery | ({self.aliases[host]} if host else set())
                self.assertEqual(expected, set(recipients))
                self.assertEqual(len(expected), len(recipients))

    def test_creation_rules_cannot_reintroduce_broad_host_access(self):
        # Inspect the small policy format without adding a CI dependency on PyYAML.
        rules = re.findall(
            r"path_regex:\s*(\S+)\s+key_groups:\s+- age:\s*\[([^\]]+)\]",
            self.policy,
        )
        self.assertEqual(len(FILES) + len(SHARED_FILES) + len(PENDING_FILES) + 1, len(rules))
        for service, (host, _) in FILES.items():
            path = f"secrets/{service}.yaml"
            matching = [aliases for pattern, aliases in rules if re.search(pattern, path)]
            self.assertTrue(matching, path)
            actual = set(re.findall(r"\*([\w-]+)", matching[0]))
            expected = {"primary", "workstation"} | ({host} if host else set())
            self.assertEqual(expected, actual, path)
        for service, (hosts, _) in {**SHARED_FILES, **PENDING_FILES}.items():
            path = f"provisioning/secrets/{service}.yaml"
            matching = [aliases for pattern, aliases in rules if re.search(pattern, path)]
            self.assertTrue(matching, path)
            self.assertEqual({"primary", "workstation"} | hosts,
                             set(re.findall(r"\*([\w-]+)", matching[0])))
        fallback = [aliases for pattern, aliases in rules if re.search(pattern, "secrets/new-service.yaml")]
        self.assertEqual(1, len(fallback))
        self.assertEqual({"primary", "workstation"}, set(re.findall(r"\*([\w-]+)", fallback[0])))

    def test_runtime_modules_use_explicit_service_files(self):
        modules = {
            "modules/services/networking/caddy.nix": "caddy",
            "modules/services/auth/authelia.nix": "authelia",
            "modules/services/media/immich.nix": "immich",
            "modules/services/infra/deployer-node.nix": "controller",
            "modules/services/monitoring/gatus.nix": "gatus",
        }
        for module, service in modules.items():
            text = (ROOT / module).read_text()
            references = re.findall(r"sopsFile\s*=\s*([^;]+);", text)
            self.assertTrue(references, module)
            expected = {f"../../../secrets/{service}.yaml"}
            if service == "caddy":
                expected.add("../../../provisioning/secrets/classeur-origin.yaml")
            self.assertEqual(expected, set(references), module)
        lxc = (ROOT / "modules/infra/proxmox-lxc-config.nix").read_text()
        self.assertNotIn("sops.defaultSopsFile", lxc)
        self.assertFalse((ROOT / "secrets/secrets.yaml").exists())
        self.assertNotIn("&github-runner", self.policy)

    def test_pilot_secret_files_have_scoped_recipients(self):
        for service, (hosts, keys) in SHARED_FILES.items():
            path = ROOT / "provisioning" / "secrets" / f"{service}.yaml"
            self.assertTrue(path.exists(), path)
            text = path.read_text()
            self.assertEqual(keys, set(re.findall(r"^([\w-]+):", text, re.MULTILINE)) - {"sops"})
            self.assertEqual({self.aliases[x] for x in hosts | {"primary", "workstation"}},
                             set(re.findall(r"recipient:\s+(age1[\w]+)", text)))
            for key in keys:
                self.assertRegex(text, rf"(?m)^{re.escape(key)}: ENC\[AES256_GCM,")


if __name__ == "__main__":
    unittest.main()
