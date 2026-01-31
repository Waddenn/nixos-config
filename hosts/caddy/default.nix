{ lib, ... }: {
  imports = [ ../../modules/infra/proxmox-lxc.nix ];
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.age.sshKeyPaths = ["/home/nixos/.ssh/id_ed25519"];
  caddy.enable = true;
}
