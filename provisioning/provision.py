#!/usr/bin/env python3
"""Controller-only glue around Nix, OpenTofu, SOPS and Colmena, never a fleet timer."""
import argparse
import fcntl
import importlib.util
import ipaddress
import json
import os
from pwd import getpwnam
from pathlib import Path
import secrets
import shlex
import shutil
import socket
import ssl
import subprocess
import sys
from datetime import datetime, timezone
import tarfile
import time
import urllib.error
import urllib.parse
import urllib.request

from tailscale_enroll import create_key

SRC = Path(__file__).resolve().parent
STATE = Path('/var/lib/proxmox-prototype')  # Keep ownership of the original state.
SPEC = importlib.util.spec_from_file_location('check_plan', SRC / 'check-plan.py')
GUARD = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(GUARD)


class ProvisionError(RuntimeError):
    pass


def run(args, *, input=None, cwd=None, env=None, timeout=1800):
    stdin = {'stdin': subprocess.DEVNULL} if input is None else {'input': input}
    r = subprocess.run(args, text=True, capture_output=True, cwd=cwd,
                       env=env, timeout=timeout, **stdin)
    if r.returncode:
        # Diagnostics stay private; command output may include sensitive material.
        (STATE / 'last-command-error.log').write_text((r.stderr or '')[-16000:])
        raise ProvisionError(f'{Path(args[0]).name} failed ({r.returncode}); private diagnostics: {STATE}/last-command-error.log')
    return r.stdout.strip()


def write_json(path, value):
    path = Path(path)
    tmp = path.with_suffix(path.suffix + '.new')
    tmp.write_text(json.dumps(value, indent=2) + '\n')
    tmp.chmod(0o600)
    tmp.replace(path)


def load(path, default=None):
    return json.loads(Path(path).read_text()) if Path(path).exists() else default


def manifest():
    return json.loads(run(['nix', 'eval', '--json', f'path:{SRC}#manifest']))


def hostdir(name):
    p = STATE / 'hosts' / name
    p.mkdir(mode=0o700, parents=True, exist_ok=True)
    return p


def migrate_runtime():
    """One-time layout change, preserving the old state, image and SSH identity."""
    old = load(STATE / 'bootstrap.auto.tfvars.json', {})
    if 'ssh_public_key' in old:
        write_json(STATE / 'bootstrap.auto.tfvars.json', {'bootstrap': {'prototype': old}})
        for source, dest in [('id_ed25519', 'ssh_key'), ('id_ed25519.pub', 'ssh_key.pub')]:
            target = hostdir('prototype') / dest
            if not target.exists():
                shutil.copyfile(STATE / source, target)
                target.chmod(0o600)


def backup():
    if not (STATE / 'terraform.tfstate').exists():
        return
    stamp = time.strftime('%Y%m%dT%H%M%S') + f'-{time.time_ns()}'
    archive = STATE / 'backups' / f'{stamp}.tar.gz'
    archive.parent.mkdir(mode=0o700, exist_ok=True)
    with tarfile.open(archive, 'w:gz') as out:
        for name in ['terraform.tfstate', 'bootstrap.auto.tfvars.json', 'hosts', 'api-token',
                     'pve-ca.pem', 'proxmox_known_hosts', 'tailscale-oauth.json']:
            if (STATE / name).exists():
                out.add(STATE / name, arcname=name)
    destination = f'/root/proxmox-prototype-backups/{archive.name}'
    with archive.open('rb') as data:
        r = subprocess.run(['ssh', '-oBatchMode=yes', '-oConnectTimeout=10', 'root@terraform',
                            f'umask 077; mkdir -p /root/proxmox-prototype-backups; chmod 700 /root/proxmox-prototype-backups; cat > {destination}'],
                           stdin=data, capture_output=True, timeout=60)
    if r.returncode:
        raise ProvisionError('Off-controller backup failed; operation withheld')


