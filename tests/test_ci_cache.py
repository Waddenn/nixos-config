"""Regression tests for the shared Cachix policy in GitHub Actions."""
from pathlib import Path
import os
import re
import unittest


ROOT = Path(os.environ.get("CI_CACHE_ROOT", Path(__file__).resolve().parents[1]))
CI = ROOT / ".github/workflows/ci.yml"
UPDATE = ROOT / ".github/workflows/update.yml"
CACHIX_ACTION = "cachix/cachix-action@38b082610b782e7e93e209c35fd730d399dee866"


def workflow(path):
    return path.read_text()


def job_block(text, job):
    start = text.index(f"  {job}:")
    following = re.search(r"(?m)^  [a-zA-Z0-9_-]+:$", text[start + len(job) + 3:])
    end = len(text) if following is None else start + len(job) + 3 + following.start()
    return text[start:end]


class CachePolicyTests(unittest.TestCase):
    def test_every_nix_job_uses_the_shared_cache(self):
        ci = workflow(CI)
        expected_jobs = ["deployment-tests", "check-formatting", "generate-matrix", "flake-check"]
        for job in expected_jobs:
            block = job_block(ci, job)
            self.assertIn(CACHIX_ACTION, block, job)
            self.assertIn("name: waddenn-nixos", block, job)

        update = workflow(UPDATE)
        self.assertEqual(update.count(CACHIX_ACTION), 1)
        self.assertIn("name: waddenn-nixos", update)

    def test_only_cachix_steps_receive_the_write_token(self):
        for path in (CI, UPDATE):
            text = workflow(path)
            self.assertEqual(text.count("secrets.CACHIX_AUTH_TOKEN"), text.count(CACHIX_ACTION))
            authenticated_actions = re.findall(
                re.escape(CACHIX_ACTION)
                + r'\n\s+with:\n\s+name: waddenn-nixos\n'
                + r'\s+authToken: "\$\{\{ secrets\.CACHIX_AUTH_TOKEN \}\}"',
                text,
            )
            self.assertEqual(len(authenticated_actions), text.count(CACHIX_ACTION))

    def test_untrusted_pull_requests_cannot_receive_secrets(self):
        ci = workflow(CI)
        self.assertRegex(ci, r"(?m)^  pull_request:$")
        self.assertNotIn("pull_request_target", ci)
        self.assertNotRegex(ci, r"(?m)^\s*(id-token|packages|pull-requests):\s*write\s*$")

    def test_magic_cache_is_not_mixed_with_cachix(self):
        for path in (CI, UPDATE):
            self.assertNotIn("magic-nix-cache-action", workflow(path))


if __name__ == "__main__":
    unittest.main()
