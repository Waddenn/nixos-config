{config, ...}: {
  users.users.docker = {
    isNormalUser = true;
    extraGroups = ["docker"];
  };
}
