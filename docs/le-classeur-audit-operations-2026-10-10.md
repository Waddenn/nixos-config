# Audit après bascule — exploitation et capacité

Observations du 10 octobre 2026, vers 11 h 48–11 h 55 Europe/Paris, en lecture
seule sur la production. Les tests de restauration modifient uniquement une base
jetable, supprimée à la fin. Aucun déploiement ni redémarrage de production.

## Capacité et latence mesurées

| Mesure | Valeur observée |
| --- | --- |
| CT | 4 CPU, 8192 MiB RAM, disque 64 GiB |
| RAM | 495 MiB utilisés ; 7696 MiB disponibles |
| Node | 223453184 octets ; aucun redémarrage |
| Disque CT | 3,6 GiB utilisés ; 61 GiB libres |
| PostgreSQL | base 155 MiB ; index publics 2496 KiB |
| Connexions | deux connexions applicatives inactives, une sonde active |
| Statistiques depuis démarrage | aucun deadlock, aucun fichier temporaire |
| HTTP santé public | 200 ; 106 ms depuis le poste, incluant réseau/TLS |
| Accueil | application 15,3 ms ; SQL 7,5 ms ; une requête SQL |
| Sauvegardes | contrôleur 12 GiB libres ; hôte séparé 7,8 GiB libres |

Ce relevé à faible charge ne mesure pas la capacité maximale concurrente. Les
512 MiB de shared_buffers, le pool Node de 12 et max_connections=50 ont une
marge suffisante dans ce relevé ; aucun changement mémoire/CPU arbitraire.
La limite applicative de 10 s par instruction et les verrous de transactions
restent à surveiller sous des imports volumineux. Ne pas multiplier les pools
ni relever max_connections pour masquer une file d'attente.

Les constats F-009 à F-011 relatifs aux quotas gratuits Hyperdrive/Neon ne sont
plus applicables à la route publique. La croissance des assets PostgreSQL reste
un sujet réel : elle augmente disque et sauvegardes, sans egress Neon actif.

## Monitoring et protections

Gatus fonctionne. Sa sonde directe `classeur` vers le CT expire après 10 s ;
sonde `classeur-proxy` via Caddy : 200 en 13,7 ms. L'ACL de bascule autorise
Caddy et le contrôleur, pas Gatus. Le champ `application.directMonitoring=false`
supprime la sonde impossible en gardant celle du proxy et ses alertes existantes.
L'inventaire refuse de désactiver la sonde directe sans proxy déclaré.
Ce correctif nécessite la promotion/CI puis l'activation ciblée de Gatus.

Nginx n'avait aucune limitation avant PostgreSQL. La configuration proposée
limite maintenant les routes dynamiques à 15 requêtes/s/IP avec rafale de 60,
et les illustrations en base à 20 requêtes/s/IP avec rafale de 120. Les bundles
statiques `/assets/` sont exemptés. La clé utilise le CF-Connecting-IP transmis
par Caddy authentifié ; remote_addr reste intact pour le contrôle du proxy.
Les dépassements répondent 429 avant Node. Ce n'est pas une défense volumétrique
contre une attaque distribuée et la limite applicative reste nécessaire.

Test réel sur nginx isolé, sans requête en production : 60 requêtes dynamiques
et 120 illustrations simultanées réussissent, 300 bundles réussissent ; une
rafale abusive de 300 requêtes dynamiques produit 235 refus 429 ; 60 requêtes
d'une autre IP réussissent immédiatement. Le script reproductible est
`scripts/classeur-ingress-check.py --nginx <binaire-nginx-Nix>`. Build NixOS
ciblé du CT réussi ; aucune activation. Les seuils restent à observer après
déploiement pour éviter de limiter les NAT partagés.

HSTS public observé : `max-age=31536000; includeSubDomains; preload` ; F-052
est déjà résolu par la configuration en amont. Ne pas ajouter un second réglage
concurrent dans Node. Ce relevé confirme l'en-tête, pas une inscription à la
liste preload des navigateurs.

F-004 : l'API Turnstile du connecteur a refusé la lecture avec l'erreur
Cloudflare 10000. Le hostname autorisé reste à attester en console ; aucune
rotation ni modification de widget. F-005 : le rapport de bascule atteste
l'URI callback Google et l'initiation ; un retour utilisateur complet reste
distinct et non vérifié ici.

