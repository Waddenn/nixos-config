# Durcissement des hôtes Proxmox

Périmètre : `proxade` et `nuc-pve-1`, cluster HOMELAB. Décision du propriétaire :
administration par Tailscale et machines techniques uniquement, pas depuis tout
le LAN. Les règles Tailscale et les secrets SOPS sont hors de ce changement.

## Politique préparée

- Pare-feu Proxmox activé sur les deux hôtes, entrées refusées par défaut,
  sorties conservées. Les configurations et flags réseau des VM/LXC restent intacts.
- Les deux nœuds `192.168.1.1` et `.3` restent mutuellement autorisés, pour conserver
  Corosync, migration, réplication et VXLAN (UDP 4789). Aucun filtre ne sera ajouté
  entre leurs réseaux virtuels par ces fichiers.
- SSH, API/interface web, SPICE et consoles sont autorisés sur `tailscale0`.
  `dev-nixos` (`192.168.1.205`) et `terraform` (`192.168.1.253`) conservent SSH/API
  sur le réseau physique. Beszel conserve TCP 45876 par Tailscale.
- Le reste du LAN ne bénéficie plus de l'autorisation implicite Proxmox pour
  `local_network` : les refus explicites précèdent les exceptions intégrées.
- OpenSSH exige une clé, y compris pour root. Le compte root, les clés du cluster,
  l'authentification web Proxmox et Tailscale SSH ne sont pas supprimés.

**Limite Tailscale :** ses chaînes `ts-input` peuvent accepter le trafic avant le
pare-feu Proxmox. Ces règles ne remplacent pas les ACL du tailnet et ne prétendent
pas limiter tous les ports entre ses membres. Le durcissement porte sur les accès
hors Tailscale et sur l'authentification OpenSSH.

Les adresses des contrôleurs sont des réservations existantes : tout changement
ou réattribution doit entraîner une révision des autorisations. L'autorisation
mutuelle des deux hyperviseurs est volontaire ; le filtrage ne protège pas contre
un hyperviseur compromis ou l'usurpation d'adresse sur le même segment Ethernet.

## Validation sans activation

Copier ce répertoire dans un répertoire temporaire privé sur chaque hôte puis :

```sh
perl /chemin/candidat/validate.pl /chemin/candidat
```

Le programme charge uniquement les fichiers candidats, compile avec la version
Proxmox installée et simule des paquets IPv4/IPv6. Il n'appelle aucune fonction
appliquant les règles au noyau. Il teste les refus LAN et invités, les autorisations
cluster/contrôleur/Tailscale et la supervision. Il ne simule pas les chaînes
Tailscale, l'ensemble du routage réel ou les sessions déjà établies.

Validation effectuée le 5 octobre 2026 : Proxmox 9.2.21, **66 simulations réussies
sur chaque nœud**. Quorum présent (2/2), aucun flag de NIC `firewall=1` trouvé.
SSH root par clé vérifié dans les deux sens sur les adresses physiques, avec les
clés hôtes obtenues par les connexions administratives authentifiées.

Une vérification SSH ordinaire depuis `nuc-pve-1` vers `192.168.1.1` rencontre
un problème de confiance de clé hôte déjà existant. Le test avec une clé hôte
explicitement vérifiée fonctionne. Ne pas désactiver `StrictHostKeyChecking` :
réconcilier cette confiance avant une activation en production.

## Livraison et activation

L'activation est une opération Proxmox distincte de la flotte NixOS :
`internal-gitops.service` ne déploie pas ces fichiers. Utiliser **dev-nixos comme
seul contrôleur**, après autorisation de livraison, fusion et succès de la CI du
SHA exact de `main`. Ne pas lancer de déploiement NixOS pour cette modification.

1. Réexaminer le quorum, les chemins SSH et la configuration de production.
   `baseline.sha256` refuse une configuration différente de celle auditée. Si elle
   a changé, analyser le diff et mettre à jour la proposition avant de continuer.