def api(path, method='GET', body=None):
    ctx = ssl.create_default_context(cafile=str(STATE / 'pve-ca.pem'))
    # Existing PVE CA predates the KeyUsage extension. Keep CA and hostname checks.
    ctx.verify_flags &= ~ssl.VERIFY_X509_STRICT
    req = urllib.request.Request('https://proxade:8006/api2/json' + path, method=method,
        headers={'Authorization': 'PVEAPIToken=' + (STATE / 'api-token').read_text().strip(),
                 'Content-Type': 'application/json'},
        data=json.dumps(body).encode() if body is not None else None)
    with urllib.request.urlopen(req, context=ctx, timeout=30) as response:
        return json.load(response)['data']


def node_ssh(s, command):
    return run(['ssh', '-oBatchMode=yes', '-oStrictHostKeyChecking=yes', '-oConnectTimeout=10',
                '-oUserKnownHostsFile=' + str(STATE / 'proxmox_known_hosts'),
                'root@' + s['node'], command])


def require_owned(s):
    state = load(STATE / 'terraform.tfstate', {})
    matches = [r for r in state.get('resources', [])
               if r.get('type') == 'proxmox_virtual_environment_container' and r.get('name') == s['name']]
    if len(matches) != 1 or len(matches[0].get('instances', [])) != 1:
        raise ProvisionError('Service is not owned by this state; implicit adoption refused')
    attrs = matches[0]['instances'][0]['attributes']
    if (attrs.get('vm_id'), attrs.get('node_name')) != (s['vmId'], s['node']):
        raise ProvisionError('State identity differs from service declaration')


def discover(s):
    require_owned(s)
    cfg = api(f"/nodes/{s['node']}/lxc/{s['vmId']}/config")
    if cfg.get('hostname') != s['hostname'] or cfg.get('protection') != 1:
        raise ProvisionError('Bootstrap target identity/protection mismatch')
    interfaces = api(f"/nodes/{s['node']}/lxc/{s['vmId']}/interfaces")
    addresses = []
    for iface in interfaces:
        if iface.get('name') == 'eth0':
            for field in ['inet', 'address']:
                if iface.get(field):
                    address = str(ipaddress.ip_interface(iface[field]).ip)
                    if ':' not in address:
                        addresses.append(address)
    if len(set(addresses)) != 1:
        raise ProvisionError('No unique bootstrap IPv4 address on eth0')
    key = node_ssh(s, f"pct exec {s['vmId']} -- /run/current-system/sw/bin/cat /etc/ssh/ssh_host_ed25519_key.pub")
    if not key.startswith('ssh-ed25519 '):
        raise ProvisionError('Unexpected guest SSH host key')
    p = hostdir(s['name'])
    old = load(p / 'identity.json')
    if old and old['hostKey'].split()[:2] != key.split()[:2]:
        raise ProvisionError('Guest host key changed; explicit identity recovery required')
    record = {'address': addresses[0], 'hostKey': key,
              'sshPublicKey': (p / 'ssh_key.pub').read_text().strip()}
    write_json(p / 'identity.json', record)
    (p / 'known_hosts').write_text(s['sshAlias'] + ' ' + key + '\n')
    public = load(SRC / 'runtime-public.json', {})
    public[s['name']] = record
    write_json(SRC / 'runtime-public.json', public)
    write_ssh_config()
    if ssh(s, 'hostname') != s['hostname']:
        raise ProvisionError('SSH hostname mismatch')
    return record


def write_ssh_config():
    public = load(SRC / 'runtime-public.json', {})
    chunks = []
    for name, record in public.items():
        s = MANIFEST[name]
        p = hostdir(name)
        chunks.append(f"Host {s['sshAlias']}\n  HostName {record['address']}\n  User root\n  HostKeyAlias {s['sshAlias']}\n  IdentityFile {p}/ssh_key\n  UserKnownHostsFile {p}/known_hosts\n  StrictHostKeyChecking yes\n  IdentitiesOnly yes\n  BatchMode yes\n  ConnectTimeout 10\n")
    (STATE / 'ssh_config').write_text('\n'.join(chunks))


def ssh(s, command, input=None):
    return run(['ssh', '-F', str(STATE / 'ssh_config'), s['sshAlias'], command], input=input)


