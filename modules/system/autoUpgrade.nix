{ config, pkgs, inputs, ... }:

{

  system.autoUpgrade = {
    enable = true;
    dates = "daily";
    flake = inputs.self.outPath;
    flags = [
      "--update-input"
      "nixpkgs"
      "-L" 
    ];
    persistent = true;
  };

}
