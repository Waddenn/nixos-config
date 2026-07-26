# ❄️ NixOS Configuration

![CI Status](https://github.com/Waddenn/nixos-config/actions/workflows/ci.yml/badge.svg)

Mon infrastructure personnelle ("Homelab") gérée avec **NixOS** et **Flakes**.

### Pré-requis
*   Nix avec les Flakes activés.
*   [Just](https://github.com/casey/just) (optionnel mais recommandé).

### Commandes usuelles

| Tâche | Commande | Description |
| :--- | :--- | :--- |
| **Appliquer** | `just switch` | Applique la configuration sur l'hôte actuel. |
| **Mettre à jour** | `just update` | Met à jour `flake.lock`. |
| **Formater** | `nix fmt` | Formate tout le code .nix (via Alejandra). |
| **Vérifier** | `nix flake check` | Vérifie la validité du flake. |

### Déploiements de la flotte

`dev-nixos` est l'unique autorité de déploiement. Les machines cibles ne
suivent pas `main` de manière autonome : l'orchestrateur leur demande
d'appliquer une révision Git complète et immuable.

Le flux reste volontairement simple :

1. La CI construit chaque configuration NixOS avant fusion.
2. `dev-nixos` construit la révision de `main` et pousse les résultats dans
   Cachix.
3. Les canaris sont activés et leur génération active est vérifiée.
4. Le batch ne démarre que si tous les canaris sont convergés.
5. Si NixOS interdit une activation à chaud, la génération est installée avec
   `nixos-rebuild boot` et l'hôte passe à l'état `reboot-required`. Aucun reboot
   n'est forcé automatiquement.
6. À chaque passage, même sans nouveau commit, l'orchestrateur réconcilie la
   flotte avec la révision désirée.

Commandes utiles :

| Commande | Description |
| :--- | :--- |
| `just deploy` | Lance l'orchestrateur normalement. |
| `just reconcile` | Force une réconciliation sans nouvelle révision. |
| `just fleet-status` | Compare Git, `/run/current-system` et le profil de boot de chaque cible. |

L'état local minimal de chaque cible se trouve dans
`/var/lib/internal-pull-update/state.env`. Le cache du contrôleur associant une
révision aux chemins Nix attendus se trouve dans
`/var/lib/internal-gitops/expected-systems.tsv`.

#### Première activation

Le passage depuis l'ancien système nécessite d'activer d'abord `dev-nixos`,
car l'orchestrateur actuellement installé ne connaît pas encore le service
template. Après fusion de la révision :

```bash
ssh root@dev-nixos
cd /home/nixos/nixos-config
git fetch origin main
git reset --hard origin/main
sudo ./scripts/pull-update-host.sh "$(git rev-parse HEAD)"
```

Si l'état retourné est `reboot-required`, redémarrer `dev-nixos`, vérifier
`/run/current-system`, puis lancer `internal-gitops.service`. Les canaris et le
batch seront ensuite migrés par le nouveau contrôleur.
