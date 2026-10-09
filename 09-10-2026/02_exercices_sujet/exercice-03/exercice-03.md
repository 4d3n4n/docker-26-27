# Exercice Docker #3


Réaliser le déploiement d'un site web customisé via Docker:

* Ce site web doit être desservi via le serveur web NGINX
* Ce site web doit avoir une page d'accueil personnalisée (contenant par exemple un message du style "Hello World" ou "Exercice 03")
* Le site web doit être accessible dans l'ordinateur hôte via une adresse telle que http://localhost:8080 (par exemple)

---

Result  CLI:
```bash
cat > "/Users/adenan/Desktop/Cours/Master 2/Dév avec Docker/09-10-2026/02_exercices_sujet/exercice-03/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Exercice 03 - Docker</title>
</head>
<body>
    <h1>Exercice 03</h1>
    <p>Bonjour, je suis Adenan !</p>
    <p>Cette page est servie par NGINX dans un conteneur Docker.</p>
</body>
</html>
EOF


docker run -d --name exo3-nginx -p 8080:80 nginx:alpine
Unable to find image 'nginx:alpine' locally
alpine: Pulling from library/nginx
1efec2485f45: Pull complete
bc862a9910f5: Pull complete
858f76146c12: Pull complete
d766d06974fa: Pull complete
766d3311d5df: Pull complete
a9986cd6f37d: Pull complete
ccea4a153c59: Pull complete
943c389642fa: Pull complete
6c2852a60c45: Download complete
dffc70821449: Download complete
Digest: sha256:df221db836e1754089190208cee7eeda94f233197056426eda74a43ab1abeac2
Status: Downloaded newer image for nginx:alpine
f0f3a10b1c6543088f396b27ddba995856a8543d8cc846ad8bfbad256686e063


docker cp "/Users/adenan/Desktop/Cours/Master 2/Dév avec Docker/09-10-2026/02_exercices_sujet/exercice-03/index.html" exo3-nginx:/usr/share/nginx/html/index.html
Successfully copied 269B (transferred 2.05kB) to exo3-nginx:/usr/share/nginx/html/index.html
```
