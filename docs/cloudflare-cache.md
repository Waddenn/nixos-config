# Cache Cloudflare de hexaflare.net

État appliqué et vérifié le 7 octobre 2026. Ces réglages sont gérés dans le
tableau de bord Cloudflare ; ce document ne les déploie pas via NixOS.

## Réglages actifs

- Smart Tiered Cache : activé dans le forfait **Smart Shield gratuit**. État
  confirmé par l'API `tiered_cache_smart_topology_enable = on`.
- Argo Smart Routing, Cache Reserve, Regional Tiered Cache et Health Checks
  payants : désactivés. Connection Reuse est déjà toujours actif.
- Une règle de cache : **Authelia - public versioned JS and CSS**,
  identifiant `e7774b0122fc4a86b13506d1fba02851`.

Expression de la règle :

```text
(http.host eq "auth.hexaflare.net" and http.request.method eq "GET" and http.request.uri.query eq "" and not any(http.request.headers.names[*] eq "cookie") and not any(http.request.headers.names[*] eq "authorization") and not http.request.uri.path contains ".." and not http.request.uri.path contains "%" and ((http.request.uri.path wildcard "/static/js/*.*.js") or (http.request.uri.path wildcard "/static/css/*.*.css")))
```

Actions : éligible au cache ; Edge TTL de **86400 secondes**, en ignorant le
Cache-Control d'origine ; statut HTTP **>= 201 : No store** ; Browser TTL :
**Respect origin TTL**. Les autres réglages de la règle restent par défaut.

Les fichiers visés portent une version dans leur nom. Les pages HTML, API,
requêtes avec paramètres, cookies ou Authorization ne reçoivent pas cette
surcharge. Leur comportement de cache habituel est conservé : ceci ne crée pas
une règle globale de bypass pour toutes les requêtes avec cookies.

## Vérifications effectuées

Avant le changement, les JS Authelia étaient systématiquement `REVALIDATED`.
Après propagation et remplissage, les fichiers suivants répondent `200 HIT`,
avec un Age qui progresse et sans Set-Cookie :

- `/static/js/index.BWFC4OSV.js`
- `/static/js/jsx-runtime.D3jfb0Ew.js`
- `/static/css/index.DtbinVJv.css`

Les deux JS ont le même SHA-256 qu'avant le changement. Le CSS conserve le
même SHA-256 sur les trois GET effectués après le changement.

Les six dernières mesures sur ces fichiers étaient comprises entre 38 et
62 ms jusqu'au premier octet, dont cinq HIT entre 38 et 54 ms. Cela confirme
le fonctionnement du cache, sans garantir la même latence pour tous les visiteurs.
Le navigateur respecte le `max-age=0` d'origine pour ces fichiers ; la durée
de 24 heures concerne le cache Cloudflare.

Les fichiers versionnés d'Immich, Home Assistant, Jellyseerr et Bitwarden
étaient déjà HIT avant l'intervention et n'ont reçu aucune règle supplémentaire.
Les contrôles finaux confirment :

| URL | HTTP | Cache |
| --- | --- | --- |
| `auth.hexaflare.net/` | 200 | DYNAMIC |
| `auth.hexaflare.net/api/health` | 200, no-store | DYNAMIC |
| `bitwarden.hexaflare.net/api/sync` | 401 sans authentification | DYNAMIC |
| `immich.hexaflare.net/api/server/ping` | 200 | DYNAMIC |
| `homeassistant.hexaflare.net/api/` | 401 sans authentification | DYNAMIC |
| `jellyseerr.hexaflare.net/login` | 200, private/no-store | DYNAMIC |
| `jellyseerr.hexaflare.net/api/v1/status` | 200 | DYNAMIC |
| `codex.hexaflare.net/` | 302 vers Authelia | DYNAMIC |

## Retour arrière

Dans Caching > Cache Rules, désactiver uniquement la règle Authelia ci-dessus.
Purger ensuite par URL les fichiers publics concernés si le retour immédiat
aux directives d'origine est nécessaire. Ne pas utiliser Purge Everything.
Dans Speed > Smart Shield, désactiver Smart Tiered Cache pour retrouver
la topologie précédente. Aucun déploiement NixOS n'est nécessaire.

Pour contrôler un fichier après remplissage, utiliser un GET (pas seulement
HEAD), regarder `CF-Cache-Status` et `Age`, puis revérifier une page HTML et une
API. Ne jamais étendre le TTL forcé aux pages de connexion ou aux données privées.

Documentation : [Cache Rules](https://developers.cloudflare.com/cache/how-to/cache-rules/settings/)
et [Smart Tiered Cache](https://developers.cloudflare.com/smart-shield/configuration/smart-tiered-cache/).
