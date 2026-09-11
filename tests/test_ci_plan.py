"""Regression tests for selective CI and its trusted baseline."""
import importlib.util
import json
import os
from pathlib import Path
import unittest
from unittest.mock import Mock, patch

source = Path(os.environ.get("CI_PLAN_SCRIPT", Path(__file__).resolve().parents[1] / "scripts/plan-ci.py"))
spec = importlib.util.spec_from_file_location("ci_plan", source)
plan = importlib.util.module_from_spec(spec)
spec.loader.exec_module(plan)


class PlanTests(unittest.TestCase):
    def setUp(self):
        self.old = {"app": {"expected": "/nix/store/app"}, "proxy": {"expected": "/nix/store/proxy"}}

    def test_local_module_change_selects_actual_changed_outputs(self):
        new = dict(self.old, app={"expected": "/nix/store/new"})
        self.assertEqual(plan.select_hosts(new, self.old, ["modules/containers/app.nix"]), (["app"], "targeted"))

    def test_shared_change_selects_all_affected_hosts(self):
        new = {n: {"expected": cfg["expected"] + "-new"} for n, cfg in self.old.items()}
        self.assertEqual(plan.select_hosts(new, self.old, ["modules/profiles/base.nix"])[0], ["app", "proxy"])

    def test_no_baseline_or_global_change_builds_everything(self):
        self.assertEqual(plan.select_hosts(self.old), (["app", "proxy"], "full"))
        for filename in plan.GLOBAL_PATHS:
            self.assertEqual(plan.select_hosts(self.old, self.old, [filename]), (["app", "proxy"], "full"))

    def test_docs_only_skip_builds(self):
        self.assertEqual(plan.select_hosts(self.old, self.old, ["docs/operations.md"]), ([], "targeted"))

    def test_added_and_removed_hosts(self):
        new = {"app": self.old["app"], "new": {"expected": "/nix/store/new"}}
        self.assertEqual(plan.select_hosts(new, self.old)[0], ["new"])

    def test_policy_only_still_runs_checks_but_needs_no_system_build(self):
        new = {n: dict(c, urls=["https://example.test/health"]) for n, c in self.old.items()}
        self.assertEqual(plan.select_hosts(new, self.old)[0], [])

    @patch.dict(os.environ, {"GITHUB_REPOSITORY": "owner/repo"})
    @patch.object(plan.subprocess, "run")
    @patch.object(plan, "run")
    def test_only_successful_main_ancestor_is_trusted(self, run, git):
        def result(sha, **kwargs):
            return dict(head_sha=sha*40, head_branch="main", event="push",
                        status="completed", conclusion="success", **kwargs)
        failed = result("b")
        failed["conclusion"] = "failure"
        pr = result("c")
        pr["event"] = "pull_request"
        run.side_effect = [json.dumps({"workflow_runs": [result("a"), failed, pr, result("d"), result("e")]}), "a"*40]
        git.side_effect = [Mock(returncode=1), Mock(returncode=0)]
        self.assertEqual(plan.trusted_baseline(Path("/tmp")), "e"*40)
        self.assertEqual(git.call_count, 2)


if __name__ == "__main__":
    unittest.main()
