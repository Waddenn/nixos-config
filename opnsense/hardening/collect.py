#!/usr/bin/env python3
"""Controller-only encrypted backup, certificate deployment and health evidence."""
import argparse
import datetime as dt
import json
import os
import lzma
import urllib.request
from pathlib import Path
import subprocess
import tempfile


def ssh(host, command, identity=None, native=False, input_data=None):
    args = ["ssh", "-o", "BatchMode=yes", "-o", "StrictHostKeyChecking=yes", "-o", "ConnectTimeout=10"]
    if native:
        args += ["-o", "HostKeyAlias=opnsense-native", "-i", str(identity), "-o", "IdentitiesOnly=yes"]
    return subprocess.run(args + [host, command], input=input_data, capture_output=True, check=True, timeout=120).stdout


def atomic(path, data):
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as file:
        os.chmod(file.name, 0o600)
        file.write(data)
        temp = file.name
    os.replace(temp, path)


def health_issues(status, now):
    issues = []
    if not status.get("audit_valid"):
        issues.append("Vulnerability database invalid")
    if status.get("vulnerability_advisories") is None:
        issues.append("Vulnerability result unavailable")
    elif status["vulnerability_advisories"]:
        issues.append(f"{status['vulnerability_advisories']} vulnerability advisories")
    if not status.get("certificate_expires") or status["certificate_expires"] < now + 21 * 86400:
        issues.append("Administration certificate expires within 21 days")
    return issues


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--state-dir", type=Path, required=True)
    parser.add_argument("--no-certificate", action="store_true")
    args = parser.parse_args()
    state = args.state_dir
    state.mkdir(mode=0o700, parents=True, exist_ok=True)
    os.umask(0o077)
    stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    identity = state / "id_ed25519"
    if not identity.is_file():
        raise RuntimeError("Dedicated controller SSH key has not been provisioned")
    host = "opnsense-maint@192.168.1.4"
    for mode in ("backup", "logs"):
        data = ssh(host, mode, identity, native=True)
        if len(data) < 128:
            raise RuntimeError(f"Empty or truncated encrypted {mode}")
        atomic(state / f"{mode}-{stamp}.cms", data)
    if not args.no_certificate:
        prefix = "/var/lib/opnsense-certificate/caddy/certificates/acme-v02.api.letsencrypt.org-directory/opnsense.hexaflare.net/opnsense.hexaflare.net"
        bundle = {"certificate": ssh("root@caddy", f"cat {prefix}.crt").decode(),
                  "private_key": ssh("root@caddy", f"cat {prefix}.key").decode()}
        ssh(host, "certificate", identity, native=True, input_data=json.dumps(bundle).encode())
    refreshed = state / "database-refreshed"
    now = dt.datetime.now(dt.timezone.utc).timestamp()
    if not refreshed.exists() or now - refreshed.stat().st_mtime >= 86400:
        with urllib.request.urlopen("https://vuxml.freebsd.org/freebsd/vuln.xml.xz", timeout=30) as response:
            compressed = response.read(4194305)
        if len(compressed) > 4194304:
            raise RuntimeError("Compressed vulnerability database too large")
        decoder = lzma.LZMADecompressor()
        database = decoder.decompress(compressed, max_length=33554433)
        if not decoder.eof or len(database) > 33554432:
            raise RuntimeError("Vulnerability database truncated or too large")
        ssh(host, "vulnerability-db", identity, native=True, input_data=database)
        atomic(refreshed, stamp.encode())
    status = json.loads(ssh(host, "status", identity, native=True))
    status["issues"] = health_issues(status, dt.datetime.now(dt.timezone.utc).timestamp())
    status["last_successful_backup"] = stamp
    atomic(state / "status.json", json.dumps(status, indent=2).encode())
    # Rotation only follows a successful backup AND health collection.
    cutoff = dt.datetime.now(dt.timezone.utc).timestamp() - 31 * 86400
    for archive in state.glob("*.cms"):
        if archive.stat().st_mtime < cutoff:
            archive.unlink()
    print(json.dumps({"backup": stamp, "issues": status["issues"]}))
    if status["issues"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
