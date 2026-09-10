import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_fullstack_app/data/api_client.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}
class MockDio extends Mock implements Dio {}

void main() {
  late MockSecureStorage storage;
  late MockDio dio;

  setUp(() {
    storage = MockSecureStorage();
    dio = MockDio();
  });

  test('injects the stored access token into requests', () async {
    when(() => storage.read(key: 'access_token')).thenAnswer((_) async => 'access-123');
    final interceptor = AuthInterceptor(storage, dio);
    final options = RequestOptions(path: '/products');
    final handler = _RequestHandler();

    await interceptor.onRequest(options, handler);

    expect(handler.options?.headers['Authorization'], 'Bearer access-123');
  });

  test('forwards requests without authorization when no token exists', () async {
    when(() => storage.read(key: 'access_token')).thenAnswer((_) async => null);
    final interceptor = AuthInterceptor(storage, dio);
    final handler = _RequestHandler();

    await interceptor.onRequest(RequestOptions(path: '/products'), handler);

    expect(handler.options?.headers.containsKey('Authorization'), isFalse);
  });
}

class _RequestHandler implements RequestInterceptorHandler {
  RequestOptions? options;

  @override
  void next(RequestOptions request) => options = request;

  @override
  void resolve(Response response, [bool callFollowingResponseInterceptor = false]) {}

  @override
  void reject(DioException error, [bool callFollowingErrorInterceptor = false]) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
