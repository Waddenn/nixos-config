{
  config,
  lib,
  pkgs,
  ...
}: {
  users.users.tom = {
    isNormalUser = true;
    description = "tom";
    extraGroups = ["networkmanager" "wheel" "lp" "scanner" "docker"];
    initialPassword = "password";
    shell = pkgs.fish;
  };

  users.defaultUserShell = pkgs.fish;
}
