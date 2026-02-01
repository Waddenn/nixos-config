{
  config,
  lib,
  ...
}: {
  options.profiles.lxc-base.enable = lib.mkEnableOption "Base LXC profile";

  config = lib.mkIf config.profiles.lxc-base.enable {
    my-services.infra.proxmox-lxc.enable = true;
  };

  imports = [../infra/proxmox-lxc-config.nix];
}
