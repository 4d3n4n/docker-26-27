# TP02 — BuildKit avancé : rapport

Fichiers livrés : [`starter/shop-worker/Dockerfile`](starter/shop-worker/Dockerfile), [`docker-bake.hcl`](docker-bake.hcl), [`buildkitd.toml`](buildkitd.toml), [`.dockerignore`](starter/shop-worker/.dockerignore) et [`.gitignore`](starter/shop-worker/.gitignore). Le code Python n'a pas été modifié.

## 1. Fuite de l'ancien `ARG`

L'ancien Dockerfile déclarait `ARG PIP_INDEX_URL` avec un identifiant dans la valeur par défaut et lançait `pip install` après cet `ARG`. Le précédent `pip.conf.example` contenait aussi un identifiant de démonstration ; il pointe désormais vers PyPI public. Je n'ai pas utilisé l'identifiant du sujet pour les essais.

Une image minimale temporaire construite avec `--build-arg PIP_INDEX_URL=https://demo:FAKE_TP02_TOKEN@pypi.org/simple` a donné les résultats suivants :

| Contrôle | Occurrences du marqueur fictif |
| --- | ---: |
| `docker history --no-trunc worker:leak-demo` | 2 |
| Attestation `--provenance=mode=max`, lue avec `docker buildx imagetools inspect --format '{{json .Provenance}}'` | 3 |
| `docker image inspect worker:leak-demo` | 0 |

Le risque est avéré dans l'historique de l'image, les métadonnées du cache de build et les attestations de provenance. La valeur est également visible dans le Dockerfile historique suivi par Git. **Nuance par rapport à l'énoncé :** un `ARG` seul n'apparaît pas nécessairement dans `docker image inspect` ni dans le système de fichiers de la couche finale ; il y apparaîtrait s'il était recopié dans un `ENV`, un label ou un fichier. Pendant un `RUN`, l'argument est disponible dans l'environnement du processus et des outils peuvent l'écrire dans leurs fichiers ou journaux. La [documentation Docker sur `ARG` et `ENV`](https://docs.docker.com/build/building/variables/) confirme cette différence.

Le changement de Dockerfile et d'exemple n'efface pas leurs anciennes valeurs de l'historique Git. Si ces identifiants étaient réels, il faudrait les révoquer.

## 2. Secret temporaire et image finale

Les deux installations pip utilisent `RUN --mount=type=secret,id=pipconf,target=/etc/pip.conf,required=true`. Le fichier local `starter/shop-worker/pip.conf` contient seulement l'URL publique du TP ; il est ignoré par Git. Le fichier [d'exemple](starter/shop-worker/pip.conf.example) permet de le recréer après un clone. `.dockerignore` l'exclut aussi du contexte Docker. Pour un registre privé, les identifiants iraient uniquement dans ce fichier local ou dans le magasin de secrets de la CI.

Depuis `starter/shop-worker`, le build direct validé est `docker build --secret id=pipconf,src=pip.conf -t worker:1.0 .`. La commande `docker run --rm worker:1.0 cat /etc/pip.conf` échoue avec « fichier inexistant », comme attendu.

Vérifications sur l'image produite par Bake : `docker history --no-trunc` ne contient ni `PIP_INDEX_URL` ni l'ancien hôte interne ; `/etc/pip.conf` est absent ; `pytest` et `ruff` sont absents du runtime ; le processus tourne avec `uid=999(worker)`. Le build passe **2 tests** et `ruff check worker tests`. Le worker expose `/metrics` sur le port 9100 et s'arrête avec le code `0` après `SIGTERM`.

Pour des dépendances Git privées, `RUN --mount=type=ssh` transmet un agent SSH sans copier la clé dans l'image. Pour un jeton disponible comme variable sur le runner, Buildx accepte `--secret id=TOKEN,env=TOKEN` ; le Dockerfile peut le lire via un secret mount, sans `ARG`. Voir la [documentation Docker des secrets de build](https://docs.docker.com/build/building/secrets/).

## 3. Cache de couches et cache mount pip

Le Dockerfile copie les fichiers `requirements*.txt` avant le code et utilise `--mount=type=cache,id=pip-${TARGETARCH},target=/root/.cache/pip,sharing=locked` pour chaque `pip install`. Les caches `pip-arm64` et `pip-amd64` étaient présents séparément dans `docker buildx du --verbose` (environ 15,5 et 15,8 Mo).

| Expérience sur `linux/arm64` | Temps réel | Observation |
| --- | ---: | --- |
| Premier build sur un builder neuf | 9,32 s | Images et paquets téléchargés ; 2 tests réussis. |
| Même build, sans modification | 0,94 s | Les étapes `pip install` sont `CACHED` : cache de couches. |
| `requests==2.32.3` ajouté dans une copie temporaire, avec `--no-cache` | 5,10 s | Les étapes pip sont rejouées ; le cache mount reste disponible. |
| Reconstruction contrôlée `--no-cache`, avec cache mount déjà rempli | 4,13 s | Les installations pip sont rejouées. |
| Même reconstruction, dans une copie du Dockerfile sans cache mount | 3,66 s | Aucun gain de temps mesurable du cache mount sur ce réseau rapide. |

