# Livraison automatique du code Classeur

Cette procédure remplace l’activation opérateur du code décrite dans l’audit du
10 octobre. Les migrations restent manuelles. L’installation du mécanisme NixOS
exige toujours une CI complète réussie pour le SHA exact de `main`, puis une
activation ciblée du CT depuis `dev-nixos`.

## Deux accès distincts

`classeur_cd` reçoit un paquet opaque avec `stage SHA40 SHA256`. Il garde son
compte, son répertoire et sa clé de staging, sans sudo. `classeur_activate`
dispose d’une autre clé et n’accepte que `activate SHA40 SHA256`. Les deux comptes
ont une commande SSH forcée, sans terminal ni forwarding. L’activation ne donne
ni shell root, ni rôle PostgreSQL propriétaire, ni accès direct aux secrets.

Le sudo de l’activateur ne permet qu’un wrapper immuable du Nix store **sans
arguments**. Celui-ci valide la ligne reçue avant de lancer une unité systemd
éphémère `le-classeur-activation.service`. La transaction continue si SSH se
coupe ; son résultat est enregistré atomiquement dans
`/var/lib/le-classeur/activation-result.json` (root, 0600). Un deuxième lancement
pendant la transaction est refusé, et le verrou `deploy.lock` couvre toute la
préparation, les contrôles et le retour arrière.

Le workflow applicatif vérifie le succès des contrôles, l’identité du dépôt,
l’événement main et son SHA exact avant d’utiliser ces accès. Le serveur valide
le paquet et son SHA-256 mais ne consulte pas GitHub : posséder la clé d’activation
donne le droit de proposer du code avec les seuls privilèges applicatifs.

## Activation et refus

1. Recopier le paquet en snapshot root et revalider checksum, identité Linux x64,
   mode non-répétition, chemins et limites de taille avant extraction. Une release
   existante n’est jamais écrasée. Garder au moins 3 Gio pour préparer un candidat.
2. Comparer exactement tout `migrations/` entre version courante et candidate,
   y compris journal et snapshots. Toute différence refuse l’automatisme avant
   de toucher au service courant. La maintenance de schéma reste explicite.
3. Tester l’encodage et le décodage Sharp sous `le_classeur_app`. Démarrer le
   candidat sous la même identité limitée et les mêmes protections systemd,
   sur **loopback 8085**, sans accès ingress. Son démarrage exécute le préflight
   PostgreSQL en lecture seule : rôle, schéma, journal et grants exacts.
4. Vérifier santé, SHA déclaré par `X-Classeur-Revision`, accueil, bundle statique
   et première illustration de l’accueil si présente. Vérifier aussi la santé
   publique courante avant la bascule pour distinguer une panne externe préalable.
5. Suspendre le timer de nettoyage et attendre la fin de son unité. Arrêter le
   candidat, remplacer atomiquement `current`, redémarrer seulement
   `le-classeur.service`, puis répéter les contrôles locaux et publics.
6. En cas d’échec après bascule, remettre le lien précédent et redémarrer
   l’application avec son schéma identique. Vérifier sa santé locale/publique.
   SIGTERM/SIGHUP et les erreurs déclenchent ce même nettoyage. Le timer reprend
   seulement s’il était actif avant l’opération. Aucune donnée de jeu n’est
   restaurée, migrée ou modifiée par l’activateur.

Le JSON de succès est unique sur stdout :
`{"status":"activated","revision":"…","sha256":"…"}`. Un retry de la même
version produit `already-active` après contrôle public. Un refus ou rollback
retourne un code non nul ; les détails techniques sont dans le journal systemd.
La version antérieure peut précéder l’en-tête de révision : le premier rollback
vérifie alors sa santé et son lien immuable connu.

Après succès, conserver cinq paquets/releases récents ainsi que le courant et
son prédécesseur. Ne supprimer que des répertoires nommés selon le protocole,
jamais des liens ni des releases opérateur sans provenance d’activation.
`operator/` et les sauvegardes restent intacts. Chaque release garde les bundles
propres de N−1, sans recopier indéfiniment les anciens bundles hérités. Une erreur
de rétention est signalée mais ne provoque pas de rollback du code sain.

Après interruption du poste, relire le résultat et le journal avant de relancer.
Une extinction forcée du CT ou un SIGKILL ne permet pas d’exécuter un `finally` :
vérifier alors `current`, la santé et le timer de nettoyage, puis reprendre sous
le même verrou. Ne jamais exécuter les anciens scripts opérateur en parallèle.

## Validation

Les tests Python utilisent de vraies archives, extractions, comparaisons de
schéma, liens atomiques et verrous ; seules les frontières systemd/réseau sont
simulées. Ils couvrent corruption, chemins interdits, contrat de migrations
modifié, échec Sharp/candidat/local/public, interruption après bascule, rollback,
timer initialement arrêté, concurrence, retry et rétention. Le build NixOS ciblé
valide également sshd et sudoers. La livraison applicative complète est vérifiée
par le workflow distinct du dépôt Le classeur.
