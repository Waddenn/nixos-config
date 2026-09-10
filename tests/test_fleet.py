"""Policy tests: no real SSH, GitHub, builds or activation."""
import importlib.util
import io
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch, Mock

source = Path(os.environ.get("FLEET_SCRIPT", Path(__file__).resolve().parents[1] / "scripts/fleet.py"))
spec = importlib.util.spec_from_file_location("fleet", source)
fleet = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fleet)


def host(canary=False, local=False):
    return {"target": True, "canary": canary, "local": local, "units": ["app.service"],
            "urls": [], "expected": "/nix/store/expected"}


class PolicyTests(unittest.TestCase):
    def test_ci_requires_exact_revision_successful_push(self):
        good = dict(headSha="a" * 40, event="push", headBranch="main", status="completed", conclusion="success")
        self.assertTrue(fleet.ci_passed([good], "a" * 40))
        self.assertTrue(fleet.ci_passed([dict(good, event="workflow_dispatch")], "a" * 40))
        for field, value in [("headBranch", "update-flake-lock"), ("headSha", "b" * 40), ("event", "pull_request"),
                             ("status", "in_progress"), ("conclusion", "failure")]:
            self.assertFalse(fleet.ci_passed([dict(good, **{field: value})], "a" * 40))
        self.assertFalse(fleet.ci_passed([], "a" * 40))

    @patch.object(fleet.urllib.request, "urlopen")
    def test_public_ci_needs_no_secret_and_preserves_gate(self, urlopen):
        urlopen.return_value = io.StringIO(fleet.json.dumps({"workflow_runs": [{
            "head_sha": "a" * 40, "head_branch": "main", "event": "workflow_dispatch",
            "status": "completed", "conclusion": "success"}]}))
        self.assertTrue(fleet.ci_passed(fleet.public_ci_runs("owner/repo", "a" * 40), "a" * 40))
        request = urlopen.call_args.args[0]
        self.assertNotIn("Authorization", dict(request.header_items()))
        self.assertIn("/actions/workflows/ci.yml/runs?head_sha=", request.full_url)

    @patch.object(fleet.urllib.request, "urlopen", side_effect=OSError("offline"))
    def test_public_ci_network_failure_blocks_deployment(self, urlopen):
        with self.assertRaises(fleet.FleetError):
            fleet.public_ci_runs("owner/repo", "a" * 40)

    def test_canary_gate_fails_closed(self):
        hosts = {"auth": host(True), "proxy": host(True), "app": host()}
        for bad in ["drift", "failed", "unreachable", "reboot-required", "unhealthy-or-diverged", None]:
            self.assertFalse(fleet.canaries_passed(hosts, {"auth": "converged", "proxy": bad}))
        self.assertTrue(fleet.canaries_passed(hosts, {"auth": "converged", "proxy": "converged"}))
        self.assertFalse(fleet.canaries_passed({"app": host()}, {"app": "converged"}))

    def test_manual_rollback_is_drift(self):
        self.assertEqual(fleet.system_status("old", "old", "new"), "drift")
        self.assertEqual(fleet.system_status("old", "new", "new"), "reboot-required")
        self.assertEqual(fleet.system_status("new", "new", "new"), "converged")
        self.assertEqual(fleet.system_status("new", "old", "new"), "drift")

    @patch.object(fleet, "run")
    def test_unreachable_canary_blocks_batch_and_self(self, run):
        f = fleet.Fleet()
        f.storage = Mock(return_value={"safe": True})
        f.systems = Mock(side_effect=[fleet.FleetError("offline"), "drift"])
        f.group = Mock()
        with self.assertRaises(fleet.FleetError):
            f.rollout({"auth": host(True), "app": host(), "dev-nixos": host(local=True)})
        f.group.assert_not_called()
        self.assertEqual(f.results["auth"], "unreachable")
        self.assertEqual(f.results["dev-nixos"], "blocked-by-canary")
        self.assertFalse(any("switch" in call.args[0] for call in run.call_args_list))

    @patch.object(fleet, "run")
    def test_unhealthy_canary_blocks_batch(self, run):
        f = fleet.Fleet()
        f.storage = Mock(return_value={"safe": True})
        f.systems = Mock(return_value="drift")
        f.deploy_host = Mock(return_value="unhealthy-or-diverged")
        f.group = Mock()
        with self.assertRaises(fleet.FleetError):
            f.rollout({"auth": host(True), "app": host()})
        f.group.assert_not_called()

    @patch.object(fleet, "run", side_effect=fleet.FleetError("build failed"))
    def test_build_failure_prevents_activation(self, run):
        f = fleet.Fleet()
        f.storage = Mock(return_value={"safe": True})
        f.systems = Mock(return_value="drift")
        f.deploy_host = Mock()
        with self.assertRaises(fleet.FleetError):
            f.rollout({"auth": host(True), "app": host()})
        f.deploy_host.assert_not_called()

    @patch.object(fleet, "run")
    def test_converged_host_checked_without_activation(self, run):
        f = fleet.Fleet()
        f.storage = Mock(return_value={"safe": True})
        f.systems = Mock(return_value="converged")
        f.healthy = Mock()
        self.assertEqual(f.deploy_host("app", host()), "converged")
        f.healthy.assert_called_once()
        run.assert_not_called()

    @patch.object(fleet, "run")
    def test_prepared_boot_is_not_reactivated(self, run):
        f = fleet.Fleet()
        f.storage = Mock(return_value={"safe": True})
        f.systems = Mock(return_value="reboot-required")
        self.assertEqual(f.deploy_host("app", host()), "reboot-required")
        run.assert_not_called()

    @patch.object(fleet, "run")
    def test_switch_inhibitor_prepares_boot_without_reboot(self, run):
        run.side_effect = [fleet.FleetError("activation failed", "switchInhibitors"), ""]
        f = fleet.Fleet()
        f.storage = Mock(return_value={"safe": True})
        f.systems = Mock(side_effect=["drift", "reboot-required"])
        self.assertEqual(f.deploy_host("app", host()), "reboot-required")
        self.assertEqual(run.call_args_list[1].args[0][4], "boot")
        self.assertTrue(run.call_args_list[0].args[0][2].endswith("/flake.nix"))
        self.assertFalse(any("--reboot" in c.args[0] for c in run.call_args_list))

    @patch.object(fleet, "run", side_effect=fleet.FleetError("activation failed", "database migration error"))
    def test_generic_failure_does_not_prepare_boot(self, run):
        f = fleet.Fleet()
        f.storage = Mock(return_value={"safe": True})
        f.systems = Mock(return_value="drift")
        self.assertEqual(f.deploy_host("app", host()), "failed")
        run.assert_called_once()

    def test_health_requires_each_unit_and_exact_http_200(self):
        f = fleet.Fleet()
        f.storage = Mock(return_value={"safe": True})
        f.ssh = Mock()
        cfg = dict(host(), units=["one.service", "two.service"], urls=["http://localhost/health"])
        f.healthy("app", cfg)
        cmd = f.ssh.call_args.args[1]
        self.assertIn("one.service && systemctl is-active --quiet two.service", cmd)
        self.assertIn('= 200', cmd)
        self.assertNotIn("--location", cmd)

    @patch.object(fleet, "run")
    def test_success_builds_controller_before_canary_and_updates_it_last(self, run):
        run.return_value = "dev-nixos"
        f = fleet.Fleet()
        f.storage = Mock(return_value={"safe": True})
        f.systems = Mock(return_value="converged")
        f.healthy = Mock()
        events = []
        run.side_effect = lambda args, **kwargs: events.append(args) or "dev-nixos"
        f.deploy_host = Mock(side_effect=lambda *args: events.append(["canary"]) or "converged")
        f.rollout({"auth": host(True), "dev-nixos": host(local=True)})
        self.assertIn("build", events[0])
        self.assertTrue(events[0][2].endswith("/flake.nix"))
        self.assertIn("auth,dev-nixos", events[0])
        self.assertEqual(events[1], ["canary"])
        self.assertEqual(events[-1][0:3], ["sudo", "systemctl", "start"])
        self.assertEqual(f.results["dev-nixos"], "converged")

    @patch.object(fleet, "run")
    def test_offline_batch_retries_without_freezing_controller(self, run):
        run.return_value = "dev-nixos"
        f = fleet.Fleet()
        f.storage = Mock(return_value={"safe": True})
        f.systems = Mock(side_effect=["converged", fleet.FleetError("offline"), "converged"])
        f.healthy = Mock()
        f.deploy_host = Mock(return_value="converged")
        with self.assertRaises(fleet.FleetError):
            f.rollout({"auth": host(True), "app": host(), "dev-nixos": host(local=True)})
        self.assertTrue(any(c.args[0][0] == "sudo" for c in run.call_args_list))
        self.assertEqual(f.results["dev-nixos"], "converged")
        self.assertEqual(f.results["app"], "unreachable")

    @patch.object(fleet, "run")
    def test_failed_reachable_batch_still_blocks_controller(self, run):
        f = fleet.Fleet()
        f.systems = Mock(return_value="drift")
        f.deploy_host = Mock(side_effect=["converged", "failed"])
        with self.assertRaises(fleet.FleetError):
            f.rollout({"auth": host(True), "app": host(), "dev-nixos": host(local=True)})
        self.assertFalse(any(c.args[0][0] == "sudo" for c in run.call_args_list))

    @patch.object(fleet, "run")
    def test_storage_counts_only_missing_paths_and_keeps_reserve(self, run):
        gib = 1024 ** 3
        run.return_value = fleet.json.dumps({"/nix/store/present": {"narSize": 9*gib},
                                             "/nix/store/missing": {"narSize": 2*gib}})
        f = fleet.Fleet()
        f.ssh = Mock(return_value=f"{3*gib}\n/nix/store/present")
        result = f.storage("app", host())
        self.assertEqual(result["missing"], 2*gib)
        self.assertEqual(result["required"], 3.5*gib)
        self.assertFalse(result["safe"])

    @patch.object(fleet, "run")
    def test_low_space_prevents_activation(self, run):
        f = fleet.Fleet()
        f.storage = Mock(return_value={"safe": False})
        f.systems = Mock(return_value="drift")
        self.assertEqual(f.deploy_host("app", host()), "insufficient-space")
        run.assert_not_called()

    def test_report_persists_failure(self):
        f = fleet.Fleet()
        f.storage = Mock(return_value={"safe": True})
        with tempfile.TemporaryDirectory() as directory, patch.dict(os.environ, {"DISCORD_WEBHOOK": ""}):
            f.state = Path(directory)
            f.report("build failed")
            self.assertEqual(fleet.json.loads((f.state / "last-run.json").read_text())["error"], "build failed")


if __name__ == "__main__":
    unittest.main()
