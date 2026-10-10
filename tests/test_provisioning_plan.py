import copy
import importlib.util
import pathlib
import unittest

PATH = pathlib.Path(__file__).resolve().parents[1] / 'provisioning/check-plan.py'
SPEC = importlib.util.spec_from_file_location('provisioning_plan', PATH)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class ProvisioningPlanTests(unittest.TestCase):
    def setUp(self):
        self.manifest = {'demo': {'name': 'demo', 'resourceAddress': 'proxmox_virtual_environment_container.demo',
                                  'vmId': 9123, 'node': 'test-node'}}
        self.plan = {'resource_changes': [{
            'address': self.manifest['demo']['resourceAddress'], 'mode': 'managed',
            'change': {'actions': ['create'], 'after': {
                'vm_id': 9123, 'node_name': 'test-node', 'protection': True}}}]}

    def test_generic_create_and_idempotent(self):
        MODULE.check(self.plan, self.manifest, 'demo')
        self.plan['resource_changes'][0]['change']['actions'] = ['no-op']
        MODULE.check(self.plan, self.manifest, 'demo')

    def test_destructive_and_unreviewed_changes(self):
        for actions in [['delete'], ['delete', 'create'], ['create', 'delete'], ['update'], ['read']]:
            with self.subTest(actions=actions), self.assertRaises(ValueError):
                plan = copy.deepcopy(self.plan)
                plan['resource_changes'][0]['change']['actions'] = actions
                MODULE.check(plan, self.manifest)

    def test_identity_scope_and_protection(self):
        for field, value in [('vm_id', 205), ('node_name', 'production'), ('protection', False)]:
            with self.subTest(field=field), self.assertRaises(ValueError):
                plan = copy.deepcopy(self.plan)
                plan['resource_changes'][0]['change']['after'][field] = value
                MODULE.check(plan, self.manifest)
        with self.assertRaises(ValueError):
            MODULE.check(self.plan, self.manifest, 'another-service')

    def growth_plan(self):
        self.manifest['demo']['diskGiB'] = 16
        change = self.plan['resource_changes'][0]['change']
        change['actions'] = ['update']
        change['before'] = dict(change['after'], disk=[{'size': 4, 'datastore_id': 'pool'}])
        change['after']['disk'] = [{'size': 16, 'datastore_id': 'pool'}]
        change['after_unknown'] = {'disk': [False]}
        return change

    def test_explicit_disk_growth_only(self):
        self.growth_plan()
        with self.assertRaises(ValueError):
            MODULE.check(self.plan, self.manifest)
        MODULE.check(self.plan, self.manifest, allow_disk_growth=True)

    def autostart_plan(self):
        self.manifest['demo']['startOnBoot'] = True
        change = self.plan['resource_changes'][0]['change']
        change.update(actions=['update'], before=dict(change['after'], start_on_boot=False))
        change['after']['start_on_boot'] = True
        return change

    def test_autostart_requires_explicit_action_and_selected_declared_identity(self):
        self.autostart_plan()
        with self.assertRaises(ValueError):
            MODULE.check(self.plan, self.manifest, 'demo')
        MODULE.check(self.plan, self.manifest, 'demo', allow_boot_enable=True)
        with self.assertRaises(ValueError):
            MODULE.check(self.plan, self.manifest, 'another', allow_boot_enable=True)

    def test_autostart_rejects_other_changes_unknowns_and_creation(self):
        self.autostart_plan()
        for mutate in [lambda c: c['after'].update(started=False),
                       lambda c: c.update(after_unknown={'disk': [True]}),
                       lambda c: c.update(actions=['create']),
                       lambda c: c.update(replace_paths=[['start_on_boot']]),
                       lambda c: c['after'].update(start_on_boot=False)]:
            with self.subTest(mutate=mutate), self.assertRaises(ValueError):
                plan = copy.deepcopy(self.plan)
                mutate(plan['resource_changes'][0]['change'])
                MODULE.check(plan, self.manifest, 'demo', allow_boot_enable=True)
        self.manifest['demo']['startOnBoot'] = False
        with self.assertRaises(ValueError):
            MODULE.check(self.plan, self.manifest, 'demo', allow_boot_enable=True)

    def capacity_plan(self):
        self.manifest['demo'].update(cores=4, memoryMiB=8192, diskGiB=64)
        change = self.plan['resource_changes'][0]['change']
        change.update(actions=['update'], before=dict(change['after'],
                      cpu=[{'cores': 2}], memory=[{'dedicated': 4096, 'swap': 0}],
                      disk=[{'size': 32, 'datastore_id': 'pool'}]))
        change['after'].update(cpu=[{'cores': 4}], memory=[{'dedicated': 8192, 'swap': 0}],
                               disk=[{'size': 64, 'datastore_id': 'pool'}])
        return change

    def test_selected_capacity_growth_only(self):
        self.capacity_plan()
        with self.assertRaises(ValueError):
            MODULE.check(self.plan, self.manifest, 'demo')
        MODULE.check(self.plan, self.manifest, 'demo', allow_capacity_growth=True)
        with self.assertRaises(ValueError):
            MODULE.check(self.plan, self.manifest, 'another', allow_capacity_growth=True)

    def test_capacity_growth_rejects_shrink_other_changes_and_unknowns(self):
        self.capacity_plan()
        for mutate in [lambda c: c['after']['cpu'][0].update(cores=1),
                       lambda c: c['after']['memory'][0].update(swap=512),
                       lambda c: c['after']['disk'][0].update(datastore_id='other'),
                       lambda c: c['after'].update(start_on_boot=True),
                       lambda c: c.update(after_unknown={'cpu': [True]}),
                       lambda c: c.update(actions=['create']),
                       lambda c: c.update(actions=['delete', 'create'])]:
            with self.subTest(mutate=mutate), self.assertRaises(ValueError):
                plan = copy.deepcopy(self.plan)
                mutate(plan['resource_changes'][0]['change'])
                MODULE.check(plan, self.manifest, 'demo', allow_capacity_growth=True)

    def test_disk_growth_rejects_shrink_other_changes_and_unknowns(self):
        self.growth_plan()
        for mutate in [lambda c: c['after']['disk'][0].update(size=2),
                       lambda c: c['after']['disk'][0].update(datastore_id='other'),
                       lambda c: c['after'].update(started=False),
                       lambda c: c.update(after_unknown={'disk': [True]}),
                       lambda c: c.update(actions=['delete', 'create'])]:
            with self.subTest(mutate=mutate), self.assertRaises(ValueError):
                plan = copy.deepcopy(self.plan)
                mutate(plan['resource_changes'][0]['change'])
                MODULE.check(plan, self.manifest, allow_disk_growth=True)

    def test_removed_declaration_still_rejects_deletion(self):
        self.plan['resource_changes'][0]['change']['actions'] = ['delete']
        with self.assertRaises(ValueError):
            MODULE.check(self.plan, {})

    def test_missing_and_incomplete(self):
        for plan in [{}, {'resource_changes': []}, {'complete': False, **self.plan}, {'errored': True, **self.plan}]:
            with self.subTest(plan=plan), self.assertRaises(ValueError):
                MODULE.check(plan, self.manifest)

    def test_retained_or_lost_resource_is_not_recreated(self):
        self.manifest['demo']['lifecycle'] = 'retained'
        with self.assertRaises(ValueError):
            MODULE.check(self.plan, self.manifest)
        self.manifest['demo']['lifecycle'] = 'active'
        self.plan['resource_drift'] = [{'change': {'actions': ['delete']}}]
        with self.assertRaises(ValueError):
            MODULE.check(self.plan, self.manifest)
