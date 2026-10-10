#!/usr/bin/env python3
"""Test ingress on a private nginx process and port, without production requests."""
import argparse
import concurrent.futures
import json
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import time
import urllib.error
import urllib.request


def burst(port, path, ip, count):
    def request(_):
        request = urllib.request.Request(
            f'http://127.0.0.1:{port}{path}', headers={'CF-Connecting-IP': ip})
        try:
            with urllib.request.urlopen(request, timeout=5) as response:
                return response.status
        except urllib.error.HTTPError as error:
            return error.code
    with concurrent.futures.ThreadPoolExecutor(max_workers=64) as executor:
        responses = list(executor.map(request, range(count)))
    return {str(code): responses.count(code) for code in set(responses)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--nginx', required=True, help='Nix-provided nginx executable')
    options = parser.parse_args()
    source = (Path(__file__).resolve().parents[1] / 'provisioning/applications/classeur.nix').read_text()
    # Exercise exactly the source's maps/zones, with its private token include
    # omitted. This is a rate-limit test, not an origin-authentication bypass.
    block = source.split("appendHttpConfig = ''", 1)[1].split("    '';", 1)[0]
    block = '\n'.join(line for line in block.splitlines() if 'include ${' not in line)
    with tempfile.TemporaryDirectory(prefix='classeur-ingress-check-') as directory:
        root = Path(directory)
        os.chmod(root, 0o755)
        for filename in ['dynamic', 'assets/a.js', 'api/admin/assets/a/thumb']:
            path = root / filename
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('ok')
            path.chmod(0o644)
            for parent in path.parents:
                if parent == root:
                    break
                parent.chmod(0o755)
        with socket.socket() as sock:
            sock.bind(('127.0.0.1', 0))
            port = sock.getsockname()[1]
        config = root / 'nginx.conf'
        config.write_text(f'''
            pid {directory}/nginx.pid;
            error_log {directory}/error.log;
            events {{ worker_connections 1024; }}
            http {{
                access_log off;
                {block}
                server {{
                    listen 127.0.0.1:{port};
                    root {directory};
                    location / {{
                        limit_req zone=classeur_dynamic burst=60 nodelay;
                        limit_req zone=classeur_artwork burst=120 nodelay;
                        limit_req_status 429;
                    }}
                }}
            }}
        ''')
        command = [options.nginx, '-e', str(root / 'error.log'), '-c', str(config), '-p', directory]
        subprocess.run(command + ['-t'], check=True)
        process = subprocess.Popen(command + ['-g', 'daemon off;'])
        try:
            for _ in range(100):
                try:
                    with socket.create_connection(('127.0.0.1', port), timeout=0.1):
                        pass
                    break
                except OSError:
                    time.sleep(0.02)
            results = {
                'normal_dynamic_60': burst(port, '/dynamic', '198.51.100.10', 60),
                'normal_artwork_120': burst(port, '/api/admin/assets/a/thumb', '198.51.100.20', 120),
                'static_300': burst(port, '/assets/a.js', '198.51.100.30', 300),
                'dynamic_flood_300': burst(port, '/dynamic', '198.51.100.40', 300),
                'different_ip_after_flood': burst(port, '/dynamic', '198.51.100.50', 60),
            }
            assert results['normal_dynamic_60'] == {'200': 60}, results
            assert results['normal_artwork_120'] == {'200': 120}, results
            assert results['static_300'] == {'200': 300}, results
            assert results['dynamic_flood_300'].get('429', 0) > 0, results
            assert results['different_ip_after_flood'] == {'200': 60}, results
            print(json.dumps(results))
        finally:
            # Stop only the specific process owned by this check.
            process.terminate()
            process.wait(timeout=5)


if __name__ == '__main__':
    main()
