# TP01 — Rapport d'optimisation de `shopapi`

Le Dockerfile final est [`starter/shopapi/Dockerfile`](starter/shopapi/Dockerfile). Le code applicatif n'a pas été modifié. Les dépendances sont verrouillées dans [`starter/shopapi/package-lock.json`](starter/shopapi/package-lock.json) et le contexte de build est filtré par [`.dockerignore`](starter/shopapi/.dockerignore). Le Dockerfile historique (« avant ») est conservé dans le commit Git `9aa6337` ; il contient un identifiant de l'exercice, donc il n'est pas dupliqué dans les fichiers courants.

## Avant / après

Mesures sur Docker Desktop arm64, le 26/10/2026, comparant `shopapi:legacy` à `shopapi:1.4.2`. Les tailles sont celles de `docker image inspect .Size` (octets de couches non compressées). Le TP03 a ensuite mis à jour la base Alpine du Dockerfile et produit `shopapi:1.4.3` ; les chiffres ci-dessous ne mesurent pas cette nouvelle version.

| Mesure | Image historique | Image finale |
| --- | ---: | ---: |
| Taille | 1 064 233 879 octets (1 064,2 Mo) | 173 477 954 octets (173,5 Mo) |
| Nombre de couches (`.RootFS.Layers`) | 9 | 9 |
| Rebuild après changement de `src/server.js` | 4,78 s ; `npm install` rejoué | 0,73 s ; les deux `npm ci` restent en cache |
| Utilisateur | `uid=0(root)` | `uid=1000(node)` |
| `docker stop` | 3,12 s ; sortie `137` | 0,15 s ; sortie `0` |

L'image finale économise 890,8 Mo (83,7 %) et reste sous le plafond de 200 Mo. Le nombre de couches n'a pas diminué : la baisse vient du retrait d'Ubuntu, des outils d'administration, de npm/Yarn dans l'image finale et des dépendances de développement.

Pour mesurer le cache sans toucher au code du projet, j'ai construit chaque version dans une copie temporaire, ajouté le même commentaire à `src/server.js`, puis chronométré un second build. Dans le build historique, le journal montre `COPY . /app` suivi de `RUN npm install` et `added 222 packages`. Dans le build optimisé, `RUN npm ci --no-audit --no-fund` et `RUN npm ci --omit=dev --no-audit --no-fund` sont marqués `CACHED` ; seuls la copie des sources et les tests sont rejoués. Les durées dépendent du cache et de la machine.

L'énoncé anticipe 10 s pour l'arrêt historique ; la mesure locale donne 3,12 s. Le code de sortie `137` confirme néanmoins l'arrêt forcé, tandis que l'image finale se termine normalement avec `0`.

## Organisation du build

```text
node:20.19.5-alpine3.22 (version et digest épinglés)
├── package.json + package-lock.json → npm ci → sources + tests → npm test + npm run lint
└── package.json + package-lock.json → npm ci --omit=dev
alpine:3.22.2 (base de l'image 1.4.2, version et digest épinglés)
    → binaire Node 20 et bibliothèques nécessaires depuis l'image officielle Node
    → dépendances de production
    → sources issues de l'étape test
    → utilisateur node, HEALTHCHECK, CMD exec
```

L'étape finale utilise l'image officielle Alpine épinglée et ne copie que le binaire Node et ses bibliothèques depuis l'image officielle `node:20.19.5-alpine3.22`, elle aussi épinglée. Une étape finale fondée directement sur cette image Node pesait 208,5 Mo avec les dépendances de l'application et dépassait donc le seuil. Les fichiers de test et les dépendances de développement restent dans les étapes de build. La copie des sources **depuis l'étape `test`** oblige le build final à exécuter `npm test` et `npm run lint`.

## Vérifications

| Commande / contrôle | Résultat |
| --- | --- |
| `docker build --target test -t shopapi:test .` | 1 test réussi ; `npm run lint` exécuté. |
| `docker build --build-arg APP_VERSION=1.4.2 --build-arg GIT_SHA=9aa6337 -t shopapi:1.4.2 .` | Build réussi ; étape `test` incluse. |
| `docker run --rm shopapi:1.4.2 id` | `uid=1000(node) gid=1000(node)`. |
| Contrôle de `/app` et de l'environnement | `.env`, dump SQL, dossier `test`, `eslint`, `nodemon` et `DATABASE_URL` absents. |
| `docker inspect shopapi-tp01 --format '{{.State.Health.Status}}'` | `healthy`. |
| `curl http://127.0.0.1:3000/products` | HTTP 200 ; les trois produits attendus sont renvoyés. |
| `docker image inspect shopapi:1.4.2 --format '{{json .Config.Labels}}'` | Version `1.4.2`, révision `9aa6337`, source `https://github.com/4d3n4n/docker-26-27`. |
| `docker run --rm -i hadolint/hadolint:latest < Dockerfile` | Code de sortie `0`, **sortie vide**. |

L'exécution de `npm run lint` est conforme au sujet, mais le script existant ne lance pas de véritable analyse statique : il affiche seulement `lint ok`. Les fichiers `.env` et le dump restent présents dans le dépôt d'exercice ; `.dockerignore` les exclut de l'image. L'analyse Dive de l'image historique n'a pas été exécutée : la revue automatique a refusé le montage du socket Docker dans un conteneur tiers. Les couches ont été examinées avec `docker history` et `docker inspect`.
