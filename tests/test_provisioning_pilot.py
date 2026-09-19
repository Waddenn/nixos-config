import importlib.util
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1] / 'provisioning'
sys.path.insert(0, str(ROOT))


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value


DEMO = module('pilot_demo', ROOT / 'applications/demo.py')
CTL = module('pilot_controller', ROOT / 'provision.py')
from tailscale_enroll import create_key, key_request


class PilotTests(unittest.TestCase):
    def test_secret_required_for_health_and_private_probe(self):
        self.assertEqual(DEMO.response('/healthz', '', '', 'x')[0], 503)
        self.assertEqual(DEMO.response('/private', 'bad', 'correct', 'x')[0], 401)
        self.assertEqual(DEMO.response('/private', 'correct', 'correct', 'x'), (200, {'authenticated': True}))
        self.assertNotIn('correct', json.dumps(DEMO.response('/healthz', '', 'correct', 'x')))

    def test_oauth_key_is_short_single_use_and_tag_scoped(self):
        bodies = []
        def opener(request, timeout):
            bodies.append((request.full_url, request.data))
            return io.BytesIO(json.dumps({'access_token': 'private-api-token'} if len(bodies) == 1 else {'key': 'private-enrollment-key'}).encode())
        self.assertEqual(create_key({'client_id': 'id', 'client_secret': 'secret'}, ['tag:test'], opener)['key'], 'private-enrollment-key')
        payload = json.loads(bodies[1][1])
        self.assertEqual(payload['expirySeconds'], 3600)
        self.assertEqual(payload['capabilities']['devices']['create'], {
            'reusable': False, 'ephemeral': False, 'preauthorized': True, 'tags': ['tag:test']})
        self.assertNotIn('secret', bodies[1][1].decode())
        with self.assertRaises(ValueError):
            key_request([])

    def test_partial_failure_is_recorded_without_later_success(self):
        with tempfile.TemporaryDirectory() as temp, mock.patch.object(CTL, 'STATE', Path(temp)):
            report = {'completed': ['prepare', 'infra']}
            def fail(_):
                raise CTL.ProvisionError('health failure')
            with self.assertRaises(CTL.ProvisionError):
                CTL.stage('health', fail, {'name': 'example'}, report)
            saved = json.loads((Path(temp) / 'hosts/example/last-run.json').read_text())
            self.assertEqual(saved['status'], 'failed')
            self.assertEqual(saved['stage'], 'health')
            self.assertEqual(saved['completed'], ['prepare', 'infra'])

    def test_enrolled_guest_does_not_generate_another_key(self):
        # Mismatched tags fail closed without re-enrolling or generating a new key.
        status = json.dumps({'BackendState': 'Running', 'Self': {'Tags': ['tag:other']}})
        with mock.patch.object(CTL, 'require_owned'), mock.patch.object(CTL, 'ssh', return_value=status), mock.patch.object(CTL, 'create_key') as create:
            with self.assertRaises(CTL.ProvisionError):
                CTL.enroll({'name': 'example', 'tailscaleTags': ['tag:test']})
            create.assert_not_called()

    def test_unowned_container_cannot_be_deployed(self):
        with tempfile.TemporaryDirectory() as temp, mock.patch.object(CTL, 'STATE', Path(temp)):
            with self.assertRaises(CTL.ProvisionError):
                CTL.require_owned({'name': 'production', 'vmId': 205, 'node': 'proxade'})

    def test_health_requires_every_unit_not_just_one(self):
        service = {'units': ['app.service'], 'monitoring': True}
        with mock.patch.object(CTL, 'require_owned'), mock.patch.object(CTL, 'ssh', return_value='inactive\nactive\nactive'):
            with self.assertRaises(CTL.ProvisionError):
                CTL.health(service)

    def test_commands_do_not_consume_the_callers_stdin(self):
        completed = mock.Mock(returncode=0, stdout='OK', stderr='')
        with mock.patch.object(CTL.subprocess, 'run', return_value=completed) as command:
            self.assertEqual(CTL.run(['ssh', 'example', 'hostname']), 'OK')
            self.assertEqual(command.call_args.kwargs['stdin'], CTL.subprocess.DEVNULL)
