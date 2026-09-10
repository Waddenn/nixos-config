#!/usr/bin/env python3
"""Colmena policy: pinned revision, CI gate, fail-closed canaries and reconciliation.

No third-party Python dependencies. Imports perform no network or deployment actions.
"""
import concurrent.futures
import contextlib
import fcntl
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile
import time
import urllib.request


class FleetError(RuntimeError):
    def __init__(self, message, output=""):
        super().__init__(message)
        self.output = output



def run(args, *, cwd=None, capture=True, timeout=120):
    try:
        result = subprocess.run(args, cwd=cwd, text=True, capture_output=capture,
                                timeout=timeout, check=False)
    except (subprocess.TimeoutExpired, OSError) as exc:
        raise FleetError(f"{args[0]}: {type(exc).__name__}") from exc
    if result.returncode:
        # Do not echo command arguments or environment (may contain credentials).
        raise FleetError(f"{args[0]} exited {result.returncode}", (result.stdout or "") + (result.stderr or ""))
    return result.stdout.strip() if capture else ""


def atomic_json(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as out:
        json.dump(value, out, sort_keys=True, indent=2)
        out.write("\n")
        name = out.name
    os.replace(name, path)


def ci_passed(runs, revision):
    return any(r.get("headSha") == revision and r.get("event") in ("push", "workflow_dispatch")
               and r.get("headBranch") == "main"
               and r.get("status") == "completed" and r.get("conclusion") == "success"
               for r in runs)


def canaries_passed(hosts, results):
    canaries = [name for name, cfg in hosts.items() if cfg.get("canary")]
    return bool(canaries) and all(results.get(name) == "converged" for name in canaries)


def system_status(current, profile, expected):
    if current == expected and profile == expected:
        return "converged"
    if profile == expected:
        return "reboot-required"
    return "drift"


class Fleet:
    def __init__(self):
        self.repo = Path(os.environ.get("REPO_DIR", "/home/nixos/nixos-config"))
        self.state = Path(os.environ.get("STATE_DIR", "/var/lib/internal-gitops"))
        self.colmena = os.environ.get("COLMENA_BIN", "colmena")
        self.parallel = int(os.environ.get("PARALLEL_HOSTS", "3"))
        self.health_timeout = int(os.environ.get("HEALTH_TIMEOUT", "120"))
        if not 1 <= self.parallel <= 16 or not 1 <= self.health_timeout <= 600:
            raise FleetError("Invalid parallelism or health timeout")
        self.revision = ""
        self.results = {}
        self.work = self.repo

    def ssh(self, host, command):
        return run(["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=8",
                    "-o", "ServerAliveInterval=10", "-o", "ServerAliveCountMax=2",
                    "-o", "StrictHostKeyChecking=accept-new", f"root@{host}", command], timeout=45)

    def systems(self, host, cfg):
        command = "readlink -f /run/current-system; readlink -f /nix/var/nix/profiles/system"
        if cfg.get("local"):
            values = [os.path.realpath("/run/current-system"),
                      os.path.realpath("/nix/var/nix/profiles/system")]
        else:
            values = self.ssh(host, command).splitlines()
        if len(values) != 2 or not all(v.startswith("/nix/store/") for v in values):
            raise FleetError("Invalid active system response")
        return system_status(*values, cfg["expected"])

    def healthy(self, host, cfg):
        # Check every unit independently: is-active with several units succeeds if ANY is active.
        commands = [f"systemctl is-active --quiet {shlex.quote(unit)}" for unit in cfg["units"]]
        commands += ["test \"$(curl --silent --output /dev/null --write-out '%{http_code}' "
                     f"--connect-timeout 5 --max-time 10 {shlex.quote(url)})\" = 200"
                     for url in cfg["urls"]]
        command = " && ".join(commands) or "true"
        if cfg.get("local"):
            run(["bash", "-c", command], timeout=45)
        else:
            self.ssh(host, command)

    def manifest(self, local=False):
        hosts = json.loads(run(["nix", "--extra-experimental-features", "nix-command flakes",
                               "eval", "--json", "--no-write-lock-file",
                               ("path:" + str(self.work) + "#fleet") if local else ".#fleet"], cwd=self.work, timeout=600))
        hosts = {name: cfg for name, cfg in hosts.items() if cfg["target"]}
        if not hosts or any(not re.fullmatch(r"[a-z0-9][a-z0-9-]*", name) for name in hosts):
            raise FleetError("Empty or invalid fleet inventory")
        return hosts

    def storage(self, host, cfg):
        info = json.loads(run(["nix", "--extra-experimental-features", "nix-command flakes",
                               "path-info", "--recursive", "--json", cfg["expected"]], timeout=120))
        paths = info if isinstance(info, dict) else {v["path"]: v for v in info}
        command = "df -B1 --output=avail /nix/store | tail -1; nix --extra-experimental-features nix-command path-info --all"
        output = run(["bash", "-c", command], timeout=120) if cfg["local"] else self.ssh(host, command)
        lines = output.splitlines()
        available = int(lines[0].strip())
        existing = set(lines[1:])
        missing = sum(v["narSize"] for path, v in paths.items() if path not in existing)
        # NAR bytes approximate filesystem usage. Keep headroom for metadata and concurrent writes.
        reserve = 1024 ** 3
        if cfg.get("oci"):
            reserve += 2 * 1024 ** 3  # Additional allowance, not an image-size guarantee.
        required = (missing * 5 + 3) // 4 + reserve
        return {"available": available, "missing": missing, "required": required,
                "safe": available >= required}

    def preflight(self):
        hosts = self.manifest(local=True)
        print("Local draft: building systems locally, then checking capacity. No activation or notification.", flush=True)
        run(["nix", "--extra-experimental-features", "nix-command flakes", "build", "--no-link",
             "--no-write-lock-file"] + ["path:" + str(self.work) + "#nixosConfigurations." + n +
                                        ".config.system.build.toplevel" for n in hosts], timeout=7200, capture=False)
        results = {}
        for name, cfg in hosts.items():
            cfg = dict(cfg, local=cfg["local"] and run(["uname", "-n"]).split(".")[0] == name)
            try:
                capacity = self.storage(name, cfg)
                results[name] = capacity
                gib = 1024 ** 3
                print(f"{name:24} free={capacity['available']/gib:.2f} GiB "
                      f"missing={capacity['missing']/gib:.2f} GiB "
                      f"budget={capacity['required']/gib:.2f} GiB "
                      f"{'OK' if capacity['safe'] else 'BLOCKED'}", flush=True)
            except (FleetError, ValueError) as exc:
                results[name] = {"error": str(exc)}
                print(f"{name:24} UNKNOWN: {exc}", flush=True)
        report = os.environ.get("PREFLIGHT_REPORT")
        if report:
            atomic_json(report, results)
        return 0 if all(v.get("safe", False) for v in results.values()) else 1

    def deploy_host(self, host, cfg):
        try:
            status = self.systems(host, cfg)
            if status == "reboot-required":
                return status
            if status != "converged":
                if not self.storage(host, cfg)["safe"]:
                    return "insufficient-space"
                print(f"{host}: activating", flush=True)
                command = [self.colmena, "--config", str(self.work), "apply", "switch",
                           "--on", host, "--parallel", "1"]
                try:
                    run(command, timeout=1800)
                except FleetError as exc:
                    inhibitors = ("switchInhibitors", "changes to critical components")
                    if not any(message in exc.output for message in inhibitors):
                        raise
                    command[4] = "boot"
                    run(command, timeout=1800)
                    prepared = self.systems(host, cfg)
                    if prepared not in ("reboot-required", "converged"):
                        raise FleetError("Boot profile differs from desired system")
                    return prepared
            deadline = time.monotonic() + self.health_timeout
            while True:
                try:
                    status = self.systems(host, cfg)
                    if status != "converged":
                        raise FleetError(status)
                    self.healthy(host, cfg)
                    return "converged"
                except FleetError:
                    if time.monotonic() >= deadline:
                        return "unhealthy-or-diverged"
                    time.sleep(5)
        except FleetError as exc:
            print(f"{host}: {exc}", flush=True)
            return "failed"

    def group(self, names, hosts):
        with concurrent.futures.ThreadPoolExecutor(max_workers=self.parallel) as pool:
            futures = {pool.submit(self.deploy_host, name, hosts[name]): name for name in names}
            for future in concurrent.futures.as_completed(futures):
                name = futures[future]
                self.results[name] = future.result()
                print(f"{name}: {self.results[name]}", flush=True)

    def report(self, error=None):
        state = {"revision": self.revision, "hosts": self.results, "error": error}
        atomic_json(self.state / "last-run.json", state)
        webhook = os.environ.get("DISCORD_WEBHOOK", "")
        if not webhook:
            return
        if webhook.startswith("discord://"):
            token, ident = webhook.removeprefix("discord://").rsplit("@", 1)
            webhook = f"https://discord.com/api/webhooks/{ident}/{token}"
        previous = self.state / "last-notification.json"
        try:
            if previous.exists() and json.loads(previous.read_text()) == state:
                return
        except (OSError, ValueError):
            pass
        summary = f"NixOS {self.revision[:12]}\n" + "\n".join(f"{n}: {s}" for n, s in sorted(self.results.items()))
        if error:
            summary += f"\n{error}"
        data = json.dumps({"content": summary[:1900]}).encode()
        try:
            req = urllib.request.Request(webhook, data=data, headers={"Content-Type": "application/json"})
            with urllib.request.urlopen(req, timeout=15):
                pass
            atomic_json(previous, state)
        except Exception:
            print("Notification failed; state saved locally", file=sys.stderr)

    def reconcile(self):
        space = os.statvfs("/nix/store")
        if space.f_bavail * space.f_frsize < 5 * 1024 ** 3:
            raise FleetError("Controller needs at least 5 GiB free before fleet builds")
        run(["git", "fetch", "origin", "main", "--prune"], cwd=self.repo)
        self.revision = run(["git", "rev-parse", "origin/main"], cwd=self.repo)
        if not re.fullmatch(r"[0-9a-f]{40}", self.revision):
            raise FleetError("Invalid revision")
        runs = json.loads(run(["gh", "run", "list", "--workflow", "ci.yml", "--commit", self.revision,
                              "--limit", "20", "--json",
                              "headSha,headBranch,event,status,conclusion"], cwd=self.repo))
        if not ci_passed(runs, self.revision):
            raise FleetError("Deployment blocked: no successful main CI for this exact revision")
        with tempfile.TemporaryDirectory(prefix="fleet-", dir=self.state) as directory:
            self.work = Path(directory) / "source"
            run(["git", "worktree", "add", "--detach", str(self.work), self.revision], cwd=self.repo)
            try:
                hosts = self.manifest()
                controllers = [n for n, c in hosts.items() if c["local"]]
                if controllers != [run(["uname", "-n"]).split(".")[0]]:
                    raise FleetError("Run deployments on the declared controller")
                self.rollout(hosts)
            finally:
                run(["git", "worktree", "remove", "--force", str(self.work)], cwd=self.repo)

    def rollout(self, hosts):
        remote = {n: c for n, c in hosts.items() if not c["local"]}
        if not any(c["canary"] for c in remote.values()):
            raise FleetError("No canaries defined; refusing rollout")
        # Probe reachability before building, without excluding missing canaries from the gate.
        reachable = []
        for name, cfg in remote.items():
            try:
                self.systems(name, cfg)
                reachable.append(name)
            except FleetError:
                self.results[name] = "unreachable"
        missing_canaries = [n for n, c in remote.items() if c["canary"] and n not in reachable]
        if missing_canaries:
            for name in hosts:
                self.results.setdefault(name, "blocked-by-canary")
            raise FleetError("Required canary unreachable; rollout withheld")
        build_hosts = reachable + [n for n, c in hosts.items() if c["local"]]
        if build_hosts:
            run([self.colmena, "--config", str(self.work), "build", "--on", ",".join(build_hosts),
                 "--parallel", str(self.parallel), "--keep-result"], capture=False, timeout=7200)
        canaries = [n for n in reachable if remote[n]["canary"]]
        # Sequential canaries avoid concurrent changes to proxy and identity provider.
        for name in canaries:
            self.results[name] = self.deploy_host(name, remote[name])
            if self.results[name] != "converged":
                break
        if not canaries_passed(remote, self.results):
            for name in hosts:
                self.results.setdefault(name, "blocked-by-canary")
            raise FleetError("Canary gate failed; remaining hosts were not activated")
        self.group([n for n in reachable if not remote[n]["canary"]], remote)
        if any(v != "converged" for v in self.results.values()):
            raise FleetError("Partial deployment; controller update withheld")
        # The existing detached systemd agent is retained only on the controller.
        for name, cfg in hosts.items():
            if not cfg["local"]:
                continue
            if run(["uname", "-n"]).split(".")[0] != name:
                self.results[name] = "wrong-controller"
                raise FleetError("Run deployments on the declared controller")
            if not self.storage(name, cfg)["safe"]:
                self.results[name] = "insufficient-space"
                raise FleetError("Controller has insufficient free space")
            run(["sudo", "systemctl", "start", f"internal-pull-update@{self.revision}.service"], timeout=1800)
            self.results[name] = self.systems(name, cfg)
            if self.results[name] == "converged":
                self.healthy(name, cfg)
            else:
                raise FleetError("Controller needs attention")

    def status(self):
        print("Comparing with the local checkout; no fetch, build or activation.")
        for name, cfg in self.manifest(local=True).items():
            try:
                # A local controller entry must be checked remotely from an operator laptop.
                cfg = dict(cfg, local=cfg["local"] and run(["uname", "-n"]).split(".")[0] == name)
                status = self.systems(name, cfg)
                if status == "converged":
                    self.healthy(name, cfg)
            except FleetError:
                status = "unreachable-or-unhealthy"
            print(f"{name:24} {status}")


def main():
    fleet = Fleet()
    if sys.argv[1:] == ["--preflight"]:
        return fleet.preflight()
    if sys.argv[1:] == ["--status"]:
        fleet.status()
        return 0
    if sys.argv[1:]:
        raise FleetError("Supported arguments: --status, --preflight")
    fleet.state.mkdir(parents=True, exist_ok=True)
    with (fleet.state / "deploy.lock").open("w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print("A deployment is already running")
            return 0
        try:
            fleet.reconcile()
        except (FleetError, ValueError) as exc:
            fleet.report(str(exc))
            print(str(exc), file=sys.stderr)
            return 1
        fleet.report()
    return 0


if __name__ == "__main__":
    with contextlib.suppress(KeyboardInterrupt):
        sys.exit(main())