def authorize(s):
    """Reserve only the declared new identity; an existing unmanaged CT is never adopted."""
    resources = json.loads(node_ssh(s, 'pvesh get /cluster/resources --type vm --output-format json'))
    live = [r for r in resources if r.get('vmid') == s['vmId']]
    owned = any(r.get('type') == 'proxmox_virtual_environment_container' and r.get('name') == s['name']
                for r in load(STATE / 'terraform.tfstate', {}).get('resources', []))
    if live:
        require_owned(s)
        if len(live) != 1 or live[0].get('node') != s['node'] or live[0].get('name') != s['hostname']:
            raise ProvisionError('Existing resource does not match the declared identity')
        return
    if owned:
        raise ProvisionError('Owned resource is missing; automatic recreation refused')
    if any(r.get('name') == s['hostname'] for r in resources):
        raise ProvisionError('Hostname already exists outside this state')
    status = api(f"/nodes/{s['node']}/status")
    available = status['memory']['total'] - status['memory']['used']
    storage = json.loads(node_ssh(s, shlex.join(['pvesh', 'get',
        f"/nodes/{s['node']}/storage/{s['storage']}/status", '--output-format', 'json'])))
    if available < (s['memoryMiB'] + 512) * 1024**2 or storage['avail'] < (s['diskGiB'] + 1) * 1024**3:
        raise ProvisionError('Insufficient capacity for the declared service and safety margin')
    account = (STATE / 'api-token').read_text().split('!', 1)[0]
    acl = [(f"/vms/{s['vmId']}", 'PVEVMAdmin'),
           (f"/storage/{s['storage']}", 'PVEDatastoreUser'),
           ('/storage/local', 'PVEDatastoreUser,NixPrototypeTemplates'),
           (f"/sdn/zones/localnetwork/{s['bridge']}", 'PVESDNUser')]
    for path, roles in acl:
        node_ssh(s, shlex.join(['pveum', 'acl', 'modify', path, '--users', account, '--roles', roles]))


def prepare(s):
    p = hostdir(s['name'])
    if not (p / 'ssh_key').exists():
        run(['ssh-keygen', '-t', 'ed25519', '-N', '', '-C', s['hostname'], '-f', str(p / 'ssh_key')])
    variables = load(STATE / 'bootstrap.auto.tfvars.json', {'bootstrap': {}})
    if s['name'] in variables['bootstrap']:
        if variables['bootstrap'][s['name']]['ssh_public_key'] != (p / 'ssh_key.pub').read_text().strip():
            raise ProvisionError('Bootstrap key differs from its recorded identity')
        return  # Existing immutable image/state ownership remains unchanged.
    expr = f'''let f = builtins.getFlake {json.dumps(str(SRC))}; in
      (f.inputs.nixpkgs.lib.nixosSystem {{ system="x86_64-linux"; modules=[
        {SRC}/bootstrap.nix {{ networking.hostName=f.inputs.nixpkgs.lib.mkOverride 40 {json.dumps(s['hostname'])};
        users.users.root.openssh.authorizedKeys.keys=[(builtins.readFile {p}/ssh_key.pub)]; }}
      ]; }}).config.system.build.tarball'''
    image = run(['nix', 'build', '--impure', '--no-link', '--print-out-paths', '--expr', expr])
    archives = list((Path(image) / 'tarball').glob('*.tar.xz'))
    if len(archives) != 1:
        raise ProvisionError('Expected one bootstrap archive')
    archive = archives[0]
    digest = run(['sha256sum', str(archive)]).split()[0]
    filename = f'nixos-prototype-{digest}.tar.xz'
    listing = api(f"/nodes/{s['node']}/storage/local/content?content=vztmpl")
    existing = [x for x in listing if x['volid'] == 'local:vztmpl/' + filename]
    if existing and existing[0]['size'] != archive.stat().st_size:
        raise ProvisionError('Incomplete or conflicting image upload; inspect PVE task')
    if not existing:
        header = p / 'upload-header'
        header.write_text('Authorization: PVEAPIToken=' + (STATE / 'api-token').read_text().strip() + '\n')
        try:
            result = json.loads(run(['curl', '--fail', '--silent', '--show-error', '--cacert', str(STATE / 'pve-ca.pem'),
                '-H', '@' + str(header), '-F', 'content=vztmpl', '-F', f'filename=@{archive};filename={filename}',
                f"https://proxade:8006/api2/json/nodes/{s['node']}/storage/local/upload"]))
            for _ in range(60):
                task = api(f"/nodes/{s['node']}/tasks/{urllib.parse.quote(result['data'], safe='')}/status")
                if task['status'] == 'stopped':
                    if task.get('exitstatus') != 'OK':
                        raise ProvisionError('PVE image upload failed')
                    break
                time.sleep(1)
            else:
                raise ProvisionError('Image upload still running; retry after inspection')
        finally:
            header.unlink(missing_ok=True)
    variables['bootstrap'][s['name']] = {'ssh_public_key': (p / 'ssh_key.pub').read_text().strip(),
                                        'template_file_id': 'local:vztmpl/' + filename}
    write_json(STATE / 'bootstrap.auto.tfvars.json', variables)


