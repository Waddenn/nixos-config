"""Containment regressions: untrusted promotion data must never skip main CI.

These tests establish that promotion is disabled, not that a new provenance
protocol is secure. Workflow shell is executed as Actions executes it (bash -e).
"""
import copy
import importlib.util
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
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
BASE, HEAD, TREE, MERGE, OTHER = (c * 40 for c in "abcde")
REPOSITORY = "owner/repo"


def legacy_proof():
    """An apparently valid proof accepted by the retired status-based protocol."""
    return {
        "run": {
            "id": 42, "event": "pull_request", "conclusion": "success",
            "path": ".github/workflows/ci.yml", "head_sha": HEAD,
            "head_branch": "feature", "head_repository": {"full_name": REPOSITORY},
            "html_url": f"https://github.com/{REPOSITORY}/actions/runs/42",
        },
        "jobs": [{"name": name, "conclusion": "success"}
                 for name in ("quick-checks", "validation", "ci-gate")],
        "pr": {
            "number": 7, "draft": False,
            "base": {"ref": "main", "sha": BASE},
            "head": {"sha": HEAD, "repo": {"full_name": REPOSITORY}},
            "merged_at": "2026-09-12T12:00:00Z", "merge_commit_sha": MERGE,
        },
        "status": {
            "context": "CI / validated merge tree", "state": "success",
            "description": f"tree={TREE}; base={BASE}",
            "creator": {"login": "github-actions[bot]"},
            "target_url": f"https://github.com/{REPOSITORY}/actions/runs/42",
            "created_at": "2026-09-12T11:59:00Z",
        },
        "commit": {"tree": {"sha": TREE}, "parents": [{"sha": BASE}, {"sha": HEAD}]},
    }


class LegacyAPI:
    repository = REPOSITORY

    def __init__(self, proof):
        open_pr = copy.deepcopy(proof["pr"])
        open_pr.update(merged_at=None, merge_commit_sha=None)
        self.values = {
            "/actions/runs/42": proof["run"],
            "/actions/runs/42/jobs": {"jobs": proof["jobs"]},
            "/pulls?state=open&base=main&head=owner%3Afeature": [open_pr],
            "/git/ref/pull/7/merge": {"object": {"type": "commit", "sha": MERGE}},
            f"/git/commits/{MERGE}": proof["commit"],
            f"/commits/{MERGE}/pulls": [proof["pr"]],
            f"/commits/{HEAD}/statuses": [proof["status"]],
        }
        self.calls = []

    def request(self, path, *, method="GET", value=None):
        self.calls.append((method, path))
        return value if method == "POST" else self.values[path]

    def paginated(self, path):
        return self.request(path)


