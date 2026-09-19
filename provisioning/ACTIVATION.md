# Raccordement proposé — aucune activation centrale effectuée

La PR propose d'ajouter le service interne `probe` au GitOps existant. Ce n'est
pas une autorisation de fusion ni un déploiement de la flotte entière.

## Cibles et effets mesurés

Comparaison des générations avec main `67d746b5575f91613448000e96056087d5cacbb2` :

| Cible | Effet de la proposition |
|---|---|
| nixos-service-probe | Reprend le CT 9902 créé dans ce lot ; même disque, clés et secret SOPS. Système issu du flake principal, agent Beszel partagé, canari applicatif. |
| caddy | Route interne `/probe/*` sur son nom MagicDNS, port 8085 ouvert uniquement sur tailscale0 ; autres sources rejetées. Aucun domaine public supplémentaire. |
| gatus | Deux contrôles dérivés : backend direct et route du proxy, avec les conditions HTTP de la déclaration. |
| beszel | Ajout automatique du seul nouveau système ; les 17 tuples existants nom/host/port/users restent identiques. Sauvegarde SQLite/YAML avant remplacement du fichier, comme actuellement. |
| dev-nixos | Clé hôte publique du nouveau service déclarée dans known_hosts système. Même contrôleur, utilisateur, timer, clé d'accès et algorithme de déploiement. |

Les autres générations sont identiques à ce main. Le CT 9901 reste isolé.
L'ancien état Telmate et les machines préexistantes ne sont pas adoptés.
Le CT 9902 garde pour ce lot sa protection et onboot=0 : ce pilote ne promet
pas de redémarrage automatique après redémarrage du nœud Proxmox.

## Prérequis avant décision de livraison

Le contrôle de capacité existant a été exécuté avec les fermetures réellement
construites. Caddy, Gatus, dev-nixos et le nouveau service passent.
**Beszel bloque actuellement** : 5 421 064 192 octets disponibles, contre
5 557 629 512 requis (1 869 123 232 manquants dans le store et marge OCI conservée),
soit environ **131 Mio de déficit**. Ce budget inclut une dérive déjà présente
sur main, pas seulement la petite nouvelle entrée de supervision.

Audit en lecture seule effectué sur Beszel : `nix-store --gc --print-dead`
retourne **0 chemin non référencé**, et cinq générations système sont conservées.
Un GC standard sans retirer de génération ne récupérera donc rien. Supprimer des
générations réduirait les possibilités de retour arrière ; ce n'est pas proposé
implicitement comme un « nettoyage sans risque ».

**Option recommandée à approuver : CT 102 sur nuc-pve-1, rootfs local-lvm,
16 → 20 Gio**, sans adoption par le nouveau state. Le thin pool local-lvm dispose
actuellement d'environ 167 Gio non alloués (349,18 Gio au total, données 52,18 %,
métadonnées 2,12 %). Aucun besoin observé d'étendre le pool lui-même.
La commande Proxmox a été vérifiée dans l'aide installée, mais **pas exécutée** :

```sh
ssh root@nuc-pve-1 'pct resize 102 rootfs 20G'
```

La taille est absolue, pas `+4G` : une relance ne doit pas augmenter encore le
volume. L'agrandissement préserve normalement le contenu ; la réduction n'est
pas prise en charge par cette commande. Avant : relever configuration/génération,
état HTTP et service Beszel, vérifier une sauvegarde récente des deux bases via
SQLite `.backup` et du YAML, puis recontrôler capacité et absence de changement
concurrent sur le CT. Après : vérifier la taille PVE **et** `df -B1 /nix/store`
dans le CT, santé et intégrité SQLite/IDs, puis recalculer le budget avec
`Fleet.storage` pour le système candidat. Ne pas déduire la réussite du seul code
retour de `pct`.

Alternative : inventorier et faire approuver précisément les générations à
retirer, en gardant la génération active, le profil système et un retour arrière
choisi ; seulement ensuite GC et nouveau préflight. Cette alternative n'a pas
été testée ni appliquée. Ne pas réduire la réserve de déploiement et ne jamais
supprimer les données Beszel pour franchir le seuil.

Ces mesures sont datées du 19 septembre 2026 et doivent être refaites avant
intervention. Aucune suppression ni extension de disque n'a été réalisée.

Le dernier rapport GitOps main était déjà partiel : Beszel en manque d'espace,
dev-nixos en dérive, valheim injoignable. Vérifier de nouveau les canaris et les
hôtes avant livraison ; un valheim toujours hors ligne impose un bilan partiel.

## Séquence après autorisation de fusion et activation

1. Revalider les seuls budgets/canaris concernés, vérifier sauvegardes state et
   données Beszel. La sonde est déjà bootstrapée et `register probe` a vérifié
   l'accès SSH strict depuis l'utilisateur GitOps existant.
2. Fusionner la PR autorisée, attendre le succès de la **CI complète du SHA exact
   de main fusionné**. Une PR verte ne remplace pas cette étape. Le changement du
   flake global conserve la sélection CI complète actuelle.
3. **La fusion suivie d'une CI main réussie rend déjà les changements éligibles
   au timer existant** (environ une heure, avec délai aléatoire). Lever le
   prérequis d'espace avant fusion ; ne pas supposer que le système attendra
   indéfiniment une commande manuelle. Pour lancer immédiatement le parcours
   autorisé, sans nouveau service systemd :

   ```sh
   ssh root@dev-nixos 'systemctl start --no-block internal-gitops.service'
   ```

   Il reconstruit/active les générations en dérive, canaris d'abord. Le nouveau
   service est canari avec les canaris existants. Ne pas contourner un échec.
   Le contrôleur est mis à jour en dernier. Les éventuelles autres dérives déjà
   présentes sont signalées par le préflight, pas annoncées comme « cinq seulement »
   sans une nouvelle comparaison live.
4. Vérifier `last-run.json`, générations actives et profils, services, santé HTTP,
   inscription Beszel et IDs des 17 systèmes historiques, deux endpoints Gatus,
   puis accès tailnet au proxy et refus hors tailnet. Les noms/IP ne sont pas
   recopiés dans des inventaires manuels.
5. Si un hôte reste injoignable ou insuffisant, rapporter précisément le résultat
   partiel ; aucune annonce de succès global. Conserver les sauvegardes.

## Repli non destructif

Avant fusion, rien de central n'est actif : conserver les deux CT et leur état.
Après activation, un échec arrête le parcours via les gardes existantes ; inspecter
l'état avant toute relance. Préférer une correction déclarative en PR puis CI main.
Pour suspendre les activations de la sonde, utiliser `lifecycle = "retained"` en
conservant `gitops.enable`, la déclaration et son identité : pas de suppression
Terraform, pas de retrait brutal de l'inventaire Beszel. Un retour de génération
NixOS ne restaure pas des données ; sauvegarder séparément les bases avant toute
opération de récupération.