## Restauration hors hôte vérifiée

Sur `dev-nixos`, utiliser le runtime Python Nix fourni par le service de
sauvegarde (Python n'est pas nécessairement dans le PATH interactif) :

```sh
python3 scripts/classeur-restore-check.py \
  --dump /var/backup/le-classeur-offhost/20261010T093559Z.dump
```

Le script vérifie SHA-256, transfère dans un répertoire privé du CT, restaure
transactionnellement sans propriétaire/grants sur une base créée depuis
template0, réindexe, vérifie index valides, circulation, compteurs et soldes
positifs, puis supprime la base et les fichiers. Il refuse tout nom cible de
production. Les originaux et droits PostgreSQL de production restent inchangés.

Exécution réelle réussie : dump hors hôte de 11 h 35 min 59, base restaurée
154 MiB, 28 tables publiques, 2783 instances et 3264 événements d'audit ;
collation 2.44/2.44. Contrôle final : zéro base `classeur_restore_check_*`.
La copie était antérieure à des écritures de production ; les nombres ne sont
pas présentés comme un rapprochement avec la progression courante.

Répéter après modification PostgreSQL/libc et périodiquement. Le test prouve une
restauration du contenu, pas un login Google ou une ouverture de booster.
Conserver les fichiers SOPS et la release compatible pour une reprise complète.

## Collation : maintenance préparée, non exécutée

`le_classeur_beta`, `postgres` et `template1` déclarent la version libc 2.42,
alors que PostgreSQL observe 2.44. template0 n'a pas de version enregistrée.
Les avertissements ne prouvent pas une corruption. Ils imposent d'examiner et
reconstruire les objets dépendants avant de rafraîchir la métadonnée. Voir la
[documentation PostgreSQL REINDEX](https://www.postgresql.org/docs/18/sql-reindex.html)
et [ALTER DATABASE](https://www.postgresql.org/docs/18/sql-alterdatabase.html).

Procédure à exécuter dans une fenêtre approuvée :

1. Produire et vérifier une sauvegarde fraîche du CT puis hors hôte. Capturer
   les compteurs/empreintes de progression et index ; garder la release courante.
2. Arrêter uniquement `le-classeur-cleanup.timer`, `le-classeur-cleanup.service`
   et `le-classeur.service`. PostgreSQL et nginx restent actifs. Attendre zéro
   session applicative active ; ne pas tuer les sessions d'autres services.
3. Comme postgres, sur chacune des trois bases concernées : `REINDEX DATABASE
   <base>` puis `REINDEX SYSTEM <base>` puis `ALTER DATABASE <base> REFRESH
   COLLATION VERSION`. Exécuter chaque commande hors transaction, avec
   `ON_ERROR_STOP=1`, `lock_timeout=5s`, `statement_timeout=120s`. Ne jamais
   rafraîchir la version si la reconstruction a échoué.
4. Relever versions réelles/enregistrées, tous les index valides et les
   invariants ; comparer les compteurs avant/après sans changement économique.
5. Redémarrer l'application puis le timer ; vérifier /health local/public,
   session Google, journaux et rapprochement administrateur. Si reconstruction
   échoue, conserver la métadonnée ancienne et diagnostiquer avant réouverture.

La reconstruction sur la base jetable a réussi ; l'interruption exacte ne
peut pas être garantie pour la production. Cette maintenance ne copie ni
réinitialise progression, assets ou numérotation.

## Droits du rôle runtime

F-020 est partiellement confirmé : rôle non propriétaire/non superuser, sans
CREATE sur schéma/base, mais UPDATE/DELETE sur les six journaux append-only.
`provisioning/applications/classeur-runtime-grants.sql` prépare le retrait exact
avec vérification des privilèges effectifs et rollback transactionnel si un droit
hérité reste excessif. Appliquer après que le préflight applicatif compatible
accepte SELECT/INSERT sur ces tables. L'ancien préflight exige le DML complet :
ne pas retirer les droits avant sa mise à jour. Aucune application automatique
par GitOps ou NixOS. Ne pas appliquer avec un rôle applicatif.

La politique SQL a été exécutée sur six tables synthétiques d'une base jetable :
révocation et vérification réussies. Un droit UPDATE hérité de PUBLIC a ensuite
provoqué le refus attendu ; vérification du rollback réussie, base supprimée.
Les privilèges du rôle dans la base de production n'ont pas été modifiés.

## Rétention et incident

CT : 14 jours configurés. Hors hôte : pas de suppression automatique. Une
sauvegarde vaut actuellement environ 154 MiB ; 30 sauvegardes quotidiennes
représentent environ 4,5 GiB, compatibles avec l'espace libre observé. 90 jours
quotidiens ne rentrent pas dans les 7,8 GiB libres du stockage séparé. Faire
approuver la rétention avant toute suppression ; surveiller le volume réel.

En incident, depuis le contrôleur : inspecter les seules unités Le classeur,
PostgreSQL et nginx, leur `Result`/`ExecMainStatus`, l'espace, la dernière
sauvegarde et la sonde Caddy. Consulter les journaux sans exporter secrets,
environnements ou détail SQL contenant des données personnelles. Couper les
ouvertures/trades par les contrôles applicatifs ; conserver annulation/nettoyage.
Un retour à une release exige un journal de migrations compatible. Un retour
à Neon exige gel et transfert inverse vérifié ; aucun simple changement DNS.
Les alertes Discord HTTP Gatus existent ; les alertes dédiées sauvegarde/espace
et une revue périodique des invariants restent à compléter sans annoncer qu'elles
sont déjà activées.

## CD : transport isolé préparé, non activé

L’application prépare un `workflow_dispatch` GitHub main-only de staging via
Tailscale OIDC. Le dépôt privé n’accepte pas les reviewers obligatoires sur son
plan actuel ; l’environnement est limité à main et `NODE_CD_ENABLED=false`.
Une identité fédérée dédiée, une règle réseau TCP22 ciblée et une clé SSH
limitée ont été configurées côté GitHub/Tailscale. Les tests de politique
acceptent le CT TCP22 et refusent PostgreSQL, HTTP origin et les autres cibles
administratives. Aucune session runner réelle n’a été exécutée ; aucun accès
root du contrôleur n’est exporté.

Le module `provisioning/applications/classeur-cd-staging.nix` est importé par
Classeur, mais **`my-services.infra.classeur-cd-staging.enable=false` par défaut**.
Il prépare, s’il est activé ultérieurement par une PR revue, le compte
`classeur_cd` sans sudo ni groupe applicatif, une clé dédiée avec `restrict`,
une `ForceCommand` et un répertoire indépendant 0700. La clé publiée est publique
uniquement ; la privée demeure hors Git et dans le secret GitHub de staging.

Le récepteur `scripts/classeur-stage-release.py` est la copie revue du transport
applicatif `scripts/cd/stage-release.py` ; toute modification de son protocole
doit garder ces copies/testeurs cohérentes. Le source est fixé dans le Nix store
par la commande forcée. Il vérifie SHA, Linux x64, non-répétition, identité,
chemins/liens, unicité des membres et limites de taille avant de conserver un
paquet opaque. Il sérialise l’entrée et refuse un cumul supérieur à 2 GiB ou
moins de 1 GiB libre. Il n’extrait, n’exécute, ne migre et ne redémarre rien.

Aucun compte, récepteur ou nouveau service n’a été installé en production.
L’activation applicative demeure une maintenance opérateur après sauvegarde,
application explicite des migrations, vérification du schéma/grants, préflight
et plan de rollback compatible N−1. Ce transport n’est pas un CD d’activation.
La politique CI exacte de main NixOS avant toute installation reste conservée.

Validation du module désactivé : aucun compte CD dans la configuration normale.
Une configuration de répétition avec option activée a été construite entièrement
sur le contrôleur, y compris validation sshd ; aucune activation. Le compte
produit n’a aucun groupe supplémentaire. Format Nix et tests du récepteur passent.

Chemin SSH effectif : Tailscale userspace, `RunSSH=false`, OpenSSH socket activé
sur TCP22. SSH standard du contrôleur vers l’IP Tailscale du CT réussit avec
la clé hôte existante. Serve expose seulement 8084 ; aucun nouveau forward
22 ou activation Tailscale SSH n’est requis/proposé. L’accès du runner OIDC
reste à vérifier après une installation autorisée du compte et du récepteur.
