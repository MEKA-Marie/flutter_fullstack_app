import 'package:flutter/material.dart';

import 'data/api_client.dart';
import 'data/local_cache.dart';
import 'data/repositories.dart';
import 'presentation/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cache = HiveLocalCache();
  await cache.init();
  final client = ApiClient();
  final auth = AuthRepository(client, cache);
  final data = DataRepository(client, cache);
  final session = await auth.restore();
  runApp(PulseboardApp(auth: auth, data: data, cache: cache, session: session));
}
