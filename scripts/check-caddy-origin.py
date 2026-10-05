#!/usr/bin/env python3
"""Exercise evaluated Caddy routes locally, with application/auth proxies mocked.

Usage: python3 scripts/check-caddy-origin.py CADDY_BINARY VIRTUAL_HOSTS_JSON
Export virtual hosts with nix eval --json .#nixosConfigurations.caddy.config.services.caddy.virtualHosts.
No production listener, certificate, credential or backend is used.
"""
import copy
import http.client
import json
from pathlib import Path
import re
import socket
import subprocess
import sys
import tempfile
import time


PROTECTED = {f"{name}.hexaflare.net" for name in (
    "auth", "bitwarden", "homeassistant", "jellyseerr", "immich", "codex"
)}
DIRECT = "nextcloud.hexaflare.net"


def remove_tls(extra):
    """Remove the one site TLS block, including nested client authentication."""
    matches = list(re.finditer(r"(?m)^\s*tls \{", extra))
    assert len(matches) == 1, "Expected exactly one site TLS block"
    start = matches[0].start()
    opening = extra.index("{", matches[0].start())
    depth = 0
    for end in range(opening, len(extra)):
        depth += (extra[end] == "{") - (extra[end] == "}")
        if depth == 0:
            return extra[:start] + extra[end + 1:]
    raise AssertionError("Unbalanced TLS block")


def transform(value, allow_test_peer=False):
    if isinstance(value, dict):
        if value.get("handler") == "reverse_proxy":
            # A premature forward_auth would return 204 and fail the deny tests.
            return {"handler": "static_response", "status_code": 204}
        result = {k: transform(v, allow_test_peer) for k, v in value.items()}
        if allow_test_peer and "remote_ip" in result:
            result["remote_ip"]["ranges"].append("127.0.0.2/32")
        return result
    if isinstance(value, list):
        return [transform(v, allow_test_peer) for v in value]
    return value


def exercise(binary, config, directory, port, allow_test_peer):
    path = directory / "test.json"
    path.write_text(json.dumps(transform(copy.deepcopy(config), allow_test_peer)))
    with (directory / "caddy.log").open("w+") as log:
        process = subprocess.Popen([binary, "run", "--config", str(path)],
                                   stdout=log, stderr=log)
        try:
            for _ in range(100):
                try:
                    with socket.create_connection(("127.0.0.1", port), timeout=.1):
                        break
                except OSError:
                    if process.poll() is not None:
                        log.seek(0)
                        raise RuntimeError(log.read())
                    time.sleep(.05)
            else:
                raise RuntimeError("Test listener did not become ready")
            for host in sorted(PROTECTED | {DIRECT}):
                for peer in ("127.0.0.1", "127.0.0.2"):
                    for forged in (False, True):
                        headers = {"Host": host}
                        if forged:
                            headers.update({"X-Forwarded-For": "173.245.48.1",
                                            "CF-Connecting-IP": "173.245.48.1",
                                            "X-Real-IP": "173.245.48.1"})
                        connection = http.client.HTTPConnection(
                            "127.0.0.1", port, timeout=3, source_address=(peer, 0))
                        connection.request("GET", "/", headers=headers)
                        response = connection.getresponse()
                        response.read()
                        expected = 204 if (host == DIRECT or
                                           allow_test_peer and peer == "127.0.0.2") else 403
                        assert response.status == expected, (
                            host, peer, forged, response.status, expected)
                        connection.close()
        finally:
            process.terminate()
            process.wait(timeout=5)


def main():
    binary, virtual_hosts_file = sys.argv[1:]
    hosts = json.loads(Path(virtual_hosts_file).read_text())
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
        port = listener.getsockname()[1]
    with tempfile.TemporaryDirectory(prefix="caddy-origin-test-") as tmp:
        directory = Path(tmp)
        sites = []
        for host in sorted(PROTECTED | {DIRECT}):
            extra = hosts[host]["extraConfig"]
            # Only remove certificate provisioning; preserve all HTTP routes.
            extra = remove_tls(extra)
            sites.append(f"http://{host}:{port} {{\n{extra}\n}}")
        caddyfile = directory / "Caddyfile"
        caddyfile.write_text("{\n admin off\n auto_https off\n}\n" + "\n".join(sites))
        config = json.loads(subprocess.check_output(
            [binary, "adapt", "--config", str(caddyfile), "--adapter", "caddyfile"],
            text=True))
        for server in config["apps"]["http"]["servers"].values():
            server["listen"] = [f"127.0.0.1:{port}"]
        exercise(binary, config, directory, port, False)
        exercise(binary, config, directory, port, True)
    print("PASS: 56 HTTP checks; direct/forged requests denied, allowed peer and Nextcloud preserved")


if __name__ == "__main__":
    main()
