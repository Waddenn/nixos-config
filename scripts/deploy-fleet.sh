#!/usr/bin/env bash
set -Eeuo pipefail

# Colors
G='\033[0;32m'
B='\033[0;34m'
Y='\033[1;33m'
R='\033[0;31m'
NC='\033[0m'
O='\033[0;33m'

# Config
REPO_DIR="${REPO_DIR:-/home/nixos/nixos-config}"
GIT_REMOTE="${GIT_REMOTE:-origin}"
GIT_BRANCH="${GIT_BRANCH:-main}"
LOCK_FILE="${LOCK_FILE:-/tmp/deploy-fleet.lock}"
LOCK_DIR="${LOCK_DIR:-/tmp/deploy-fleet.lockdir}"
MAX_FETCH_RETRIES="${MAX_FETCH_RETRIES:-3}"
SSH_CONNECT_TIMEOUT="${SSH_CONNECT_TIMEOUT:-8}"
HOST_UPDATE_TIMEOUT="${HOST_UPDATE_TIMEOUT:-1800}"
POLL_INTERVAL_SECONDS="${POLL_INTERVAL_SECONDS:-5}"
CACHIX_CACHE_NAME="${CACHIX_CACHE_NAME:-waddenn-nixos}"
CANARY_HOSTS="${CANARY_HOSTS:-authelia,caddy}"
SELF_UPDATE_NODE="${SELF_UPDATE_NODE:-dev-nixos}"
FORCE_UPDATE="${FORCE_UPDATE:-0}"
SSH_RETRY_ATTEMPTS="${SSH_RETRY_ATTEMPTS:-30}"
SSH_RETRY_SLEEP_SECONDS="${SSH_RETRY_SLEEP_SECONDS:-2}"

# Filled once per run, after we resolve the git rev we want to deploy.
FLEET_REV=""

log_info() { echo -e "${B}$*${NC}"; }
log_warn() { echo -e "${O}$*${NC}"; }
log_ok() { echo -e "${G}$*${NC}"; }
log_err() { echo -e "${R}$*${NC}"; }

is_truthy() {
  case "${1:-}" in
    1|true|TRUE|yes|YES|y|Y|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

ssh_retry() {
  local host="$1"; shift
  local attempt=1
  while (( attempt <= SSH_RETRY_ATTEMPTS )); do
    if ssh -o BatchMode=yes -o ConnectTimeout="$SSH_CONNECT_TIMEOUT" -o StrictHostKeyChecking=accept-new \
      "root@${host}" "$@"; then
      return 0
    fi
    attempt=$((attempt + 1))
    sleep "$SSH_RETRY_SLEEP_SECONDS"
  done
  return 1
}

require_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || {
    log_err "❌ Missing required command: $cmd"
    exit 1
  }
}

csv_to_lines() {
  printf '%s\n' "${1:-}" \
    | tr ',' '\n' \
    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
    | grep -v '^$' \
    | sort -u
}

lines_to_csv() {
  tr '\n' ',' | sed 's/,$//; s/,/, /g'
}

intersect_csv_lists() {
  local a="${1:-}" b="${2:-}"
  local a_lines b_lines
  a_lines="$(csv_to_lines "$a" || true)"
  b_lines="$(csv_to_lines "$b" || true)"
  if [[ -z "$a_lines" || -z "$b_lines" ]]; then
    return 0
  fi
  comm -12 <(printf '%s\n' "$a_lines") <(printf '%s\n' "$b_lines") | lines_to_csv
}

subtract_csv_lists() {
  local base="${1:-}" remove="${2:-}"
  local base_lines remove_lines
  base_lines="$(csv_to_lines "$base" || true)"
  remove_lines="$(csv_to_lines "$remove" || true)"
  if [[ -z "$base_lines" ]]; then
    return 0
  fi
  if [[ -z "$remove_lines" ]]; then
    printf '%s\n' "$base_lines" | lines_to_csv
    return 0
  fi
  comm -23 <(printf '%s\n' "$base_lines") <(printf '%s\n' "$remove_lines") | lines_to_csv
}

merge_csv_lists() {
  local a="${1:-}" b="${2:-}"
  printf '%s\n%s\n' "$a" "$b" \
    | tr ',' '\n' \
    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
    | grep -v '^$' \
    | sort -u \
    | lines_to_csv
}

