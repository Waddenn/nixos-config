# Rotation des mots de passe Authelia

Les métadonnées des comptes (nom, adresse et groupes) restent déclarées dans
`hosts/authelia/default.nix`. Chaque compte référence un secret SOPS distinct via
`hashSecret`. Le hash Argon2id n'est injecté dans la base utilisateurs qu'à
l'activation, dans un template SOPS sous `/run/secrets-rendered/`; il n'entre donc
plus dans Git ni dans le Nix store.

## Limite de la migration

Les anciens hashes ont déjà été publiés dans l'historique Git. Les chiffrer dans
le commit courant empêche de nouvelles expositions, mais ne retire aucune copie
historique. Il faut donc changer les mots de passe des comptes `admin` et `tom`
après la mise en production de cette migration. Cette rotation invalide la valeur
historique, même si elle reste accessible dans d'anciens commits ou clones.

Réécrire l'historique public n'est pas nécessaire après la rotation et casserait
les clones et références existants. Si une purge est tout de même exigée, elle
doit être traitée comme une opération séparée et coordonnée avec tous les clones.

## Procédure de rotation

1. Générer un nouveau hash sans placer le mot de passe ni le hash dans le shell,
   l'historique du terminal ou un ticket :

   ```bash
   nix shell nixpkgs#authelia --command authelia crypto hash generate argon2
   ```

2. Ouvrir le fichier chiffré et remplacer uniquement le secret du compte :

   ```bash
   nix shell nixpkgs#sops --command sops secrets/secrets.yaml
   ```

   Les clés attendues sont `authelia_user_admin_password_hash` et
   `authelia_user_tom_password_hash`. Ne jamais ajouter leur valeur à un fichier
   Nix, à la description d'une PR ou aux logs de CI.

3. Vérifier localement avant publication :

   ```bash
   python3 -m unittest discover -s tests -p 'test_*.py'
   nix fmt -- --check
   nix build .#nixosConfigurations.authelia.config.system.build.toplevel --dry-run
   ```

4. Suivre ensuite le processus normal : PR prête, CI complète verte, fusion, puis
   CI verte du commit exact de `main`. Le déploiement reste une action séparée et
   explicitement autorisée.

5. Après activation autorisée, tester la connexion de chaque compte avec son
   nouveau mot de passe et son second facteur, puis vérifier `authelia.service` et
   la sonde publique. Ne supprimer aucune identité ni aucun groupe pendant la
   rotation.

## Ajout d'un compte

Ajouter ses métadonnées avec un nom de secret unique :

```nix
declarativeUsers.alice = {
  displayname = "Alice";
  hashSecret = "authelia_user_alice_password_hash";
  email = "alice@example.net";
  groups = ["users"];
};
```

Ajouter ensuite la clé correspondante dans `secrets/secrets.yaml` avec SOPS. Une
assertion Nix interdit de partager le même secret entre deux comptes.
