#!/usr/bin/env python3
"""Reject mutation of existing resources, even after a declaration is removed."""
import json
import sys


def check(plan, manifest, selected=None):
    if plan.get('errored') or plan.get('complete') is False:
        raise ValueError('Incomplete or errored plan')
    if any('delete' in r.get('change', {}).get('actions', []) for r in plan.get('resource_drift', [])):
        raise ValueError('Resource disappeared outside OpenTofu; restore before reconciling')
    changes = plan.get('resource_changes')
    if not isinstance(changes, list):
        raise ValueError('Missing resource changes')
    expected = {s['resourceAddress']: s for s in manifest.values()}
    observed = set()
    for resource in changes:
        address = resource['address']
        if address not in expected or resource.get('mode') != 'managed':
            raise ValueError('Resource outside declared ownership; removal requires explicit retirement')
        if address in observed:
            raise ValueError('Duplicate resource change')
        observed.add(address)
        s, change = expected[address], resource['change']
        if change['actions'] not in (['create'], ['no-op']):
            raise ValueError('Updates, deletes and replacements are not automatic')
        if change['actions'] == ['create'] and s.get('lifecycle') == 'retained':
            raise ValueError('A retained service cannot create a new resource')
        if change['actions'] == ['create'] and selected and s['name'] != selected:
            raise ValueError('Creation outside the selected service')
        after = change.get('after') or {}
        if (after.get('vm_id'), after.get('node_name'), after.get('protection')) != (s['vmId'], s['node'], True):
            raise ValueError('Identity differs from declaration or protection is missing')
    if observed != set(expected):
        raise ValueError('Incomplete resource plan')


if __name__ == '__main__':
    try:
        check(json.load(sys.stdin), json.load(open(sys.argv[1])), sys.argv[2] if len(sys.argv) > 2 else None)
    except (ValueError, KeyError, TypeError, IndexError) as error:
        sys.exit(f'Unsafe provisioning plan: {error}')
