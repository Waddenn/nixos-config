# Migration, exploitation et reprise

## Première activation de cette révision

La configuration est préparée localement. Aucun déploiement, redémarrage, changement
Proxmox, publication Git ou rotation de webhook n'est réalisé par les tests.

1. Revoir les changements d'images : les digests initiaux correspondent aux registres
   lors de la préparation, pas nécessairement aux images actuellement en exécution.
2. Fusionner la révision et attendre la CI complète du commit de `main`.
3. Sur `dev-nixos`, arrêter temporairement le timer avant le bootstrap, puis attendre
   la fin d'une éventuelle exécution de `internal-gitops.service`.
4. Récupérer la révision et appeler l'agent du nouveau checkout avec son SHA complet :

```bash
sudo systemctl stop internal-gitops.timer
# Vérifier qu'aucune opération n'est encore active avant de continuer.
systemctl is-active internal-gitops.service
cd /home/nixos/nixos-config
git fetch origin main
revision=$(git rev-parse origin/main)
# Checkout de migration séparé pour préserver les modifications locales éventuelles.
git worktree add --detach /var/tmp/nixos-colmena-bootstrap "$revision"
sudo env REPO_DIR=/home/nixos/nixos-config \
  bash /var/tmp/nixos-colmena-bootstrap/scripts/pull-update-host.sh "$revision"
```

L'agent évalue la révision Git directement et préserve le checkout de travail.
Si le résultat est `reboot-required`, redémarrer le contrôleur dans une fenêtre de
maintenance et vérifier sa génération. Le timer peut être réactivé par l'activation
NixOS ; sa garde CI reste obligatoire.

```bash
sudo systemctl start internal-gitops.timer
sudo systemctl start internal-gitops.service
sudo journalctl -u internal-gitops.service -n 100 --no-pager
```

La première exécution migre les canaris, puis le reste des cibles. L'ancien agent
pull est retiré des cibles lors de cette activation. Conserver leurs anciens checkouts
jusqu'à validation, puis les retirer séparément s'ils ne servent plus.

## Accès et tests applicatifs

Le contrôleur utilise SSH root sur les noms de la flotte, comme le déploiement
précédent. OpenSSH refuse toujours le login root direct ; l'accès Tailscale SSH
et ses ACL doivent donc être fonctionnels. Préserver un accès console Proxmox
indépendant pendant la migration.

Les sondes de canaris testent Authelia directement et via le domaine public servi
par Caddy. Un code HTTP différent de 200, notamment une redirection, ne valide pas
la sonde. Chaque unité est vérifiée individuellement. Un test de connexion utilisateur
complet et la restauration de données restent des validations distinctes.

Le profil Tailscale annonce maintenant l'exit node de manière déclarative.
L'approbation dans Tailscale reste nécessaire. Les sous-réseaux existants ne sont
pas inventés : leurs annonces doivent être relevées sur le routeur puis déclarées
via `my-services.networking.tailscale.extraSetFlags`.

## Incident de déploiement

- `insufficient-space` : transfert bloqué ; vérifier les générations retenues, le store Nix et les volumes Docker.
- `unreachable` : vérifier DNS, Tailscale, ACL et accès console.
- `unhealthy-or-diverged` : vérifier services applicatifs et génération active.
- `reboot-required` : génération préparée, redémarrage à planifier.
- CI absente/en échec : corriger ou attendre la CI ; `reconcile` ne contourne pas cette garde.
- Déploiement partiel : le contrôleur n'est pas mis à jour ; corriger puis relancer.

Lire `last-run.json` et les journaux systemd. Pour une configuration sans migration
de données, la génération précédente peut servir à une reprise manuelle via console.
Pour un service ayant migré sa base, restaurer une sauvegarde cohérente avec la version
applicative plutôt que supposer qu'un rollback Nix rétablit les données.

## Périmètre Proxmox

La mise en place de nouvelles sauvegardes est reportée à la demande de l'utilisateur.
Cette refonte ne modifie pas les sauvegardes existantes et n'ajoute pas de dump Nextcloud.
La destination de sauvegarde n'est pas requise pour poursuivre cette refonte.

À valider avant de conclure à la haute disponibilité : quorum, stockage disponible
sur les nœuds de reprise, ressources HA déclarées et RAM disponible après perte d'un
nœud. Ne pas changer les privilèges LXC sans vérifier les UID/GID et les montages.
Le paramètre Nix `proxmoxLXC.privileged` adapte le système invité ; il ne convertit
pas le conteneur dans Proxmox.

## Secrets

Le webhook en clair de Gatus a été retiré du code. Gatus utilise le secret SOPS
`discord-webhook`, converti en environnement uniquement dans `/run`, accessible à root.
L'ancien webhook reste dans l'historique Git : le révoquer dans Discord et effectuer
la rotation du secret si nécessaire. Aucun secret n'a été déchiffré pour cette refonte.

## Sources techniques

- [Colmena : options et parallélisme](https://colmena.cli.rs/0.4/reference/cli.html)
- [Proxmox : conteneurs et sauvegardes des montages](https://pve.proxmox.com/pve-docs/chapter-pct.html)
- [Tailscale : exit nodes](https://tailscale.com/docs/features/exit-nodes)
