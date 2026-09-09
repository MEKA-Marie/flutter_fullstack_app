import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

abstract interface class LocalCache {
  Future<void> saveList(String key, List<Map<String, dynamic>> value);
  List<Map<String, dynamic>> readList(String key);
  Future<void> saveSession(String token, String username);
  Map<String, String>? readSession();
  Future<void> clearSession();
}

class HiveLocalCache implements LocalCache {
  static const _boxName = 'app_cache';
  late final Box<String> _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
  }

  @override
  Future<void> saveList(String key, List<Map<String, dynamic>> value) => _box.put(key, jsonEncode(value));

  @override
  List<Map<String, dynamic>> readList(String key) {
    final raw = _box.get(key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  @override
  Future<void> saveSession(String token, String username) async {
    await _box.put('session', jsonEncode({'token': token, 'username': username}));
  }

  @override
  Map<String, String>? readSession() {
    final raw = _box.get('session');
    if (raw == null) return null;
    final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return {'token': decoded['token'] as String, 'username': decoded['username'] as String};
  }

  @override
  Future<void> clearSession() => _box.delete('session');
}

class MemoryCache implements LocalCache {
  final Map<String, List<Map<String, dynamic>>> lists = {};
  Map<String, String>? session;

  @override
  Future<void> saveList(String key, List<Map<String, dynamic>> value) async => lists[key] = value;
  @override
  List<Map<String, dynamic>> readList(String key) => lists[key] ?? [];
  @override
  Future<void> saveSession(String token, String username) async => session = {'token': token, 'username': username};
  @override
  Map<String, String>? readSession() => session;
  @override
  Future<void> clearSession() async => session = null;
}
