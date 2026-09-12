#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 7 ]]; then
  echo "usage: $0 SEED TARGET MARKER OWNER GROUP YQ VALIDATOR [ARG ...]" >&2
  exit 64
fi

seed=$1
target=$2
marker=$3
owner=$4
group=$5
yq=$6
shift 6
validator=("$@")

target_dir=${target%/*}
backup="${target}.pre-sops-migration"
temp=

cleanup() {
  [[ -z "$temp" ]] || rm -f -- "$temp"
}
trap cleanup EXIT

install -d -m 0700 -o "$owner" -g "$group" -- "$target_dir"

if [[ -L "$target" ]] || { [[ -e "$target" ]] && [[ ! -f "$target" ]]; }; then
  echo "refusing non-regular Authelia users database" >&2
  exit 1
fi
if [[ -L "$marker" ]] || { [[ -e "$marker" ]] && [[ ! -f "$marker" ]]; }; then
  echo "refusing non-regular Authelia migration marker" >&2
  exit 1
fi
if [[ -L "$backup" ]] || { [[ -e "$backup" ]] && [[ ! -f "$backup" ]]; }; then
  echo "refusing non-regular Authelia migration backup" >&2
  exit 1
fi

if [[ -e "$marker" ]]; then
  [[ -s "$target" ]] || {
    echo "Authelia users database is missing after completed migration" >&2
    exit 1
  }
  "$yq" eval -e '.users | type == "!!map" and length > 0' "$target" >/dev/null
  chown "$owner:$group" -- "$target"
  chmod 0600 -- "$target"
  "${validator[@]}"
  exit 0
fi

[[ -f "$seed" && -s "$seed" ]] || {
  echo "Authelia users seed is missing or empty" >&2
  exit 1
}
"$yq" eval -e '.users | type == "!!map" and length > 0' "$seed" >/dev/null

had_target=false
if [[ -e "$target" ]]; then
  [[ -s "$target" ]] || {
    echo "refusing empty existing Authelia users database" >&2
    exit 1
  }
  "$yq" eval -e '.users | type == "!!map" and length > 0' "$target" >/dev/null
  had_target=true
  if [[ ! -e "$backup" ]]; then
    install -m 0600 -o "$owner" -g "$group" -- "$target" "$backup"
  fi
fi

temp=$(mktemp "${target_dir}/.users_database.yml.XXXXXX")
if [[ "$had_target" == true ]]; then
  # The persistent database wins so user-changed hashes are never overwritten.
  "$yq" eval-all -o=yaml -I=2 \
    'select(fileIndex == 0) * select(fileIndex == 1)' \
    "$seed" "$target" >"$temp"
else
  "$yq" eval -o=yaml -I=2 '.' "$seed" >"$temp"
fi
"$yq" eval -e '.users | type == "!!map" and length > 0' "$temp" >/dev/null
chown "$owner:$group" -- "$temp"
chmod 0600 -- "$temp"
mv -T -- "$temp" "$target"
temp=

if ! "${validator[@]}"; then
  if [[ "$had_target" == true ]]; then
    install -m 0600 -o "$owner" -g "$group" -- "$backup" "$target"
  else
    rm -f -- "$target"
  fi
  echo "Authelia rejected the migrated users database; previous state restored" >&2
  exit 1
fi

install -m 0600 -o "$owner" -g "$group" /dev/null "$marker"
