"""Regression tests for safe promotion of a fully validated PR merge tree."""
import importlib.util
import os
from pathlib import Path
import unittest
from unittest.mock import patch


source = Path(os.environ.get(
    "CI_PROMOTION_SCRIPT",
    Path(__file__).resolve().parents[1] / "scripts/ci-promotion.py",
))
spec = importlib.util.spec_from_file_location("ci_promotion", source)
promotion = importlib.util.module_from_spec(spec)
spec.loader.exec_module(promotion)
ROOT = Path(os.environ.get("CI_PROMOTION_ROOT", source.resolve().parents[1]))


REPOSITORY = "owner/repo"
BASE = "a" * 40
HEAD = "b" * 40
TREE = "c" * 40
MERGE = "d" * 40


def run(run_id=42):
    return {
        "id": run_id,
        "event": "pull_request",
        "conclusion": "success",
        "path": promotion.WORKFLOW_PATH,
        "head_repository": {"full_name": REPOSITORY},
        "head_sha": HEAD,
        "head_branch": "feature",
        "html_url": f"https://github.com/{REPOSITORY}/actions/runs/{run_id}",
    }


def jobs():
    return [
        {"name": "quick-checks", "conclusion": "success"},
        {"name": "validation", "conclusion": "success"},
        {"name": "ci-gate", "conclusion": "success"},
    ]


def pr(*, merged=True):
    return {
        "number": 7,
        "draft": False,
        "base": {"ref": "main", "sha": BASE},
        "head": {"sha": HEAD, "repo": {"full_name": REPOSITORY}},
        "merged_at": "2026-09-12T12:00:00Z" if merged else None,
        "merge_commit_sha": MERGE if merged else None,
    }


class FakeGitHub:
    repository = REPOSITORY

    def __init__(self, values):
        self.values = values
        self.posts = []

    def request(self, path, *, method="GET", value=None):
        if method == "POST":
            self.posts.append((path, value))
            return value
        return self.values[path]

    def paginated(self, path):
        return self.values[path]


class PromotionTests(unittest.TestCase):
    def test_full_run_requires_terminal_full_validation_jobs(self):
        self.assertTrue(promotion.full_run_succeeded(run(), jobs(), REPOSITORY))
        for name in ("quick-checks", "validation", "ci-gate"):
            broken = jobs()
            next(job for job in broken if job["name"] == name)["conclusion"] = "skipped"
            self.assertFalse(promotion.full_run_succeeded(run(), broken, REPOSITORY), name)

    def test_publisher_derives_tree_and_parents_from_github_merge_ref(self):
        open_pr = pr(merged=False)
        api = FakeGitHub({
            "/actions/runs/42": run(),
            "/actions/runs/42/jobs": {"jobs": jobs()},
            "/pulls?state=open&base=main&head=owner%3Afeature": [open_pr],
            "/git/ref/pull/7/merge": {"object": {"type": "commit", "sha": MERGE}},
            f"/git/commits/{MERGE}": {
                "tree": {"sha": TREE},
                "parents": [{"sha": BASE}, {"sha": HEAD}],
            },
        })
        promotion.publish(api, "42")
        self.assertEqual(api.posts[0][0], f"/statuses/{HEAD}")
        self.assertEqual(api.posts[0][1]["description"], promotion.description(TREE, BASE))

    @patch.object(promotion, "git")
    def test_main_accepts_only_matching_merge_tree_base_head_and_run(self, git):
        git.side_effect = [MERGE, TREE, f"{BASE} {HEAD}"]
        status = {
            "context": promotion.CONTEXT,
            "state": "success",
            "description": promotion.description(TREE, BASE),
            "creator": {"login": "github-actions[bot]"},
            "target_url": f"https://github.com/{REPOSITORY}/actions/runs/42",
            "created_at": "2026-09-12T11:59:00Z",
        }
        api = FakeGitHub({
            f"/commits/{MERGE}/pulls": [pr()],
            f"/commits/{HEAD}/statuses": [status],
            "/actions/runs/42": run(),
            "/actions/runs/42/jobs": {"jobs": jobs()},
        })
        self.assertEqual(promotion.verify_main(api)["id"], 42)

    @patch.object(promotion, "git")
    def test_different_tree_fails_closed(self, git):
        git.side_effect = [MERGE, "e" * 40, f"{BASE} {HEAD}"]
        api = FakeGitHub({
            f"/commits/{MERGE}/pulls": [pr()],
            f"/commits/{HEAD}/statuses": [],
        })
        with self.assertRaises(promotion.PromotionError):
            promotion.verify_main(api)

    def test_squash_or_rebase_commit_is_not_promoted(self):
        api = FakeGitHub({})
        with patch.object(promotion, "git", side_effect=[MERGE, TREE, BASE]):
            with self.assertRaises(promotion.PromotionError):
                promotion.verify_main(api)

    def test_fork_pr_is_not_trusted_for_promotion(self):
        foreign = pr()
        foreign["head"]["repo"]["full_name"] = "someone/fork"
        with self.assertRaises(promotion.PromotionError):
            promotion.single_pr([foreign], repository=REPOSITORY, base=BASE, head=HEAD,
                                merge_sha=MERGE)

    def test_workflow_permissions_and_trusted_default_branch_checkout(self):
        publisher = (ROOT / ".github/workflows/promote-ci.yml").read_text()
        ci = (ROOT / ".github/workflows/ci.yml").read_text()
        self.assertIn("workflow_run:", publisher)
        self.assertIn("statuses: write", publisher)
        self.assertIn("ref: main", publisher)
        self.assertNotIn("pull_request_target", publisher + ci)
        self.assertNotIn("statuses: write", ci)
        self.assertNotIn("upload-artifact", publisher)
        self.assertIn("ci-gate:", ci)

    def test_promotion_mechanism_changes_force_full_build_selection(self):
        plan_source = (ROOT / "scripts/plan-ci.py").read_text()
        self.assertIn('".github/workflows/promote-ci.yml"', plan_source)
        self.assertIn('"scripts/ci-promotion.py"', plan_source)


if __name__ == "__main__":
    unittest.main()
