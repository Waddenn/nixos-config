#!/bin/sh
# Tailscale's address arrives after the early webgui bind during boot.
set -eu
attempt=0
while [ "$attempt" -lt 30 ]; do
  if /sbin/ifconfig tailscale0 2>/dev/null | /usr/bin/grep -q 'inet 100.103.199.91 '; then
    /usr/local/sbin/configctl webgui restart
    /usr/bin/logger -t opnsense-hardening 'Private webgui rebound after Tailscale became ready'
    exit 0
  fi
  attempt=$((attempt + 1))
  sleep 2
done
/usr/bin/logger -p auth.err -t opnsense-hardening 'Tailscale address unavailable: private webgui rebind deferred; use console recovery'
exit 1
