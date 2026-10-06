"""Exercise HAProxy against a fake Docker Unix socket; never use a real daemon."""
import http.client
import http.server
import os
from pathlib import Path
import shutil
import socket
import socketserver
import subprocess
import tempfile
import threading
import time
import unittest


HAPROXY = os.environ.get("HAPROXY_BIN") or shutil.which("haproxy")
CONFIG = Path(os.environ.get("BESZEL_PROXY_CONFIG", Path(__file__).resolve().parents[1]
                            / "modules/services/monitoring/beszel-docker-proxy.cfg"))


class UnixHTTPConnection(http.client.HTTPConnection):
    def connect(self):
        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.sock.settimeout(self.timeout)
        self.sock.connect(self.host)


@unittest.skipUnless(HAPROXY, "HAProxy integration runs in the Nix deployment-scripts check")
class ProxyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory(prefix="beszel-proxy-")
        cls.addClassCleanup(cls.tmp.cleanup)
        directory = Path(cls.tmp.name)
        cls.proxy_socket = str(directory / "proxy.sock")
        backend_socket = str(directory / "engine.sock")
        cls.received = []

        class Handler(http.server.BaseHTTPRequestHandler):
            def do_GET(self):
                cls.received.append((self.command, self.path))
                self.send_response(200)
                self.send_header("Content-Length", "2")
                self.end_headers()
                self.wfile.write(b"OK")

            def do_HEAD(self):
                cls.received.append((self.command, self.path))
                self.send_response(200)
                self.send_header("Content-Length", "0")
                self.end_headers()

            def log_message(self, *args):
                pass

        cls.server = socketserver.UnixStreamServer(backend_socket, Handler)
        threading.Thread(target=cls.server.serve_forever, daemon=True).start()
        cls.addClassCleanup(cls.server.server_close)
        cls.addClassCleanup(cls.server.shutdown)
        config = CONFIG.read_text().replace("/run/beszel-docker-proxy/docker.sock", cls.proxy_socket)
        config = config.replace("/run/docker.sock", backend_socket)
        config_path = directory / "haproxy.cfg"
        config_path.write_text(config)
        cls.process = subprocess.Popen([HAPROXY, "-W", "-db", "-f", str(config_path)],
                                       stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
        cls.addClassCleanup(cls.stop_proxy)
        deadline = time.monotonic() + 5
        while not Path(cls.proxy_socket).exists():
            if cls.process.poll() is not None:
                raise RuntimeError(cls.process.stderr.read().decode())
            if time.monotonic() >= deadline:
                raise RuntimeError("HAProxy did not start")
            time.sleep(0.02)

    @classmethod
    def stop_proxy(cls):
        cls.process.terminate()
        try:
            cls.process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            cls.process.kill()
            cls.process.wait()
        cls.process.stderr.close()

    def request(self, method, path):
        conn = UnixHTTPConnection(self.proxy_socket, timeout=3)
        try:
            conn.request(method, path, headers={"Host": "localhost"})
            response = conn.getresponse()
            response.read()
            return response.status
        finally:
            conn.close()

    def test_monitoring_reaches_the_backend(self):
        cid = "a" * 64
        for path in ["/_ping", "/version", "/info", "/containers/json",
                     "/v1.52/containers/json", f"/containers/{cid}/json",
                     f"/containers/{cid}/stats?stream=0&one-shot=1",
                     f"/containers/{cid}/logs?stdout=1&tail=200"]:
            with self.subTest(path=path):
                before = len(self.received)
                self.assertEqual(self.request("GET", path), 200)
                self.assertEqual(self.received[before:], [("GET", path)])
        self.assertEqual(self.request("HEAD", "/_ping"), 200)

    def test_mutations_never_reach_the_backend(self):
        cid = "a" * 12
        for method, path in [("POST", "/containers/create"),
                             ("POST", f"/containers/{cid}/exec"),
                             ("POST", f"/containers/{cid}/start"),
                             ("POST", f"/containers/{cid}/stop"),
                             ("DELETE", f"/containers/{cid}"),
                             ("PUT", f"/containers/{cid}/archive"),
                             ("POST", "/build"), ("POST", "/plugins/create"),
                             ("POST", "/containers/json"),
                             ("PATCH", "/info"), ("OPTIONS", "/info")]:
            with self.subTest(method=method, path=path):
                before = len(self.received)
                self.assertEqual(self.request(method, path), 403)
                self.assertEqual(len(self.received), before)

    def test_other_reads_and_path_tricks_never_reach_the_backend(self):
        cid = "a" * 12
        for path in [f"/containers/{cid}/archive?path=/etc/shadow",
                     "/images/json", "/secrets", "/configs", "/events",
                     "/containers/json/../create", "/containers/%2e%2e/json",
                     "/containers/json%2f..%2fcreate", "//containers/json",
                     "/containers/not-a-container-id/json", "/containers/json;create"]:
            with self.subTest(path=path):
                before = len(self.received)
                self.assertIn(self.request("GET", path), (400, 403))
                self.assertEqual(len(self.received), before)


if __name__ == "__main__":
    unittest.main()
