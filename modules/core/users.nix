{
  pkgs,
  lib,
  username,
  ...
}: {
  programs.fish.enable = true;
  users = {
    defaultUserShell = pkgs.fish;
    users.${username} = {
      isNormalUser = true;
      description = lib.mkDefault "${username} account";
      extraGroups = ["networkmanager" "wheel"];
    };
  };
}
