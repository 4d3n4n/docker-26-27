# Diagnostic du Compose initial

| Problème | Conséquence |
| --- | --- |
| `version: '3'` est obsolète avec Compose actuel | Avertissement et impression trompeuse qu'une version fige les fonctionnalités. |
| Images `postgres` et `redis` sans version | Un nouveau pull peut modifier la stack sans changement du dépôt. |
| Base publiée sur `5432:5432` | PostgreSQL est joignable depuis l'hôte et potentiellement le réseau. |
| Redis publié sur `6379:6379` | Cache et file de commandes exposés sans authentification. |
| API publiée directement sur `3000:3000` | Aucun point d'entrée central ni contrôle du trafic. |
| Mot de passe `postgres` et URL avec mot de passe dans le YAML | Identifiant divulgué dans Git et dans la configuration résolue. |
| `links` sur l'API et le worker | Mécanisme ancien, inutile pour la résolution DNS des services Compose. |
| `sleep 10` avant l'API | Délai arbitraire : trop court si la base tarde, inutile si elle est prête. |
| Aucun `healthcheck` ni `depends_on` conditionnel | `up` ne garantit pas que les dépendances soient prêtes. |
| Réseau unique implicite | Aucune séparation entre proxy public et services internes. |
| Aucun volume nommé pour PostgreSQL et Redis | Les données disparaissent avec la recréation des conteneurs. |
| Pas de script d'initialisation de la base | L'API peut démarrer sans tables `products` et `orders`. |
| `restart: always` seulement sur le worker | Comportement incohérent après une panne ou un redémarrage. |
| Aucun plafond CPU/mémoire ni rotation des logs | Une panne peut consommer les ressources du serveur ou remplir le disque. |
| Aucun profil pour les outils | L'administration et les migrations ne sont pas isolées des services permanents. |
