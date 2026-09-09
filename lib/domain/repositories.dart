import '../data/models.dart';

abstract interface class AuthGateway {
  Future<Session> login(String username, String password);
  Future<Session> register(String username, String password);
  Future<Session?> restore();
  Future<Session> refresh(Session session);
  Future<void> logout();
}

abstract interface class DataGateway {
  Future<List<Product>> products();
  Future<List<AppUser>> users();
  Future<List<Todo>> todos();
}