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
- Échec sur une cible joignable : le contrôleur n'est pas mis à jour ; corriger puis relancer.
- Cible secondaire injoignable : signalée et retentée chaque heure ; le contrôleur
  peut se mettre à jour si toutes les cibles joignables sont conformes.

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

## Permissions du dépôt du contrôleur

Le bootstrap root et le service nixos partagent les métadonnées Git. Le dépôt
existant a été configuré avec `core.sharedRepository=group`, groupe `users`,
écriture de groupe et bit setgid sur ses répertoires `.git`. Conserver ces droits
lors d'une restauration ou recréation du checkout afin que les fetch root ne
bloquent pas les fetch du service. Le contenu applicatif n'est pas concerné.

## Inventaire Beszel

Beszel suit automatiquement les `nixosConfigurations` dont l'agent est activé.
Les dossiers `hosts/_…` sont exclus par la découverte des hôtes ; une machine
simplement injoignable reste surveillée. Les machines hors NixOS sont déclarées
uniquement dans `modules/data/beszel-hosts.nix` (`externalHosts`).

Le fichier YAML est appliqué au démarrage du hub et son changement provoque un
redémarrage du seul service Beszel. Ne pas ajouter les machines NixOS dans l'UI :
le fichier fait autorité. Pour conserver l'historique lors d'un changement de nom
d'affichage, garder le nom existant dans `nameOverrides`. Beszel identifie une
entrée par le triplet nom/adresse/port ; changer ce triplet crée une nouvelle entrée.

Avant chaque changement de fichier, les bases SQLite et l'ancien YAML sont archivés
avec des droits privés dans `/home/nixos/beszel_data/inventory-backup-*`.
Les entrées retirées et leur historique ne sont plus disponibles dans l'UI ; les
archives permettent une récupération. Elles sont conservées sans purge automatique.
Pour une restauration complète, arrêter Beszel, sauvegarder l'état présent, restaurer
les deux bases et l'ancien YAML, puis utiliser la configuration Nix correspondante
avant redémarrage pour éviter de réappliquer immédiatement le nouvel inventaire.

## Déploiements ciblés

La CI évalue toujours l'inventaire et vérifie les scripts, le formatage et la parité
Colmena/NixOS. Elle construit uniquement les systèmes dont le chemin de sortie Nix
change depuis une révision ancêtre de `main` ayant une CI réussie. Un commit précédent
non validé ne sert jamais de référence. Les nouveaux hôtes sont construits ; les hôtes
retirés disparaissent de la matrice. Une modification documentaire peut ne lancer
aucune construction ; le job `validation` vérifie explicitement ce cas.

Un changement du lock, du flake, des points d'entrée partagés ou du mécanisme de CI
force les constructions complètes. L'absence de référence fiable ou l'impossibilité
de l'évaluer revient aussi au parcours complet. `ci-plan.json`, disponible en artefact
GitHub, indique la référence, les systèmes sélectionnés et leurs chemins attendus.

Le contrôleur garde sa garde CI sur le commit exact. Il sonde les générations actives
et préparées en parallèle (8 connexions maximum), vérifie la santé des systèmes déjà
conformes et construit seulement les systèmes en dérive. Les canaris modifiés sont
activés en premier ; les canaris inchangés doivent toujours être sains. Le contrôleur
n'est réactivé que si son propre système change, après les cibles joignables.

Une machine hors ligne reste signalée et retentée au cycle suivant ; elle ne déclenche
pas de construction inutile. Un rollback manuel est détecté par la génération réelle.
Le journal donne la durée du précontrôle et le nombre de systèmes à construire.
