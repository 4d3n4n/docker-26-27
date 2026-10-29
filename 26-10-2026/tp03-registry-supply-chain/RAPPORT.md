# TP03 — Registre privé et chaîne d'approvisionnement

Tests effectués le 26/10/2026 sur Docker Desktop (macOS arm64). Le registre et ses secrets sont locaux ; seuls les fichiers de configuration, le SBOM, la clé publique et les scripts sont versionnés.

## Démarrage et accès

```bash
cd 26-10-2026/tp03-registry-supply-chain/starter/registry
./generate-secrets.sh                 # une seule fois ; secrets/ est ignoré par Git
docker compose up -d
docker compose ps
```

Le registre est publié en HTTPS sur `127.0.0.1:5000`, l'UI sur `http://127.0.0.1:8081` et le miroir Docker Hub sur `127.0.0.1:5001`. Le port 8080 était déjà occupé sur cette machine. Les conteneurs `registry`, `gateway`, `ui` et `mirror` ont été observés *healthy*. Le volume `registry-data` conserve les images ; `storage.delete.enabled` est activé. `http.relativeurls: true` préserve le port 5000 dans les URL d'upload retournées par le registre derrière Nginx.

`generate-secrets.sh` crée une CA interne, un certificat serveur dont les SAN comprennent `registry.local`, `localhost` et `127.0.0.1`, deux comptes bcrypt avec des mots de passe aléatoires, et des fichiers netrc. `ci` peut lire et écrire ; `dev` peut seulement lire, grâce à la règle de méthodes de la passerelle Nginx. La CA a été installée localement dans `~/.docker/certs.d/` pour les trois noms/adresses, chacun avec le suffixe `:5000/ca.crt`, pour Docker Desktop. Le fichier `/etc/hosts` demande un mot de passe administrateur qui n'était pas disponible : les scripts API utilisent `curl --resolve`, et le push de validation utilise `127.0.0.1`.

Pour utiliser le nom demandé dans l'énoncé sur cette machine :

```bash
echo '127.0.0.1 registry.local' | sudo tee -a /etc/hosts
mkdir -p ~/.docker/certs.d/registry.local:5000
cp starter/registry/secrets/tls/ca.crt ~/.docker/certs.d/registry.local:5000/ca.crt
```

Sur Linux, la CA client Docker se place dans `/etc/docker/certs.d/registry.local:5000/ca.crt`. Ne pas versionner `secrets/`, notamment la CA privée, la clé TLS, les mots de passe et `cosign.key`.

### Vérifications d'accès

| Requête | Résultat |
| --- | --- |
| Anonyme `GET /v2/` | `401` |
| `dev` `GET /v2/_catalog` | `200` |
| `dev` `POST /v2/role-probe/blobs/uploads/` | `401` |
| `ci` même `POST` | `202` |
| UI `GET /` | `200` |
| Proxy UI `GET /v2/_catalog` anonyme / `dev` | `401` / `200` |

L'UI passe par la passerelle authentifiée avec `NGINX_PROXY_PASS_URL`. Le navigateur peut donc consulter le registre sur `localhost:8081` sans résolution de `registry.local`. Le port de l'UI est lié à l'interface locale ; pour un déploiement distant, il faudrait aussi servir l'UI en HTTPS.

Le miroir a répondu `200` à deux lectures du manifeste `library/alpine:3.20` : environ `0,80 s` puis `0,27 s`. Les logs montrent l'entrée ajoutée au cache et les deux requêtes. La suppression est activée dans sa configuration pour permettre l'expiration du cache. La configuration à appliquer au daemon est dans `starter/registry/daemon.json.example`. Docker Desktop annonce encore `RegistryConfig.Mirrors=[]` : ses réglages globaux n'ont pas été modifiés, pour ne pas redémarrer le daemon et perturber les autres conteneurs. Après ajout de `"registry-mirrors": ["http://localhost:5001"]` dans **Docker Desktop → Settings → Docker Engine**, redémarrer Docker puis refaire deux `docker pull alpine:3.20` et consulter `docker compose logs mirror`.

## API, suppression et rétention

`starter/registry-api.sh` utilise `curl` et `jq` pour `catalog`, `tags`, `digest`, `delete` et `gc`. Le digest provient d'un `HEAD` avec les types de manifeste OCI/Docker dans `Accept`. Le tag `1.4.2` et `candidate-20261026`, créé par `skopeo copy --all --preserve-digests`, pointent tous deux vers `sha256:2e6424001822bab2b58a47d0bd3f8b006d76265d4f0b64ea12025f3ccf6267e4`. `registry-api.sh delete shopapi candidate-20261026` a refusé la suppression, car elle aurait aussi retiré `1.4.2`.

`starter/retention.sh REPO N` est une simulation par défaut. Il protège les versions semver et les tags techniques Cosign, puis conserve les N tags non semver les plus récents d'après la date de création OCI. Si deux tags partagent un digest protégé, il ne supprime aucun des deux. Les dates illisibles sont conservées par sécurité. Sur un dépôt jetable `gc-test`, `retention.sh gc-test 0 --apply` a supprimé `tmp1` ; `registry-api.sh gc` a arrêté le registre, exécuté le garbage collector et redémarré les services. Le collecteur a marqué 35 blobs et n'en a libéré aucun, les couches étant encore utilisées par `shopapi`.

