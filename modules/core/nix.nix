{
  inputs,
  config,
  ...
}: {
  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = false;
  };
  nix = {
    nixPath = ["nixpkgs=${inputs.nixpkgs}"];
    channel.enable = false;
    extraOptions = ''
      warn-dirty = false
    '';
    settings = {
      auto-optimise-store = true;
      # Automatic GC collects only unreferenced paths; retained generations stay protected.
      min-free =
        if config.my-services.infra.deployer-node.enable
        then 5368709120
        else 1073741824;
      max-free =
        if config.my-services.infra.deployer-node.enable
        then 8589934592
        else 3221225472;
      experimental-features = ["nix-command" "flakes"];
      substituters = [
        # high priority since it's almost always used
        "https://cache.nixos.org?priority=10"

        "https://hyprland.cachix.org"
        "https://nix-community.cachix.org"
        "https://numtide.cachix.org"
        "https://waddenn-nixos.cachix.org"
      ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
        "waddenn-nixos.cachix.org-1:jNMQSkhK3tnymEL3tlStOaFvRcEkqdOxtZ8y5hF6ftU="
      ];
    };
    gc = {
      automatic = true;
      persistent = true;
      dates = "daily";
      options = "--delete-older-than 14d";
    };
    optimise = {
      automatic = true;
      dates = ["03:15"]; # Daily at 3:15 AM
    };
  };
}
