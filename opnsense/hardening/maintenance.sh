#!/bin/sh
set -eu
[ "$(id -u)" = 0 ] || exit 126
case "${1:-}" in
  backup)
    exec /usr/local/bin/openssl cms -encrypt -aes-256-gcm -binary -in /conf/config.xml -outform DER /conf/opnsense-hardening/backup-public.pem
    ;;
  logs)
    archive=$(mktemp /tmp/opnsense-logs.XXXXXX)
    trap 'rm -f "$archive"' EXIT HUP INT TERM
    chmod 600 "$archive"
    tar -czhf "$archive" -C /var/log audit/latest.log system/latest.log lighttpd/latest.log
    /usr/local/bin/openssl cms -encrypt -aes-256-gcm -binary -in "$archive" -outform DER /conf/opnsense-hardening/backup-public.pem
    ;;
  vulnerability-db)
    exec /usr/local/bin/php /conf/opnsense-hardening/maintenance.php vulnerability-db
    ;;
  status)
    exec /usr/local/bin/php /conf/opnsense-hardening/maintenance.php status
    ;;
  certificate)
    exec /usr/local/bin/php /conf/opnsense-hardening/maintenance.php certificate
    ;;
  *) exit 126 ;;
esac
