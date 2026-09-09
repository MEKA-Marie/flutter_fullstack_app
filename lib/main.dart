import 'package:flutter/material.dart';
import 'data/api_client.dart';
import 'data/local_cache.dart';
import 'data/models.dart';
import 'data/repositories.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cache = HiveLocalCache();
  await cache.init();
  final client = ApiClient();
  runApp(PulseboardApp(auth: AuthRepository(client, cache), data: DataRepository(client, cache), cache: cache));
}

class PulseboardApp extends StatelessWidget {
  const PulseboardApp({super.key, required this.auth, required this.data, required this.cache});
  final AuthRepository auth;
  final DataRepository data;
  final HiveLocalCache cache;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Pulseboard',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff146c94)), useMaterial3: true),
        home: LoginPage(auth: auth, data: data, cache: cache),
      );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.auth, required this.data, required this.cache});
  final AuthRepository auth;
  final DataRepository data;
  final HiveLocalCache cache;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController(text: 'emilys');
  final password = TextEditingController(text: 'emilyspass');
  bool loading = false;
  String? error;

  Future<void> submit() async {
    setState(() { loading = true; error = null; });
    try {
      final session = await widget.auth.login(username.text.trim(), password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => Dashboard(session: session, auth: widget.auth, data: widget.data)));
    } catch (exception) {
      if (mounted) setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Padding(padding: const EdgeInsets.all(28), child: Card(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.insights, size: 52, color: Color(0xff146c94)),
          const SizedBox(height: 16),
          Text('Pulseboard', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Vos données, même quand le réseau hésite.', textAlign: TextAlign.center),
          const SizedBox(height: 28),
          TextField(controller: username, decoration: const InputDecoration(labelText: 'Identifiant', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Mot de passe', prefixIcon: Icon(Icons.lock_outline), border: OutlineInputBorder())),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 14), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: loading ? null : submit, icon: loading ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.login), label: const Text('Se connecter')),
          TextButton.icon(onPressed: loading ? null : () async {
            setState(() { loading = true; error = null; });
            try {
              final session = await widget.auth.register(username.text.trim(), password.text);
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => Dashboard(session: session, auth: widget.auth, data: widget.data)));
            } catch (exception) {
              if (mounted) setState(() => error = exception.toString());
            } finally {
              if (mounted) setState(() => loading = false);
            }
          }, icon: const Icon(Icons.person_add_outlined), label: const Text('Créer un compte')),
          const SizedBox(height: 12),
          const Text('Démo : emilys / emilyspass', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
        ])))))));
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key, required this.session, required this.auth, required this.data});
  final Session session;
  final AuthRepository auth;
  final DataRepository data;
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int tab = 0;
  late Future<Object> content;

  @override
  void initState() { super.initState(); content = widget.data.products(); }

  void changeTab(int index) => setState(() { tab = index; content = [widget.data.products(), widget.data.users(), widget.data.todos()][index]; });

  Future<void> logout() async {
    await widget.auth.logout();
    if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LoginPage(auth: widget.auth, data: widget.data, cache: HiveLocalCache())));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Pulseboard'), actions: [Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Center(child: Text(widget.session.username))), IconButton(onPressed: logout, tooltip: 'Déconnexion', icon: const Icon(Icons.logout))]),
        body: FutureBuilder<Object>(future: content, builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return ErrorState(message: snapshot.error.toString(), retry: () => changeTab(tab));
          final value = snapshot.data!;
          if (value is List<Product>) return ProductView(items: value);
          if (value is List<AppUser>) return UserView(items: value);
          return TodoView(items: value as List<Todo>);
        }),
        bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: changeTab, destinations: const [NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Produits'), NavigationDestination(icon: Icon(Icons.people_outline), label: 'Équipe'), NavigationDestination(icon: Icon(Icons.checklist), label: 'Tâches')]),
      );
}

class ProductView extends StatelessWidget {
  const ProductView({super.key, required this.items});
  final List<Product> items;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [const Header(title: 'Catalogue', subtitle: 'Produits synchronisés depuis l’API'), ...items.map((item) => Card(child: ListTile(leading: CircleAvatar(backgroundImage: NetworkImage(item.thumbnail)), title: Text(item.title), subtitle: Text(item.category), trailing: Text('\$${item.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))))) ]);
}

class UserView extends StatelessWidget {
  const UserView({super.key, required this.items});
  final List<AppUser> items;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [const Header(title: 'Équipe', subtitle: 'Utilisateurs disponibles'), ...items.map((item) => Card(child: ListTile(leading: CircleAvatar(backgroundImage: NetworkImage(item.image)), title: Text(item.name), subtitle: Text(item.email))))]);
}

class TodoView extends StatelessWidget {
  const TodoView({super.key, required this.items});
  final List<Todo> items;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [const Header(title: 'Tâches', subtitle: 'Suivi opérationnel'), ...items.map((item) => Card(child: CheckboxListTile(value: item.completed, onChanged: null, title: Text(item.todo), secondary: Text('#${item.id}'))))]);
}

class Header extends StatelessWidget {
  const Header({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)), Text(subtitle)]));
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, size: 48), const SizedBox(height: 12), const Text('Impossible de charger les données'), Text(message, textAlign: TextAlign.center), const SizedBox(height: 16), OutlinedButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Réessayer'))])));
}
