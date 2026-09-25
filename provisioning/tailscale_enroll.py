"""OAuth stays on the controller; only a short, single-use key reaches the guest."""
import json
import urllib.parse
import urllib.request

TOKEN_URL = 'https://api.tailscale.com/api/v2/oauth/token'
KEYS_URL = 'https://api.tailscale.com/api/v2/tailnet/-/keys'


def key_request(tags):
    if not tags or any(not tag.startswith('tag:') for tag in tags):
        raise ValueError('Explicit Tailscale tags are required')
    return {'capabilities': {'devices': {'create': {
        'reusable': False, 'ephemeral': False, 'preauthorized': True, 'tags': tags,
    }}}, 'expirySeconds': 3600, 'description': 'dev-nixos service enrollment'}


def create_key(credentials, tags, opener=urllib.request.urlopen):
    form = urllib.parse.urlencode({
        'grant_type': 'client_credentials', 'client_id': credentials['client_id'],
        'client_secret': credentials['client_secret'], 'scope': 'auth_keys',
        'tags': ' '.join(tags),
    }).encode()
    with opener(urllib.request.Request(TOKEN_URL, data=form), timeout=30) as response:
        token = json.load(response)['access_token']
    request = urllib.request.Request(KEYS_URL, data=json.dumps(key_request(tags)).encode(),
        headers={'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json'})
    with opener(request, timeout=30) as response:
        return json.load(response)
