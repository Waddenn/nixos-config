# Liaison directe Caddy → Classeur

Exception OPNsense ciblée : `192.168.40.105:41641` →
`192.168.1.159:41641`, UDP IPv4 sur `opt4`, avec état.
Elle autorise uniquement le transport chiffré Tailscale. Aucun accès LAN
HTTP, SSH ou PostgreSQL, changement NAT, ACL Tailscale ou proxy applicatif.
Les deux démons doivent conserver le port 41641 et les adresses observées.

Sur OPNsense, utiliser un répertoire de transaction neuf sous
`/root/classeur-direct/`. Préparer avec `configure.php prepare`, rendre la
candidate avec `../hardening/render-filter.php`, vérifier `pfctl -nf`, et
vérifier que le diff natif ajoute exactement la règle déclarée. Marquer alors
la transaction `validated`. Appliquer avec `configure.php apply`, puis
`configctl filter reload`. Ne pas recharger un fichier PF incomplet à la main.

Programmer avant activation un retour arrière différé : `configure.php rollback`
puis `configctl filter reload`, sauf marqueur `confirmed` créé après les contrôles.
La restauration retire seulement la règle exacte et conserve les changements
concurrents. Les fichiers XML privés restent sur le pare-feu, jamais dans Git.

Contrôler `tailscale ping` et `tailscale status` depuis les deux hôtes : `direct`
doit remplacer `relay "par"`. Comparer un transfert d'image non mis en cache,
puis vérifier santé publique, refus sans token d'origine, port UDP et règles
persistantes. Cette exception ne remplace pas la politique du tailnet.
