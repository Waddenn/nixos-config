# Accès durable Tailscale

Identité OAuth créée et vérifiée le 19 septembre 2026, après confirmation : **dev-nixos-provisioning-pilot**.
Scope **auth_keys** uniquement (la console inclut sa lecture), tag exact
**tag:nixos-pilot**. Aucun scope devices, policy_file, DNS, utilisateurs,
OAuth keys ou accès API global. Ne pas réutiliser l'ancien client OAuth `all`.

TagOwner configuré : `tag:nixos-pilot: [autogroup:admin]` aux tagOwners.
Le fragment adjacent est une fusion ciblée, jamais un remplacement de la politique.
La politique complète est maintenant versionnée dans un dépôt local privé,
voir `tailscale/README.md`.
Le grant global a été retiré : le contrôleur accède aux pilotes en TCP 22,
Caddy/Gatus aux ports applicatifs 8080/8082. Les postes administrateurs
conservent leurs droits explicites. Le tag pilote ne donne aucun droit SSH
Tailscale et ne permet pas d'administrer les autres serveurs.
L'accès SSH standard reste protégé par la clé du contrôleur et la clé hôte épinglée.
Pas d'exposition Internet/Funnel pour ces pilotes.

Le contrôleur conserve `tailscale-oauth.json` (client_id/client_secret) root:root
0600 sous `/var/lib/proxmox-prototype`, sauvegardé uniquement dans les archives
root-only sur l'autre nœud. Ce secret durable ne va ni dans le CT, ni dans Git,
ni dans le Nix store. Le script échange OAuth pour un token API d'une heure,
puis crée une auth key non réutilisable, non éphémère, préautorisée, valable
une heure, portant uniquement les tags déclarés. La clé courte transite par SSH
vers `/run`, puis est supprimée. Une relance sur un appareil déjà enrôlé ne
crée pas une autre clé. Un échec conserve la progression sans supprimer le CT.

L'expiration de l'auth key empêche les futurs enrôlements ; elle ne déconnecte
pas un appareil inscrit. Les appareils taggés ont l'expiration de node key
désactivée par défaut : surveiller/révoquer leur identité séparément.

Rotation : créer un nouveau client avec mêmes scope/tag, remplacer atomiquement
le fichier privé, tester une génération d'auth key, puis révoquer l'ancien client.
Révoquer OAuth empêche les nouvelles clés mais ne supprime pas les appareils déjà
inscrits. Pour retirer un appareil, opération explicite distincte dans Tailscale.
Ne pas lier cette révocation au retrait d'une déclaration Nix.

Client ID public : `k4oCtQm2cw11CNTRL`. Le tag et les scopes ont été vérifiés
dans la console. Le client OAuth historique avec scope `all` a été révoqué le 6 octobre 2026.

Sources : [OAuth Tailscale](https://tailscale.com/docs/features/oauth-clients),
[clés d'authentification](https://tailscale.com/docs/features/access-control/auth-keys).
