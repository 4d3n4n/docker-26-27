# Exercice Docker #6

Via Docker, créer un conteneur utilitaire basé sur une image d'un serveur web.

Ce conteneur aura pour but de permettre le développement d'un site internet sans avoir à installer localement de dépendances ou de librairies.

Il sera possible, via un dossier placé sur notre ordinateur, de coder directement un site web desservi par NGINX (qui lui sera exécuté dans un conteneur).

Pour cela, il vous faudra utiliser un type de volume (via l'option de lancement `-v`).


---

Result CLI:
```bash
$ docker run -d --name exo6-nginx -p 8090:80 -v '/Users/adenan/Desktop/Cours/Master 2/Dév avec Docker/09-10-2026/02_exercices_sujet/exercice-06/site:/usr/share/nginx/html:ro' nginx:alpine
bdf57339050833069a33e5992aef7a04eb45ae8fd65e5a12b759f54c1387b36c

$ docker ps --filter name=exo6-nginx --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
NAMES        IMAGE          STATUS                  PORTS
exo6-nginx   nginx:alpine   Up                       0.0.0.0:8090->80/tcp, [::]:8090->80/tcp

$ docker inspect --format '{{range .Mounts}}{{.Type}} {{.Source}} -> {{.Destination}} {{if .RW}}rw{{else}}ro{{end}}{{end}}' exo6-nginx
bind /Users/adenan/Desktop/Cours/Master 2/Dév avec Docker/09-10-2026/02_exercices_sujet/exercice-06/site -> /usr/share/nginx/html ro

$ curl -fsS http://localhost:8090
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <title>Exercice 06</title>
</head>
<body>
  <h1>Exercice 06</h1>
  <p>Cette page est servie par NGINX depuis un dossier monte avec Docker.</p>
</body>
</html>
```