def infra(s, apply=False):
    config = run(['nix', 'build', f'path:{SRC}', '--no-link', '--print-out-paths'])
    shutil.copyfile(config, STATE / 'config.tf.json')
    shutil.copyfile(SRC / '.terraform.lock.hcl', STATE / '.terraform.lock.hcl')
    env = dict(os.environ, PROXMOX_VE_API_TOKEN=(STATE / 'api-token').read_text().strip(),
               SSL_CERT_FILE=str(STATE / 'pve-ca.pem'))
    for args in [['init', '-input=false', '-lockfile=readonly'], ['validate'],
                 ['plan', '-input=false', '-lock-timeout=30s', '-out=review.tfplan']]:
        text = run(['tofu', *args], cwd=STATE, env=env)
        (STATE / ('tofu-' + args[0] + '.log')).write_text(text)
    plan = json.loads(run(['tofu', 'show', '-json', 'review.tfplan'], cwd=STATE, env=env))
    GUARD.check(plan, MANIFEST, s['name'])
    if apply:
        (STATE / 'tofu-apply.log').write_text(run(['tofu', 'apply', '-input=false', 'review.tfplan'], cwd=STATE, env=env))


def encrypt_secrets(s):
    target = SRC / 'secrets' / (s['name'] + '.yaml')
    if target.exists():
        return
    record = load(hostdir(s['name']) / 'identity.json')
    host_age = run(['ssh-to-age'], input=record['hostKey'] + '\n')
    controller_age = run(['ssh-to-age', '-i', '/etc/ssh/ssh_host_ed25519_key.pub'])
    if not s['generatedSecrets']:
        raise ProvisionError('Supply the encrypted application secrets before deployment')
    plaintext = json.dumps({key: secrets.token_urlsafe(32) for key in s['generatedSecrets']})
    encrypted = run(['sops', '--encrypt', '--input-type', 'json', '--output-type', 'yaml',
                     '--age', host_age + ',' + controller_age, '/dev/stdin'], input=plaintext)
    target.write_text(encrypted + '\n')


def deploy(s):
    require_owned(s)
    run(['colmena', '--config', str(SRC / 'flake.nix'), 'apply', '--on', s['name'], '--keep-result'],
        env=dict(os.environ, SSH_CONFIG_FILE=str(STATE / 'ssh_config')))
    units = s['units'] + ['tailscaled.service'] + (['gatus.service'] if s['monitoring'] else [])
    ssh(s, 'systemctl start ' + shlex.join(units))


def health(s):
    require_owned(s)
    units = s['units'] + ['tailscaled.service'] + (['gatus.service'] if s['monitoring'] else [])
    states = ssh(s, 'systemctl is-active ' + shlex.join(units) + ' || true').splitlines()
    if states != ['active'] * len(units):
        raise ProvisionError('One or more required services are not active')
    body = json.loads(ssh(s, shlex.join(['curl', '-fsS', f"http://127.0.0.1:{s['port']}{s['healthPath']}"])))
    if any(body.get(key) != value for key, value in s['healthBody'].items()):
        raise ProvisionError('Application health failed')
    probe = s.get('secretProbe')
    if probe:
        # Credential never crosses the LAN in HTTP or appears in argv/stdout.
        command = ("printf '%s: %s\\n' " + shlex.quote(probe['header']) +
                   ' "$(cat ' + shlex.quote('/run/secrets/' + probe['secret']) + ')" | ' +
                   shlex.join(['curl', '-fsS', '-H', '@-', f"http://127.0.0.1:{s['port']}{probe['path']}"]))
        if json.loads(ssh(s, command)) != probe['expected']:
            raise ProvisionError('SOPS-backed authentication probe failed')
    if s['monitoring']:
        for _ in range(15):
            entries = json.loads(ssh(s, 'curl -fsS http://127.0.0.1:8081/api/v1/endpoints/statuses'))
            entries = [entry for entry in entries if entry['name'] == s['name'] and entry['group'] == 'pilot']
            results = entries[0].get('results', []) if len(entries) == 1 else []
            latest = results[-1] if results else {}
            timestamp = datetime.fromisoformat(latest['timestamp']) if 'timestamp' in latest else None
            if latest.get('success') and timestamp and (datetime.now(timezone.utc) - timestamp).total_seconds() < 20:
                break
            time.sleep(1)
        else:
            raise ProvisionError('Gatus has no recent successful application probe')


