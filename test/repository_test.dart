import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_fullstack_app/data/api_client.dart';
import 'package:flutter_fullstack_app/data/local_cache.dart';
import 'package:flutter_fullstack_app/data/repositories.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late DataRepository repository;
  late MemoryCache cache;

  setUp(() {
    dio = MockDio();
    cache = MemoryCache();
    repository = DataRepository(ApiClient(dio: dio, addAuthInterceptor: false), cache);
  });

  test('products are mapped and cached after a successful request', () async {
    when(() => dio.get('/products?limit=30')).thenAnswer((_) async => Response(requestOptions: RequestOptions(path: '/products?limit=30'), data: {'products': [{'id': 1, 'title': 'Desk', 'price': 12, 'category': 'office', 'thumbnail': ''}]}));

    final products = await repository.products();

    expect(products.single.title, 'Desk');
    expect(cache.readList('products'), hasLength(1));
  });

  test('users fall back to the local cache when the network fails', () async {
    await cache.saveList('users', [{'id': 4, 'firstName': 'Ada', 'lastName': 'Lovelace', 'email': 'ada@example.com', 'image': ''}]);
    when(() => dio.get('/users?limit=30')).thenThrow(DioException(requestOptions: RequestOptions(path: '/users?limit=30')));

    final users = await repository.users();

    expect(users.single.name, 'Ada Lovelace');
    expect(repository.lastLoadWasCached, isTrue);
  });

  test('todos expose a user-facing failure when no cache exists', () async {
    when(() => dio.get('/todos?limit=30')).thenThrow(DioException(requestOptions: RequestOptions(path: '/todos?limit=30'), message: 'offline'));

    expect(repository.todos(), throwsA(isA<NetworkFailure>()));
  });

  test('malformed API payloads become user-facing failures', () async {
    when(() => dio.get('/products?limit=30')).thenAnswer((_) async => Response(requestOptions: RequestOptions(path: '/products?limit=30'), data: {'unexpected': []}));

    expect(repository.products(), throwsA(isA<NetworkFailure>()));
  });
}