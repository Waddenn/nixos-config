#!/usr/bin/env python3
"""Publish and verify a durable proof for an already validated PR merge tree.

The publisher runs from the default branch through ``workflow_run``.  It records a
GitHub commit status only after independently resolving the PR merge ref and checking
that the completed CI contained the full validation gate.  The verifier runs on the
exact main commit and accepts the proof only when its tree and both merge parents
match.  Any API, topology, provenance, or timing ambiguity fails closed.
"""
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request


CONTEXT = "CI / validated merge tree"
WORKFLOW_PATH = ".github/workflows/ci.yml"
RUN_URL = re.compile(r"https://github\.com/([^/]+/[^/]+)/actions/runs/([0-9]+)$")
SHA = re.compile(r"[0-9a-f]{40}")


class PromotionError(RuntimeError):
    pass


def git(*args):
    return subprocess.check_output(["git", *args], text=True).strip()


class GitHub:
    def __init__(self, repository, token=None):
        if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repository):
            raise PromotionError("invalid GitHub repository")
        self.repository = repository
        self.api = f"https://api.github.com/repos/{repository}"
        self.token = token or os.environ.get("GH_TOKEN", "")

    def request(self, path, *, method="GET", value=None):
        headers = {
            "Accept": "application/vnd.github+json",
            "User-Agent": "nixos-ci-promotion",
            "X-GitHub-Api-Version": "2022-11-28",
        }
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        data = None if value is None else json.dumps(value).encode()
        request = urllib.request.Request(self.api + path, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                return json.load(response)
        except (OSError, ValueError, urllib.error.HTTPError) as exc:
            raise PromotionError(f"GitHub API failed for {path}") from exc

    def paginated(self, path):
        separator = "&" if "?" in path else "?"
        return self.request(f"{path}{separator}per_page=100")


def description(tree, base):
    if not SHA.fullmatch(tree) or not SHA.fullmatch(base):
        raise PromotionError("invalid tree or base SHA")
    return f"tree={tree}; base={base}"


def jobs_by_name(jobs):
    return {job.get("name"): job.get("conclusion") for job in jobs}


def full_run_succeeded(run, jobs, repository):
    names = jobs_by_name(jobs)
    return (
        run.get("event") == "pull_request"
        and run.get("conclusion") == "success"
        and run.get("path") == WORKFLOW_PATH
        and run.get("head_repository", {}).get("full_name") == repository
        and SHA.fullmatch(run.get("head_sha", "")) is not None
        and names.get("quick-checks") == "success"
        and names.get("validation") == "success"
        and names.get("ci-gate") == "success"
    )


def single_pr(prs, *, repository, base, head, merge_sha=None):
    matches = []
    for pr in prs:
        if (pr.get("base", {}).get("ref") == "main"
                and pr.get("base", {}).get("sha") == base
                and pr.get("head", {}).get("sha") == head
                and pr.get("head", {}).get("repo", {}).get("full_name") == repository):
            if merge_sha is None or (pr.get("merged_at") and pr.get("merge_commit_sha") == merge_sha):
                matches.append(pr)
    if len(matches) != 1:
        raise PromotionError("expected exactly one matching same-repository PR")
    return matches[0]


def publish(api, run_id):
    run = api.request(f"/actions/runs/{run_id}")
    jobs = api.paginated(f"/actions/runs/{run_id}/jobs").get("jobs", [])
    if not full_run_succeeded(run, jobs, api.repository):
        print("Run is not an eligible successful full PR validation; nothing to publish.")
        return

    owner = api.repository.split("/", 1)[0]
    branch = run.get("head_branch", "")
    query = urllib.parse.urlencode({"state": "open", "base": "main", "head": f"{owner}:{branch}"})
    prs = api.paginated(f"/pulls?{query}")
    # The base SHA comes from GitHub's immutable merge commit, not from branch output.
    eligible = [pr for pr in prs if not pr.get("draft") and pr.get("head", {}).get("sha") == run["head_sha"]]
    if len(eligible) != 1:
        raise PromotionError("expected exactly one ready PR for the validated head")
    candidate = eligible[0]
    base = candidate.get("base", {}).get("sha", "")
    pr = single_pr(eligible, repository=api.repository, base=base, head=run["head_sha"])

    ref = api.request(f"/git/ref/pull/{pr['number']}/merge")
    merge_sha = ref.get("object", {}).get("sha", "")
    if ref.get("object", {}).get("type") != "commit" or not SHA.fullmatch(merge_sha):
        raise PromotionError("PR merge ref is not a commit")
    commit = api.request(f"/git/commits/{merge_sha}")
    parents = [parent.get("sha") for parent in commit.get("parents", [])]
    tree = commit.get("tree", {}).get("sha", "")
    if parents != [base, run["head_sha"]] or not SHA.fullmatch(tree):
        raise PromotionError("PR merge ref does not have the expected base and head")

    api.request(
        f"/statuses/{run['head_sha']}",
        method="POST",
        value={
            "state": "success",
            "context": CONTEXT,
            "description": description(tree, base),
            "target_url": run["html_url"],
        },
    )
    print(f"Published validated tree {tree} for PR #{pr['number']} from run {run_id}.")


def verify_main(api, root=Path(".")):
    head = git("-C", str(root), "rev-parse", "HEAD")
    tree = git("-C", str(root), "show", "-s", "--format=%T", "HEAD")
    parents = git("-C", str(root), "show", "-s", "--format=%P", "HEAD").split()
    if len(parents) != 2:
        raise PromotionError("main is not a two-parent merge commit")
    base, pr_head = parents

    prs = api.paginated(f"/commits/{head}/pulls")
    pr = single_pr(prs, repository=api.repository, base=base, head=pr_head, merge_sha=head)
    expected = description(tree, base)
    statuses = api.paginated(f"/commits/{pr_head}/statuses")
    candidates = [status for status in statuses
                  if status.get("context") == CONTEXT
                  and status.get("state") == "success"
                  and status.get("description") == expected
                  and status.get("creator", {}).get("login") == "github-actions[bot]"]
    if not candidates:
        raise PromotionError("no trusted status matches this merge tree and base")

    merged_at = pr.get("merged_at", "")
    for status in candidates:
        match = RUN_URL.fullmatch(status.get("target_url", ""))
        if not match or match.group(1).lower() != api.repository.lower():
            continue
        run = api.request(f"/actions/runs/{match.group(2)}")
        jobs = api.paginated(f"/actions/runs/{match.group(2)}/jobs").get("jobs", [])
        if (full_run_succeeded(run, jobs, api.repository)
                and run.get("head_sha") == pr_head
                and status.get("created_at", "") <= merged_at):
            print(f"Promoted full validation run {run['id']} for identical tree {tree}.")
            return run
    raise PromotionError("matching status has no eligible full CI run provenance")


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in ("publish", "verify-main"):
        raise SystemExit("usage: ci-promotion.py publish|verify-main")
    api = GitHub(os.environ["GITHUB_REPOSITORY"])
    try:
        if sys.argv[1] == "publish":
            publish(api, os.environ["WORKFLOW_RUN_ID"])
        else:
            verify_main(api, Path(os.environ.get("GITHUB_WORKSPACE", ".")))
    except (KeyError, PromotionError, subprocess.CalledProcessError) as exc:
        print(f"CI promotion unavailable: {exc}", file=sys.stderr)
        raise SystemExit(1)


if __name__ == "__main__":
    main()
