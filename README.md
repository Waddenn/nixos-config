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