2. Vérifier un accès console de secours et de nouvelles connexions SSH par clé
   dans les deux sens entre nœuds. Vérifier depuis dev-nixos les clés hôtes et
   l'accès aux deux nœuds. Une session SSH déjà ouverte ne suffit pas.
3. Depuis un checkout du SHA approuvé sur dev-nixos, copier `proxmox/hardening/`
   sur chaque hôte, par exemple dans `/root/proxmox-hardening-release/`.
4. Choisir le même identifiant de lot sur les deux hôtes (ex. `20261005-SHA`).
   Exécuter **prepare sur les deux hôtes avant toute activation** :

```sh
bash /root/proxmox-hardening-release/manage.sh prepare 20261005-SHA
```

Cette commande sauvegarde les fichiers initiaux, conserve une copie du candidat,
valide les règles et prépare la configuration SSH. Elle n'active rien. Un lot est
à usage unique ; conserver les sauvegardes en cas d'échec de préparation.

5. Activer d'abord `proxade`, vérifier les nouvelles connexions, le quorum et les
   réseaux invités, puis activer `nuc-pve-1` :

```sh
bash /root/proxmox-hardening-release/manage.sh activate 20261005-SHA
```

Chaque activation arme **son propre retour arrière automatique après 10 minutes**.
Le démon pare-feu existant applique les fichiers de façon asynchrone. Ne pas arrêter
`pve-firewall`, ce qui retirerait ses protections. Les connexions établies peuvent
survivre : tester de nouvelles connexions.

6. Avant confirmation, contrôler les deux nœuds :
   - `pve-firewall status` indique `enabled/running`, sans changement en attente ;
   - `pvecm status` conserve deux votes et le quorum ;
   - nouvelles sessions SSH par clé et HTTP/API 8006 via Tailscale ;
   - SSH inter-nœuds, accès du contrôleur, Beszel et connectivité des VM/LXC ;
   - refus de nouvelles connexions LAN 22/8006 depuis une machine non autorisée ;
   - `sshd -T` indique `passwordauthentication no`,
     `kbdinteractiveauthentication no`, `permitrootlogin prohibit-password`
     (ou son synonyme `without-password`).
7. Confirmer **sur les deux hôtes**, avant leurs échéances :

```sh
bash /root/proxmox-hardening-release/manage.sh confirm 20261005-SHA
```

La confirmation vérifie l'état local, mais ne remplace pas les tests externes de
l'étape 6. Elle annule le timer local et conserve les sauvegardes. Si l'un des timers
expire, il peut restaurer le fichier cluster partagé et désactiver la protection
sur les deux hôtes : recontrôler les deux, ne pas annoncer de succès partiel caché.

## Retour arrière

Depuis une console ou un accès encore disponible, sur chaque hôte :

```sh
bash /root/proxmox-hardening/20261005-SHA/candidate/manage.sh rollback 20261005-SHA
```

Le script restaure le fichier cluster partagé et le fichier hôte initial, retire
uniquement son propre ajout SSH et recharge SSH. Il ne remet pas un ancien fichier
sur une modification concurrente inconnue : dans ce cas il signale le fichier à
examiner et garde les originaux dans `/root/proxmox-hardening/LOT/original/`.
Le timer transitoire ne survit pas au redémarrage : ne pas redémarrer un hôte pendant
la fenêtre d'activation. La procédure et son retour arrière restent à éprouver en
production lors de l'activation autorisée.

## Références

- Configuration PVE installée : `/usr/share/perl5/PVE/Firewall.pm`, notamment
  `enable_host_firewall`, `compile` et l'ajout implicite de `local_network` au groupe
  `management` ; c'est cette version locale qui a été validée.
- Documentation : https://pve.proxmox.com/pve-docs/chapter-pve-firewall.html
- Tailscale SSH : https://tailscale.com/docs/features/tailscale-ssh
