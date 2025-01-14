{ config, pkgs, ... }:

{

services.minecraft-server = {
  enable = true;
  eula = false; 
  declarative = true;

  # see here for more info: https://minecraft.gamepedia.com/Server.properties#server.properties
  serverProperties = {
    server-port = 25565;
    gamemode = "survival";
    motd = "NixOS Minecraft server on Tailscale!";
    max-players = 5;
    enable-rcon = true;

    "rcon.password" = "hunter2";
    level-seed = "10292992";
  };
};

nixpkgs.config.allowUnfree = true;


}

