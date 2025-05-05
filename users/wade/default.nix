{
  config,
  pkgs,
  ...
}: {
  users.users.wade = {
    isNormalUser = true;
    extraGroups = ["wheel" "video" "audio" "networkmanager"];
    shell = pkgs.zsh;
    initialPassword = "password";
  };
}
