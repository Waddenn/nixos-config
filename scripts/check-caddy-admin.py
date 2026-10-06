#!/usr/bin/env python3
"""Exercise admin isolation, metrics and reload using Caddy and two real UIDs."""
import json
import os
import pwd
import socket
import stat
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
from pathlib import Path


def identity(user):
    account = pwd.getpwnam(user)

    def enter():
        os.setgroups([])
        os.setgid(account.pw_gid)
        os.setuid(account.pw_uid)
        os.umask(0o077)

    return account, enter


def main():
    binary, hosts_file = sys.argv[1:]
    if os.geteuid() != 0:
        raise SystemExit("Run as root to verify different service identities")
    owner, as_owner = identity("nobody")
    _, as_observer = identity("beszel")
    hosts = json.loads(Path(hosts_file).read_text())
    metrics = hosts["http://127.0.0.1:2019"]["extraConfig"]
    with tempfile.TemporaryDirectory(prefix="caddy-admin-test-") as tmp:
        directory = Path(tmp)
        os.chown(directory, owner.pw_uid, owner.pw_gid)
        directory.chmod(0o700)
        admin_socket = directory / "admin.sock"
        address = f"unix/{admin_socket}"
        with socket.socket() as listener:
            listener.bind(("127.0.0.1", 0))
            port = listener.getsockname()[1]
        config = directory / "Caddyfile"
        config.write_text(
            "{\n admin " + address + "|0600\n auto_https off\n"
            " metrics {\n per_host\n }\n}\n"
            f"http://127.0.0.1:{port} {{\n" + metrics + "\n}\n"
        )
        os.chown(config, owner.pw_uid, owner.pw_gid)
        config.chmod(0o600)
        environment = os.environ | {"HOME": tmp, "XDG_CONFIG_HOME": tmp,
                                    "XDG_DATA_HOME": tmp}
        with (directory / "caddy.log").open("w") as log:
            process = subprocess.Popen(
                [binary, "run", "--config", str(config), "--adapter", "caddyfile"],
                preexec_fn=as_owner, env=environment, stdout=log, stderr=log,
            )
            try:
                deadline = time.monotonic() + 10
                while not admin_socket.exists():
                    if process.poll() is not None or time.monotonic() > deadline:
                        raise RuntimeError("Isolated Caddy did not start")
                    time.sleep(0.1)
                information = admin_socket.stat()
                assert stat.S_IMODE(information.st_mode) == 0o600, information
                assert information.st_uid == owner.pw_uid, information

                def unix_get(drop_privileges):
                    # A separate process ensures the request uses the tested UID.
                    code = (
                        "import socket; s=socket.socket(socket.AF_UNIX); "
                        f"s.connect({str(admin_socket)!r}); "
                        "s.sendall(b'GET /config/ HTTP/1.1\\r\\nHost: localhost\\r\\n"
                        "Connection: close\\r\\n\\r\\n'); "
                        "print(s.recv(100).split(b'\\r\\n')[0].decode())"
                    )
                    return subprocess.run(
                        [sys.executable, "-c", code], preexec_fn=drop_privileges,
                        capture_output=True, text=True, timeout=5,
                    )

                assert "200" in unix_get(None).stdout, "root denied"
                assert "200" in unix_get(as_owner).stdout, "Caddy UID denied"
                denied = unix_get(as_observer)
                assert denied.returncode != 0 and "PermissionError" in denied.stderr
                base = f"http://127.0.0.1:{port}"
                for method, path in [("GET", "/config/"), ("POST", "/load"),
                                     ("DELETE", "/config/"), ("POST", "/metrics")]:
                    request = urllib.request.Request(base + path, method=method,
                                                     data=b"{}" if method == "POST" else None)
                    try:
                        urllib.request.urlopen(request, timeout=5)
                    except urllib.error.HTTPError as error:
                        assert error.code == 404, (method, path, error.code)
                    else:
                        raise AssertionError((method, path, "unexpected access"))
                with urllib.request.urlopen(base + "/metrics", timeout=5) as response:
                    assert response.status == 200
                    assert b"caddy_" in response.read()
                subprocess.run(
                    [binary, "reload", "--config", str(config), "--adapter", "caddyfile",
                     "--address", address, "--force"], preexec_fn=as_owner,
                    env=environment, stdout=log, stderr=log, check=True, timeout=10,
                )
                assert "200" in unix_get(as_owner).stdout, "admin lost after reload"
                assert unix_get(as_observer).returncode != 0, "isolation lost after reload"
                with urllib.request.urlopen(base + "/metrics", timeout=5) as response:
                    assert response.status == 200
                print("PASS: socket 0600; root/Caddy allowed; Beszel denied; "
                      "TCP admin paths rejected; metrics and reload work")
            finally:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()


if __name__ == "__main__":
    main()
