# Exercice Docker #5 — MySQL et Adminer

## Objectif

Déployer une base de données MySQL et une interface d'administration web (Adminer) à l'aide de Docker, en utilisant deux conteneurs distincts.

## Travail demandé

1. Créer un réseau Docker dédié à l'exercice.
2. Déployer un conteneur **MySQL** avec une base de données et un utilisateur dédiés.
3. Déployer un conteneur **Adminer** permettant d'administrer MySQL depuis un navigateur.
4. Faire communiquer les deux conteneurs via le réseau Docker.
5. Se connecter à MySQL depuis Adminer, créer une table et y insérer quelques enregistrements.

## Contraintes

- Les conteneurs doivent communiquer par leur nom, sans adresse IP fixe.
- Les données MySQL doivent être conservées même après la suppression et la recréation du conteneur.
- Les conteneurs doivent redémarrer automatiquement en cas d'arrêt inattendu ou de redémarrage de Docker.
- Seule l'interface Adminer doit être accessible depuis la machine hôte.

## Vérifications

- Consulter les enregistrements depuis Adminer.
- Supprimer puis recréer le conteneur MySQL.
- Vérifier que la table et ses enregistrements sont toujours présents.
- Simuler une panne d'un conteneur et vérifier son redémarrage automatique.

## Bonus

Reproduire le déploiement à l'aide d'un fichier `compose.yaml` pour démarrer les deux services avec une seule commande.


---

Result CLI :
```bash
$ docker network create exo5-reseau
843047a5786d1b8bf40f5fb260a33c66a456465956aa58706125862c29a26e0c

$ docker volume create exo5-mysql-data
exo5-mysql-data

$ docker pull mysql:8.4
Digest: sha256:6ea90827b1100f8f2ae306a539f86d2c264a26ed435a2a9f75551dd5c3aeb242
Status: Downloaded newer image for mysql:8.4
docker.io/library/mysql:8.4

$ docker pull adminer:5
Digest: sha256:e3a6b4942dd088a29cc8bbce22553429247c5c2b30b07d856ae49012b5c84a5b
Status: Downloaded newer image for adminer:5
docker.io/library/adminer:5

$ docker run -d --name exo5-mysql --network exo5-reseau --restart always -e MYSQL_ROOT_PASSWORD=exo5-root-2026 -e MYSQL_DATABASE=ecole -e MYSQL_USER=etudiant -e MYSQL_PASSWORD=exo5-etudiant-2026 -v exo5-mysql-data:/var/lib/mysql --health-cmd 'MYSQL_PWD="$MYSQL_PASSWORD" mysql --protocol=TCP -h127.0.0.1 -u"$MYSQL_USER" "$MYSQL_DATABASE" -e "SELECT 1" >/dev/null 2>&1' --health-interval 5s --health-timeout 3s --health-start-period 30s --health-retries 20 mysql:8.4
9903039b4c53df368bc52a8dc374fce1bf7f9fc920c306b6fc61d73527dd53a6

$ docker run -d --name exo5-adminer --network exo5-reseau --restart always -p 127.0.0.1:8080:8080 -e ADMINER_DEFAULT_SERVER=exo5-mysql adminer:5
c6cf8e64b66e4f835fce1697a9d01694c9d2c66a8a68d627b2fe2bb6ce47d53f

$ docker ps --filter network=exo5-reseau --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
NAMES          IMAGE       STATUS                   PORTS
exo5-adminer   adminer:5   Up                         127.0.0.1:8080->8080/tcp
exo5-mysql     mysql:8.4   Up (healthy)              3306/tcp, 33060/tcp

$ docker inspect --format '{{.Name}} restart={{.HostConfig.RestartPolicy.Name}} ports={{json .HostConfig.PortBindings}}' exo5-mysql exo5-adminer
/exo5-mysql restart=always ports={}
/exo5-adminer restart=always ports={"8080/tcp":[{"HostIp":"127.0.0.1","HostPort":"8080"}]}

$ docker exec -e MYSQL_PWD=exo5-etudiant-2026 exo5-mysql mysql -uetudiant --table ecole -e 'SELECT * FROM etudiants ORDER BY id;'
+----+--------+-------------------+
| id | prenom | formation         |
+----+--------+-------------------+
|  1 | Adenan | Master 2          |
|  2 | Alice  | Developpement web |
|  3 | Karim  | DevOps            |
+----+--------+-------------------+

$ docker inspect --format '{{.Id}} {{range .Mounts}}{{.Name}} -> {{.Destination}}{{end}}' exo5-mysql
9903039b4c53df368bc52a8dc374fce1bf7f9fc920c306b6fc61d73527dd53a6 exo5-mysql-data -> /var/lib/mysql

$ docker stop exo5-mysql
exo5-mysql

$ docker rm exo5-mysql
exo5-mysql

$ docker run -d --name exo5-mysql --network exo5-reseau --restart always -e MYSQL_ROOT_PASSWORD=exo5-root-2026 -e MYSQL_DATABASE=ecole -e MYSQL_USER=etudiant -e MYSQL_PASSWORD=exo5-etudiant-2026 -v exo5-mysql-data:/var/lib/mysql --health-cmd 'MYSQL_PWD="$MYSQL_PASSWORD" mysql --protocol=TCP -h127.0.0.1 -u"$MYSQL_USER" "$MYSQL_DATABASE" -e "SELECT 1" >/dev/null 2>&1' --health-interval 5s --health-timeout 3s --health-start-period 30s --health-retries 20 mysql:8.4
87c9c5bd38beea583c233470a2c49518ba03f728ee45d1bf29f737a5d17b8527

$ docker exec -e MYSQL_PWD=exo5-etudiant-2026 exo5-mysql mysql -uetudiant --table ecole -e 'SELECT * FROM etudiants ORDER BY id;'
+----+--------+-------------------+
| id | prenom | formation         |
+----+--------+-------------------+
|  1 | Adenan | Master 2          |
|  2 | Alice  | Developpement web |
|  3 | Karim  | DevOps            |
+----+--------+-------------------+

$ docker exec --user 0 exo5-mysql sh -c 'kill -TERM 1'

$ docker inspect --format '{{.Name}} status={{.State.Status}} health={{.State.Health.Status}} restarts={{.RestartCount}}' exo5-mysql
/exo5-mysql status=running health=healthy restarts=1

$ docker exec -e MYSQL_PWD=exo5-etudiant-2026 exo5-mysql mysql -uetudiant --table ecole -e 'SELECT * FROM etudiants ORDER BY id;'
+----+--------+-------------------+
| id | prenom | formation         |
+----+--------+-------------------+
|  1 | Adenan | Master 2          |
|  2 | Alice  | Developpement web |
|  3 | Karim  | DevOps            |
+----+--------+-------------------+
```
