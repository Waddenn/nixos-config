{
  config,
  lib,
  pkgs,
  ...
}: let
  githubToken = "";
  githubRepo = "tom/nixos-config";
in {
  services.github-runners = {
    runner1 = {
      replace = true;
      token = githubToken;
      url = "https://github.com/${githubRepo}";
      extraLabels = ["nixos" "self-hosted"];
      workDir = "/var/lib/github-runner";
    };
  };
}
