#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
GIT_REMOTE="${GIT_REMOTE:-origin}"
GIT_BRANCH="${GIT_BRANCH:-main}"
SSH_CONNECT_TIMEOUT="${SSH_CONNECT_TIMEOUT:-5}"
SSH_CONFIG_FILE="${SSH_CONFIG_FILE:-/dev/null}"

if ! command -v nix >/dev/null 2>&1 && command -v distrobox >/dev/null 2>&1; then
  exec distrobox enter nix-deploy -- \
    bash -lc "cd $(printf '%q' "$REPO_DIR") && ./scripts/fleet-status.sh"
fi

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

require_cmd git
require_cmd nix
require_cmd ssh

cd "$REPO_DIR"
desired_rev="$(git rev-parse "${GIT_REMOTE}/${GIT_BRANCH}")"

mapfile -t hosts < <(
  # shellcheck disable=SC2016
  nix --extra-experimental-features "nix-command flakes" eval --raw --impure --expr '
let
  flake = builtins.getFlake (toString ./.);
  names = builtins.attrNames flake.nixosConfigurations;
  isTarget = n:
    builtins.hasAttr "my-services" flake.nixosConfigurations.${n}.config
    && builtins.hasAttr "infra" flake.nixosConfigurations.${n}.config."my-services"
    && builtins.hasAttr "deployment-target" flake.nixosConfigurations.${n}.config."my-services".infra
    && flake.nixosConfigurations.${n}.config."my-services".infra."deployment-target".enable;
in
  builtins.concatStringsSep "\n" (builtins.filter isTarget names)
' | sort -u
)

printf '%-24s %-17s %-8s %-8s %-8s %s\n' "HOST" "STATUS" "GIT" "SYSTEM" "AGENT" "DETAIL"

for host in "${hosts[@]}"; do
  set +e
  data="$(
    ssh -o BatchMode=yes -o ConnectTimeout="$SSH_CONNECT_TIMEOUT" -o StrictHostKeyChecking=accept-new \
      -F "$SSH_CONFIG_FILE" \
      "root@${host}" 'printf "CURRENT="; readlink -f /run/current-system 2>/dev/null; printf "PROFILE="; readlink -f /nix/var/nix/profiles/system 2>/dev/null; printf "REPO_REV="; git -c safe.directory=/home/nixos/nixos-config -C /home/nixos/nixos-config rev-parse HEAD 2>/dev/null; printf "STATE_STATUS="; sed -n "s/^STATUS=//p" /var/lib/internal-pull-update/state.env 2>/dev/null | tail -n 1; printf "STATE_REV="; sed -n "s/^TARGET_REV=//p" /var/lib/internal-pull-update/state.env 2>/dev/null | tail -n 1; printf "STATE_EXPECTED="; sed -n "s/^EXPECTED_SYSTEM=//p" /var/lib/internal-pull-update/state.env 2>/dev/null | tail -n 1' 2>/dev/null
  )"
  rc=$?
  set -e

  if [[ $rc -ne 0 ]]; then
    printf '%-24s %-17s %-8s %-8s %-8s %s\n' "$host" "unreachable" "-" "-" "-" "SSH failed"
    continue
  fi

  current="$(sed -n 's/^CURRENT=//p' <<<"$data" | tail -n 1)"
  profile="$(sed -n 's/^PROFILE=//p' <<<"$data" | tail -n 1)"
  repo_rev="$(sed -n 's/^REPO_REV=//p' <<<"$data" | tail -n 1)"
  state_status="$(sed -n 's/^STATE_STATUS=//p' <<<"$data" | tail -n 1)"
  state_rev="$(sed -n 's/^STATE_REV=//p' <<<"$data" | tail -n 1)"
  state_expected="$(sed -n 's/^STATE_EXPECTED=//p' <<<"$data" | tail -n 1)"
  git_state="drift"
  system_state="drift"
  agent_state="drift"
  [[ "$repo_rev" == "$desired_rev" ]] && git_state="ok"
  [[ -n "$current" && "$current" == "$profile" ]] && system_state="ok"
  if [[ "$state_status" == "active" && "$state_rev" == "$desired_rev" &&
        -n "$state_expected" && "$current" == "$state_expected" ]]; then
    agent_state="ok"
  fi

  status="drift"
  detail="active/profile mismatch"
  if [[ "$state_status" == "reboot-required" && "$state_rev" == "$desired_rev" ]]; then
    status="reboot-required"
    detail="generation prepared"
  elif [[ "$git_state" == "ok" && "$system_state" == "ok" && "$agent_state" == "ok" ]]; then
    status="converged"
    detail="${current##*/}"
  elif [[ "$git_state" != "ok" ]]; then
    detail="repository revision differs"
  elif [[ "$state_rev" != "$desired_rev" ]]; then
    detail="agent revision differs"
  elif [[ "$state_status" != "active" ]]; then
    detail="agent status: ${state_status:-missing}"
  elif [[ -z "$state_expected" ]]; then
    detail="agent expected system missing"
  elif [[ "$current" != "$state_expected" ]]; then
    detail="active system differs from expected"
  fi

  printf '%-24s %-17s %-8s %-8s %-8s %s\n' "$host" "$status" "$git_state" "$system_state" "$agent_state" "$detail"
done