def enroll(s):
    require_owned(s)
    status = json.loads(ssh(s, 'tailscale status --json || true'))
    if status.get('BackendState') != 'Running':
        credential = STATE / 'tailscale-oauth.json'
        if not credential.exists():
            raise ProvisionError('Tailscale OAuth credential is not installed; enrollment withheld')
        if credential.stat().st_mode & 0o077:
            raise ProvisionError('OAuth credential must be root-only')
        pending_dir = Path('/run/service-provisioning')
        pending_dir.mkdir(mode=0o700, exist_ok=True)
        pending = pending_dir / (s['name'] + '.json')
        cached = load(pending, {})
        if cached.get('expires', 0) < time.time() + 60:
            key = create_key(load(credential), s['tailscaleTags'])
            cached = {'key': key['key'], 'expires': time.time() + 3500}
            write_json(pending, cached)
        guest_key = '/run/provisioning-enrollment.key'
        ssh(s, 'umask 077; cat > ' + guest_key, input=cached['key'])
        try:
            flags = ['tailscale', 'up', '--auth-key=file:' + guest_key,
                     '--accept-dns=false', '--hostname=' + s['hostname'],
                     '--advertise-tags=' + ','.join(s['tailscaleTags']), '--timeout=60s']
            ssh(s, shlex.join(flags))
        finally:
            ssh(s, 'rm -f ' + guest_key)
        pending.unlink(missing_ok=True)
        status = json.loads(ssh(s, 'tailscale status --json || true'))
    if status.get('BackendState') != 'Running':
        raise ProvisionError('Tailscale is not running')
    if set(status.get('Self', {}).get('Tags', [])) != set(s['tailscaleTags']):
        raise ProvisionError('Tailscale identity has unexpected tags; no automatic retagging')
    addresses = [ip for ip in status.get('TailscaleIPs', []) if ':' not in ip]
    if len(addresses) != 1:
        raise ProvisionError('Expected one Tailscale IPv4 address')
    with urllib.request.urlopen(f"http://{addresses[0]}:{s['port']}{s['healthPath']}", timeout=15) as response:
        data = json.load(response)
        if any(data.get(key) != value for key, value in s['healthBody'].items()):
            raise ProvisionError('Health over Tailscale failed')
    public = load(SRC / 'runtime-public.json')
    public[s['name']]['bootstrapAddress'] = public[s['name']]['address']
    public[s['name']]['address'] = addresses[0]
    write_json(SRC / 'runtime-public.json', public)
    write_ssh_config()
    if ssh(s, 'hostname') != s['hostname']:
        raise ProvisionError('SSH over Tailscale failed')


