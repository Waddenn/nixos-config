#!/usr/bin/env python3
"""Reject mutation of existing resources, even after a declaration is removed."""
import json
import sys


def has_unknown(value):
    if isinstance(value, dict):
        return any(has_unknown(v) for v in value.values())
    if isinstance(value, list):
        return any(has_unknown(v) for v in value)
    return bool(value)


def capacity_growth(before, after, declaration):
    old_rest, new_rest = dict(before), dict(after)
    grew = False
    for attribute, field, declared in [('cpu', 'cores', 'cores'),
                                       ('memory', 'dedicated', 'memoryMiB'),
                                       ('disk', 'size', 'diskGiB')]:
        old, new = before.get(attribute), after.get(attribute)
        if not isinstance(old, list) or not isinstance(new, list) or len(old) != 1 or len(new) != 1:
            return False
        old, new = old[0], new[0]
        if (type(old.get(field)) not in (int, float) or type(new.get(field)) not in (int, float) or
                new[field] != declaration.get(declared) or new[field] < old[field]):
            return False
        grew |= new[field] > old[field]
        old_rest[attribute] = [{k: v for k, v in old.items() if k != field}]
        new_rest[attribute] = [{k: v for k, v in new.items() if k != field}]
    return grew and old_rest == new_rest


def check(plan, manifest, selected=None, allow_disk_growth=False, allow_boot_enable=False, allow_capacity_growth=False):
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
        if (allow_disk_growth or allow_boot_enable or allow_capacity_growth) and change['actions'] == ['create']:
            raise ValueError('Maintenance cannot create resources')
        if change['actions'] == ['update'] and allow_capacity_growth:
            if (s['name'] != selected or not capacity_growth(change.get('before') or {}, change.get('after') or {}, s) or
                    has_unknown(change.get('after_unknown', {})) or change.get('replace_paths')):
                raise ValueError('Only selected declared CPU/memory/disk growth without other changes is allowed')
        elif change['actions'] == ['update'] and allow_boot_enable:
            before, after = change.get('before') or {}, change.get('after') or {}
            if (s['name'] != selected or not s.get('startOnBoot') or
                    before.get('start_on_boot') is not False or after.get('start_on_boot') is not True or
                    {k: v for k, v in before.items() if k != 'start_on_boot'} !=
                    {k: v for k, v in after.items() if k != 'start_on_boot'} or
                    has_unknown(change.get('after_unknown', {})) or change.get('replace_paths')):
                raise ValueError('Only selected declared autostart enablement without other changes is allowed')
        elif change['actions'] == ['update'] and allow_disk_growth:
            before, after = change.get('before') or {}, change.get('after') or {}
            old_disks, new_disks = before.get('disk'), after.get('disk')
            if not isinstance(old_disks, list) or not isinstance(new_disks, list) or len(old_disks) != 1 or len(new_disks) != 1:
                raise ValueError('Resize requires exactly one existing disk')
            old, new = old_disks[0], new_disks[0]
            if (not isinstance(old.get('size'), (int, float)) or
                    new.get('size') != s.get('diskGiB') or new['size'] <= old['size'] or
                    {k: v for k, v in old.items() if k != 'size'} != {k: v for k, v in new.items() if k != 'size'} or
                    {k: v for k, v in before.items() if k != 'disk'} != {k: v for k, v in after.items() if k != 'disk'} or
                    has_unknown(change.get('after_unknown', {})) or change.get('replace_paths')):
                raise ValueError('Only declared disk growth without other changes is allowed')
        elif change['actions'] not in (['create'], ['no-op']):
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
