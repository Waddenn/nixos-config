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
      corepack # provides npm, yarn, pnpm
      rustc
      cargo
    ];

    # Enable Docker for agent container operations
    my-services.dev.docker.enable = true;

    # Ensure the main user can use docker
    users.users.nixos.extraGroups = ["docker"];
  };
}
