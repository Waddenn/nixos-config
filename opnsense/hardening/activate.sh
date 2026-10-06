#!/bin/sh
# Root-only transaction with ten-minute watchdog and concurrent-change guards.
set -eu
[ "$(id -u)" = 0 ] || exit 126
state=/root/opnsense-hardening/20261006
if [ "${OPNSENSE_TRANSACTION_LOCKED:-}" != 1 ]; then
  export OPNSENSE_TRANSACTION_LOCKED=1
  exec /usr/local/bin/flock -n -o "$state/transaction.lock" /bin/sh "$0" "$@"
fi
staged=$state/staged
original=$state/original
case "${1:-}" in
  prepare)
    cmp /conf/config.xml "$original/config.xml"
    php "$staged/maintenance.php" certificate --check < "$staged/certificate.json"
    expected=$(sha256 -q /conf/config.xml)
    php "$staged/configure.php" --policy="$staged/policy.json" --credentials="$staged/credentials.json" --certificate="$staged/certificate.json" --expected="$expected" --candidate="$staged/candidate.xml" --mfa-enrolled
    php "$staged/render-filter.php" "$staged/candidate.xml" > "$staged/candidate.pf"
    pfctl -nf "$staged/candidate.pf"
    printf '%s\n' "$expected" > "$state/expected.sha256"
    : > "$state/staged.sha256"
    for file in activate.sh configure.php validate.php render-filter.php policy.json credentials.json certificate.json maintenance.php maintenance.sh dispatch.sh sudoers backup-public.pem; do
      printf '%s %s\n' "$file" "$(sha256 -q "$staged/$file")" >> "$state/staged.sha256"
    done
    ;;
  activate)
    [ -f "$state/enrollment-verified" ] || { echo 'MFA enrollment not verified' >&2; exit 1; }
    [ ! -f "$state/active" ] || { echo 'Transaction already active' >&2; exit 1; }
    while read -r file reviewed; do
      [ "$(sha256 -q "$staged/$file")" = "$reviewed" ] || { echo "Staged file changed since preparation: $file" >&2; exit 1; }
    done < "$state/staged.sha256"
    expected=$(cat "$state/expected.sha256")
    [ "$(sha256 -q /conf/config.xml)" = "$expected" ] || { echo 'Config changed since preparation' >&2; exit 1; }
    mkdir -p /conf/opnsense-hardening
    chmod 700 /conf/opnsense-hardening
    for file in maintenance.php maintenance.sh dispatch.sh backup-public.pem; do cp "$staged/$file" "/conf/opnsense-hardening/$file"; done
    chmod 755 /conf/opnsense-hardening /conf/opnsense-hardening/dispatch.sh
    chmod 700 /conf/opnsense-hardening/maintenance.sh
    chmod 600 /conf/opnsense-hardening/maintenance.php /conf/opnsense-hardening/backup-public.pem
    sudoers=/usr/local/etc/sudoers.d/opnsense-maintenance
    [ ! -e "$sudoers" ] || { echo 'Unexpected sudoers entry; refuse overwrite' >&2; exit 1; }
    cp "$staged/sudoers" "$sudoers"
    chmod 440 "$sudoers"
    /usr/local/sbin/visudo -cf "$sudoers"
    touch "$state/active"
    /usr/sbin/daemon -f /bin/sh -c "unset OPNSENSE_TRANSACTION_LOCKED; sleep 600; /bin/sh '$staged/activate.sh' rollback"
    php "$staged/configure.php" --policy="$staged/policy.json" --credentials="$staged/credentials.json" --certificate="$staged/certificate.json" --expected="$expected" --apply --mfa-enrolled
    sha256 -q /conf/config.xml > "$state/applied.sha256"
    /usr/local/sbin/pluginctl -s openssh restart
    /usr/local/sbin/configctl unbound restart
    /usr/local/sbin/configctl filter reload
    /usr/local/sbin/configctl webgui restart
    ;;
  confirm)
    [ -f "$state/active" ]
    touch "$state/confirmed"
    rm "$state/active"
    ;;
  rollback)
    [ -f "$state/active" ] || exit 0
    [ ! -f "$state/confirmed" ] || exit 0
    reference="$state/expected.sha256"
    [ ! -f "$state/applied.sha256" ] || reference="$state/applied.sha256"
    if [ "$(sha256 -q /conf/config.xml)" != "$(cat "$reference")" ]; then
      logger -p auth.crit 'OPNsense hardening rollback stopped: concurrent configuration change; use console snapshot recovery'
      exit 1
    fi
    cp -p "$original/config.xml" /conf/config.xml
    rm -f /tmp/config.cache /usr/local/etc/sudoers.d/opnsense-maintenance
    php -r 'require_once "config.inc"; require_once "auth.inc"; local_sync_accounts();'
    /usr/local/sbin/pluginctl -s openssh restart
    /usr/local/sbin/configctl unbound restart
    /usr/local/sbin/configctl filter reload
    /usr/local/sbin/configctl webgui restart
    rm "$state/active"
    logger -p auth.notice 'OPNsense hardening original configuration restored'
    ;;
  *) echo 'Usage: activate.sh prepare|activate|confirm|rollback' >&2; exit 2 ;;
esac
