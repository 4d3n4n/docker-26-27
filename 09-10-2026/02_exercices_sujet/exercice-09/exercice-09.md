# Exercice Docker #9

Réaliser deux APIs en Java (via Spring Boot) et les conteneuriser. 

## API Logs

L'objectif de cette API est de permettre le stockage et la récupération de logs dans un fichier / une base de données.

Elle possèdera plusieurs endpoints tels que:
* `GET /api/v1/logs`: Récupération de l'ensemble des logs
* `POST /api/v1/logs`: Ajout d'un nouveau log à notre listing

Un logs sera consistué de la sorte:

```json
{
  "message": "string",
  "source": "string",
  "timestamp": "string",
  "level": "string",
}
```

* Le message sera l'erreur retournée par l'API du CRUD
* La source sera une chaine de caractère de type `[CrudAPI] GET /api/v1/chemin/appelle`
* Le timestamp sera l'indicatif de temps du moment où le message d'erreur à été levé par l'API
* Le niveau sera un énum de type `INFO | WARN | ERR` permettant de savoir s'il s'agit d'une erreur ou d'un simple appel ayant retourné un 200

## API CRUD

Cette API devra permettre la réalisation d'un CRUD de base sur une entité de votre choix (pour l'exemple, cela sera des chiens).

Elle offrira plusieurs endpoints, de type: 
* `GET /api/v1/dogs`: Listing des chiens
* `GET /api/v1/dogs/{dogId}`: Récupération d'un chien et de ses détails
* `POST /api/v1/dogs`: Ajout d'un nouveau chien à notre base de données
* `PUT /api/v1/dogs/{dogId}`: Edition d'un chien via son ID
* `DELETE /api/v1/dogs/{dogId}`: Suppression d'un chien via son ID

Pour fonctionner, l'API utilisera Hibernate et sera connectée à une base de données de type MySQL / PostgresSQL.

Lors de l'interaction de l'utilisateur avec cette API, des logs seront générés et seront transmis à l'API de logging via un client HTTP (de type RestTemplate en Java donc). Ces logs contiendront des informations, principalement les erreurs générés par l'API de Crud, dans le but de permettre par la suite le monitoring de notre environnement Dockerisé.

La base de données sera également conteneurisée, de sorte à ne pas avoir à installer le moindre SGBD en local.

Pour réaliser cet exercice, il est conseillé de: 

* Commencer par créer une base de données via Docker (en la rendant disponible à l'extérieur via le port forwarding)
* Créer un projet de type Java / Spring Boot compatible avec notre système de données (attention au driver à choisir pour Hibernate / JPA)
* Développer une API en local
* Créer le Dockerfile de l'API
* Créer une image de notre API
* Relancer l'API via Docker de sorte à en tester son fonctionnement et sa capacité à communiquer avec la BdD

## Fichiers créés

* `crud-api/` contient l'API CRUD Spring Boot et son client `RestTemplate`.
* `logs-api/` contient l'API Spring Boot qui stocke les logs en base.
* `compose.yaml` démarre les deux APIs et PostgreSQL.

Ports : PostgreSQL `5434`, API Logs `8082`, API CRUD `8083`.

---

Result CLI:
```bash
$ docker build -t exo9-logs-api:1.0 09-10-2026/02_exercices_sujet/exercice-09/logs-api
...
exo9-logs-api:1.0

$ docker build -t exo9-crud-api:1.0 09-10-2026/02_exercices_sujet/exercice-09/crud-api
...
exo9-crud-api:1.0

$ docker compose -f 09-10-2026/02_exercices_sujet/exercice-09/compose.yaml up -d --no-build
Container exo9-postgres Healthy
Container exo9-logs-api Started
Container exo9-crud-api Started

$ curl -sS -X POST http://localhost:8083/api/v1/dogs -H 'Content-Type: application/json' -d '{"name":"Nova","birthDate":"2023-01-22","breed":"Berger australien","sterilized":false}'
{"id":1,"name":"Nova","birthDate":"2023-01-22","breed":"Berger australien","sterilized":false}

$ curl -sS -X PUT http://localhost:8083/api/v1/dogs/1 -H 'Content-Type: application/json' -d '{"name":"Nova","birthDate":"2023-01-22","breed":"Berger australien","sterilized":true}'
{"id":1,"name":"Nova","birthDate":"2023-01-22","breed":"Berger australien","sterilized":true}

$ curl -sS -o /dev/null -w '%{http_code}\n' http://localhost:8083/api/v1/dogs/99
404

$ curl -sS -o /dev/null -w '%{http_code}\n' -X DELETE http://localhost:8083/api/v1/dogs/1
204

$ curl -sS http://localhost:8082/api/v1/logs
[{"id":1,"message":"Dogs list retrieved","source":"[CrudAPI] GET /api/v1/dogs","timestamp":"2026-10-09T11:48:54.650649Z","level":"INFO"},{"id":2,"message":"Dog created","source":"[CrudAPI] POST /api/v1/dogs","timestamp":"2026-10-09T11:48:54.879552Z","level":"INFO"},{"id":3,"message":"Dog updated","source":"[CrudAPI] PUT /api/v1/dogs/1","timestamp":"2026-10-09T11:48:54.915172Z","level":"INFO"},{"id":4,"message":"Dog not found","source":"[CrudAPI] GET /api/v1/dogs/99","timestamp":"2026-10-09T11:48:54.935262Z","level":"ERR"},{"id":5,"message":"Dog deleted","source":"[CrudAPI] DELETE /api/v1/dogs/1","timestamp":"2026-10-09T11:48:54.96786Z","level":"INFO"}]
```
