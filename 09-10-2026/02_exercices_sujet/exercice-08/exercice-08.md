# Exercice Docker #8

Réaliser une API en Java (via Spring Boot) conteneurisée. 

Cette API devra permettre la réalisation d'un CRUD de base sur une entité de votre choix (pour l'exemple, cela sera des chiens).

Elle offrira plusieurs endpoints, de type: 
* `GET /api/v1/dogs`: Listing des chiens
* `GET /api/v1/dogs/{dogId}`: Récupération d'un chien et de ses détails
* `POST /api/v1/dogs`: Ajout d'un nouveau chien à notre base de données
* `PUT /api/v1/dogs/{dogId}`: Edition d'un chien via son ID
* `DELETE /api/v1/dogs/{dogId}`: Suppression d'un chien via son ID

Pour fonctionner, l'API utilisera Hibernate et sera connectée à une base de données de type MySQL / PostgresSQL.

La base de données sera également conteneurisée, de sorte à ne pas avoir à installer le moindre SGBD en local.

Pour réaliser cet exercice, il est conseillé de: 

* Commencer par créer une base de données via Docker (en la rendant disponible à l'extérieur via le port forwarding)
* Créer un projet de type Java / Spring Boot compatible avec notre système de données (attention au driver à choisir pour Hibernate / JPA)
* Développer une API en local
* Créer le Dockerfile de l'API
* Créer une image de notre API
* Relancer l'API via Docker de sorte à en tester son fonctionnement et sa capacité à communiquer avec la BdD

## Fichiers créés

* `src/` contient l'API Spring Boot et le CRUD de l'entité `Dog`.
* `Dockerfile` construit l'image `exo8-dogs-api:1.0`.
* `compose.yaml` démarre l'API et PostgreSQL. La base est disponible sur le port `5433` et l'API sur le port `8081`.

---

Result CLI:
```bash
$ docker build -t exo8-dogs-api:1.0 09-10-2026/02_exercices_sujet/exercice-08
... 
#15 naming to docker.io/library/exo8-dogs-api:1.0 done
#15 DONE

$ docker compose -f 09-10-2026/02_exercices_sujet/exercice-08/compose.yaml up -d --no-build
Container exo8-api Running
Container exo8-postgres Running
Container exo8-postgres Healthy

$ curl -sS http://localhost:8081/api/v1/dogs
[]

$ curl -sS -X POST http://localhost:8081/api/v1/dogs -H 'Content-Type: application/json' -d '{"name":"Rex","birthDate":"2021-06-10","breed":"Labrador","sterilized":true}'
{"id":1,"name":"Rex","birthDate":"2021-06-10","breed":"Labrador","sterilized":true}

$ curl -sS http://localhost:8081/api/v1/dogs/1
{"id":1,"name":"Rex","birthDate":"2021-06-10","breed":"Labrador","sterilized":true}

$ curl -sS -X PUT http://localhost:8081/api/v1/dogs/1 -H 'Content-Type: application/json' -d '{"name":"Rex","birthDate":"2021-06-10","breed":"Labrador retriever","sterilized":true}'
{"id":1,"name":"Rex","birthDate":"2021-06-10","breed":"Labrador retriever","sterilized":true}

$ curl -sS -o /dev/null -w '%{http_code}\n' -X DELETE http://localhost:8081/api/v1/dogs/1
204

$ curl -sS http://localhost:8081/api/v1/dogs
[]
```
