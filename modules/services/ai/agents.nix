{
  config,
  lib,
  pkgs,
  ...
}: {
  options.my-services.ai.infra-agents.enable = lib.mkEnableOption "Enable infrastructure AI agents environment";

  config = lib.mkIf config.my-services.ai.infra-agents.enable {
    environment.systemPackages = with pkgs; [
      git
      colmena
      jq
      python3
      curl
      gh
      python3Packages.pip
      nodejs_22
      corepack 
      rustc
      cargo
    ];

    # Configuration pour permettre l'installation de packages npm non disponibles dans nixpkgs
    # (exemple: codex-cli, etc.)
    environment.variables = {
      NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    };
    
    # Ajouter le bin path de npm global au PATH
    environment.sessionVariables = {
      PATH = "$HOME/.npm-global/bin:$PATH";
    };

    # Enable Docker for agent container operations
    my-services.dev.docker.enable = true;

    # Ensure the main user can use docker
    users.users.nixos.extraGroups = ["docker"];
  };
}
