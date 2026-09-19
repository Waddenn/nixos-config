#!/usr/bin/env bash
# Run inside `nix develop -c bash run.sh plan|apply` on dev-nixos only.
set -euo pipefail
umask 077
[[ $(hostname -s) == dev-nixos && $EUID == 0 ]] || { echo 'Run as root on dev-nixos' >&2; exit 1; }
case ${1:-} in plan|apply) mode=$1 ;; *) echo 'Usage: run.sh plan|apply' >&2; exit 2 ;; esac
src=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
state=/var/lib/proxmox-prototype
[[ -d $state && $(stat -c '%a:%u' "$state") == 700:0 ]] || { echo 'State directory must be root-owned mode 700' >&2; exit 1; }
exec 9>"$state/controller.lock"
flock -n 9 || { echo 'Another provisioning operation is running' >&2; exit 1; }
backup() {
  if [[ -f $state/terraform.tfstate ]]; then
    stamp=$(date -u +%Y%m%dT%H%M%S%N)
    cp -- "$state/terraform.tfstate" "$state/backups/$stamp.tfstate"
    # Independent physical node (nuc-pve-1); storage only, never a second controller.
    tar -C "$state" -czf - terraform.tfstate bootstrap.auto.tfvars.json \
      id_ed25519 id_ed25519.pub api-token pve-ca.pem |
      ssh -o BatchMode=yes -o ConnectTimeout=10 root@terraform \
        "umask 077; mkdir -p /root/proxmox-prototype-backups; chmod 700 /root/proxmox-prototype-backups; cat > /root/proxmox-prototype-backups/$stamp.tar.gz"
  fi
}
trap backup EXIT
backup
export PROXMOX_VE_API_TOKEN
PROXMOX_VE_API_TOKEN=$(cat "$state/api-token")
export SSL_CERT_FILE="$state/pve-ca.pem"
config=$(nix build "path:$src" --no-link --print-out-paths)
cp -- "$config" "$state/config.tf.json"
cp -- "$src/.terraform.lock.hcl" "$state/.terraform.lock.hcl"
cd "$state"
tofu init -input=false -lockfile=readonly
tofu validate
tofu plan -input=false -lock-timeout=30s -out=review.tfplan
tofu show -json review.tfplan | python3 "$src/check-plan.py"
if [[ $mode == apply ]]; then
  tofu apply -input=false -lock-timeout=30s review.tfplan
fi
