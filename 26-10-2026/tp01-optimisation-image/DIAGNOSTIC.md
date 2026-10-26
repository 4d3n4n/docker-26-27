# Diagnostic de l'image historique `shopapi:legacy`

Mesures effectuées le 26/10/2026 avec Docker Desktop (architecture arm64), avant la modification du Dockerfile. Les commandes Docker ci-dessous s'exécutent depuis `starter/shopapi`. Les valeurs des secrets ne sont volontairement pas reproduites. Pour les couches, la commande utilisée est `docker history --human=false --format '{{.Size}} {{.CreatedBy}}' shopapi:legacy | rg -v 'DATABASE_URL|postgres://'` : elle masque la couche qui contient l'identifiant.

## Taille et performance

| Problème | Preuve (commande → sortie) | Impact |
| --- | --- | --- |
| 1. Image trop grande | `docker image inspect shopapi:legacy --format '{{.Size}}'` → `1064233879` octets (1 064 Mo). | Dépasse le plafond de 200 Mo ; transferts et stockage du registre coûteux. |
| 2. Outils de développement et d'administration dans la production | `docker run --rm shopapi:legacy sh -c 'for x in vim git curl wget python3; do command -v "$x"; done'` → `/usr/bin/vim`, `/usr/bin/git`, `/usr/bin/curl`, `/usr/bin/wget`, `/usr/bin/python3`. La commande `docker history` filtrée ci-dessus → couche `apt-get install -y curl wget …` de `379478016` octets. | Grossit l'image et ajoute des paquets à maintenir. |
| 3. Node installé sur Ubuntu via deux couches supplémentaires | La commande `docker history` filtrée ci-dessus → couche `apt-get update` de `80674816` octets, couche `apt-get install -y nodejs` de `173338624` octets. | Base et installation lourdes ; reconstruction lente et plus de couches à transférer. |
| 4. Dépendances de développement installées en production | `docker run --rm shopapi:legacy sh -c 'test -d /app/node_modules/nodemon && echo nodemon; test -d /app/node_modules/eslint && echo eslint'` → `nodemon`, `eslint`. Le Dockerfile historique contient aussi `RUN npm install -g nodemon`. | Espace occupé inutilement et dépendances supplémentaires à surveiller. |
| 5. Cache npm conservé dans l'image | `docker run --rm shopapi:legacy du -sh /root/.npm` → `34M /root/.npm`. | Ajoute des archives npm sans utilité à l'exécution. |
| 6. Cache Docker invalidé par toute modification de source | Dockerfile historique : `COPY . /app` précède `RUN npm install`. Dans une copie temporaire, après un commentaire ajouté à `src/server.js`, `docker build --progress=plain` montre `COPY . /app`, puis `RUN npm install` et `added 222 packages` ; temps total `real 4.78`. | Chaque changement de source relance l'installation des dépendances. |
| 7. Résolution des dépendances non figée | Au départ, `git ls-files package-lock.json` ne retournait rien ; le Dockerfile historique utilisait `RUN npm install` avec des versions `^` dans `package.json`. | Deux builds peuvent résoudre des versions de paquets différentes. |

## Sécurité

| Problème | Preuve (commande → sortie) | Impact |
| --- | --- | --- |
| 8. Processus root | `docker run --rm shopapi:legacy id` → `uid=0(root) gid=0(root)`. | Augmente les privilèges disponibles en cas de compromission. |
| 9. Identifiant de base de données embarqué | `docker run --rm shopapi:legacy sh -c 'env \| grep -q DATABASE_URL && echo DATABASE_URL_present'` → `DATABASE_URL_present`. Le Dockerfile historique définit cette variable via `ENV`. | Secret exposé dans la configuration, l'environnement et l'historique de l'image. |
| 10. Fichiers sensibles copiés dans `/app` | `docker run --rm shopapi:legacy sh -c 'test -f /app/.env && echo .env_present; test -f /app/dump-prod-2024.sql && echo dump_present'` → `.env_present`, `dump_present`. | Le fichier d'environnement et le dump peuvent être lus par toute personne ayant accès à l'image. |
| 11. Aucun filtrage du contexte | Dans la version historique, `git ls-files .dockerignore` → sortie vide ; le Dockerfile fait `COPY . /app`. `docker run --rm shopapi:legacy ls -a /app` inclut `.env`, `.gitignore` et le dump. | Tous les fichiers locaux du contexte peuvent entrer dans l'image, y compris d'éventuels `node_modules` ou `.git`. |
| 12. Installation via script distant non figé | Dockerfile historique : `RUN curl -fsSL https://deb.nodesource.com/setup_20.x \| bash -` puis `RUN apt-get install -y nodejs`. | La chaîne d'installation dépend d'un script et de paquets qui peuvent changer entre deux builds. |

## Exploitabilité

| Problème | Preuve (commande → sortie) | Impact |
| --- | --- | --- |
| 13. Démarrage via un shell et npm | `docker image inspect shopapi:legacy --format '{{json .Config.Cmd}}'` → `["/bin/sh","-c","npm start"]`. `/usr/bin/time -p docker stop shopapi-tp01-legacy` → `real 3.12` ; `docker inspect` → `exit=137`. | Le processus applicatif ne reçoit pas correctement le signal ; Docker termine ici le conteneur de force. |
| 14. Aucun contrôle de santé | `docker image inspect shopapi:legacy --format '{{json .Config.Healthcheck}}'` → `null`. | L'orchestrateur ne peut pas distinguer un processus vivant d'une API fonctionnelle. |
| 15. Métadonnées OCI applicatives absentes | `docker image inspect shopapi:legacy --format '{{json .Config.Labels}}'` → `{"org.opencontainers.image.version":"22.04"}` : seule la version héritée d'Ubuntu apparaît. | Impossible de retrouver directement version, révision Git et dépôt source de l'application. |
| 16. Tests absents du build | Dockerfile historique : aucune étape `npm test` ni `npm run lint` ; `docker history shopapi:legacy` ne comporte qu'un `RUN npm install` applicatif. | Une image peut être publiée sans avoir exécuté les vérifications prévues. |

L'analyse des couches a été faite avec `docker history` et `docker inspect`. La revue automatique a refusé Dive en conteneur avec le socket Docker monté, car ce montage donnerait un contrôle étendu au conteneur tiers. Elle a aussi refusé de transmettre le Dockerfile historique, qui contient un identifiant, au conteneur Hadolint. Ces deux opérations n'ont pas été exécutées.
