#!/usr/bin/env bash
# Build an SSH-ready NixOS image on the controller, then upload it using the API.
set -euo pipefail
umask 077
[[ $(hostname -s) == dev-nixos && $EUID == 0 ]] || exit 1
src=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
state=/var/lib/proxmox-prototype
[[ $(stat -c '%a:%u' "$state") == 700:0 ]] || exit 1
exec 9>"$state/controller.lock"
flock -n 9 || exit 1
if [[ ! -e $state/id_ed25519 ]]; then
  ssh-keygen -t ed25519 -N '' -C nixos-provisioning-prototype -f "$state/id_ed25519" >/dev/null
fi
# Only the public key is read during evaluation; no secret enters the Nix store.
export PROTOTYPE_SOURCE="$src"
image=$(nix build --impure --no-link --print-out-paths --expr '
  let src = builtins.getEnv "PROTOTYPE_SOURCE";
      f = builtins.getFlake src;
  in (f.inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ (src + "/bootstrap.nix") {
      users.users.root.openssh.authorizedKeys.keys = [
        (builtins.readFile /var/lib/proxmox-prototype/id_ed25519.pub)
      ];
    } ];
  }).config.system.build.tarball')
archives=("$image"/tarball/*.tar.xz)
[[ ${#archives[@]} == 1 && -f ${archives[0]} ]] || exit 1
archive=${archives[0]}
sha=$(sha256sum "$archive" | cut -d ' ' -f1)
filename="nixos-prototype-$sha.tar.xz"
printf 'Authorization: PVEAPIToken=%s\n' "$(cat "$state/api-token")" > "$state/upload-header"
trap 'rm -f "$state/upload-header"' EXIT
curl_args=(--fail --silent --show-error --cacert "$state/pve-ca.pem" -H "@$state/upload-header")
curl "${curl_args[@]}" 'https://proxade:8006/api2/json/nodes/proxade/storage/local/content?content=vztmpl' > "$state/templates.json"
if ! python3 - "$state/templates.json" "$filename" <<'PY'
import json,sys
entries=json.load(open(sys.argv[1]))['data']
sys.exit(0 if any(e['volid']=='local:vztmpl/'+sys.argv[2] for e in entries) else 1)
PY
then
  curl "${curl_args[@]}" -F content=vztmpl -F "filename=@$archive;filename=$filename" \
    https://proxade:8006/api2/json/nodes/proxade/storage/local/upload > "$state/upload-result.json"
  task=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["data"])' "$state/upload-result.json")
  result=running
  for ((attempt=0; attempt<60; attempt++)); do
    curl "${curl_args[@]}" "https://proxade:8006/api2/json/nodes/proxade/tasks/$task/status" > "$state/upload-status.json"
    result=$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1]))["data"]; print(d["status"]+":"+d.get("exitstatus", ""))' "$state/upload-status.json")
    [[ $result == stopped:OK ]] && break
    [[ $result != stopped:* ]] || { echo "Upload failed: $result" >&2; exit 1; }
    sleep 1
  done
  [[ $result == stopped:OK ]] || { echo 'Upload still running; inspect the PVE task before retrying' >&2; exit 1; }
fi
python3 - "$state" "$filename" <<'PY'
import json,pathlib,sys
p=pathlib.Path(sys.argv[1])
(p/'bootstrap.auto.tfvars.json').write_text(json.dumps({
    'ssh_public_key': (p/'id_ed25519.pub').read_text().strip(),
    'template_file_id': 'local:vztmpl/'+sys.argv[2],
}))
PY
printf '%s\n' "$image" > "$state/bootstrap-image"
printf '%s\n' "$filename"
