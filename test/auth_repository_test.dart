import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_fullstack_app/data/api_client.dart';
import 'package:flutter_fullstack_app/data/local_cache.dart';
import 'package:flutter_fullstack_app/data/repositories.dart';

class MockDio extends Mock implements Dio {}
class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockDio dio;
  late MockSecureStorage storage;
  late MemoryCache cache;
  late AuthRepository repository;

  setUp(() {
    dio = MockDio();
    storage = MockSecureStorage();
    when(() => storage.write(key: any(named: 'key'), value: any(named: 'value'))).thenAnswer((_) async {});
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    cache = MemoryCache();
    repository = AuthRepository(ApiClient(dio: dio, storage: storage, addAuthInterceptor: false), cache);
  });

  test('login stores the JWT session locally', () async {
    when(() => dio.post('/auth/login', data: any(named: 'data'))).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          data: {'accessToken': 'access-123', 'refreshToken': 'refresh-123', 'username': 'emilys'},
        ));

    final session = await repository.login('emilys', 'emilyspass');

    expect(session.token, 'access-123');
    expect(cache.readSession(), {'token': 'access-123', 'username': 'emilys', 'refreshToken': 'refresh-123'});
  });

  test('restore returns the cached session', () async {
    await cache.saveSession('access-123', 'emilys', refreshToken: 'refresh-123');

    final session = await repository.restore();

    expect(session?.username, 'emilys');
    expect(session?.refreshToken, 'refresh-123');
  });

  test('logout clears the persisted session', () async {
    await cache.saveSession('access-123', 'emilys');

    await repository.logout();

    expect(cache.readSession(), isNull);
  });
}
