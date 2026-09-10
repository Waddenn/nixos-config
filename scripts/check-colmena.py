#!/usr/bin/env python3
"""Verify that Colmena activates exactly the systems checked by CI."""
import json
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
flake = "path:" + str(root)
base = ["nix", "--extra-experimental-features", "nix-command flakes"]
expected = json.loads(subprocess.check_output(
    base + ["eval", "--json", "--no-write-lock-file", flake + "#fleet"], text=True))
actual = json.loads(subprocess.check_output(
    base + ["run", "--no-write-lock-file", flake + "#colmena", "--", "--config", flake,
            "eval", "-E", "{ nodes, ... }: builtins.mapAttrs (_: n: toString n.config.system.build.toplevel) nodes"], text=True))
different = [name for name, cfg in expected.items() if actual.get(name) != cfg["expected"]]
if different or actual.keys() != expected.keys():
    raise SystemExit("Colmena/NixOS mismatch: " + ", ".join(different))
print(f"Colmena/NixOS generation parity verified for {len(expected)} hosts")