def register(s):
    """Authenticate the existing GitOps user before proposing main-flake ownership."""
    require_owned(s)
    health(s)
    record = load(hostdir(s['name']) / 'identity.json')
    identity = {key: record[key] for key in ['hostKey', 'sshPublicKey']}
    directory = SRC / 'identities'
    directory.mkdir(exist_ok=True)
    target = directory / (s['name'] + '.json')
    if target.exists() and load(target) != identity:
        raise ProvisionError('Published SSH identity differs; explicit recovery required')
    # The host key was obtained through authenticated Proxmox SSH, not keyscan.
    controller_user = getpwnam('nixos')
    ssh_dir = Path(controller_user.pw_dir) / '.ssh'
    known = ssh_dir / 'known_hosts'
    ssh_dir.mkdir(mode=0o700, exist_ok=True)
    for hostname in [s['hostname']]:
        if known.exists():
            found = subprocess.run(['ssh-keygen', '-F', hostname, '-f', str(known)],
                                   text=True, capture_output=True, check=False)
            if found.returncode not in (0, 1):
                raise ProvisionError('Cannot read controller SSH trust file')
            keys = [line.split()[1:3] for line in found.stdout.splitlines() if line and not line.startswith('#')]
            expected = record['hostKey'].split()[:2]
            if keys and (expected not in keys or any(key[0] == 'ssh-ed25519' and key != expected for key in keys)):
                raise ProvisionError('Controller already trusts a different host key')
        else:
            keys = []
        if not keys:
            with known.open('a') as output:
                output.write('\n' + hostname + ' ' + record['hostKey'] + '\n')
            known.chmod(0o600)
            os.chown(known, controller_user.pw_uid, controller_user.pw_gid)
        result = run(['runuser', '-u', 'nixos', '--', 'ssh', '-oBatchMode=yes',
                      '-oStrictHostKeyChecking=yes', '-oConnectTimeout=10',
                      '-oHostKeyAlgorithms=ssh-ed25519', '-oUpdateHostKeys=no',
                      'root@' + hostname, 'hostname'])
        if result != s['hostname']:
            raise ProvisionError('Existing GitOps identity cannot authenticate the new service')
    write_json(target, identity)
    target.chmod(0o644)  # Public keys only: this generated artifact belongs in Git.


def stage(name, action, s, report):
    report.update(stage=name, status='running')
    write_json(hostdir(s['name']) / 'last-run.json', report)
    try:
        result = action(s)
    except Exception:
        report.update(status='failed')
        write_json(hostdir(s['name']) / 'last-run.json', report)
        raise
    report['completed'].append(name)
    report.update(status='complete')
    write_json(hostdir(s['name']) / 'last-run.json', report)
    print(f'{s["name"]}: {name} OK', flush=True)
    return result


def main():
    global MANIFEST
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['authorize', 'prepare', 'plan', 'infra', 'discover', 'secrets', 'deploy', 'health', 'enroll', 'register', 'up'])
    parser.add_argument('service')
    args = parser.parse_args()
    if os.geteuid() != 0 or socket.gethostname().split('.')[0] != 'dev-nixos':
        raise ProvisionError('Run as root on dev-nixos only')
    os.umask(0o077)
    if STATE.stat().st_uid != 0 or STATE.stat().st_mode & 0o077:
        raise ProvisionError('State directory must be root-owned mode 0700')
    with (STATE / 'controller.lock').open('w') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise ProvisionError('Another provisioning operation is running') from None
        MANIFEST = manifest()
        if args.service not in MANIFEST:
            raise ProvisionError('Unknown service')
        s = MANIFEST[args.service]
        if s.get('gitops', {}).get('enable') and args.action in ('deploy', 'up'):
            raise ProvisionError('GitOps-owned service: activation requires the main fleet CI/canary path')
        if s['lifecycle'] != 'active' and args.action not in ('plan', 'infra'):
            raise ProvisionError('Retained service: activation is disabled')
        backup()
        migrate_runtime()
        actions = {'authorize': authorize, 'prepare': prepare, 'plan': infra, 'infra': lambda s: infra(s, True),
                   'discover': discover, 'secrets': encrypt_secrets, 'deploy': deploy, 'health': health, 'enroll': enroll, 'register': register}
        steps = ['authorize', 'prepare', 'infra', 'discover', 'secrets', 'deploy', 'health', 'enroll'] if args.action == 'up' else [args.action]
        report = {'service': s['name'], 'completed': [], 'mode': 'isolated-pilot'}
        try:
            for name in steps:
                stage(name, actions[name], s, report)
        finally:
            backup()


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        # HTTP errors may have sensitive response bodies: report only the category.
        if isinstance(error, (ProvisionError, ValueError)):
            sys.exit(str(error))
        sys.exit(f'Provisioning stopped: {type(error).__name__}; inspect private diagnostics')
