# Exercice Docker #7

Via Docker, créer un conteneur de base de données (de type MySQL) possédant déjà plusieurs tables et données à son lancement.
* Ce conteneur devra être initialisé via un script de type sql contenant l'initialisation de la base de données
* Ce conteneur devra être instancié via une image construite par vos soins

Concernant le contenu de la base de données, celle-ci devra se nommer kennelDB et comporter:
* Des clients (nom, prénom, date de naissance, pseudonymme)
* Des adresses (numéro, rue, code postal, commune)
* Des associations clients-adresses
* Des chiens (nom, date de naissance, race, statut de stérilisation)
* Des chats (nom, date de naissance, race, statut de stérilisation)

## Fichiers créés

* `Dockerfile` construit l'image `exo7-kennel:1.0` à partir de MySQL 8.4.
* `init.sql` crée `kennelDB`, les cinq tables demandées et leurs données initiales.

---

Result CLI:
```bash
$ docker build -t exo7-kennel:1.0 09-10-2026/02_exercices_sujet/exercice-07
... 
#7 naming to docker.io/library/exo7-kennel:1.0 done
#7 DONE

$ docker run -d --name exo7-kennel -e MYSQL_ROOT_PASSWORD=exo7-root-2026 exo7-kennel:1.0
736512d9ec38b4f628844f578f8044e8da3824010fda9deadf43ef37f6233fe1

$ docker exec exo7-kennel mysql -uroot -pexo7-root-2026 -N -e 'USE kennelDB; SHOW TABLES; SELECT COUNT(*) AS clients FROM clients; SELECT COUNT(*) AS adresses FROM adresses; SELECT COUNT(*) AS chiens FROM chiens; SELECT COUNT(*) AS chats FROM chats;'
adresses
chats
chiens
clients
clients_adresses
2
2
2
2

$ docker ps --filter 'name=^/exo7-kennel$' --format '{{.Names}} | {{.Image}} | {{.Status}}'
exo7-kennel | exo7-kennel:1.0 | Up

$ docker exec exo7-kennel mysql -uroot -pexo7-root-2026 -e 'USE kennelDB; SELECT c.prenom, c.nom, a.numero, a.rue, a.code_postal, a.commune FROM clients c JOIN clients_adresses ca ON ca.client_id = c.id JOIN adresses a ON a.id = ca.adresse_id; SELECT nom, race, sterilise FROM chiens; SELECT nom, race, sterilise FROM chats;'
prenom  nom      numero  rue                 code_postal  commune
Lea     Martin   12      rue des Lilas       69003        Lyon
Hugo    Bernard  4       avenue de la Gare   33000        Bordeaux
nom     race                 sterilise
Rex     Labrador             1
Nova    Berger australien    0
nom     race      sterilise
Milo    Europeen   1
Plume   Siamois    0
```
