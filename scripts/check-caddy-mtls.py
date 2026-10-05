#!/usr/bin/env python3
"""Test evaluated Caddy TLS policy with disposable certificates on loopback.

Usage: python3 scripts/check-caddy-mtls.py CADDY_BINARY VIRTUAL_HOSTS_JSON
Requires openssl. No Cloudflare credentials, real client keys or backends used.
"""
import importlib.util
import json
import os
from pathlib import Path
import re
import socket
import ssl
import subprocess
import sys
import tempfile
import time

spec = importlib.util.spec_from_file_location(
    "origin", Path(__file__).with_name("check-caddy-origin.py"))
origin = importlib.util.module_from_spec(spec)
spec.loader.exec_module(origin)


def certificates(directory):
    def run(*args):
        subprocess.run(["openssl", *args], cwd=directory, check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    run("req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "1",
        "-keyout", "server.key", "-out", "server.pem", "-subj", "/CN=*.hexaflare.net",
        "-addext", "subjectAltName=DNS:*.hexaflare.net")
    for name in ("ca", "wrong"):
        run("req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "1",
            "-keyout", f"{name}.key", "-out", f"{name}.pem", "-subj", f"/CN={name}",
            "-addext", "basicConstraints=critical,CA:TRUE")
    run("req", "-new", "-newkey", "rsa:2048", "-nodes", "-keyout", "client.key",
        "-out", "client.csr", "-subj", "/CN=test-client")
    (directory / "client.ext").write_text(
        "basicConstraints=critical,CA:FALSE\nextendedKeyUsage=clientAuth\n")
    run("x509", "-req", "-in", "client.csr", "-CA", "ca.pem", "-CAkey", "ca.key",
        "-CAcreateserial", "-days", "1", "-out", "client.pem", "-extfile", "client.ext")


def request(directory, port, sni, host, certificate, version):
    context = ssl.create_default_context(cafile=str(directory / "server.pem"))
    context.minimum_version = context.maximum_version = version
    if certificate:
        context.load_cert_chain(directory / f"{certificate}.pem",
                                directory / f"{certificate}.key")
    try:
        with socket.create_connection(("127.0.0.1", port), timeout=3,
                                      source_address=("127.0.0.2", 0)) as raw:
            with context.wrap_socket(raw, server_hostname=sni) as connection:
                connection.sendall(f"GET / HTTP/1.1\r\nHost: {host}\r\nConnection: close\r\n\r\n".encode())
                data = connection.recv(4096)
                return int(data.split()[1]) if data else "TLS_REJECTED"
    except ssl.SSLError:
        return "TLS_REJECTED"


def main():
    binary, hosts_file = sys.argv[1:]
    hosts = json.loads(Path(hosts_file).read_text())
    os.umask(0o077)
    with tempfile.TemporaryDirectory(prefix="caddy-mtls-test-") as tmp:
        directory = Path(tmp)
        certificates(directory)
        with socket.socket() as listener:
            listener.bind(("127.0.0.1", 0))
            port = listener.getsockname()[1]
        sites = []
        modes = set()
        for host in sorted(origin.PROTECTED | {origin.DIRECT}):
            extra = hosts[host]["extraConfig"]
            if host in origin.PROTECTED:
                mode = re.search(r"mode (verify_if_given|require_and_verify)", extra)
                assert mode, f"Missing verified client authentication for {host}"
                modes.add(mode.group(1))
                extra, count = re.subn(r"trust_pool file \S+", f"trust_pool file {directory}/ca.pem", extra)
                assert count == 1
            else:
                assert "client_auth" not in extra, "Nextcloud must retain direct TLS access"
            extra, count = re.subn(r"dns cloudflare[^\n]*", "", extra)
            assert count == 1
            extra = extra.replace("tls {", f"tls {directory}/server.pem {directory}/server.key {{", 1)
            sites.append(f"https://{host}:{port} {{\n{extra}\n}}")
        assert len(modes) == 1
        mode = modes.pop()
        caddyfile = directory / "Caddyfile"
        caddyfile.write_text("{\n admin off\n auto_https off\n servers {\n strict_sni_host on\n }\n}\n" + "\n".join(sites))
        config = json.loads(subprocess.check_output(
            [binary, "adapt", "--config", str(caddyfile), "--adapter", "caddyfile"], text=True))
        # Mock proxies, and allow a loopback peer to reach the HTTP layer after TLS.
        config = origin.transform(config, allow_test_peer=True)
        for server in config["apps"]["http"]["servers"].values():
            server["listen"] = [f"127.0.0.1:{port}"]
        path = directory / "config.json"
        path.write_text(json.dumps(config))
        with (directory / "caddy.log").open("w+") as log:
            env = dict(os.environ, XDG_DATA_HOME=str(directory / "data"),
                       XDG_CONFIG_HOME=str(directory / "config"))
            process = subprocess.Popen([binary, "run", "--config", str(path)],
                                       stdout=log, stderr=log, env=env)
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
                    raise RuntimeError("TLS test listener did not become ready")
                count = 0
                for version in (ssl.TLSVersion.TLSv1_2, ssl.TLSVersion.TLSv1_3):
                    for host in sorted(origin.PROTECTED):
                        for cert in (None, "wrong", "client"):
                            expected = (204 if cert == "client" or
                                        cert is None and mode == "verify_if_given" else "TLS_REJECTED")
                            actual = request(directory, port, host, host, cert, version)
                            assert actual == expected, (host, version, cert, actual, expected)
                            count += 1
                        # An unprotected SNI must never bypass a protected Host's policy.
                        actual = request(directory, port, origin.DIRECT, host, None, version)
                        assert actual == 421, ("domain fronting", host, actual)
                        count += 1
                    assert request(directory, port, origin.DIRECT, origin.DIRECT, None, version) == 204
                    count += 1
            finally:
                process.terminate()
                process.wait(timeout=5)
        print(f"PASS: {count} TLS checks ({mode}), including wrong certificates, domain fronting and Nextcloud")


if __name__ == "__main__":
    main()