csv_contains() {
  local list_csv="${1:-}" needle="${2:-}"
  csv_to_lines "$list_csv" | grep -Fxq "$needle"
}

acquire_lock() {
  if command -v flock >/dev/null 2>&1; then
    exec 9>"$LOCK_FILE"
    if ! flock -n 9; then
      log_warn "⚠️ Another deployment is already running. Exiting."
      exit 0
    fi
    return 0
  fi

  if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    log_warn "⚠️ Another deployment is already running (lockdir). Exiting."
    exit 0
  fi
  trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT
}

fetch_with_retry() {
  local attempt=1
  while (( attempt <= MAX_FETCH_RETRIES )); do
    if git fetch "$GIT_REMOTE" "$GIT_BRANCH" --prune >/dev/null 2>&1; then
      return 0
    fi
    log_warn "⚠️ git fetch failed (attempt $attempt/$MAX_FETCH_RETRIES)."
    attempt=$((attempt + 1))
    sleep 2
  done
  return 1
}

sync_repo_to_remote() {
  log_info "🔄 Syncing working tree with ${GIT_REMOTE}/${GIT_BRANCH}..."
  git checkout -q "$GIT_BRANCH"
  git reset --hard "${GIT_REMOTE}/${GIT_BRANCH}" >/dev/null
}

discover_pull_hosts() {
  nix eval --json --impure --expr '
let
  flake = builtins.getFlake (toString ./.);
  names = builtins.attrNames flake.nixosConfigurations;
  isPull = n:
    builtins.hasAttr "my-services" flake.nixosConfigurations.${n}.config
    && builtins.hasAttr "infra" flake.nixosConfigurations.${n}.config."my-services"
    && builtins.hasAttr "pull-updater" flake.nixosConfigurations.${n}.config."my-services".infra
    && flake.nixosConfigurations.${n}.config."my-services".infra."pull-updater".enable;
in
  builtins.filter isPull names
' | jq -r '.[]' | sort -u | lines_to_csv
}

build_expected_for_hosts() {
  local hosts_csv="$1"
  EXPECTED_PATHS=()
  BUILT_PATHS=()

  local host outpath
  while IFS= read -r host; do
    [[ -n "$host" ]] || continue
    # Use git+file to ignore untracked files (hosts may have junk/untracked in the checkout).
    # Pin to a single rev so expected outPaths are stable and comparable.
    outpath="$(nix build --no-link --print-out-paths "git+file://${REPO_DIR}?rev=${FLEET_REV}#nixosConfigurations.${host}.config.system.build.toplevel" | tail -n 1)"
    EXPECTED_PATHS+=("${host}=${outpath}")
    BUILT_PATHS+=("$outpath")
  done < <(csv_to_lines "$hosts_csv")
}

lookup_expected() {
  local host="$1"
  local kv
  for kv in "${EXPECTED_PATHS[@]:-}"; do
    if [[ "${kv%%=*}" == "$host" ]]; then
      printf '%s\n' "${kv#*=}"
      return 0
    fi
  done
  return 1
}

