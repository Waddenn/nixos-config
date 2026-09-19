import copy
import importlib.util
import pathlib
import unittest

PATH = pathlib.Path(__file__).resolve().parents[1] / 'provisioning/prototype/check-plan.py'
SPEC = importlib.util.spec_from_file_location('prototype_plan', PATH)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class PrototypePlanTests(unittest.TestCase):
    def setUp(self):
        self.plan = {'resource_changes': [{
            'address': MODULE.ADDRESS, 'mode': 'managed',
            'change': {'actions': ['create'], 'after': {
                'vm_id': 9901, 'node_name': 'proxade', 'protection': True}}}]}

    def test_create_and_idempotent(self):
        MODULE.check(self.plan)
        self.plan['resource_changes'][0]['change']['actions'] = ['no-op']
        MODULE.check(self.plan)

    def test_destructive_and_unreviewed_changes(self):
        for actions in [['delete'], ['delete', 'create'], ['create', 'delete'], ['update'], ['read']]:
            with self.subTest(actions=actions), self.assertRaises(ValueError):
                plan = copy.deepcopy(self.plan)
                plan['resource_changes'][0]['change']['actions'] = actions
                MODULE.check(plan)

    def test_identity_scope_and_protection(self):
        for field, value in [('vm_id', 205), ('node_name', 'nuc-pve-1'), ('protection', False)]:
            with self.subTest(field=field), self.assertRaises(ValueError):
                plan = copy.deepcopy(self.plan)
                plan['resource_changes'][0]['change']['after'][field] = value
                MODULE.check(plan)
        self.plan['resource_changes'][0]['address'] = 'unrelated.production'
        with self.assertRaises(ValueError):
            MODULE.check(self.plan)

    def test_missing_extra_and_incomplete(self):
        for plan in [{}, {'resource_changes': []}, {'complete': False, **self.plan},
                     {'errored': True, **self.plan},
                     {'resource_changes': self.plan['resource_changes'] * 2}]:
            with self.subTest(plan=plan), self.assertRaises(ValueError):
                MODULE.check(plan)
