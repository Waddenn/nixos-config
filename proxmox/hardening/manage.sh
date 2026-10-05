#!/usr/bin/env bash
# Run on each PVE host, from a reviewed release copied by dev-nixos.
set -Eeuo pipefail
umask 077

mode=${1:-}
batch=${2:-}
[[ $EUID == 0 ]] || { echo 'Run as root on a Proxmox host.' >&2; exit 1; }
[[ $batch =~ ^[a-zA-Z0-9_-]{1,64}$ ]] || { echo 'Usage: manage.sh prepare|activate|confirm|rollback BATCH' >&2; exit 1; }
node=$(hostname -s)
[[ $node == proxade || $node == nuc-pve-1 ]] || { echo 'Unexpected host.' >&2; exit 1; }
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
state=/root/proxmox-hardening/$batch
unit=proxmox-hardening-rollback
cluster=/etc/pve/firewall/cluster.fw
host=/etc/pve/nodes/$node/host.fw
ssh_config=/etc/ssh/sshd_config.d/00-proxmox-hardening.conf
exec 9>/run/lock/proxmox-hardening.lock
if [[ $mode == rollback ]]; then
    flock -w 60 9
else
    flock -n 9
fi || { echo 'Another hardening operation is running.' >&2; exit 1; }

check_quorum() {
    pvecm status | grep -Eq '^Quorate:[[:space:]]+Yes$'
}
check_ssh() {
    /usr/sbin/sshd -t
    local config
    config=$(/usr/sbin/sshd -T)
    grep -Eq '^permitrootlogin (prohibit-password|without-password)$' <<< "$config"
    grep -qx 'passwordauthentication no' <<< "$config"
    grep -qx 'kbdinteractiveauthentication no' <<< "$config"
    grep -qx 'pubkeyauthentication yes' <<< "$config"
}
restore() {
    # Never overwrite an unrelated change made after preparation/activation.
    local dest original candidate incomplete=0
    for dest in "$cluster" "$host"; do
        original=$state/original/cluster.fw
        candidate=$state/candidate/cluster.fw
        if [[ $dest == "$host" ]]; then
            original=$state/original/$node.fw
            candidate=$state/candidate/host.fw
        fi
        if cmp -s "$dest" "$candidate" || cmp -s "$dest" "$original"; then
            cat "$original" > "$dest"
        else
            echo "Concurrent change: left $dest untouched; original in $state/original" >&2
            incomplete=1
        fi
    done
    if [[ -f $ssh_config ]]; then
        if cmp -s "$ssh_config" "$state/candidate/00-proxmox-hardening.conf"; then
            rm -- "$ssh_config"
        else
            echo "Concurrent SSH change: left $ssh_config untouched." >&2
            incomplete=1
        fi
    fi
    if /usr/sbin/sshd -t; then
        systemctl reload ssh || incomplete=1
    else
        incomplete=1
    fi
    # The running pve-firewall daemon reconciles restored files; do not stop it.
    touch "$state/rolled-back"
    echo "Rollback processed on $node (incomplete=$incomplete). Check pve-firewall status and cluster quorum."
    return "$incomplete"
}

case $mode in
prepare)
    [[ ! -e $state && ! -e $ssh_config ]]
    ! systemctl is-active --quiet "$unit.timer"
    check_quorum
    systemctl is-active --quiet pve-firewall
    sha256sum -c "$here/baseline.sha256"
    # Enabling the cluster firewall must not silently activate guest filtering.
    if grep -R -q 'firewall=1' /etc/pve/nodes/*/lxc /etc/pve/nodes/*/qemu-server; then
        echo 'Guest NIC firewall enabled: review guest effects before proceeding.' >&2
        exit 1
    fi
    perl "$here/validate.pl" "$here"
    install -d -m 0700 "$state/original"
    cp -a "$here" "$state/candidate"
    cp "$cluster" "$state/original/cluster.fw"
    cp /etc/pve/nodes/proxade/host.fw "$state/original/proxade.fw"
    cp /etc/pve/nodes/nuc-pve-1/host.fw "$state/original/nuc-pve-1.fw"
    cp /etc/ssh/sshd_config "$state/original/sshd_config"
    cp -a /etc/ssh/sshd_config.d "$state/original/sshd_config.d"
    cat "$here/00-proxmox-hardening.conf" /etc/ssh/sshd_config > "$state/sshd-preview.conf"
    /usr/sbin/sshd -t -f "$state/sshd-preview.conf"
    /usr/sbin/sshd -T -f "$state/sshd-preview.conf" > "$state/sshd-preview.effective"
    grep -qx 'passwordauthentication no' "$state/sshd-preview.effective"
    (cd "$state/candidate" && sha256sum cluster.fw host.fw 00-proxmox-hardening.conf validate.pl manage.sh) > "$state/candidate.sha256"
    touch "$state/prepared"
    echo "Prepared $node batch=$batch. Prepare BOTH nodes before activating either."
    ;;
activate)
    [[ -f $state/prepared && ! -e $state/activated && ! -e $state/rolled-back && ! -e $ssh_config ]]
    (cd "$state/candidate" && sha256sum -c "$state/candidate.sha256")
    check_quorum
    # A peer may already have installed the shared cluster file, but no other change is accepted.
    cmp -s "$cluster" "$state/original/cluster.fw" || cmp -s "$cluster" "$state/candidate/cluster.fw"
    cmp -s "$host" "$state/original/$node.fw"
    cmp -s /etc/ssh/sshd_config "$state/original/sshd_config"
    diff -qr /etc/ssh/sshd_config.d "$state/original/sshd_config.d"
    perl "$state/candidate/validate.pl" "$state/candidate"
    systemd-run --unit="$unit" --on-active=10m --timer-property=AccuracySec=1s \
        /bin/bash "$state/candidate/manage.sh" rollback "$batch"
    trap 'trap - ERR; echo "Activation failed; rolling back." >&2; restore' ERR
    install -m 0600 "$state/candidate/00-proxmox-hardening.conf" "$ssh_config"
    check_ssh
    systemctl reload ssh
    cat "$state/candidate/host.fw" > "$host"
    cat "$state/candidate/cluster.fw" > "$cluster"
    touch "$state/activated"
    trap - ERR
    echo 'Applied candidate. Firewall daemon reconciles asynchronously.'
    echo 'Verify NEW SSH/web sessions, quorum, VM connectivity and monitoring on BOTH nodes before confirm.'
    echo 'Automatic rollback in 10 minutes unless both nodes are confirmed.'
    ;;
confirm)
    [[ -f $state/activated && ! -e $state/rolled-back ]]
    systemctl is-active --quiet "$unit.timer"
    check_quorum
    check_ssh
    cmp -s "$cluster" "$state/candidate/cluster.fw"
    cmp -s "$host" "$state/candidate/host.fw"
    pve-firewall status | grep -q 'Status: enabled/running'
    # The operator must verify external connectivity as documented before confirmation.
    systemctl stop "$unit.timer"
    ! systemctl is-active --quiet "$unit.service"
    touch "$state/confirmed"
    echo "Confirmed $node. Original files retained in $state/original."
    ;;
rollback)
    [[ -f $state/prepared ]]
    restore
    systemctl stop "$unit.timer" || true
    ;;
*) echo 'Usage: manage.sh prepare|activate|confirm|rollback BATCH' >&2; exit 1 ;;
esac
