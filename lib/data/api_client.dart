import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  ApiClient({Dio? dio, FlutterSecureStorage? storage, bool addAuthInterceptor = true})
      : dio = dio ?? Dio(BaseOptions(baseUrl: 'https://dummyjson.com', connectTimeout: const Duration(seconds: 8), receiveTimeout: const Duration(seconds: 8))),
        _storage = storage ?? const FlutterSecureStorage() {
    if (addAuthInterceptor) this.dio.interceptors.add(AuthInterceptor(_storage));
  }

  final Dio dio;
  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) => _storage.write(key: 'access_token', value: token);
  Future<void> clearToken() => _storage.delete(key: 'access_token');
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this.storage);
  final FlutterSecureStorage storage;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storage.read(key: 'access_token');
    if (token != null && token.isNotEmpty) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }
}