Le cache de couches réutilise le **résultat complet** d'une instruction tant que ses entrées ne changent pas. Le cache mount conserve des fichiers pip entre exécutions de l'instruction ; il est local au builder, peut être supprimé par le nettoyage automatique et **n'est pas exporté** par `--cache-to`. `--no-cache` ignore les couches, mais ne désactive pas à lui seul le cache mount. Les journaux pip ont encore affiché des téléchargements lors du test : ce cache ne garantit ni un gain de temps constant ni un build hors ligne. Je n'ai pas exécuté `docker builder prune -f`, qui toucherait aussi les caches d'autres projets et ne garantit pas la conservation des cache mounts ; les essais `--no-cache` sont isolés. Voir la [référence Dockerfile](https://docs.docker.com/reference/dockerfile/).

## 4. Deux architectures

Le builder `shop` utilise le driver `docker-container` et annonce `linux/amd64` et `linux/arm64`. Le build direct du worker avec `--platform linux/amd64,linux/arm64 --push` a pris **11,58 s**. Les deux architectures ont passé les 2 tests et Ruff. Dans ce build sur Mac arm64, `python -m venv` a pris 1,2 s pour arm64 et 2,0 s pour amd64 ; cette dernière plateforme est émulée. Sur un runner amd64, c'est généralement le build arm64 qui subirait l'émulation. Des nœuds Buildx natifs pour chaque architecture évitent QEMU.

Après le build Bake final, `docker buildx imagetools inspect` montre un index OCI avec `linux/amd64` et `linux/arm64` pour les deux images :

| Image publiée | Digest de l'index |
| --- | --- |
| `127.0.0.1:5000/shop-worker:1.0` | `sha256:4807a3dee0f173c38fafb4bd933a886176668be4da54ae718629d2a4eb47ac80` |
| `127.0.0.1:5000/shop-api:1.0` | `sha256:da5543fff99ccd2081125ace65af9b59835e867e9f74f73726901b7f5a5c92d7` |

Chaque entrée de plateforme renvoie à un manifeste avec sa configuration et ses couches. Les entrées `unknown/unknown` observées sont des attestations, pas d'autres architectures. Avec le driver `docker-container`, un build sans exporteur ne charge pas automatiquement son image dans le moteur local : `--push`, `-o type=oci,dest=...` ou `--load` avec un magasin local compatible sont des sorties possibles. La [documentation multi-plateforme Docker](https://docs.docker.com/build/building/multi-platform/) décrit les index et les contraintes du magasin d'images. `TARGETARCH` sert ici à nommer un cache pip distinct par architecture, afin de ne pas mélanger les roues binaires.

## 5. Cache distant et Bake

`docker-bake.hcl` définit le groupe `default` (`api` + `worker`), la cible abstraite `_common` (labels, plateformes et politique de cache), `VERSION`, `GIT_SHA`, `REGISTRY`, et `worker-test` qui s'arrête à l'étape `test`. Les cibles concrètes exportent des caches distincts en `mode=max` vers `cache:api` et `cache:worker` pour éviter qu'elles s'écrasent. `docker buildx bake --print` et `docker buildx bake --print worker-test` ont confirmé le plan.

Le registre local contenait les deux caches. Un **second builder vierge** a importé `cache:worker` : les étapes pip et les tests étaient `CACHED`, avec un build terminé en **2,75 s**. Cela démontre le partage des couches entre runners. Le cache mount pip du premier builder n'a pas été transféré au second. Avec `mode=min`, l'export se limite aux couches nécessaires à l'image finale ; `mode=max` inclut aussi les étapes intermédiaires `builder` et `test`, utiles ici. Les variantes `type=gha` et `type=s3` remplacent le registre selon l'infrastructure CI, avec leurs propres identifiants et règles d'accès. Voir le [cache de registre Docker](https://docs.docker.com/build/cache/backends/registry/) et la [référence Bake](https://docs.docker.com/build/bake/reference/).

Pour reproduire depuis ce dossier :

```bash
cp starter/shop-worker/pip.conf.example starter/shop-worker/pip.conf
docker run -d --name shop-tp02-registry -p 127.0.0.1:5000:5000 registry:2
docker buildx create --name shop --driver docker-container --driver-opt network=host \
  --buildkitd-config buildkitd.toml --use --bootstrap
docker buildx bake --print
VERSION=1.0 GIT_SHA=$(git rev-parse --short HEAD) docker buildx bake worker-test
VERSION=1.0 GIT_SHA=$(git rev-parse --short HEAD) docker buildx bake --push
docker buildx imagetools inspect 127.0.0.1:5000/shop-worker:1.0
VERSION=1.0 GIT_SHA=$(git rev-parse --short HEAD) docker buildx bake \
  --set '*.platform=linux/arm64' --load
```

`--push` publie l'index multiarchitecture ; `--load` charge une plateforme localement sans remplacer le tag publié. Le registre HTTP de ce TP est limité à `127.0.0.1` ; pour une CI réelle, utiliser un registre TLS authentifié et adapter `REGISTRY` et la configuration BuildKit.

Le registre et les builders utilisés pour les mesures étaient temporaires et ont été supprimés après la vérification. Les commandes ci-dessus les recréent pour reproduire les résultats.
