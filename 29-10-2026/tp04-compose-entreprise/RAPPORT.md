# TP04 — Stack Compose Shop SAS

Le diagnostic du fichier initial est dans [DIAGNOSTIC.md](DIAGNOSTIC.md). Les applications reprises des TP01 et TP02 sont dans `apps/` ; seuls les fichiers nécessaires au build ont été copiés, sans `.env` ni dump SQL du TP01.

## Fichiers livrés

- `compose.yml` : base commune, projet `shop`, réseaux `front` et `back`, volumes nommés, healthchecks, secrets, routage et profils.
- `compose.override.yml` : développement, chargé automatiquement par Compose, avec source montée et `node --watch`, debug lié à `127.0.0.1`.
- `compose.prod.yml` : images du registre du TP03, deux API, limites de ressources et protections du système de fichiers.
- `.env.example`, `Makefile`, `smoke-test.sh`, `db/init.sql`, `migrations/002-add-sku.sql` et `bin/init-local.sh`.

## Démarrage

Depuis ce dossier :

```bash
make up                         # initialise les secrets, construit et attend la stack dev saine
make test                       # /ready, cache Redis, commande confirmée en base
make migrate M=002-add-sku.sql  # migration ponctuelle (profil ops)
docker compose --profile tools up -d --wait adminer
docker compose --profile tools stop adminer
```

`bin/init-local.sh` crée un mot de passe PostgreSQL aléatoire dans `secrets/db_password.txt`, un `pip.conf` local pour le build du worker et copie `.env.example` vers `.env`. `secrets/` et `.env` sont ignorés par Git. PostgreSQL reçoit `POSTGRES_PASSWORD_FILE`. L'API et le worker lisent le même fichier de secret au démarrage, construisent `DATABASE_URL`, puis lancent leur programme avec `exec`, sans modification du code des TP01/TP02. Le mot de passe n'apparaît pas dans le YAML résolu ni dans l'environnement déclaré par Compose ; l'URL est toutefois présente dans l'environnement des processus applicatifs, conformément à leur interface existante.

Le réseau `back` est `internal: true`. PostgreSQL, Redis et le worker n'ont aucun port publié ; seul le proxy publie le port 80 dans la base et en prod. En dev, les ports 3000, 5432 et le dashboard Traefik sont publiés sur `127.0.0.1` uniquement. Le port 8080 était déjà utilisé par `exo5-adminer` sur cette machine : le `.env` local, non versionné, définit `TRAEFIK_DASHBOARD_PORT=8082`. L'exemple versionné garde 8080.

L'API est accessible par `http://api.localhost/`. Le profil `tools` rend Adminer accessible par `http://adminer.localhost/` lorsqu'il est lancé. Le profil `ops` fournit `migrate`, conteneur ponctuel. Le mot de passe est injecté au client `psql` depuis `/run/secrets/db_password` et la migration refuse un nom de fichier invalide.

## Mode production

Le registre TLS du TP03 doit être démarré et contenir `shopapi:1.4.3` et `shop-worker:1.4.3`. `REGISTRY` et `VERSION` viennent de `.env`. Sur la machine de validation, l'API était déjà publiée par le TP03 ; l'image worker a été construite et publiée dans **le registre Docker local** `127.0.0.1:5000`, puis les deux images ont été effectivement tirées par Compose. Aucun push Git n'a été effectué.

```bash
make prod-up
make test
make prod-migrate M=002-add-sku.sql
docker compose -f compose.yml -f compose.prod.yml ps
```

La surcharge prod supprime `build` avec `!reset`, impose `pull_policy: always` et définit deux réplicas de l'API. `docker compose -f compose.yml -f compose.prod.yml config` ne contient aucune clé `build` pour l'API ou le worker et n'expose que `proxy:80`. L'API, le worker et Traefik utilisent `read_only`, un `tmpfs` pour `/tmp`, `cap_drop: [ALL]`, `no-new-privileges` et des plafonds CPU/mémoire. PostgreSQL et Redis gardent leurs chemins de données inscriptibles sur des volumes nommés ; ils ont aussi des plafonds CPU/mémoire. Tous les services permanents ont des logs JSON rotatifs et `restart: unless-stopped`.

Le TP demandait `traefik:v3.1`. Son fournisseur Docker échoue contre le Docker Engine 29.8.2 de cette machine (API minimale 1.40), même avec une version d'API explicitement fixée. L'image utilisée est donc `traefik:v3.6.16`, version précise dont le fournisseur Docker prend en charge ce minimum. Voir la [note de migration Traefik](https://doc.traefik.io/traefik/migrate/v3/) et la [référence de l'API Docker](https://docs.docker.com/reference/api/engine/). Le montage en lecture seule de la socket Docker permet à Traefik de lire les labels ; il ne constitue pas un filtrage des opérations de l'API Docker. Ce point pourra être renforcé au TP08.

## Vérifications

| Contrôle | Résultat |
| --- | --- |
| `docker compose config` dev et prod | Valides ; en prod `build` absent, seul le port 80 est publié. |
| `make up` / `make prod-up` | Tous les services permanents `healthy` avec `--wait`. |
| `make test` en dev et en prod | `/ready` confirme PostgreSQL et Redis, second `/products` renvoie `X-Cache: HIT`, commande `confirmed` par le worker. |
| Source API touchée en dev | `node --watch` a journalisé `Restarting 'src/server.js'` et l'API est restée saine. |
| Adminer avec profil `tools` | HTTP 200 sur `adminer.localhost`, puis service arrêté. |
| Migration | `002-add-sku.sql` appliquée ; seconde exécution sans doublon. |
| Prod | Deux API saines ; huit requêtes successives alternent entre `172.24.0.3:3000` et `172.24.0.4:3000` dans les logs d'accès Traefik. |
| `up --scale api=3`, puis `up` | Trois réplicas, puis retour à deux selon `deploy.replicas`. |
| Protections réellement appliquées | `read_only=true`, `cap_drop=[ALL]`, `no-new-privileges`, 256 Mio et 0,5 CPU sur API/worker ; réseau `shop_back` interne. |

Le `Makefile` construit directement les images via `docker build` avant `docker compose up --no-build --wait`. Sur cette installation, le chemin du cours contient un accent Unicode dont les deux normalisations ne correspondent pas dans les permissions de lecture demandées par Buildx Bake ; `docker compose up --build` échoue alors avant de construire. Le build direct a exécuté les tests intégrés aux Dockerfiles et permet ensuite à Compose de démarrer la stack normalement.
