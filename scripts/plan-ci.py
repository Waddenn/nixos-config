#!/usr/bin/env python3
"""Select builds by Nix output, against a successful ancestor CI on main.

Failure to find/evaluate a trusted baseline selects every host. Current evaluation
errors remain fatal. No path-to-host guesses: shared modules may affect any host.
"""
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile


GLOBAL_PATHS = {
    "flake.lock", "flake.nix", "hosts/default.nix", "lib/builder.nix",
    "lib/host-modules.nix", "modules/default.nix", ".github/workflows/ci.yml",
    "scripts/plan-ci.py",
}


def run(args, cwd=None):
    return subprocess.check_output(args, cwd=cwd, text=True).strip()


def evaluate(root):
    return json.loads(run(["nix", "--extra-experimental-features", "nix-command flakes",
                           "eval", "--json", "--no-write-lock-file", f"path:{root}#fleet"]))


def select_hosts(current, previous=None, files=()):
    if previous is None or GLOBAL_PATHS.intersection(files):
        return sorted(current), "full"
    return sorted(n for n, cfg in current.items()
                  if n not in previous or cfg["expected"] != previous[n]["expected"]), "targeted"


def trusted_baseline(root):
    repository = os.environ["GITHUB_REPOSITORY"]
    runs = json.loads(run(["gh", "api", f"repos/{repository}/actions/workflows/ci.yml/runs"
                          "?branch=main&status=success&per_page=100"]))["workflow_runs"]
    head = run(["git", "rev-parse", "HEAD"], root)
    for result in runs:
        sha = result.get("head_sha", "")
        if (not re.fullmatch(r"[0-9a-f]{40}", sha) or sha == head
                or result.get("head_branch") != "main"
                or result.get("event") not in ("push", "workflow_dispatch")
                or result.get("status") != "completed" or result.get("conclusion") != "success"):
            continue
        if subprocess.run(["git", "merge-base", "--is-ancestor", sha, "HEAD"],
                          cwd=root, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
            return sha
    return None


def main():
    root = Path(__file__).resolve().parents[1]
    current = evaluate(root)
    previous, baseline, files = None, None, []
    try:
        baseline = trusted_baseline(root)
        if baseline:
            files = run(["git", "diff", "--name-only", baseline, "HEAD"], root).splitlines()
            # Global edits deliberately keep the complete validation path.
            if not GLOBAL_PATHS.intersection(files):
                with tempfile.TemporaryDirectory(prefix="ci-baseline-") as directory:
                    checkout = Path(directory) / "source"
                    run(["git", "worktree", "add", "--detach", str(checkout), baseline], root)
                    try:
                        previous = evaluate(checkout)
                    finally:
                        run(["git", "worktree", "remove", "--force", str(checkout)], root)
    except (KeyError, ValueError, OSError, subprocess.CalledProcessError):
        print("Trusted baseline unavailable; building all systems.", flush=True)
        previous = None
    hosts, mode = select_hosts(current, previous, files)
    print(f"CI {mode}: {len(hosts)}/{len(current)} hosts: {', '.join(hosts) or 'none'}", flush=True)
    report = {"baseline": baseline, "mode": mode, "hosts": hosts,
              "expected": {n: c["expected"] for n, c in current.items()}}
    Path("ci-plan.json").write_text(json.dumps(report, indent=2) + "\n")
    with open(os.environ["GITHUB_OUTPUT"], "a") as output:
        output.write("hosts=" + json.dumps(hosts) + "\n")
        output.write("has-builds=" + str(bool(hosts)).lower() + "\n")
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as summary:
            summary.write(f"CI mode: **{mode}**. Builds: **{len(hosts)}/{len(current)}**.\n\n"
                          f"Baseline: `{baseline or 'none'}`\n\n"
                          + "\n".join(f"- {n}" for n in hosts) + "\n")


if __name__ == "__main__":
    main()
