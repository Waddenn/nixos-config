# Durcissement OPNsense

Politique explicite dans `policy.json`, appliquée avec les fonctions natives
OPNsense. Les secrets, exports XML et clés privées restent hors dépôt.

## Périmètre préparé le 6 octobre 2026

- Administration HTTPS sur LAN et Tailscale, autorisée uniquement depuis les
  adresses Tailscale du portable de Tom et de son POCO. Utiliser
  `https://opnsense.hexaflare.net`, DNS A vers `100.103.199.91`, sans proxy public.
  Ne pas autoriser l'adresse LAN du routeur comme source d'administration : le
  SNAT des routes Tailscale pourrait sinon contourner la sélection des postes.
- Au boot, un hook asynchrone attend au maximum 60 secondes l'adresse Tailscale
  et relance le webgui sur ses interfaces privées ; le démarrage initial précède
  parfois l'adresse du VPN. Il ne change ni les listeners prévus ni les règles PF.
- Compte nominatif `tom`, mot de passe suivi du code OTP ; seul le backend
  `OPNsense MFA` est utilisé pour le web. Le compte root conserve ses identifiants
  pour console et secours Tailscale SSH, mais n'a pas de secours web sans OTP.
- Certificat ACME DNS-01 émis par un Caddy séparé sans listener HTTP, avec le
  secret Cloudflare déjà disponible sur Caddy. Aucun jeton Cloudflare sur le
  pare-feu. Déploiement horaire des renouvellements par dev-nixos.
- Alias `PrivateNetworks` étendu aux réseaux privés/réservés IPv4 et IPv6 pour
  rendre les règles « Internet uniquement » effectives hors des seuls VLAN locaux.
- Unbound limité à LAN/loopback, DNSSEC, ACL par défaut refuse et clients précis ;
  exception TCP/UDP 53 sur LAN pour ces clients.
- Le compte de maintenance possède page-all, requis par OPNsense pour créer un
  shell SSH dans wheel ; il ne possède pas de secret OTP et ne peut donc pas
  utiliser le web avec le backend MFA exclusif. Sa clé n'autorise que les cinq
  commandes exactes du dispatcher, sans forwarding ni commande libre.
- SSH natif sans root ni mot de passe, limité à dev-nixos `192.168.1.205` vers WAN
  `192.168.1.4:22`, avec clé dédiée et commandes forcées. WAN est ici un LAN amont
  privé : désactivation de blockpriv avec maintien du refus par défaut et de
  blockbogons. Le DNAT Caddy et les anciennes exceptions restent identiques.
- Sauvegardes XML et archives de journaux chiffrées CMS AES-256-GCM sur le pare-feu,
  collectées sur dev-nixos chaque heure, rétention 31 jours. La clé de déchiffrement
  reste hors contrôleur. Pas de notification externe envoyée automatiquement.
- Mise à jour quotidienne de la base VuXML officielle, état JSON et unité systemd
  en échec si certificat proche d'expiration, audit invalide ou avis présents.

Les journaux sont des captures horaires, pas un syslog temps réel. Le trafic
intra-VLAN doit être protégé sur les hôtes. Les flux via Tailscale restent aussi
soumis à la politique du tailnet ; aucune assertion sur un utilisateur tiers sans
sonde dédiée. Le certificat privé utilise un nom public et figure dans les logs CT.

## Préparation et activation

État opérationnel : `/root/opnsense-hardening/20261006` sur OPNsense. Original
`config.xml` et état Tailscale sauvegardés ; snapshot disque VM 200 sur proxade :
`pre-opnsense-hardening-20261006`. La sauvegarde CMS a été déchiffrée et son SHA256
comparé au XML original. Ne pas remplacer cette sauvegarde par un nouvel état.

Le dossier `staged` contient les fichiers de ce dossier, ainsi que les fichiers
privés mode 600 `credentials.json` et `certificate.json`. Le marqueur
`enrollment-verified` est créé dans le dossier d'état après vérification de l'OTP
fourni par Tom. `activate.sh prepare` vérifie le SHA original, la chaîne du
certificat, les modèles natifs et la syntaxe PF sans charger les règles.
`validate.php candidate.xml` vérifie la conservation NAT/exceptions/root et le
backend MFA ; fournir le mot de passe par stdin pour tester le backend natif.
Il ne sauvegarde aucune configuration.

Après validation explicite de l'activation réseau :

```sh
sh /root/opnsense-hardening/20261006/staged/activate.sh activate
# Contrôler HTTPS/MFA, refus web des segments, DNSSEC, SSH contrôleur et Internet.
sh /root/opnsense-hardening/20261006/staged/activate.sh confirm
```

Un watchdog restaure la configuration après dix minutes sans confirmation. Il
refuse d'écraser une modification concurrente ; dans ce cas utiliser la console
Proxmox et le snapshot. Le verrou est libéré avant l'attente du watchdog. La
restauration peut aussi être demandée avec `activate.sh rollback`. Le watchdog
couvre la transaction de configuration, pas une mise à niveau du système.

Déployer les services Nix uniquement après fusion autorisée et CI réussie sur le
SHA exact de main, selon `AGENTS.md` et `docs/operations.md`. Seuls Caddy et
le contrôleur importent ce module. Clé du contrôleur provisionnée hors Nix :
`/var/lib/opnsense-maintenance/id_ed25519`, propriétaire nixos, mode 600 ; clé
publique dans `credentials.json` sur OPNsense. Clé d'hôte native épinglée dans
le module, distincte de celle de Tailscale SSH. Après confirmation réseau et
activation Nix, démarrer `opnsense-maintenance.service`, vérifier les archives et
`status.json`, puis arrêter le service transitoire `opnsense-cert-prepare` une fois
le service permanent `opnsense-certificate` validé.

## Restauration des archives

Les clés de secours sont dans le dossier local protégé :
`/var/home/tom/Documents/audits/opnsense-20261006/private`. Le mot de passe de Tom
et l'URI OTP sont dans `tom-enrollment.txt`. La clé CMS est `backup.key` ; conserver
une seconde copie indépendante protégée avant de supprimer le poste source.

```sh
umask 077
openssl cms -decrypt -inform DER -in backup-YYYYMMDDTHHMMSSZ.cms \
  -inkey /chemin/protege/backup.key -out config.xml
openssl cms -decrypt -inform DER -in logs-YYYYMMDDTHHMMSSZ.cms \
  -inkey /chemin/protege/backup.key -out logs.tar.gz
```

## Mise à niveau encore nécessaire

Le dépôt signé 25.7 indique tous ses paquets à jour, mais **25.7 est en fin de
support**. L'audit initial fiable détecte 35 avis dans 12 paquets : le nombre ne
prouve pas l'exploitabilité de chaque service. Parcours annoncé par le firmware :
25.7 -> 26.1, puis branche supportée 26.7 (26.7.5 disponible lors de la préparation).
Ne pas installer directement des paquets FreeBSD génériques sur OPNsense.

Après validation explicite de la fenêtre de maintenance, conserver accès console
Proxmox, sauvegarde indépendante et snapshot. Lancer le parcours firmware natif,
attendre chaque redémarrage, puis vérifier interfaces, PF, Tailscale SSH/routes,
MFA, DNSSEC et exceptions applicatives avant l'étape suivante. Refaire `pkg audit`
et vérifier les plugins et le noyau après migration. En cas de perte de réseau,
revenir au snapshot depuis proxade ; la restauration nécessite l'arrêt de la VM
et provoque une coupure. Aucun redémarrage de mise à niveau n'est lancé par ces
scripts de maintenance.
