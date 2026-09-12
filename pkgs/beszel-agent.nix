{
  lib,
  stdenvNoCC,
  fetchurl,
}: let
  release = builtins.fromJSON (builtins.readFile ../lib/beszel-release.json);
in
  stdenvNoCC.mkDerivation {
    pname = "beszel-agent";
    inherit (release) version;
    src = fetchurl {
      url = "https://github.com/henrygd/beszel/releases/download/v${release.version}/beszel-agent_linux_amd64.tar.gz";
      hash = release.agentHash;
    };
    sourceRoot = ".";
    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;
    installPhase = ''
      runHook preInstall
      install -Dm755 beszel-agent "$out/bin/beszel-agent"
      runHook postInstall
    '';
    doInstallCheck = true;
    installCheckPhase = ''
      test "$("$out/bin/beszel-agent" --version)" = "beszel-agent ${release.version}"
    '';
    meta = {
      description = "Official Beszel agent matching the hub release";
      homepage = "https://beszel.dev";
      license = lib.licenses.mit;
      platforms = ["x86_64-linux"];
      mainProgram = "beszel-agent";
    };
  }
