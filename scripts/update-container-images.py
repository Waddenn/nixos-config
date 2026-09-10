#!/usr/bin/env python3
"""Resolve tracked OCI tags atomically. Requires skopeo; downloads no image layers."""
import json
from pathlib import Path
import re
import subprocess


def main():
    path = Path(__file__).resolve().parents[1] / "lib/container-images.json"
    locks = json.loads(path.read_text())
    updated = {}
    for source in locks:
        digest = subprocess.check_output(
            ["skopeo", "inspect", "--format", "{{.Digest}}", "docker://" + source],
            text=True, timeout=90).strip()
        if not re.fullmatch(r"sha256:[a-f0-9]{64}", digest):
            raise ValueError(f"Invalid registry digest for {source}")
        updated[source] = digest
    tmp = path.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(updated, sort_keys=True, indent=2) + "\n")
    tmp.replace(path)


if __name__ == "__main__":
    main()
