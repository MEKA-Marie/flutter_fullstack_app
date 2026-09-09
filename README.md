# Pulseboard

Application Flutter full-stack de suivi de données, construite avec une séparation `domain`, `data` et `presentation`, et le repository pattern.

## Architecture

- `lib/domain/repositories.dart` : contrats métier indépendants de l'implémentation réseau.
- `lib/data/models.dart` : modèles métier Product, AppUser et Todo.
- `lib/data/api_client.dart` : client Dio et intercepteur bearer token.
- `lib/data/local_cache.dart` : contrat de cache, Hive JSON et cache mémoire de test.
- `lib/data/repositories.dart` : AuthRepository et DataRepository, indépendants de l’UI.
- `lib/main.dart` : composition de l’application et présentation Flutter.

## APIs utilisées

- [DummyJSON](https://dummyjson.com) fournit l’authentification et les produits, utilisateurs et tâches.
- Identifiants de démonstration : `emilys` / `emilyspass`.
- L’inscription utilise `POST /users/add`. DummyJSON ne persiste pas réellement les utilisateurs créés et ne renvoie pas de JWT sur cette route ; l'application conserve donc une session de démonstration après la création, tandis que le login de production utilise le JWT retourné par `/auth/login`.
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
- Tests : sept tests unitaires de la couche repository, répartis dans `test/repository_test.dart` et `test/auth_repository_test.dart`, couvrant cache hors ligne, erreur réseau, payload invalide, login JWT, restauration de session et logout.

## Vérification de la livraison

```bash
flutter analyze
flutter test
flutter build web
```

Le projet est publié sur GitHub : https://github.com/MEKA-Marie/flutter_fullstack_app
