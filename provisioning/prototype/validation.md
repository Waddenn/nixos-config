# Validation du 19 septembre 2026

## Observé sur le jetable

- Terranix 2.9.0, OpenTofu 1.12.6, bpg/proxmox 0.113.1 ; `init` signé puis
  `init -lockfile=readonly` et `validate` réussis.
- Création finale depuis un state sans ressource et un CT 9901 absent :
  **1 ajouté, 0 modifié, 0 détruit**, avec compte `nixos-prototype@pve`, nesting
  dès création et image construite depuis `bootstrap.nix`. Aucun jeton root.
- Image : `local:vztmpl/nixos-prototype-6d083990ea052828323405e9c7687ec74231dd036d1790ecc4245c06e6a73679.tar.xz`.
- CT 9901 sur proxade : unprivileged=1, protection=1, nesting=1, onboot=0,
  1 vCPU, 512 Mio, 4 Gio Storage2 ; environ 801 Mio de disque utilisés.
- NixOS `26.11.20260917.e554fab` démarre. DHCP observé : `192.168.1.182`.
  Cette adresse peut changer. SSH root par clé dédiée depuis dev-nixos réussi,
  avec clé hôte obtenue via `pct exec` sur le canal SSH administrateur authentifié.
  Vérification stricte, aucun `StrictHostKeyChecking=no`.
- `sshd.socket` actif (activation à la demande), aucune unité en échec.
  Aucune inscription Tailscale, aucun secret SOPS, aucune application ou entrée DNS.
- Second plan puis plan après restauration : **No changes**.
- Simulation de perte du fichier state sous flock, restauration de la copie
  située sur terraform/nuc-pve-1, comparaison exacte des octets et nouveau plan
  sans changement. SHA-256 de l'état restauré :
  `d0cb326963aaa02eac2d0bd6f2ede11dbb9045a0f9dfb04d3933298f27ffa145`.
  Ce test couvre la reprise avec sauvegarde, pas un crash serveur au milieu de
  l'extraction du disque ni l'import d'une ressource orpheline sans sauvegarde.
- Droits effectifs vérifiés : `/vms/205` n'a que Sys.Audit, aucun droit VM ;
  `/vms/9901` possède les droits VM nécessaires. Jeton root de diagnostic révoqué
  et ses ACL supprimées. Ancien utilisateur/jeton Terraform inchangés.

## Historique du diagnostic, distinct du chemin final

Une première création avec l'ancienne image, sans nesting, était idempotente
mais ne démarrait pas complètement. La modification features par bpg a échoué
en HTTP 403 avec compte PVE et avec jeton root à privilèges séparés. Un PUT
restreint `features=nesting=1` a permis de confirmer le problème de montage ;
l'image n'avait ensuite aucun sshd configuré. Ce CT de diagnostic sans données
a été arrêté et supprimé explicitement après contrôle hostname/tag/disque.
Seul le jetable créé dans cette tâche a été supprimé. PVE a également supprimé
son ACL spécifique, qui a été rétablie avant la création finale.

Le chemin final ne dépend d'aucune de ces réparations : construction/upload de
l'image, puis création par OpenTofu avec nesting dès la première requête.

## Limites avant un pilote

- Aucun conteneur préexistant adopté ou recréé. Aucun changement de la flotte,
  aucune fusion et aucun lancement manuel de déploiement GitOps.
- DHCP et étape manuelle de vérification de clé hôte adaptés à l'expérience ;
  adresse réservée et distribution de confiance à formaliser pour la production.
- Pas de test de perte totale du cluster, de rotation des secrets, d'enrôlement
  Tailscale/SOPS, ni de plan d'import de l'ancien Telmate.
- Le plan protégé ne permet que création/no-op. Les mises à jour et la gestion
  de ressources supplémentaires demandent une extension revue et testée.
- Pas de destruction automatique ; CT conservé joignable pour revue, 512 Mio
  réservés et onboot désactivé. Image et state restent présents.

## Contrôles de sécurité et de code

- Exécution concurrente sous flock : refus immédiat observé.
- Plan réel avec la déclaration retirée dans une copie de configuration :
  suppression détectée et rejetée ; ce plan n'a jamais été appliqué.
- 69 tests Python réussis, dont quatre nouveaux tests couvrant création/no-op,
  suppression/remplacement/mise à jour, identité/protection et plans incomplets.
- ShellCheck des deux scripts et vérification du format Nix réalisés sur copie
  isolée sur dev-nixos ; aucun build de la flotte demandé pour ce prototype.
