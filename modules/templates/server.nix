 { config, ... }:

{

  imports = [
    ../common/base.nix
    ../common/zramswap.nix
    ../services/tailscale.nix
  ];

}
