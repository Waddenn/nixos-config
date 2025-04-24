{
  config,
  lib,
  pkgs,
  ...
}: let
  githubToken = "";
  githubRepo = "tom/nixos-config";
in {
  services.github-runner = {
    enable = true;
    name = "runner1";
    token = githubToken;
    url = "https://github.com/${githubRepo}";
    extraLabels = ["nixos" "self-hosted"];
    workDir = "/var/lib/github-runner";
  };
}
