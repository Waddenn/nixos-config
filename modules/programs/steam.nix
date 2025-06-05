{
  config,
  lib,
  pkgs,
  ...
}: {
  options.steam.enable = lib.mkEnableOption "Enable Steam + gamescope + Proton support";

  config = lib.mkIf config.steam.enable {
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "steam"
        "steam-original"
        "steam-unwrapped"
        "steam-run"
      ];

    programs.steam = {
      enable = true;

      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;

      gamescopeSession = {
        enable = true;
        args = [
          "-f"
          "-w"
          "2880"
          "-h"
          "1800"
          "--xwayland-count=1"
          "--xwayland"
        ];
        env = {
          GDK_BACKEND = "wayland";
          QT_QPA_PLATFORM = "wayland";
          SDL_VIDEODRIVER = "wayland";
          MOZ_ENABLE_WAYLAND = "1";
          WLR_NO_HARDWARE_CURSORS = "1";
          AMD_VULKAN_ICD = "RADV";
        };
      };

      protontricks = {
        enable = true;
        package = pkgs.protontricks;
      };
    };

    programs.gamescope = {
      enable = true;
      capSysNice = true;
    };

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    hardware.amdgpu.amdvlk = {
      enable = true;
      support32Bit.enable = true;
    };

    programs.appimage = {
      enable = true;
      binfmt = true;
    };

    hardware.steam-hardware.enable = true;
  };
}
