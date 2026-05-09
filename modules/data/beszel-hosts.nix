{
  # Liste centralisée des hosts monitorés par Beszel
  # Ajouter ici chaque nouveau host avec beszel-agent
  hosts = {
    beszel = "beszel.salamander-scala.ts.net";
    caddy = "caddy.salamander-scala.ts.net";
    calibre = "calibre.salamander-scala.ts.net";
    nextcloud = "nextcloud-pgsql.salamander-scala.ts.net";
    nuc-pve-1 = "nuc-pve-1.salamander-scala.ts.net";
    plexade = "plexade.salamander-scala.ts.net";
    proxade = "proxade.salamander-scala.ts.net";
    tailscale-exit-node = "tailscale-exit-node.salamander-scala.ts.net";
    tailscale-subnet = "tailscale-subnet.salamander-scala.ts.net";
    paperless = "paperless.salamander-scala.ts.net";
    terraform = "terraform.salamander-scala.ts.net";
    immich = "immich.salamander-scala.ts.net";
    ia-controller = "ia-controller.salamander-scala.ts.net";
  };

  # Configuration commune pour tous les hosts
  port = 45876;
  beszelUsers = ["tom@patelas.com"];
}
