#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="${REPO_DIR:-/home/nixos/nixos-config}"
GIT_REMOTE="${GIT_REMOTE:-origin}"
GIT_BRANCH="${GIT_BRANCH:-main}"
STATE_DIR="${STATE_DIR:-/var/lib/internal-pull-update}"
STATE_FILE="${STATE_FILE:-${STATE_DIR}/state.env}"
LOCK_FILE="${LOCK_FILE:-/run/lock/internal-pull-update.lock}"
TARGET_REV="${1:-${TARGET_REV:-}}"

host="${HOSTNAME:-}"
if [[ -z "$host" && -r /proc/sys/kernel/hostname ]]; then
  host="$(cat /proc/sys/kernel/hostname 2>/dev/null || true)"
fi
if [[ -z "$host" ]]; then
  host="$(uname -n 2>/dev/null || true)"
fi
host="${host%%.*}"

if [[ -z "$host" ]]; then
  echo "[pull-update] unable to resolve hostname" >&2
  exit 1
fi

if [[ ! "$TARGET_REV" =~ ^[0-9a-f]{40}$ ]]; then
  echo "[pull-update] a full 40-character Git revision is required" >&2
  exit 2
fi

mkdir -p "$STATE_DIR"
mkdir -p "$(dirname "$LOCK_FILE")" 2>/dev/null || true

write_state() {
  local status="$1"
  local expected_system="${2:-}"
  local current_system="${3:-}"
  local tmp
  tmp="$(mktemp "${STATE_DIR}/state.env.XXXXXX")"
  {
    printf 'TARGET_REV=%s\n' "$TARGET_REV"
    printf 'STATUS=%s\n' "$status"
    printf 'EXPECTED_SYSTEM=%s\n' "$expected_system"
    printf 'CURRENT_SYSTEM=%s\n' "$current_system"
    printf 'UPDATED_AT=%s\n' "$(date --iso-8601=seconds)"
  } >"$tmp"
  chmod 0644 "$tmp"
  mv -f "$tmp" "$STATE_FILE"
}

read_state_value() {
  local key="$1"
  [[ -r "$STATE_FILE" ]] || return 0
  sed -n "s/^${key}=//p" "$STATE_FILE" | tail -n 1
}

if command -v flock >/dev/null 2>&1; then
  exec 9>"$LOCK_FILE"
  if ! flock -n 9; then
    echo "[pull-update] another update is already running; exiting."
    exit 0
  fi
else
  lockdir="${LOCK_FILE}.d"
  if ! mkdir "$lockdir" 2>/dev/null; then
    echo "[pull-update] another update is already running (lockdir); exiting."
    exit 0
  fi
  trap 'rmdir "$lockdir" 2>/dev/null || true' EXIT
fi

cd "$REPO_DIR"
start_ts="$(date +%s)"
echo "[pull-update] host=${host} target=${TARGET_REV} repo=${REPO_DIR}"

# The service runs as root while the checkout is owned by nixos.
git_safe=(git -c "safe.directory=${REPO_DIR}")
"${git_safe[@]}" fetch "$GIT_REMOTE" "$GIT_BRANCH" --prune

if ! "${git_safe[@]}" cat-file -e "${TARGET_REV}^{commit}" 2>/dev/null; then
  echo "[pull-update] target revision is not available after fetch: ${TARGET_REV}" >&2
  write_state "failed" "" "$(readlink -f /run/current-system 2>/dev/null || true)"
  exit 1
fi

if ! "${git_safe[@]}" merge-base --is-ancestor "$TARGET_REV" "${GIT_REMOTE}/${GIT_BRANCH}"; then
  echo "[pull-update] refusing revision outside ${GIT_REMOTE}/${GIT_BRANCH}: ${TARGET_REV}" >&2
  write_state "failed" "" "$(readlink -f /run/current-system 2>/dev/null || true)"
  exit 1
fi

current_system="$(readlink -f /run/current-system 2>/dev/null || true)"
profile_system="$(readlink -f /nix/var/nix/profiles/system 2>/dev/null || true)"
state_rev="$(read_state_value TARGET_REV)"
state_status="$(read_state_value STATUS)"

# A previous `boot` completed after the host was rebooted.
if [[ "$state_rev" == "$TARGET_REV" && "$state_status" == "reboot-required" &&
      -n "$current_system" && "$current_system" == "$profile_system" ]]; then
  write_state "active" "$profile_system" "$current_system"
  echo "[pull-update] active after reboot system=${current_system}"
  exit 0
fi

# Fast path for an already reconciled host.
if [[ "$state_rev" == "$TARGET_REV" && "$state_status" == "active" &&
      -n "$current_system" && "$current_system" == "$profile_system" ]]; then
  echo "[pull-update] already active system=${current_system}"
  exit 0
fi

"${git_safe[@]}" reset --hard "$TARGET_REV" >/dev/null

switch_log="$(mktemp -t internal-pull-update.XXXXXX)"
trap 'rm -f "$switch_log"' EXIT

set +e
nixos-rebuild switch --flake "git+file://${REPO_DIR}?rev=${TARGET_REV}#${host}" 2>&1 | tee "$switch_log"
switch_rc=${PIPESTATUS[0]}
set -e

if [[ $switch_rc -eq 0 ]]; then
  current_system="$(readlink -f /run/current-system 2>/dev/null || true)"
  profile_system="$(readlink -f /nix/var/nix/profiles/system 2>/dev/null || true)"
  write_state "active" "$profile_system" "$current_system"
  duration="$(( $(date +%s) - start_ts ))"
  echo "[pull-update] RESULT=active duration=${duration}s system=${current_system}"
  exit 0
fi

if grep -Eq "switchInhibitors|changes to critical components|nixos-rebuild boot" "$switch_log"; then
  echo "[pull-update] live activation inhibited; preparing the generation for next boot"
  if nixos-rebuild boot --flake "git+file://${REPO_DIR}?rev=${TARGET_REV}#${host}"; then
    current_system="$(readlink -f /run/current-system 2>/dev/null || true)"
    profile_system="$(readlink -f /nix/var/nix/profiles/system 2>/dev/null || true)"
    write_state "reboot-required" "$profile_system" "$current_system"
    echo "[pull-update] RESULT=reboot-required expected=${profile_system} current=${current_system}"
    exit 0
  fi
fi

current_system="$(readlink -f /run/current-system 2>/dev/null || true)"
profile_system="$(readlink -f /nix/var/nix/profiles/system 2>/dev/null || true)"
write_state "failed" "$profile_system" "$current_system"
echo "[pull-update] RESULT=failed" >&2
exit "$switch_rc"
