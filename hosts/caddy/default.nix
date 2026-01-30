{ lib, ... }: {
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.age.sshKeyPaths = ["/home/nixos/.ssh/id_ed25519"];
  caddy.enable = true;
  gitAutoPull.enable = lib.mkForce false;
}
