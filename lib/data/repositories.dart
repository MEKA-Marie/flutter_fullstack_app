import 'package:dio/dio.dart';
import 'api_client.dart';
import 'local_cache.dart';
import 'models.dart';
import '../domain/repositories.dart';

class NetworkFailure implements Exception {
  NetworkFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthRepository implements AuthGateway {
  AuthRepository(this.client, this.cache);
  final ApiClient client;
  final LocalCache cache;

  @override
  Future<Session> login(String username, String password) async {
    try {
      final response = await client.dio.post('/auth/login', data: {'username': username, 'password': password, 'expiresInMins': 30});
      final token = response.data['accessToken'] as String? ?? response.data['token'] as String? ?? '';
      final session = Session(token: token, refreshToken: response.data['refreshToken'] as String?, username: response.data['username'] as String? ?? username);
      await _persist(session);
      return session;
    } on DioException catch (error) {
      throw NetworkFailure(error.response?.data?['message'] as String? ?? 'Connexion impossible. Vérifiez vos identifiants.');
    }
  }

  @override
  Future<Session?> restore() async {
    final stored = cache.readSession();
    if (stored == null) return null;
    final session = Session(token: stored['token']!, username: stored['username']!, refreshToken: stored['refreshToken']);
    await client.saveToken(session.token, refreshToken: session.refreshToken);
    return session;
  }

  @override
  Future<Session> refresh(Session session) async {
    final refreshToken = session.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return session;
    try {
      final response = await client.dio.post('/auth/refresh', data: {'refreshToken': refreshToken, 'expiresInMins': 30});
      final refreshed = Session(token: response.data['accessToken'] as String? ?? session.token, refreshToken: response.data['refreshToken'] as String? ?? refreshToken, username: session.username);
      await _persist(refreshed);
      return refreshed;
    } on DioException {
      return session;
    }
  }

  Future<void> _persist(Session session) async {
    await client.saveToken(session.token, refreshToken: session.refreshToken);
    await cache.saveSession(session.token, session.username, refreshToken: session.refreshToken);
  }

  @override
  Future<Session> register(String username, String password) async {
    try {
      final response = await client.dio.post('/users/add', data: {'username': username, 'password': password, 'firstName': username, 'lastName': 'Pulseboard'});
      final session = Session(token: response.data['accessToken'] as String? ?? 'registered-demo', username: response.data['username'] as String? ?? username);
      await _persist(session);
      return session;
    } on DioException catch (error) {
      throw NetworkFailure(error.response?.data?['message'] as String? ?? 'Inscription impossible.');
    }
  }

  @override
  Future<void> logout() async {
    await client.clearToken();
    await cache.clearSession();
  }
}

class DataRepository implements DataGateway {
  DataRepository(this.client, this.cache);
  final ApiClient client;
  final LocalCache cache;
  bool lastLoadWasCached = false;

  @override
  Future<List<Product>> products() => _fetchList('products', '/products?limit=30', (data) => Product.fromJson(data));
  @override
  Future<List<AppUser>> users() => _fetchList('users', '/users?limit=30', (data) => AppUser.fromJson(data));
  @override
  Future<List<Todo>> todos() => _fetchList('todos', '/todos?limit=30', (data) => Todo.fromJson(data));

  Future<List<T>> _fetchList<T>(String key, String path, T Function(Map<String, dynamic>) parse) async {
    try {
      lastLoadWasCached = false;
      final response = await client.dio.get(path);
      final payload = response.data;
      if (payload is! Map || payload[key] is! List) throw const FormatException('Payload API invalide');
      final rows = (payload[key] as List).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
      await cache.saveList(key, rows);
      return rows.map(parse).toList();
    } catch (error) {
      final cached = _readCached(key, parse);
      if (cached != null && cached.isNotEmpty) {
        lastLoadWasCached = true;
        return cached;
      }
      final message = error is DioException ? error.message : null;
      throw NetworkFailure(message ?? 'Données indisponibles. Vérifiez votre connexion.');
    }
  }

  List<T>? _readCached<T>(String key, T Function(Map<String, dynamic>) parse) {
    try {
      return cache.readList(key).map(parse).toList();
    } on Object {
      return null;
    }
  }
}
