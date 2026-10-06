# Politique Tailscale

La politique complète appliquée le 6 octobre 2026 est conservée dans un dépôt Git
local privé sous `~/.local/share/nixos-config/tailscale-policy/versioned/policy.json`.
Le dépôt GitHub étant public, son inventaire et ses comptes ne sont pas publiés ici.
Les adresses et comptes doivent être actualisés après vérification de l'inventaire réel.

## Identités et droits

- `managed-server` sépare les serveurs du compte humain ; les rôles Caddy,
  Beszel, Terraform, Gatus et GitOps sont déclarés dans les configurations NixOS.
  Les deux hôtes Proxmox sont taggés dans la console et ne sont pas gérés par NixOS.
- Les tags sont attribuables uniquement par les administrateurs (Gatus par le
  propriétaire). `nixos-pilot` conserve son enrôlement OAuth limité à `auth_keys`.
- SSH humain exige une vérification SSO toutes les 12 heures. GitOps accepte
  uniquement root/nixos vers les serveurs taggés ; le grant réseau du contrôleur
  limite en plus les destinations à la flotte, Proxmox et aux pilotes, en TCP 22.
- Caddy n'a aucun accès SSH aux serveurs. Beszel est limité aux agents 45876,
  Terraform aux deux API Proxmox 8006. Les autres flux applicatifs sont explicites.
- POCO et Redmi n'ont plus les droits administrateurs ni Funnel. Ils accèdent
  aux ports applicatifs désignés, à Internet via les exit nodes, et à Moonlight
  sur Lenovo/Bazzite (TCP 47984/47989/48010, UDP 47998-48000). Le port 47990
  d'administration Sunshine est exclu. Le streaming réel reste à tester sur les
  appareils, actuellement hors ligne.

## Modification et reprise

1. Sauvegarder la politique actuelle depuis l'éditeur JSON et vérifier la dérive
   avec le fichier privé avant modification ; ne pas écraser une modification extérieure.
2. Modifier la copie sur une branche, relire les grants et les tests réseau/SSH.
3. Coller la politique complète dans la console ; Tailscale refuse une politique
   dont les tests échouent. Vérifier l'enregistrement et relire le fichier appliqué.
4. Contrôler le déploiement GitOps, les flux applicatifs et un refus SSH depuis Caddy.
   Conserver une session d'administration pendant les changements d'accès.
5. Reporter tout changement de console dans le dépôt privé ; les réglages Nix suivent la CI de ce dépôt.

La politique n'est pas synchronisée automatiquement par un client OAuth : le
client d'enrôlement n'a pas le scope `policy_file` et ne doit pas recevoir ce droit.
Les ACL ne filtrent que les flux passant par Tailscale, pas les connexions directes
sur le LAN ni les accès publics Internet. Un test de politique ne prouve pas
qu'une application écoute ou que son authentification est sûre.

Les appareils expirés/hors ligne, routes, DNS et tags historiques sont conservés
lorsque leur retrait n'est pas confirmé. Immich CT103 était arrêté et verrouillé
au moment des vérifications ; ne pas le démarrer ou lever son verrou implicitement.

Références : [syntaxe Tailscale](https://tailscale.com/docs/reference/syntax/policy-file),
[SSH et check mode](https://tailscale.com/docs/features/tailscale-ssh).
