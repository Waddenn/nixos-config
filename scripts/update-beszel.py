#!/usr/bin/env python3
"""Pin one upstream release for the native NixOS agent and Docker hub atomically."""
import base64
import hashlib
import json
from pathlib import Path
import re
import subprocess
import urllib.request


ROOT = Path(__file__).resolve().parents[1]


def get(url):
    request = urllib.request.Request(url, headers={"User-Agent": "nixos-beszel-updater"})
    with urllib.request.urlopen(request, timeout=120) as response:
        return response.read()


def resolve_release(release, fetch=get, inspect=subprocess.check_output):
    tag = release["tag_name"]
    if release.get("draft") or release.get("prerelease") or not re.fullmatch(r"v\d+\.\d+\.\d+", tag):
        raise ValueError("Expected a stable Beszel release")
    version = tag[1:]
    base = f"https://github.com/henrygd/beszel/releases/download/{tag}/"
    asset = "beszel-agent_linux_amd64.tar.gz"
    checksum_file = fetch(base + f"beszel_{version}_checksums.txt").decode()
    checksums = {fields[1].lstrip("*"): fields[0] for line in checksum_file.splitlines()
                 if len(fields := line.split()) == 2}
    archive_hash = hashlib.sha256(fetch(base + asset)).digest()
    if archive_hash.hex() != checksums.get(asset):
        raise ValueError("Beszel agent checksum does not match upstream checksums")
    digest = inspect(["skopeo", "inspect", "--format", "{{.Digest}}",
                      f"docker://henrygd/beszel:{version}"], text=True, timeout=120).strip()
    if not re.fullmatch(r"sha256:[a-f0-9]{64}", digest):
        raise ValueError("Invalid Beszel hub digest")
    return {"version": version, "hubDigest": digest,
            "agentHash": "sha256-" + base64.b64encode(archive_hash).decode()}


def main():
    release = json.loads(get("https://api.github.com/repos/henrygd/beszel/releases/latest"))
    lock = resolve_release(release)
    path = ROOT / "lib/beszel-release.json"
    temp = path.with_suffix(".json.tmp")
    temp.write_text(json.dumps(lock, indent=2, sort_keys=True) + "\n")
    temp.replace(path)
    print(f"Pinned Beszel hub and agent to {lock['version']}")


if __name__ == "__main__":
    main()
