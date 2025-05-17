{
  config,
  pkgs,
  ...
}: let
  username = config.var.username;
in {
  programs.phish.enable = true;
  users = {
    defaultUserShell = pkgs.fish;
    users.${username} = {
      isNormalUser = true;
      description = "${username} account";
      extraGroups = ["networkmanager" "wheel"];
    };
  };
}
