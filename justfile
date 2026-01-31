# Build the system config and switch to it when running `just` with no args
default: switch

hostname := `hostname | cut -d "." -f 1`

### linux
# Build the NixOS configuration without switching to it
[linux]
build target_host=hostname flags="":
  sudo nixos-rebuild build --flake .#{{target_host}} {{flags}}

# Build the NixOS config with the --show-trace flag set
[linux]
trace target_host=hostname: (build target_host "--show-trace")

# Build the NixOS configuration and switch to it.
[linux]
switch target_host=hostname:
  sudo nixos-rebuild switch --flake .#{{target_host}}

## colmena
cbuild:
  colmena build

capply:
  colmena apply

# Update flake inputs to their latest revisions
update:
  nix flake update


# Garbage collect old OS generations and remove stale packages from the nix store
gc generations="5":
  nix-env --delete-generations {{generations}}
  nix-store --gc

supdate:
    sops updatekeys secrets/secrets.yaml

sgen:
    nix-shell -p ssh-to-age --run "ssh-to-age -i ~/.ssh/id_ed25519.pub"

# Usage: just senc <fichier>
# Exemple: just senc cf_api_token.env
senc file:
    sops --encrypt {{file}} > {{file}}.enc
