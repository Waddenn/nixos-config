#!/usr/bin/env bash
set -Eeuo pipefail

# Colors & Emojis
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
COLMENA_BIN="${COLMENA_BIN:-colmena}"
LOCK_FILE="${LOCK_FILE:-/tmp/deploy-fleet.lock}"
LOCK_DIR="${LOCK_DIR:-/tmp/deploy-fleet.lockdir}"
MAX_FETCH_RETRIES="${MAX_FETCH_RETRIES:-3}"
SELF_UPDATE_NODE="${SELF_UPDATE_NODE:-dev-nixos}"
RETRY_FAILED_ONCE="${RETRY_FAILED_ONCE:-1}"
RETRY_DELAY_SECONDS="${RETRY_DELAY_SECONDS:-8}"

log_info() { echo -e "${B}$*${NC}"; }
log_warn() { echo -e "${O}$*${NC}"; }
log_ok() { echo -e "${G}$*${NC}"; }
log_err() { echo -e "${R}$*${NC}"; }

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

merge_csv_lists() {
  local a="${1:-}" b="${2:-}"
  printf '%s\n%s\n' "$a" "$b" \
    | tr ',' '\n' \
    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
    | grep -v '^$' \
    | sort -u \
    | lines_to_csv
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

LOGFILE=""
cleanup() {
  if [[ -n "$LOGFILE" && -f "$LOGFILE" ]]; then
    rm -f "$LOGFILE"
  fi
}
trap cleanup EXIT

require_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || {
    log_err "❌ Missing required command: $cmd"
    exit 1
  }
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

  # Fallback when flock is unavailable in the unit PATH.
  if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    log_warn "⚠️ Another deployment is already running (lockdir). Exiting."
    exit 0
  fi
  trap 'rmdir "$LOCK_DIR" 2>/dev/null || true; cleanup' EXIT
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

get_repo_slug() {
  local remote_url slug
  remote_url="$(git config --get "remote.${GIT_REMOTE}.url" || true)"

  case "$remote_url" in
    git@github.com:*)
      slug="${remote_url#git@github.com:}"
      ;;
    https://github.com/*)
      slug="${remote_url#https://github.com/}"
      ;;
    http://github.com/*)
      slug="${remote_url#http://github.com/}"
      ;;
    *)
      return 1
      ;;
  esac

  slug="${slug%.git}"
  [[ "$slug" == */* ]] || return 1
  printf '%s\n' "$slug"
}

verify_ci_status() {
  local commit_sha="$1"

  if ! command -v gh >/dev/null 2>&1 || [[ -z "${GH_TOKEN:-}" ]]; then
    log_warn "⚠️  Skipping CI check (gh missing or GH_TOKEN unset)."
    return 0
  fi

  local repo_slug
  if ! repo_slug="$(get_repo_slug)"; then
    log_warn "⚠️  Could not resolve GitHub repo slug from git remote, skipping CI check."
    return 0
  fi

  log_info "📡 Verifying CI status for ${repo_slug}@${commit_sha:0:7}..."

  local checks has_failure has_pending
  checks="$(gh api "repos/${repo_slug}/commits/${commit_sha}/check-runs" --jq '.check_runs[]? | [.name, (.status // "unknown"), (.conclusion // "none")] | @tsv' 2>/dev/null || true)"

  if [[ -z "$checks" ]]; then
    log_warn "⚠️  No check-runs found for this commit. Proceeding."
    return 0
  fi

  has_failure="$(printf '%s\n' "$checks" | awk -F '\t' '$3 == "failure" || $3 == "cancelled" || $3 == "timed_out" || $3 == "action_required" {print "yes"; exit}')"
  has_pending="$(printf '%s\n' "$checks" | awk -F '\t' '$2 != "completed" {print "yes"; exit}')"

  if [[ "$has_failure" == "yes" ]]; then
    log_err "🛑 CI check failed for ${commit_sha:0:7}. Aborting deployment."
    return 1
  fi

  if [[ "$has_pending" == "yes" ]]; then
    log_warn "⚠️  Some CI checks are still pending for ${commit_sha:0:7}. Proceeding anyway."
  else
    log_ok "✅ CI checks are green."
  fi

  return 0
}

sync_repo_to_remote() {
  log_info "🔄 Syncing working tree with ${GIT_REMOTE}/${GIT_BRANCH}..."
  git checkout -q "$GIT_BRANCH"
  git reset --hard "${GIT_REMOTE}/${GIT_BRANCH}" >/dev/null
}

parse_hosts() {
  local clean_log="$1"

  SUCCEEDED_LIST="$(printf '%s\n' "$clean_log" \
    | grep '| Activation successful' \
    | awk -F '|' '{gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1}' \
    | sort -u \
    | tr '\n' ',' \
    | sed 's/,$//; s/,/, /g' \
    || true)"

  local push_failures act_failures
  push_failures="$(printf '%s\n' "$clean_log" \
    | grep 'Failed to push system closure to' \
    | awk '{gsub(/^[ \t]+|[ \t]+$/, "", $NF); print $NF}' \
    || true)"

  act_failures="$(printf '%s\n' "$clean_log" \
    | grep 'Activation failed' -B 1 \
    | grep ' | ' \
    | awk -F '|' '{gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1}' \
    || true)"

  PUSH_FAILED_LIST="$(printf '%s\n' "$push_failures" \
    | grep -v '^$' \
    | sort -u \
    | lines_to_csv \
    || true)"

  ACT_FAILED_LIST="$(printf '%s\n' "$act_failures" \
    | grep -v '^$' \
    | sort -u \
    | lines_to_csv \
    || true)"

  FAILED_LIST="$(printf '%s\n%s\n' "$push_failures" "$act_failures" \
    | grep -v '^$' \
    | sort -u \
    | tr '\n' ',' \
    | sed 's/,$//; s/,/, /g' \
    || true)"
}

run_fleet_deploy() {
  local start_time end_time duration

  start_time="$(date +%s)"
  log_info "🏗️  Starting fleet deployment..."
  log_info "----------------------------------------------------------"

  LOGFILE="$(mktemp)"

  set +e
  "$COLMENA_BIN" apply --color always --parallel 2 --keep-result --on @remote 2>&1 | tee "$LOGFILE"
  FLEET_EXIT=${PIPESTATUS[0]}
  set -e

  local clean_log
  clean_log="$(sed 's/\x1b\[[0-9;]*m//g' "$LOGFILE" || true)"
  parse_hosts "$clean_log"

  local first_exit first_succeeded first_failed first_act_failed
  first_exit=$FLEET_EXIT
  first_succeeded="${SUCCEEDED_LIST:-}"
  first_failed="${FAILED_LIST:-}"
  first_act_failed="${ACT_FAILED_LIST:-}"
  RECOVERED_LIST=""

  # Retry once for transient SSH drops during switch (service/network restarts).
  # We only retry activation failures, not push/connectivity failures.
  if [[ "${RETRY_FAILED_ONCE}" == "1" && $first_exit -ne 0 && -n "$first_act_failed" ]]; then
    local retry_nodes retry_log retry_clean retry_exit retry_succeeded retry_failed recovered
    retry_nodes="$(printf '%s\n' "$first_act_failed" | tr -d ' ')"

    log_warn "⚠️  Retrying activation-failed hosts once (possible transient SSH disconnects): $first_act_failed"
    sleep "$RETRY_DELAY_SECONDS"

    retry_log="$(mktemp)"
    set +e
    "$COLMENA_BIN" apply --color always --parallel 1 --keep-result --on "$retry_nodes" 2>&1 | tee "$retry_log"
    retry_exit=${PIPESTATUS[0]}
    set -e

    retry_clean="$(sed 's/\x1b\[[0-9;]*m//g' "$retry_log" || true)"
    parse_hosts "$retry_clean"
    retry_succeeded="${SUCCEEDED_LIST:-}"
    retry_failed="${FAILED_LIST:-}"
    rm -f "$retry_log"

    # Merge initial and retry successes.
    SUCCEEDED_LIST="$(merge_csv_lists "$first_succeeded" "$retry_succeeded")"
    FAILED_LIST="$first_failed"

    if [[ $retry_exit -eq 0 ]]; then
      # Retry fully recovered all previously failed nodes.
      SUCCEEDED_LIST="$(merge_csv_lists "$SUCCEEDED_LIST" "$first_act_failed")"
      RECOVERED_LIST="$first_act_failed"
      FAILED_LIST="$(subtract_csv_lists "$FAILED_LIST" "$first_act_failed")"
      if [[ -z "${FAILED_LIST:-}" ]]; then
        FLEET_EXIT=0
      else
        FLEET_EXIT=1
      fi
    else
      if [[ -n "$retry_failed" ]]; then
        recovered="$(subtract_csv_lists "$first_act_failed" "$retry_failed")"
        RECOVERED_LIST="$recovered"
        SUCCEEDED_LIST="$(merge_csv_lists "$SUCCEEDED_LIST" "$recovered")"
        FAILED_LIST="$(subtract_csv_lists "$FAILED_LIST" "$recovered")"
      else
        FAILED_LIST="$first_failed"
      fi
      FLEET_EXIT=$retry_exit
    fi
  fi

  if [[ $FLEET_EXIT -ne 0 && -z "${FAILED_LIST:-}" ]]; then
    FAILED_LIST="Unknown/General Failure (check logs)"
  fi

  end_time="$(date +%s)"
  duration=$((end_time - start_time))
  DURATION_STR="$((duration / 60))min $((duration % 60))s"
}

build_report() {
  local commit_hash commit_msg
  commit_hash="$(git rev-parse --short HEAD)"
  commit_msg="$(git log -1 --format=%s)"

  REPORT_BODY="**Commit:** \`${commit_hash}\` - ${commit_msg}
**Duration:** ${DURATION_STR}"

  if [[ -n "${SUCCEEDED_LIST:-}" ]]; then
    REPORT_BODY+="

✅ **Updated:** ${SUCCEEDED_LIST}"
  fi

  if [[ -n "${FAILED_LIST:-}" ]]; then
    REPORT_BODY+="

❌ **Failed:** ${FAILED_LIST}"
  fi

  if [[ -n "${RECOVERED_LIST:-}" ]]; then
    REPORT_BODY+="

↻ **Recovered after retry:** ${RECOVERED_LIST}"
  fi

  if [[ $FLEET_EXIT -eq 0 ]]; then
    TITLE="🚀 Fleet Deployment Success"
    COLOR=3066993
    log_ok "\n✅ FLEET SUCCESS: Nodes updated."
  else
    TITLE="⚠️ Fleet Partial Deployment"
    COLOR=15105570
    log_warn "\n⚠️  FLEET PARTIAL: Some nodes failed."
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

  if [[ -z "$current_host" ]]; then
    log_warn "\n🏠 Unable to determine current hostname, skipping self-update."
    return 0
  fi

  if [[ "$current_host" != "$SELF_UPDATE_NODE" ]]; then
    log_info "\n🏠 Skipping self-update on ${current_host} (target: ${SELF_UPDATE_NODE})."
    return 0
  fi

  log_info "\n🏠 Triggering self-update for ${SELF_UPDATE_NODE}..."

  local unit_name
  unit_name="${SELF_UPDATE_NODE}-self-update-$(date +%s)"

  if ! sudo systemd-run \
    --unit="$unit_name" \
    --description='GitOps Self-Update' \
    --working-directory="$REPO_DIR" \
    --property='Type=oneshot' \
    --property='RemainAfterExit=no' \
    /run/current-system/sw/bin/bash -lc "export PATH=/run/current-system/sw/bin:\$PATH; ${COLMENA_BIN} apply-local --color always --node ${SELF_UPDATE_NODE}" \
    >/dev/null; then
    log_warn "⚠️  Failed to schedule self-update unit ${unit_name}."
  fi
}

main() {
  require_cmd git
  require_cmd "$COLMENA_BIN"

  cd "$REPO_DIR"
  acquire_lock

  echo -e "\n${B}╔════════════════════════════════════════════════════════╗${NC}"
  echo -e "${B}║           🚀 INTERNAL GITOPS: AUTO-DEPLOYER            ║${NC}"
  echo -e "${B}╚════════════════════════════════════════════════════════╝${NC}\n"

  echo -e "${Y}🔍 Checking for updates...${NC}"

  if ! fetch_with_retry; then
    log_err "❌ Unable to fetch ${GIT_REMOTE}/${GIT_BRANCH} after ${MAX_FETCH_RETRIES} attempts."
    exit 1
  fi

  LOCAL="$(git rev-parse HEAD)"
  REMOTE="$(git rev-parse "${GIT_REMOTE}/${GIT_BRANCH}")"

  if [[ "$LOCAL" == "$REMOTE" ]]; then
    log_ok "😴 No changes found. System is up to date."
    return 0
  fi

  log_ok "✨ New changes detected!"

  verify_ci_status "$REMOTE" || exit 0
  sync_repo_to_remote
  run_fleet_deploy
  build_report
  send_discord_notification

  # Trigger self-update only on SELF_UPDATE_NODE host
  trigger_self_update

  return 0
}

main "$@"
