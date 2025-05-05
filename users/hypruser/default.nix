{
  config,
  pkgs,
  ...
}: {
  users.users.hypruser = {
    isNormalUser = true;
    extraGroups = ["wheel" "video" "audio" "networkmanager"];
    shell = pkgs.zsh;
    initialPassword = "password";
  };
}
