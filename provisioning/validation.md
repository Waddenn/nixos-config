> Historique du premier pilote applicatif. Voir la [validation suivante](validation-integration.md)
> pour le second CT et la proposition de raccordement central.

# Pilote applicatif — validation du 19 septembre 2026

## Périmètre effectivement déployé

Un seul service, `prototype`, CT 9901 sur proxade, réutilise l'identité et le state
du premier lot. Il possède 1 vCPU, 512 Mio, disque Storage2 4 Gio, unprivileged=1,
nesting=1, protection=1, onboot=0. Aucun conteneur préexistant n'a été adopté.
L'ancien Terraform/Telmate et le GitOps de production restent inchangés.

La déclaration `services.nix` produit les ressources Terranix/OpenTofu, le nœud
Colmena isolé, la configuration applicative et le contrôle Gatus. Le flake racine
ne découvre pas ce pilote : aucun ajout à `hosts/`, à Beszel ou au timer de flotte.
L'enrôlement OAuth est une configuration durable du contrôleur, réutilisable
avec le tag autorisé ; aucune clé manuelle par appareil.

## Résultats réels

- Parcours `up prototype` exécuté plusieurs fois avec succès : authorize,
  prepare, infra, discover, secrets, deploy, health, enroll. Dernier rapport
  `hosts/prototype/last-run.json` : huit étapes terminées, `status=complete`.
- Migration de la disposition des fichiers et de la variable bootstrap sans
  changer l'adresse de ressource ni le template initial. Plans suivants sans
  changement ; aucune recréation du CT pour installer l'application.
- Colmena déploie NixOS sur SSH LAN avant l'enrôlement. SOPS déchiffre le secret
  généré pour la clé hôte du CT ; `LoadCredential` le fournit au service.
  La sonde privée locale répond `authenticated=true`, sans sortie du secret.
- Démo HTTP sur 8080 : `/healthz` répond `status=ready, service=prototype`.
  Gatus sur localhost:8081 observe la santé toutes les cinq secondes. Les unités
  service-demo, tailscaled et gatus sont actives ; aucune unité en échec au contrôle final.
- Client OAuth `dev-nixos-provisioning-pilot`, scope auth_keys, tag:nixos-pilot,
  créé après autorisation explicite. Identité Tailscale réelle :
  **100.115.82.1**, hostname nixos-provisioning-prototype, tag attendu vérifié.
  HTTP et SSH avec clé hôte épinglée fonctionnent sur cette adresse.
- Tailscale utilise le mode userspace : aucune modification des devices/features
  de l'hôte Proxmox. Les relances conservent l'identité déjà enrôlée.
- Fichiers API PVE, OAuth et state vérifiés root:root 0600 ; fichiers d'enrôlement
  temporaires absents après succès, côté contrôleur et invité.

Ces adresses sont des observations, pas des paramètres à copier dans un inventaire.

## Échecs et reprise testés

- Arrêt réel de service-demo : `health` refuse le résultat, `last-run.json`
  indique failed/health. Gatus a enregistré `success=false` à
  **08:44:54.873791296 UTC**. Relance complète : service rétabli et huit étapes OK,
  sans recréation du CT ni nouvelle inscription Tailscale.
- Vrai plan OpenTofu de retrait de déclaration, produit sur une **copie isolée**
  du state : action delete détectée et rejetée par la garde générique.
  Aucun plan de suppression appliqué.
- Nouvelle archive restaurée dans un dossier isolé : égalité des octets du state,
  des variables, des accès PVE/OAuth et de la clé SSH du pilote. Le premier lot
  avait aussi testé la perte du state de travail, sa restauration depuis l'autre
  nœud et le plan sans changement ; voir son rapport historique.
- 78 tests Python réussis, dont identité/protection, plans incomplets,
  suppression/mise à jour/remplacement, ressource disparue hors OpenTofu,
  retrait retenu, refus d'adoption, échec partiel, santé de toutes les unités,
  paramètres OAuth, secret applicatif et préservation de stdin de l'appelant.
- Format du dépôt `nix fmt -- --check` réussi sur copie isolée de dev-nixos.
  Check Nix `single-declaration` réussi aussi depuis une copie sans faits runtime :
  doublons refusés, identités et endpoint dérivés de la même déclaration.
  L'expression bootstrap utilisée par `prepare` a été évaluée avec un autre
  hostname ; l'override NixOS reprend bien ce nouveau nom.

## Limites explicites

Le parcours courant complet a été testé sur **un** CT. La création de ce CT a
été validée au premier lot ; le second lot l'a conservé. Aucun second service
n'a été réellement créé pour cette validation. Les contrôles Python/Nix
couvrent la généralisation ; ils ne prouvent pas un déploiement multi-service.

Le pilote n'a ni domaine public, ni proxy Caddy, ni intégration au hub Beszel ou
Gatus de production. Son Gatus local démontre l'endpoint dérivé et la détection
réelle d'une panne. Aucun service métier n'a été migré. La politique Tailscale
existante autorise déjà largement le réseau : le tag limite les enrôlements
OAuth, **il n'isole pas le pilote du reste du tailnet**.

Pas de test de perte totale du cluster, de rotation OAuth/SSH/SOPS ou de crash
PVE durant une création. Les sauvegardes sont sur un autre nœud du même cluster ;
il manque une copie hors cluster avant production. La clé hôte privée du
contrôleur, destinataire SOPS de secours, relève de sa propre sauvegarde ;
l'archive de provisionnement ne la contient pas. La clé hôte privée du CT reste
sur son disque : sauvegarder le CT pour préserver cette identité.

Ce lot accepte création/no-op et activation applicative des seuls pilotes.
Les changements d'infrastructure et retraits destructifs demandent un autre
parcours revu. La promotion vers la production et son intégration à la CI exacte
main/canaris/GitOps restent à réaliser séparément. PR prête ne signifie pas fusion
ou déploiement de la flotte.
