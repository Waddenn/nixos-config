"""A deliberately small pilot: health and a credential-backed authenticated probe."""
import hmac
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


def response(path, supplied, token, name):
    if path == '/healthz':
        return (200, {'status': 'ready', 'service': name}) if token else (503, {'status': 'unready'})
    if path == '/private':
        if token and hmac.compare_digest(supplied, token):
            return 200, {'authenticated': True}
        return 401, {'authenticated': False}
    if path == '/':
        return 200, {'service': name, 'message': 'NixOS provisioning pilot'}
    return 404, {'error': 'not found'}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        token = (Path(os.environ['CREDENTIALS_DIRECTORY']) / 'demo-token').read_text().strip()
        code, body = response(self.path, self.headers.get('X-Demo-Token', ''), token,
                              os.environ['SERVICE_NAME'])
        data = json.dumps(body).encode()
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *_):
        pass  # Never log credentials or arbitrary request headers.


if __name__ == '__main__':
    ThreadingHTTPServer(('0.0.0.0', int(os.environ['PORT'])), Handler).serve_forever()
