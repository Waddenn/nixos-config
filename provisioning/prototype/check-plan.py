#!/usr/bin/env python3
"""Fail closed: this experiment can only create or observe its single CT."""
import json
import sys

ADDRESS = "proxmox_virtual_environment_container.prototype"


def check(plan):
    if plan.get("errored") or plan.get("complete") is False:
        raise ValueError("Incomplete or errored plan")
    changes = plan.get("resource_changes")
    if not isinstance(changes, list) or len(changes) != 1:
        raise ValueError("Expected exactly one managed prototype resource")
    for resource in changes:
        change = resource["change"]
        if resource["address"] != ADDRESS or resource.get("mode") != "managed":
            raise ValueError("Resource outside the experiment")
        if change["actions"] not in (["create"], ["no-op"]):
            raise ValueError("Updates, deletes and replacements require a separate reviewed procedure")
        after = change.get("after") or {}
        if (after.get("vm_id"), after.get("node_name"), after.get("protection")) != (9901, "proxade", True):
            raise ValueError("Unexpected identity or missing Proxmox protection")


if __name__ == "__main__":
    try:
        check(json.load(sys.stdin))
    except (ValueError, KeyError, TypeError) as error:
        sys.exit(f"Unsafe prototype plan: {error}")
