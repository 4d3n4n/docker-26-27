# Exercice Docker #2

Déployer, au moyen de Docker, une image du jeu 2048:

* Trouver dans le registre d'images de conteneur public DockerHub, une image compatible du jeu 2048
* Récupérer l'image localement
* Lancer un conteneur basé sur l'image de l'application (faire en sorte que celle-ci soit disponible au port hôte 8080, ou 8090 si non disponible)
* Naviguer, via le navigateur de l'ordinateur (pas via le conteneur) vers http://localhost:8080 et faire en sorte de voir l'application

---

Result  CLI:
```bash
docker pull --platform linux/amd64 jgreat/2048:latest
latest: Pulling from jgreat/2048
4133f32212b2: Pull complete
fdcbcb327323: Pull complete
a3050ef5251f: Pull complete
550fe1bea624: Pull complete
d421ba34525b: Pull complete
bfbcec2fc4d5: Pull complete
Digest: sha256:f2fb81b24707bb89fee8bcf89ce57e6e7bae105320562cc4e5b2875a6424f955
Status: Downloaded newer image for jgreat/2048:latest
docker.io/jgreat/2048:latest
docker run -d --name exo2-2048 --platform linux/amd64 -p 8080:80 jgreat/2048:latest
e0c968c8e23b1c65c15f1f5fb9194f1e3f6ebe83f06770e622eec00f4e050a1f
docker stop exo2-2048
```
