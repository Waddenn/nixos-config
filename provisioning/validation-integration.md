# Deuxième service et raccordement central — 19 septembre 2026

## Création réelle et indépendance

`probe` a été ajouté à `services.nix`, puis créé depuis dev-nixos par
`nix develop -c python3 provision.py up probe`. Le parcours n'a nécessité ni
modification ad hoc dans Proxmox ni clé Tailscale manuelle : authorize, prepare,
infra, discover, secrets, deploy, health et enroll ont réussi.

| Service | CT / nœud | Application | Tailscale observé |
|---|---|---|---|
| prototype | 9901 / proxade | HTTP 8080 | 100.115.82.1 |
| probe | 9902 / proxade | HTTP 8082 | 100.93.239.9 |

Les deux CT sont non privilégiés, protégés, avec nesting dès création, chacun
1 vCPU / 512 Mio / 4 Gio Storage2, et onboot=0. Le state est commun mais contient
deux adresses de ressources distinctes. Clés SSH hôte, clés d'amorçage, secrets
applicatifs et adresses Tailscale comparés : tous distincts. Les valeurs secrètes
n'ont pas été affichées ni publiées. Les inscriptions réutilisent seulement le
client OAuth approuvé, scope auth_keys et tag:nixos-pilot inchangés.

Les deux services ont été réconciliés après création, sans recréation. Arrêt réel
de service-demo sur `probe` : sa santé échoue pendant que `prototype` reste sain.
Relance complète de `up probe` avant transfert GitOps : huit étapes réussies,
même identité et disque. SOPS, sonde privée et Gatus local vérifiés sur chacun.

`register probe` a ensuite authentifié le vrai compte GitOps `nixos` avec sa clé
préexistante, en SSH strict. Les clés publiques observées sont publiées dans
`identities/probe.json` ; aucune IP n'y est dupliquée. Le secret SOPS propre à
probe est chiffré dans Git. OAuth/API/private keys restent root-only hors Git.

## Proposition centrale, construite mais non activée

Comparaison à main `67d746b5575f91613448000e96056087d5cacbb2` : seules cinq
fermetures changent — nixos-service-probe, caddy, gatus, beszel et dev-nixos.
Les cinq systèmes ont été construits localement, sans activation centrale.

- Nœud NixOS/Colmena, santé, canari et agent Beszel dérivés de la déclaration.
  Le module agent et `lib/beszel-release.json` sont ceux déjà utilisés en production.
- Gatus dérive le backend et la route proxy ; Caddy dérive le chemin `/probe/*`
  et le backend MagicDNS. Aucune entrée DNS public ou IP statique ajoutée.
- Test réel du bloc Caddy généré dans un processus temporaire sur dev-nixos,
  arrêté après le test : source Tailscale → HTTP 200 et corps du **second** service ;
  source loopback hors plage Tailscale → HTTP 403. Ce test ne prétend pas que la
  configuration du Caddy central est déjà active.
- Connexions réelles depuis les hôtes Caddy et Gatus existants vers le backend
  MagicDNS : HTTP ready. Interface tailscale0 existante vérifiée sur Caddy.
- YAML Beszel candidat comparé au fichier réellement actif : les **17 systèmes
  existants** conservent tous leurs champs, seul nixos-service-probe est ajouté
  (18 au total). Aucune écriture des bases ou de la configuration du hub.
- Une divergence NixOS/Colmena découverte au contrôle a été corrigée : le module
  commun fixe explicitement `nixpkgs.flake.source`, comme les hôtes historiques.
  Parité finalement vérifiée pour **15 hôtes** par le contrôle déjà exécuté
  dans la CI principale.
- `gitops.enable` retire le service du hive isolé ; `up` et `deploy` refusent
  une activation directe. Un second `register` a aussi été vérifié : il accepte
  la clé Ed25519 épinglée même si SSH a ajouté une clé RSA authentifiée ; il force
  Ed25519 pour sa vérification et refuse toujours un remplacement de cette clé.
  Retenir une déclaration conserve sa ressource et son
  entrée Beszel, en excluant son activation.

## Validation et prérequis d'activation

81 tests Python passent. Ils incluent les gardes CI main exact/canaris existantes,
la protection de propriété/state, l'interdiction de contourner GitOps et le refus
d'écraser une identité hôte publique déjà enregistrée. Format Nix, contrôles de
l'inventaire commun, de l'intégration et des scripts sont effectués sur une copie
isolée du contrôleur. La CI rapide de PR ne remplace pas la CI complète de main.

Le budget d'espace réel passe pour Caddy, Gatus, dev-nixos et probe. Beszel manque
d'environ **131 Mio par rapport à la garde existante**, qui reste inchangée.
Ce problème était déjà visible dans le dernier GitOps main. L'audit du GC trouve
zéro chemin non référencé et cinq générations conservées. Une extension ciblée
CT102/nuc-pve-1 de 16 à 20 Gio est proposée à approbation, avec capacité du thin pool
vérifiée ; aucune suppression ou extension n'a été faite. Les mesures et la séquence d'activation
sont détaillées dans [ACTIVATION.md](ACTIVATION.md).

Aucune fusion, activation centrale ni migration métier dans cette validation.
La politique Tailscale large existante est conservée ; un tag OAuth n'est pas
une barrière réseau. Les tests ne couvrent toujours pas la perte totale du
cluster, un crash PVE durant création ou une rotation complète des identités.
