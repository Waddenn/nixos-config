{
  config,
  pkgs,
  ...
}: {
  users.users.wade = {
    isNormalUser = true;
    extraGroups = ["wheel" "video" "audio" "networkmanager"];
    shell = pkgs.fish;
    initialPassword = "password";
  };
  users.defaultUserShell = pkgs.fish;
}
