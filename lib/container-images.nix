# Source tags are resolved only by the scheduled updater, never at deployment time.
let
  locks = builtins.fromJSON (builtins.readFile ./container-images.json);
in
  builtins.mapAttrs (source: digest: "${source}@${digest}") locks
