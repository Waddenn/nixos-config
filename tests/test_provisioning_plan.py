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
