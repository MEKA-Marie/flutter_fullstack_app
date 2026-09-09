# Pulseboard

Application Flutter full-stack de suivi de données, construite en architecture Feature-First avec repository pattern.

## Architecture

- `lib/data/models.dart` : modèles métier Product, AppUser et Todo.
- `lib/data/api_client.dart` : client Dio et intercepteur bearer token.
- `lib/data/local_cache.dart` : contrat de cache, Hive JSON et cache mémoire de test.
- `lib/data/repositories.dart` : AuthRepository et DataRepository, indépendants de l’UI.
- `lib/main.dart` : composition de l’application et présentation.

## APIs utilisées

- [DummyJSON](https://dummyjson.com) fournit l’authentification et les produits, utilisateurs et tâches.
- Identifiants de démonstration : `emilys` / `emilyspass`.
- L’inscription utilise `POST /users/add`, puis ouvre une session locale de démonstration.
- Le token est conservé dans le stockage sécurisé et injecté par l’intercepteur Dio.
- La session est restaurée au redémarrage et le `refreshToken` est conservé pour appeler `/auth/refresh`.
- Les listes sont mises en cache dans Hive et servent de repli en cas d’erreur réseau.

## Lancer le projet

```bash
flutter pub get
flutter run
flutter test
```

Une connexion est nécessaire au premier chargement des listes ; ensuite les données déjà consultées restent visibles hors ligne.

## Checklist du projet

- Authentification : login, inscription et logout.
- JWT : injection automatique du bearer token avec Dio.
- Refresh JWT : renouvellement automatique après une réponse `401`.
- API REST : trois écrans distincts pour produits, utilisateurs et tâches.
- Persistance : Hive pour les listes et la session, stockage sécurisé pour les tokens.
- Hors ligne : retour aux listes Hive lorsqu’une requête réseau échoue.
- Tests : trois tests unitaires de la couche repository dans `test/repository_test.dart`.
