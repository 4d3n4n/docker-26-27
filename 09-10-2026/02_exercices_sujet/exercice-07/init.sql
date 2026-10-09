CREATE DATABASE IF NOT EXISTS kennelDB
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE kennelDB;

CREATE TABLE clients (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nom VARCHAR(100) NOT NULL,
  prenom VARCHAR(100) NOT NULL,
  date_naissance DATE NOT NULL,
  pseudonyme VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE adresses (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  numero VARCHAR(10) NOT NULL,
  rue VARCHAR(150) NOT NULL,
  code_postal VARCHAR(10) NOT NULL,
  commune VARCHAR(100) NOT NULL
);

CREATE TABLE clients_adresses (
  client_id INT UNSIGNED NOT NULL,
  adresse_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (client_id, adresse_id),
  FOREIGN KEY (client_id) REFERENCES clients(id),
  FOREIGN KEY (adresse_id) REFERENCES adresses(id)
);

CREATE TABLE chiens (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nom VARCHAR(100) NOT NULL,
  date_naissance DATE NOT NULL,
  race VARCHAR(100) NOT NULL,
  sterilise BOOLEAN NOT NULL
);

CREATE TABLE chats (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nom VARCHAR(100) NOT NULL,
  date_naissance DATE NOT NULL,
  race VARCHAR(100) NOT NULL,
  sterilise BOOLEAN NOT NULL
);

INSERT INTO clients (nom, prenom, date_naissance, pseudonyme) VALUES
  ('Martin', 'Lea', '1992-04-15', 'leam'),
  ('Bernard', 'Hugo', '1987-11-03', 'hugo_b');

INSERT INTO adresses (numero, rue, code_postal, commune) VALUES
  ('12', 'rue des Lilas', '69003', 'Lyon'),
  ('4', 'avenue de la Gare', '33000', 'Bordeaux');

INSERT INTO clients_adresses (client_id, adresse_id) VALUES
  (1, 1),
  (2, 2);

INSERT INTO chiens (nom, date_naissance, race, sterilise) VALUES
  ('Rex', '2021-06-10', 'Labrador', TRUE),
  ('Nova', '2023-01-22', 'Berger australien', FALSE);

INSERT INTO chats (nom, date_naissance, race, sterilise) VALUES
  ('Milo', '2020-09-18', 'Europeen', TRUE),
  ('Plume', '2022-03-07', 'Siamois', FALSE);