push_cache_paths() {
  if ! command -v cachix >/dev/null 2>&1; then
    log_warn "⚠️ cachix not found, skipping binary cache push."
    return 0
  fi

  if [[ -z "${CACHIX_AUTH_TOKEN:-}" ]]; then
    if [[ -n "${CACHIX_AUTH_TOKEN_FILE:-}" && -f "${CACHIX_AUTH_TOKEN_FILE}" ]]; then
      CACHIX_AUTH_TOKEN="$(cat "${CACHIX_AUTH_TOKEN_FILE}")"
      export CACHIX_AUTH_TOKEN
    fi
  fi
  if [[ -z "${CACHIX_AUTH_TOKEN:-}" && -f /run/secrets/cachix-auth-token ]]; then
    CACHIX_AUTH_TOKEN="$(cat /run/secrets/cachix-auth-token)"
    export CACHIX_AUTH_TOKEN
  fi

  if [[ -z "${CACHIX_AUTH_TOKEN:-}" ]]; then
    log_warn "⚠️ CACHIX_AUTH_TOKEN not set, skipping cache push."
    return 0
  fi

  if [[ ${#BUILT_PATHS[@]} -eq 0 ]]; then
    return 0
  fi

  log_info "📦 Pushing ${#BUILT_PATHS[@]} build outputs to Cachix (${CACHIX_CACHE_NAME})..."
  cachix push "$CACHIX_CACHE_NAME" "${BUILT_PATHS[@]}"
}

trigger_host_update() {
  local host="$1"
  local out rc
  set +e
  out="$(ssh -o BatchMode=yes -o ConnectTimeout="$SSH_CONNECT_TIMEOUT" -o StrictHostKeyChecking=accept-new \
    "root@${host}" "systemctl start internal-pull-update.service" 2>&1)"
  rc=$?
  set -e

  if [[ $rc -eq 0 ]]; then
    return 0
  fi

  if echo "$out" | grep -q "Unit internal-pull-update.service not found"; then
    log_warn "⚠️ ${host}: pull-updater unit missing, running bootstrap rebuild."
    ssh -o BatchMode=yes -o ConnectTimeout="$SSH_CONNECT_TIMEOUT" -o StrictHostKeyChecking=accept-new \
      "root@${host}" \
      "systemd-run --unit=internal-pull-bootstrap --description='Bootstrap Pull Updater' --working-directory='${REPO_DIR}' /run/current-system/sw/bin/bash -lc \"cd '${REPO_DIR}'; git config --system --add safe.directory '${REPO_DIR}' >/dev/null 2>&1 || true; git -c safe.directory='${REPO_DIR}' fetch '${GIT_REMOTE}' '${GIT_BRANCH}' --prune; git -c safe.directory='${REPO_DIR}' reset --hard '${GIT_REMOTE}/${GIT_BRANCH}'; rev=\\$(git -c safe.directory='${REPO_DIR}' rev-parse HEAD); nixos-rebuild switch --flake 'git+file://${REPO_DIR}?rev=\\${rev}#${host}'\" >/dev/null"
    BOOTSTRAP_LIST="$(merge_csv_lists "$BOOTSTRAP_LIST" "$host")"
    return 0
  fi

  printf '%s\n' "$out" >&2
  return "$rc"
}

wait_host_update_done() {
  local host="$1"
  local waited=0 state rc
  local unit_name="internal-pull-update.service"
  if csv_contains "${BOOTSTRAP_LIST:-}" "$host"; then
    unit_name="internal-pull-bootstrap.service"
  fi
  while (( waited < HOST_UPDATE_TIMEOUT )); do
    set +e
    state="$(ssh -o BatchMode=yes -o ConnectTimeout="$SSH_CONNECT_TIMEOUT" "root@${host}" "systemctl is-active ${unit_name} || true" 2>/dev/null)"
    rc=$?
    set -e
    # During switch, SSH may drop (tailscale/network restarts). Treat that as "still in progress".
    if [[ $rc -ne 0 ]]; then
      sleep "$POLL_INTERVAL_SECONDS"
      waited=$((waited + POLL_INTERVAL_SECONDS))
      continue
    fi
    if [[ "$state" != "active" && "$state" != "activating" ]]; then
      return 0
    fi
    sleep "$POLL_INTERVAL_SECONDS"
    waited=$((waited + POLL_INTERVAL_SECONDS))
  done
  return 1
}

collect_host_result() {
  local host="$1" expected="$2"

  if ! ssh_retry "$host" "echo ok" >/dev/null 2>&1; then
    UNREACHABLE_LIST="$(merge_csv_lists "$UNREACHABLE_LIST" "$host")"
    return 0
  fi

  local current result unit_name
  unit_name="internal-pull-update.service"
  if csv_contains "${BOOTSTRAP_LIST:-}" "$host"; then
    unit_name="internal-pull-bootstrap.service"
  fi
  current="$(ssh_retry "$host" "readlink -f /run/current-system" 2>/dev/null || true)"
  result="$(ssh_retry "$host" "systemctl show -p Result --value ${unit_name}" 2>/dev/null || true)"

  if [[ "$result" == "success" ]]; then
    UPDATED_LIST="$(merge_csv_lists "$UPDATED_LIST" "$host")"
    if [[ -n "$expected" && -n "$current" && "$current" == "$expected" ]]; then
      CONFIRMED_LIST="$(merge_csv_lists "$CONFIRMED_LIST" "$host")"
    elif [[ -n "$expected" && -n "$current" && "$current" != "$expected" ]]; then
      DIVERGED_LIST="$(merge_csv_lists "$DIVERGED_LIST" "$host")"
    fi
    return 0
  fi

  FAILED_LIST="$(merge_csv_lists "$FAILED_LIST" "$host")"
}

run_group() {
  local group_name="$1"
  local hosts_csv="$2"
  local started_hosts=""

  if [[ -z "$hosts_csv" ]]; then
    log_warn "⚠️ ${group_name}: no hosts selected."
    return 0
  fi

  log_info "\n🏗️  ${group_name}: building host systems..."
  build_expected_for_hosts "$hosts_csv"
  push_cache_paths

  local host
  while IFS= read -r host; do
    [[ -n "$host" ]] || continue
    log_info "▶ ${group_name}: triggering ${host}"
    if ! trigger_host_update "$host"; then
      UNREACHABLE_LIST="$(merge_csv_lists "$UNREACHABLE_LIST" "$host")"
      continue
    fi
    started_hosts="$(merge_csv_lists "$started_hosts" "$host")"
  done < <(csv_to_lines "$hosts_csv")

  while IFS= read -r host; do
    [[ -n "$host" ]] || continue
    if ! wait_host_update_done "$host"; then
      FAILED_LIST="$(merge_csv_lists "$FAILED_LIST" "$host")"
      continue
    fi
    collect_host_result "$host" "$(lookup_expected "$host" || true)"
  done < <(csv_to_lines "$started_hosts")
}

build_report() {
  local commit_hash commit_msg
  commit_hash="$(git rev-parse --short HEAD)"
  commit_msg="$(git log -1 --format=%s)"

  REPORT_BODY="**Commit:** \`${commit_hash}\` - ${commit_msg}
**Duration:** ${DURATION_STR}
**Canary:** ${CANARY_EFFECTIVE:-none}
**Batch:** ${BATCH_EFFECTIVE:-none}"

  if [[ -n "${CONFIRMED_LIST:-}" ]]; then
    REPORT_BODY+="

✅ **Confirmed (expected == current):** ${CONFIRMED_LIST}"
  fi

  if [[ -n "${DIVERGED_LIST:-}" ]]; then
    REPORT_BODY+="

⚠️ **Diverged (success but expected != current):** ${DIVERGED_LIST}"
  fi

  if [[ -n "$UPDATED_LIST" ]]; then
    REPORT_BODY+="

✅ **Updated:** ${UPDATED_LIST}"
  fi

  if [[ -n "$UNREACHABLE_LIST" ]]; then
    REPORT_BODY+="

📡 **Unreachable:** ${UNREACHABLE_LIST}"
  fi

  if [[ -n "$FAILED_LIST" ]]; then
    REPORT_BODY+="

❌ **Failed:** ${FAILED_LIST}"
  fi

  if [[ -n "$SKIPPED_LIST" ]]; then
    REPORT_BODY+="

⏭️ **Skipped:** ${SKIPPED_LIST}"
  fi

  if [[ -z "$FAILED_LIST" && -z "$UNREACHABLE_LIST" ]]; then
    TITLE="🚀 Fleet Deployment Success"
    COLOR=3066993
    log_ok "\n✅ FLEET SUCCESS: Nodes updated."
  else
    TITLE="⚠️ Fleet Partial Deployment"
    COLOR=15105570
    log_warn "\n⚠️  FLEET PARTIAL: Some nodes failed/unreachable."
  fi
}

send_discord_notification() {
  if [[ -z "${DISCORD_WEBHOOK:-}" ]]; then
    log_warn "⚠️  DISCORD_WEBHOOK not set, skipping notification."
    return 0
  fi

  require_cmd jq
  require_cmd curl

  log_info "📡 Sending Discord notification..."

  local webhook_url
  if [[ "$DISCORD_WEBHOOK" == discord://* ]]; then
    local id token
    id="$(printf '%s\n' "$DISCORD_WEBHOOK" | sed -E 's#discord://.*@(.*)#\1#' || true)"
    token="$(printf '%s\n' "$DISCORD_WEBHOOK" | sed -E 's#discord://(.*)@.*#\1#' || true)"
    webhook_url="https://discord.com/api/webhooks/${id}/${token}"
  else
    webhook_url="$DISCORD_WEBHOOK"
  fi

  local payload
  payload="$(jq -n \
    --arg title "$TITLE" \
    --arg desc "$REPORT_BODY" \
    --arg color "$COLOR" \
    '{
      embeds: [{
        title: $title,
        description: $desc,
        color: ($color | tonumber),
        timestamp: (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
      }]
    }')"

  curl -fsS -X POST -H 'Content-Type: application/json' -d "$payload" "$webhook_url" >/dev/null \
    || log_err "❌ Failed to send Discord notification"
}

trigger_self_update() {
  local current_host
  current_host="${HOSTNAME:-}"
  if [[ -z "$current_host" && -r /proc/sys/kernel/hostname ]]; then
    current_host="$(cat /proc/sys/kernel/hostname 2>/dev/null || true)"
  fi
  if [[ -z "$current_host" ]]; then
    current_host="$(uname -n 2>/dev/null || true)"
  fi
  current_host="${current_host%%.*}"

  if [[ "$current_host" != "$SELF_UPDATE_NODE" ]]; then
    return 0
  fi

  if ! systemctl list-unit-files internal-pull-update.service >/dev/null 2>&1; then
    log_warn "⚠️  Local self-update unit not installed on ${SELF_UPDATE_NODE}, skipping."
    return 0
  fi

  log_info "\n🏠 Triggering self-update for ${SELF_UPDATE_NODE}..."
  if ! sudo systemctl start internal-pull-update.service; then
    log_warn "⚠️  Failed to start local self-update service."
  fi
}

main() {
  require_cmd git
  require_cmd nix
  require_cmd jq
  require_cmd ssh

  cd "$REPO_DIR"
  acquire_lock

  echo -e "\n${B}╔════════════════════════════════════════════════════════╗${NC}"
  echo -e "${B}║     🚀 INTERNAL GITOPS: ORCHESTRATOR + CACHIX         ║${NC}"
  echo -e "${B}╚════════════════════════════════════════════════════════╝${NC}\n"

  echo -e "${Y}🔍 Checking for updates...${NC}"
  if ! fetch_with_retry; then
    log_err "❌ Unable to fetch ${GIT_REMOTE}/${GIT_BRANCH} after ${MAX_FETCH_RETRIES} attempts."
    exit 1
  fi

  local local_sha remote_sha
  local_sha="$(git rev-parse HEAD)"
  remote_sha="$(git rev-parse "${GIT_REMOTE}/${GIT_BRANCH}")"

  if [[ "$local_sha" == "$remote_sha" ]] && ! is_truthy "$FORCE_UPDATE"; then
    log_ok "😴 No changes found. System is up to date."
    exit 0
  fi

  if [[ "$local_sha" == "$remote_sha" ]]; then
    log_warn "⚠️ Force update enabled: proceeding even though local == remote."
  else
    log_ok "✨ New changes detected!"
  fi
  sync_repo_to_remote

  local start_time end_time duration
  start_time="$(date +%s)"

  UPDATED_LIST=""
  CONFIRMED_LIST=""
  DIVERGED_LIST=""
  FAILED_LIST=""
  UNREACHABLE_LIST=""
  SKIPPED_LIST=""
  BOOTSTRAP_LIST=""

  local all_targets
  all_targets="$(discover_pull_hosts)"
  if [[ -z "$all_targets" ]]; then
    log_warn "⚠️ No pull-updater targets found, nothing to orchestrate."
    exit 0
  fi

  CANARY_EFFECTIVE="$(intersect_csv_lists "$all_targets" "$CANARY_HOSTS")"
  BATCH_EFFECTIVE="$(subtract_csv_lists "$all_targets" "$CANARY_EFFECTIVE")"

  log_info "🎯 Pull targets: ${all_targets}"
  log_info "🧪 Canary: ${CANARY_EFFECTIVE:-none}"

  # We pin expected builds to a single revision (the one we're about to deploy).
  FLEET_REV="$remote_sha"

  run_group "CANARY" "$CANARY_EFFECTIVE"

  if [[ -n "$FAILED_LIST" || -n "$UNREACHABLE_LIST" ]]; then
    SKIPPED_LIST="$BATCH_EFFECTIVE"
    log_warn "⚠️ Canary failed/unreachable, skipping batch rollout."
  else
    log_info "📦 Canary passed, running batch rollout..."
    run_group "BATCH" "$BATCH_EFFECTIVE"
  fi

  end_time="$(date +%s)"
  duration=$((end_time - start_time))
  DURATION_STR="$((duration / 60))min $((duration % 60))s"

  build_report
  send_discord_notification
  trigger_self_update
}

main "$@"
