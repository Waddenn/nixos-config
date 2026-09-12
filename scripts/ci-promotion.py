#!/usr/bin/env python3
"""Retired promotion interface: fail closed, including for stale external callers.

A commit status, a mutable PR merge ref, and green job names cannot establish
immutable build provenance. Do not re-enable this interface with a flag or token;
see docs/ci-promotion-security.md for the requirements of a replacement.
"""
from pathlib import Path
import sys


DISABLED_REASON = (
    "tree promotion is disabled: immutable tested-merge provenance and an "
    "authenticated validation definition are unavailable; run full CI on main"
)


class PromotionError(RuntimeError):
    pass


def publish(api, run_id):
    """Never issue a proof, even when called by an older publisher workflow."""
    raise PromotionError(DISABLED_REASON)


def verify_main(api, root=Path(".")):
    """Never accept a historical status or artifact as authorization to skip CI."""
    raise PromotionError(DISABLED_REASON)


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in ("publish", "verify-main"):
        raise SystemExit("usage: ci-promotion.py publish|verify-main")
    print(f"CI promotion unavailable: {DISABLED_REASON}", file=sys.stderr)
    raise SystemExit(1)


if __name__ == "__main__":
    main()
