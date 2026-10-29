# Politique de tags — Shop SAS

- Une version publiée, par exemple `1.4.3`, est **immuable**. Une correction reçoit une nouvelle version ; le registre de ce TP n'impose pas techniquement cette règle, donc la CI doit refuser la réutilisation d'un tag existant.
- Les tags de travail (`candidate-<date>-<sha>`, `pr-<numéro>-<sha>`) peuvent être supprimés par la politique de rétention. `retention.sh` conserve tous les tags semver et les N tags de travail les plus récents.
- `latest` est interdit pour les déploiements : sa cible peut changer sans modification du fichier Compose et rendre un retour arrière ambigu.
- Le déploiement référence le **digest**, vérifié après le push :

```yaml
services:
  api:
    image: registry.local:5000/shopapi@sha256:759d46d70699a6c1c88bdb02ce16dd37e4191d57a167d115a11ca7512d24de05
```

L'exemple ci-dessus désigne la version validée `1.4.3`. La signature Cosign porte sur ce digest, pas sur le nom du tag. Un retag vers le même manifeste conserve la signature vérifiable ; un tag déplacé vers un autre digest exige une nouvelle signature.

Retag distant sans téléchargement dans le daemon Docker (avec l'authentification et le certificat du registre configurés côté Skopeo) :

```bash
skopeo copy --all --preserve-digests \
  docker://registry.local:5000/shopapi:1.4.2 \
  docker://registry.local:5000/shopapi:candidate-20261026
```

Le test de ce TP donne le même digest `sha256:2e6424…` pour les deux tags. L'API Registry v2 supprime un **manifeste par digest** : une suppression peut faire disparaître plusieurs tags. `registry-api.sh delete` refuse donc un digest partagé, sauf `--force-shared` ; `retention.sh` le conserve si un des tags est protégé.
