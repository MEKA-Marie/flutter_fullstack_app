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
- Les listes sont mises en cache dans Hive et servent de repli en cas d’erreur réseau.

## Lancer le projet

```bash
flutter pub get
flutter run
flutter test
```

Une connexion est nécessaire au premier chargement des listes ; ensuite les données déjà consultées restent visibles hors ligne.
