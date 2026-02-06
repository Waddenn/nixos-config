# SOPS + NixOS (ce repo)

## Fichiers clés
- `.sops.yaml`: liste des clés `age` autorisées.
- `secrets/secrets.yaml`: secrets chiffrés SOPS.
- Modules Nix: lisent les secrets via `config.sops.secrets.<name>.path`.

## Flux minimal
1. Ajouter la clé `age` du host dans `.sops.yaml`.
2. Rekey du fichier secrets:
```bash
nix shell nixpkgs#sops --command sops updatekeys -y secrets/secrets.yaml
```
3. Ajouter/mettre à jour un secret:
```bash
nix shell nixpkgs#sops --command sops secrets/secrets.yaml
```
4. Déployer le host concerné.

## Comment obtenir la clé `age`
- Cas host NixOS (ton cas): convertir la clé SSH host en clé `age` publique.
```bash
ssh nixos@<host> 'cat /etc/ssh/ssh_host_ed25519_key.pub' \
  | nix shell nixpkgs#ssh-to-age --command ssh-to-age
```
- Résultat: une clé `age1...` à ajouter dans `.sops.yaml`.
- Ensuite faire le rekey:
```bash
nix shell nixpkgs#sops --command sops updatekeys -y secrets/secrets.yaml
```

- Cas clé age dédiée (poste local):
```bash
age-keygen -o ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt
```
- La sortie `age1...` est la clé publique à mettre dans `.sops.yaml`.

## Pattern Nix à utiliser
```nix
sops.secrets.mon_secret = {
  sopsFile = ../../../secrets/secrets.yaml;
  owner = "service-user";
  group = "service-group";
  mode = "0400";
  restartUnits = ["mon-service.service"];
};
```
Puis dans la config service:
```nix
... = config.sops.secrets.mon_secret.path;
```

## Point important
Si un host n'est pas dans `.sops.yaml` (ex: `immich`), il ne pourra pas déchiffrer `secrets/secrets.yaml`, même si le secret existe.
