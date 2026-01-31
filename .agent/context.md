# Contexte du Projet NixOS

Ce projet est une configuration NixOS modulaire gérée via Nix Flakes.
Il a pour but de déployer une infrastructure personnelle (Homelab) sur plusieurs machines (hôtes).

## Stack Technique
- **OS**: NixOS
- **Gestionnaire**: Nix Flakes
- **Secrets**: SOPS-Nix
- **CI**: GitHub Actions (Format & Check)
- **Déploiement**: `just switch` ou `colmena` (si configuré)

## Architecture Cible
L'architecture suit strictement le principe : **"Explicit Infra, Implicit Services"**.
- Les hôtes définissent leur infrastructure et activent les services.
- Les services sont des modules NixOS isolés et réutilisables.

## État Actuel
- Le projet est en cours de refonte architecturale.
- La CI est en place.
- Les workflows d'agent (`validate`, `add_service`) sont configurés.