class PromotionTests(unittest.TestCase):
    def assert_rejected(self, proof, *, tree=TREE, parents=None):
        api = LegacyAPI(proof)
        # Compatibility with the old verifier makes these real attack fixtures:
        # the old happy-path verifier would accept several of them.
        with patch.object(promotion, "git", create=True,
                          side_effect=[MERGE, tree, parents or f"{BASE} {HEAD}"]):
            with self.assertRaisesRegex(promotion.PromotionError, "disabled"):
                promotion.verify_main(api)
        with self.assertRaisesRegex(promotion.PromotionError, "disabled"):
            promotion.publish(api, "42")
        self.assertEqual(api.calls, [], "retired proofs must not be queried or published")

    def test_even_apparently_valid_legacy_proof_is_rejected(self):
        self.assert_rejected(legacy_proof())

    def test_base_advances_during_run_with_unchanged_head(self):
        proof = legacy_proof()
        # Run tested BASE+HEAD; live endpoints and status now claim OTHER+HEAD.
        proof["run"]["pull_requests"] = [{"base": {"sha": OTHER}}]
        proof["pr"]["base"]["sha"] = OTHER
        proof["commit"]["parents"][0]["sha"] = OTHER
        proof["status"]["description"] = f"tree={TREE}; base={OTHER}"
        self.assert_rejected(proof, parents=f"{OTHER} {HEAD}")

    def test_other_workflow_can_imitate_bot_status_and_ci_url(self):
        # Deliberately byte-identical to the approved publisher's status: the
        # status API cannot distinguish a token from another repository workflow.
        self.assert_rejected(legacy_proof())

    def test_status_linking_directly_to_another_workflow_is_rejected(self):
        proof = legacy_proof()
        proof["run"]["path"] = ".github/workflows/impostor.yml"
        self.assert_rejected(proof)

    def test_modified_ci_with_successful_noop_jobs_is_rejected(self):
        proof = legacy_proof()
        for job in proof["jobs"]:
            job["steps"] = [{"name": "run: true", "conclusion": "success"}]
        self.assert_rejected(proof)

    def test_real_different_tree_with_otherwise_matching_proof_is_rejected(self):
        self.assert_rejected(legacy_proof(), tree=OTHER)

    def test_squash_rebase_and_octopus_are_rejected(self):
        for parents in (BASE, f"{BASE} {HEAD} {OTHER}"):
            with self.subTest(parents=parents):
                self.assert_rejected(legacy_proof(), parents=parents)

    def test_fork_is_rejected(self):
        proof = legacy_proof()
        proof["pr"]["head"]["repo"]["full_name"] = "someone/fork"
        proof["run"]["head_repository"]["full_name"] = "someone/fork"
        self.assert_rejected(proof)

    def test_missing_expired_invalid_and_cancelled_proofs_are_rejected(self):
        for change in ({"status": {}}, {"status": {"created_at": "2000-01-01T00:00:00Z"}},
                       {"run": {"conclusion": "cancelled"}}, {"commit": {"tree": {"sha": "bad"}}}):
            with self.subTest(change=change):
                proof = legacy_proof()
                proof.update(change)
                self.assert_rejected(proof)

    def test_ambiguous_or_truncated_api_pages_are_not_consulted(self):
        api = LegacyAPI(legacy_proof())
        api.values[f"/commits/{HEAD}/statuses"] *= 101
        api.values[f"/commits/{MERGE}/pulls"] *= 101
        with self.assertRaisesRegex(promotion.PromotionError, "disabled"):
            promotion.verify_main(api)
        self.assertEqual(api.calls, [])

    def test_cli_fails_without_credentials_and_cannot_be_enabled_by_environment(self):
        for command in ("publish", "verify-main"):
            with self.subTest(command=command):
                result = subprocess.run([sys.executable, str(source), command],
                                        env={"CI_PROMOTION_ENABLED": "true"},
                                        capture_output=True, text=True)
                self.assertEqual(result.returncode, 1)
                self.assertIn("disabled", result.stderr)


class WorkflowTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow = (ROOT / ".github/workflows/ci.yml").read_text()

    def shell(self, job):
        block = re.search(rf"(?ms)^  {job}:\n(.*?)(?=^  [a-z][a-z-]*:|\Z)", self.workflow)[1]
        script = re.search(r"(?m)^        run: \|\n((?:          .*\n|\n)+)", block)[1]
        return "\n".join(line[10:] for line in script.splitlines())

    def execute(self, job, **environment):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "output"
            result = subprocess.run(["bash", "--noprofile", "--norc", "-e", "-o", "pipefail", "-c",
                                     self.shell(job)], capture_output=True, text=True,
                                    env=dict(os.environ, GITHUB_OUTPUT=str(output), **environment))
            return result, output.read_text() if output.exists() else ""

    def test_validation_mode_keeps_prs_quick_and_main_dispatch_full(self):
        for event, ref, draft, expected in (
            ("push", "refs/heads/main", "", "true"),
            ("pull_request", "refs/pull/7/merge", "false", "false"),
            ("workflow_dispatch", "refs/heads/main", "", "true"),
            ("workflow_dispatch", "refs/heads/update-flake-lock", "", "true"),
            ("pull_request", "refs/pull/7/merge", "", "false"),
            ("push", "", "", "true"),
            ("unknown", "refs/heads/main", "", "true"),
            ("pull_request", "refs/pull/7/merge", "true", "false"),
            ("push", "refs/heads/feature", "", "true"),
        ):
            with self.subTest(event=event, ref=ref, draft=draft):
                result, output = self.execute("validation-mode", EVENT_NAME=event, EVENT_REF=ref,
                                              PR_DRAFT=draft)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(output, f"full={expected}\n")

    def gate(self, **environment):
        values = dict(EVENT_NAME="push", EVENT_REF="refs/heads/main", PR_DRAFT="",
                      QUICK="success", MODE="success", FULL="true", VALIDATION="success")
        values.update(environment)
        return self.execute("ci-gate", **values)[0].returncode

    def test_main_gate_accepts_only_successful_full_validation(self):
        self.assertEqual(self.gate(), 0)
        for key in ("QUICK", "MODE", "VALIDATION"):
            for value in ("failure", "cancelled", "skipped", ""):
                with self.subTest(key=key, value=value):
                    self.assertNotEqual(self.gate(**{key: value}), 0)
        for full in ("false", "", "nonsense"):
            self.assertNotEqual(self.gate(FULL=full, VALIDATION="skipped", PROMOTED="true"), 0)

    def test_dispatch_and_unknown_events_cannot_use_quick_or_promoted_mode(self):
        for event in ("workflow_dispatch", "unknown"):
            self.assertNotEqual(self.gate(EVENT_NAME=event, PR_DRAFT="false",
                                         FULL="false", VALIDATION="skipped", PROMOTED="true"), 0)

    def test_ready_pr_and_fork_keep_quick_checks(self):
        for event, ref, draft in (("pull_request", "refs/pull/7/merge", "false"),
                                  ("pull_request", "refs/pull/8/merge", "false")):
            self.assertEqual(self.gate(EVENT_NAME=event, EVENT_REF=ref, PR_DRAFT=draft,
                                      FULL="false", VALIDATION="skipped"), 0)
            self.assertNotEqual(self.gate(EVENT_NAME=event, EVENT_REF=ref, PR_DRAFT=draft,
                                         FULL="false", VALIDATION="skipped", QUICK="failure"), 0)

    def test_branch_pushes_are_filtered_and_drafts_allocate_no_runner(self):
        triggers = self.workflow.split("permissions:", 1)[0]
        self.assertIn("  push:\n    branches: [main]", triggers)
        self.assertIn("ready_for_review", triggers)
        self.assertIn("converted_to_draft", triggers)
        condition = "github.event_name != 'pull_request' || github.event.pull_request.draft == false"
        self.assertIn("  quick-checks:\n    if: " + condition, self.workflow)
        # The always-running final gate must also be disabled on drafts.
        self.assertIn("  ci-gate:\n    if: always() && (" + condition + ")", self.workflow)
        self.assertIn("  validation-mode:\n    needs: quick-checks", self.workflow)

    def test_publisher_and_status_privileges_are_removed(self):
        self.assertFalse((ROOT / ".github/workflows/promote-ci.yml").exists())
        self.assertNotIn("ci-promotion.py", self.workflow)
        self.assertNotIn("promoted", self.workflow.lower())
        self.assertNotIn("pull_request_target", self.workflow)
        self.assertNotRegex(self.workflow, r"(?m)^\s*(statuses|id-token|attestations):\s*write")
        block = self.workflow.split("  validation-mode:", 1)[1].split("  deployment-tests:", 1)[0]
        self.assertNotIn("GH_TOKEN", block)
        self.assertIn("if: always()", self.workflow.split("  ci-gate:", 1)[1])


if __name__ == "__main__":
    unittest.main()
