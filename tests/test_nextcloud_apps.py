import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
NEXTCLOUD = ROOT / "modules/services/misc/nextcloud.nix"


class NextcloudAppsTest(unittest.TestCase):
    def test_contacts_duplicate_is_archived_before_setup(self):
        module = NEXTCLOUD.read_text()
        self.assertIn("systemd.services.nextcloud-setup.preStart", module)
        self.assertIn("/var/lib/nextcloud/store-apps/contacts", module)
        self.assertIn("nextcloud-occ app:disable contacts", module)
        self.assertIn("/var/lib/nextcloud/app-backups/managed-by-nix", module)
        self.assertIn(
            "extraApps = with config.services.nextcloud.package.packages.apps;",
            module,
        )
        self.assertRegex(module, r"(?s)inherit\s+calendar\s+contacts\s+notes")


if __name__ == "__main__":
    unittest.main()
