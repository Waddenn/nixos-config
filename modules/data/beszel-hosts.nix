{
  # NixOS systems come from nixosConfigurations with beszel-agent enabled.
  # Only machines managed outside this flake belong in this list.
  externalHosts = {
    nuc-pve-1 = "nuc-pve-1.salamander-scala.ts.net";
    plexade = "plexade.salamander-scala.ts.net";
    proxade = "proxade.salamander-scala.ts.net";
  };

  # Preserve existing Beszel identities and their history.
  nameOverrides.nextcloud-pgsql = "nextcloud";
  hostOverrides.valheim = "valheim-server.salamander-scala.ts.net";
  tailnet = "salamander-scala.ts.net";
  port = 45876;
  beszelUsers = ["tom@patelas.com"];
}
