# Initial guest configuration, deliberately independent of the production modules.
{modulesPath, ...}: {
  imports = [(modulesPath + "/virtualisation/proxmox-lxc.nix")];
  proxmoxLXC = {
    manageNetwork = false;
    privileged = false;
  };
  networking.hostName = "nixos-provisioning-prototype";
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };
  nix.settings = {
    sandbox = false;
    experimental-features = ["nix-command" "flakes"];
  };
  system.stateVersion = "25.05";
}
