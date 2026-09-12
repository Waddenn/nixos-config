#!/usr/bin/env python3
"""Verify that the pinned Docker hub reports the shared Beszel release."""
import json
from pathlib import Path
import subprocess

release = json.loads((Path(__file__).resolve().parents[1] / "lib/beszel-release.json").read_text())
image = f"henrygd/beszel:{release['version']}@{release['hubDigest']}"
actual = subprocess.check_output(["docker", "run", "--rm", "--network", "none", image, "--version"],
                                 text=True, timeout=180).strip()
if actual != f"beszel version {release['version']}":
    raise SystemExit(f"Hub release mismatch: {actual}")
print(actual)
