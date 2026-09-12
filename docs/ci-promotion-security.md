# Audit de la promotion CI par arbre

Note historique : ce document décrit la correction de la PR #33. Depuis la
simplification de la CI, toutes les PR ont uniquement des tests rapides ; la CI
complète automatique est effectuée sur `main`. Voir la [procédure actuelle](operations.md#branches-de-travail-et-pr).

État : **désactivée**, PR #33, audit du 12 septembre 2026. Le gain recherché
(supprimer la seconde CI complète après fusion) n'est pas livré. Le repli complet
est le résultat de sécurité retenu ; les trois P1 sont neutralisés par retrait du
chemin vulnérable, pas par l'ajout d'un nouveau protocole de provenance.

## Pourquoi le protocole précédent ne peut pas être conservé

1. **Base mutable (P1).** `publish()` résolvait le merge ref et la base au moment de
   la publication. Rien ne liait ce commit au merge réellement testé par le run.
   Un test de A+H pouvait ainsi certifier B+H. Le champ `pull_requests` d'un run ne
   répare pas ce problème : lors de l'audit, le run GitHub `34704846287` avait
   `head_sha=fbd61bd3cffe5603d66d8b6c2757f92e0febe38c`, mais sa PR associée exposait
   déjà `head.sha=f924629912749070f96082b41d695cd571015375`. Ces données sont une
   association courante, pas un instantané d'exécution immuable. Le publieur et
   toutes les lectures de merge ref sont retirés.
2. **Statut imitable (P1).** `github-actions[bot]` identifie l'application Actions,
   pas le workflow ni sa révision. Un autre workflow peut produire le même contexte,
   la même description et la même URL. Aucun statut n'est désormais consommé, le
   workflow `promote-ci.yml` est supprimé et son droit `statuses: write` disparaît.
3. **CI modifiable (P1).** Le chemin `ci.yml` et des jobs verts nommés
   `quick-checks`, `validation`, `ci-gate` ne prouvent pas ce qu'ils ont exécuté.
   Une PR pourrait remplacer leurs commandes par `true`. Aucun run PR, même vert,
   ne peut désormais autoriser le raccourci de `main` ; les modifications de CI
   passent elles aussi par le parcours complet. Cela ne rend pas un workflow
   malveillant fusionné digne de confiance : la revue de la chaîne CI reste
   nécessaire, comme pour tout code disposant de privilèges après fusion.

`ci-gate` contrôle à nouveau l'événement : sur `main`, PR prête, lancement manuel
ou événement non reconnu, il exige `full=true` et `validation=success`. Une sortie
vide, `full=false` ou un ancien `PROMOTED=true` ne suffit jamais. Seuls une PR
explicitement brouillon et un push sur une branche ordinaire ont le parcours rapide.
L'ancien CLI est une interface de refus, sans API, jeton ni option de réactivation.

## Cas limites et permissions

- Squash, rebase, fork, arbre réellement différent, base avancée, run annulé,
  preuve périmée/absente, doublons ou API indisponible : parcours complet sur `main`.
- La méthode précédente appelée `paginated()` ne lisait que les 100 premiers
  résultats. Elle est supprimée, ainsi que tous les consommateurs de listes de
  preuves. Aucun résultat partiel ne peut être accepté. Un futur protocole devra
  parcourir toutes les pages, lier les jobs à la tentative exacte du run et rejeter
  les doublons ou les limites incomplètes. Le sélecteur existant `plan-ci.py` ne
  parcourt que 100 runs de référence : une référence absente déclenche tous les
  builds ; il n'autorise pas la promotion.
- Permissions CI globales : `contents: read`. `actions: read` est limité au job
  `generate-matrix` qui recherche sa référence CI. La sélection du mode n'a plus
  de checkout ni de jeton transmis au shell. Les droits du job existant
  `promote-update` et les jetons Cachix restent inchangés ; aucun nouveau droit
  d'écriture, OIDC ou attestation n'est accordé.

## Identité Git et Nix

La recherche dans les fichiers Nix de cette révision n'a trouvé aucun usage direct
de `self.rev`, `self.lastModified`, `sourceInfo` ou `system.configurationRevision`.
Mais `inputs` est passé aux modules via `specialArgs` : ils peuvent accéder à
`inputs.self`, y compris dans une prochaine PR. Une égalité d'arbre Git n'est donc
pas une garantie générale d'égalité des dérivations. Le merge temporaire et le
commit final peuvent avoir des SHA et des dates différents. Nix expose ces
[métadonnées de flake](https://nix.dev/manual/nix/2.35/command-ref/new-cli/nix3-flake).
De plus, le plan actuel évalue `path:...#fleet` tandis que les builds utilisent
`.#nixosConfigurations...` : ce sont deux modes d'entrée à prendre en compte.

Avant toute réactivation, comparer les chemins de dérivation et les sorties
attendues sous les entrées réellement utilisées par la CI et par Colmena pour les
deux commits, ou imposer une normalisation explicite et auditée des métadonnées.
Une simple recherche textuelle n'est pas une preuve d'indépendance des métadonnées.
Cachix signé authentifie les objets de store ; il n'authentifie pas la provenance
GitHub et ne remplace pas cette comparaison.

## Conditions d'une réactivation

Le blocage concerne les primitives du prototype (statuts et associations REST),
pas une impossibilité de GitHub. Les [attestations et workflows réutilisables de
confiance](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/increase-security-rating)
peuvent fournir les éléments manquants, mais ce parcours n'est ni implémenté ni
validé ici. Un remplacement doit notamment :

- capturer le merge SHA réellement checkouté, ses parents et son arbre dans une
  exécution liée de façon authentifiée au run **et à sa tentative** ;
- vérifier une définition de validation approuvée à un SHA immuable, les dépendances
  exécutées, l'identité du workflow signataire et sa révision ; les changements de
  cette chaîne doivent rester exclus jusqu'au bootstrap complet de confiance ;
- isoler la signature du code PR, des artefacts et paramètres qu'il pourrait
  falsifier ; ne pas réinterpréter une simple charge utile comme preuve ;
- authentifier la source, le signataire, les horodatages et le digest. La
  [documentation de `gh attestation verify`](https://cli.github.com/manual/gh_attestation_verify)
  distingue les champs du certificat authentifiés des prédicats potentiellement
  contrôlés par le workflow ;
- appliquer une expiration, une règle d'unicité et une pagination complète, puis
  refuser strictement toute différence de commit testé, base, tête, arbre, sorties
  Nix, workflow ou tentative ;
- réussir un essai réel de bout en bout avec des preuves négatives avant d'activer
  l'omission des builds, tout en conservant la CI du SHA exact de `main`, Cachix
  signé, canaris, santé, espace et déploiements ciblés.

## Validation de cette correction

`tests/test_ci_promotion.py` contient des preuves du format précédent, dont la
progression de base, le statut imité, le workflow différent, les jobs no-op, le
véritable arbre différent et les cas limites. Elles sont toutes refusées sans
appel API. Ces tests prouvent le confinement, pas la validité d'un protocole futur.
Les tests exécutent également les blocs Bash réels de `validation-mode` et
`ci-gate` pour vérifier le parcours complet et empêcher un succès par mode manquant
ou promotion imitée. Les contrôles de cache et de déploiement existants sont
conservés. Aucun workflow manuel, passage en PR prête, merge ou déploiement ne fait
partie de cette intervention.

Résultats locaux de l'audit :

- `python3 -m unittest discover -s tests -p 'test_*.py'` : **62 tests réussis**,
  dont **16 tests de confinement et de parcours CI**.
- Les mêmes fixtures de progression de base, statut imité et jobs no-op ont été
  exécutées contre le script de `f924629` : l'ancien vérificateur les accepte et
  l'ancien publieur émet même une preuve après progression de base. Le nouveau
  code refuse ces trois cas.
- Sur `dev-nixos`, dans un répertoire temporaire distinct du checkout opérationnel :
  `nix fmt -- --check`, `nix build --no-link .#checks.x86_64-linux.deployment-scripts`
  (incluant ShellCheck et les tests Python de déploiement), et `actionlint` sur
  `.github/workflows/ci.yml` : **réussis**.
- Un flake minimal isolé, évalué avec Nix 2.34.8, a reproduit deux commits d'arbre
  identique avec `rev`, `lastModified` et `drvPath` différents. Il démontre la limite
  d'une preuve par arbre ; il ne prétend pas que les systèmes actuels changent avec
  ces métadonnées.
- `git diff --check` : **réussi**. Aucun système NixOS de la flotte n'a été reconstruit
  ni activé pour cette correction de workflow.
