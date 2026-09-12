import hashlib
import importlib.util
import os
from pathlib import Path
import unittest
from unittest.mock import Mock

source = Path(os.environ.get("BESZEL_UPDATER", Path(__file__).resolve().parents[1] / "scripts/update-beszel.py"))
spec = importlib.util.spec_from_file_location("beszel_update", source)
updater = importlib.util.module_from_spec(spec)
spec.loader.exec_module(updater)


class ReleaseTests(unittest.TestCase):
    def test_both_artifacts_use_the_same_release(self):
        archive = b"test archive"
        checksum = hashlib.sha256(archive).hexdigest()
        fetch = Mock(side_effect=[f"{checksum}  beszel-agent_linux_amd64.tar.gz\n".encode(), archive])
        inspect = Mock(return_value="sha256:" + "a"*64)
        lock = updater.resolve_release({"tag_name": "v0.19.0"}, fetch, inspect)
        self.assertEqual(lock["version"], "0.19.0")
        self.assertEqual(lock["hubDigest"], "sha256:" + "a"*64)
        self.assertTrue(lock["agentHash"].startswith("sha256-"))
        self.assertTrue(all("/v0.19.0/" in c.args[0] for c in fetch.call_args_list))
        self.assertEqual(inspect.call_args.args[0][-1], "docker://henrygd/beszel:0.19.0")

    def test_bad_checksum_prevents_lock_creation(self):
        with self.assertRaisesRegex(ValueError, "checksum"):
            updater.resolve_release({"tag_name": "v0.19.0"}, Mock(side_effect=[b"wrong sums", b"archive"]), Mock())

    def test_prerelease_is_rejected(self):
        for release in [{"tag_name": "v0.20.0-rc1"}, {"tag_name": "v0.20.0", "prerelease": True},
                        {"tag_name": "v0.20.0", "draft": True}]:
            with self.assertRaises(ValueError):
                updater.resolve_release(release, Mock(), Mock())

    def test_bad_hub_digest_prevents_lock_creation(self):
        checksum = hashlib.sha256(b"archive").hexdigest()
        with self.assertRaisesRegex(ValueError, "digest"):
            updater.resolve_release({"tag_name": "v0.19.0"},
                                    Mock(side_effect=[f"{checksum} beszel-agent_linux_amd64.tar.gz".encode(), b"archive"]),
                                    Mock(return_value="invalid"))


if __name__ == "__main__":
    unittest.main()
