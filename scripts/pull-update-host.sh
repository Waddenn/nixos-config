#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="${REPO_DIR:-/home/nixos/nixos-config}"
GIT_REMOTE="${GIT_REMOTE:-origin}"
GIT_BRANCH="${GIT_BRANCH:-main}"
LOCK_FILE="${LOCK_FILE:-/run/lock/internal-pull-update.lock}"

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

mkdir -p "$(dirname "$LOCK_FILE")" 2>/dev/null || true
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
echo "[pull-update] host=${host} repo=${REPO_DIR} remote=${GIT_REMOTE}/${GIT_BRANCH}"

# Service runs as root while repo is owned by nixos user.
git config --system --add safe.directory "$REPO_DIR" >/dev/null 2>&1 || true
git_safe=(git -c "safe.directory=${REPO_DIR}")

"${git_safe[@]}" fetch "$GIT_REMOTE" "$GIT_BRANCH" --prune
old_head="$("${git_safe[@]}" rev-parse --short HEAD || true)"
"${git_safe[@]}" reset --hard "${GIT_REMOTE}/${GIT_BRANCH}" >/dev/null
new_rev="$("${git_safe[@]}" rev-parse HEAD)"
new_head="${new_rev:0:7}"

echo "[pull-update] git ${old_head:-unknown} -> ${new_head}"
nixos-rebuild switch --flake "git+file://${REPO_DIR}?rev=${new_rev}#${host}"

current_system="$(readlink -f /run/current-system 2>/dev/null || true)"
duration="$(( $(date +%s) - start_ts ))"
echo "[pull-update] success host=${host} duration=${duration}s system=${current_system}"
