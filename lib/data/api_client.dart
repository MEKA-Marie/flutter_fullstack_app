import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  ApiClient({Dio? dio, FlutterSecureStorage? storage, bool addAuthInterceptor = true})
      : dio = dio ?? Dio(BaseOptions(baseUrl: 'https://dummyjson.com', connectTimeout: const Duration(seconds: 8), receiveTimeout: const Duration(seconds: 8))),
        _storage = storage ?? const FlutterSecureStorage() {
    if (addAuthInterceptor) this.dio.interceptors.add(AuthInterceptor(_storage, this.dio));
  }

  final Dio dio;
  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token, {String? refreshToken}) async {
    await _storage.write(key: 'access_token', value: token);
    if (refreshToken != null) await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this.storage, this.dio);
  final FlutterSecureStorage storage;
  final Dio dio;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storage.read(key: 'access_token');
    if (token != null && token.isNotEmpty) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 || err.requestOptions.extra['skipAuthRefresh'] == true) {
      handler.next(err);
      return;
    }
    final refreshToken = await storage.read(key: 'refresh_token');
    if (refreshToken == null || refreshToken.isEmpty) {
      handler.next(err);
      return;
    }
    try {
      final response = await dio.post('/auth/refresh', data: {'refreshToken': refreshToken, 'expiresInMins': 30}, options: Options(extra: {'skipAuthRefresh': true}));
      final accessToken = response.data['accessToken'] as String?;
      if (accessToken == null || accessToken.isEmpty) {
        handler.next(err);
        return;
      }
      await storage.write(key: 'access_token', value: accessToken);
      final request = err.requestOptions;
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.extra['skipAuthRefresh'] = true;
      handler.resolve(await dio.fetch(request));
    } on DioException {
      handler.next(err);
    }
  }
}
