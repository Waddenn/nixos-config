#!/bin/sh
# Authorized-key forced command: no arguments, shell expansion, or forwarding.
set -eu
case "${SSH_ORIGINAL_COMMAND:-}" in
  backup|logs|status|certificate|vulnerability-db)
    exec /usr/local/bin/sudo -n /conf/opnsense-hardening/maintenance.sh "$SSH_ORIGINAL_COMMAND"
    ;;
  *) echo 'Command denied' >&2; exit 126 ;;
esac