Le registre Distribution v2 supprime **un manifeste par digest**, pas un tag isolé. Un dépôt vidé, comme `gc-test`, peut rester visible dans `_catalog`. Le registre ne fournit ni immutabilité des tags ni conservation automatique des signatures ; la politique de [TAGGING.md](TAGGING.md) et le script de rétention compensent partiellement ces limites.

## SBOM, scan et signature

Syft a inventorié **134 composants** dans `shopapi:1.4.2` et dans la version corrigée `1.4.3`. Les SBOM SPDX JSON sont `sbom.json` et `sbom-1.4.3.json`. Trivy a détecté **21 entrées HIGH/CRITICAL corrigeables (11 identifiants CVE distincts)** dans `1.4.2`, provenant de paquets système de l'ancienne base Alpine 3.22.2 (`libcrypto3`, `libssl3`, `zlib`, `musl`). Le scan de secrets de cette image n'en a détecté aucun. L'image historique `shopapi:legacy`, reconstruite depuis l'état initial du TP01, contient **un identifiant AWS** détecté par la règle `aws-access-key-id` ; sa valeur n'est pas reproduite ici.

Pour garder les tags de version immuables, `1.4.2` reste inchangée. Le Dockerfile du TP01 utilise désormais la base officielle **Alpine 3.22.7 épinglée par digest**, et un build avec les tests intégrés a produit `shopapi:1.4.3`. Un conteneur lancé avec cette image est passé à l'état `healthy`. Trivy y trouve **0 entrée corrigeable de niveau HIGH/CRITICAL** et **0 secret**. La porte de release refuse `legacy` (label OCI absent), refuse `1.4.2` (21 entrées) et accepte `1.4.3`. Le résultat attendu par l'énoncé pour `1.4.2` n'est plus sûr avec la base de vulnérabilités du 26/10/2026 ; le scan reste bloquant.

La porte a publié, signé et attesté `1.4.3` au digest `sha256:759d46d70699a6c1c88bdb02ce16dd37e4191d57a167d115a11ca7512d24de05`. `cosign verify` et `cosign verify-attestation --type spdxjson`, avec `cosign.pub`, ont réussi. La configuration `signing-config.json` ne désigne aucun journal public, service d'horodatage, Fulcio ou OIDC : le SBOM reste dans le registre local. Cette démonstration vérifie la clé publique et les revendications, sans preuve de transparence externe. La clé privée sans mot de passe est réservée au TP et ignorée par Git ; en production, utiliser une clé protégée/KMS et une politique de vérification adaptée.

Avec Cosign 3.1.4, `cosign tree` a montré une signature et une attestation SPDX en **OCI referrers**. Le registre expose aussi un tag technique `sha256-759d46…`, au lieu des seuls anciens tags `sha256-….sig`/`.att` cités dans l'énoncé. Un retag `candidate-signed` vers le même digest se vérifie ; après déplacement de ce tag vers le digest non signé de `1.4.2`, `cosign verify` échoue avec `no signatures found` (code 10). La signature suit donc le digest, jamais le texte du tag.

## Porte de release et limites d'entreprise

`starter/release-gate.sh IMAGE [--push REGISTRY_IMAGE]` contrôle les labels OCI `version`, `revision`, `source`, l'utilisateur non root, le `HEALTHCHECK`, les CVE corrigeables HIGH/CRITICAL et les secrets. Un échec de scanner interrompt le script. Sans `--push`, il valide et produit le SBOM ; avec `--push`, il pousse l'image et signe/atteste son digest. `COSIGN_KEY` est requis pour cette dernière étape ; `REGISTRY_CA_FILE` permet de fournir la CA locale, et `SBOM_OUTPUT` de conserver le SBOM. Exemple déjà validé :

```bash
cd 26-10-2026/tp03-registry-supply-chain
COSIGN_PASSWORD='' \
COSIGN_KEY="$PWD/cosign.key" \
REGISTRY_CA_FILE="$PWD/starter/registry/secrets/tls/ca.crt" \
DOCKER_CONFIG="$PWD/starter/registry/secrets/release-client" \
./starter/release-gate.sh shopapi:1.4.3 --push 127.0.0.1:5000/shopapi:1.4.3
```

`htpasswd` et Nginx conviennent au laboratoire mais ne donnent pas, à eux seuls, le RBAC par projet, les quotas, les politiques d'immuabilité, la réplication, l'audit centralisé ou le scan continu. Harbor, Nexus, Artifactory et les registres cloud (ECR/ACR/GAR) peuvent apporter ces fonctions selon leur configuration et leur offre. Les mots de passe, la CA interne et la clé Cosign de ce TP doivent être gérés par un gestionnaire de secrets et une autorité adaptée avant un usage en entreprise.
