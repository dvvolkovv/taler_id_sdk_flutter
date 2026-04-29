import 'package:flutter/material.dart';
import 'package:talerid_oauth/talerid_oauth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final client = await TalerIdClient.create(
    clientId: 'taler-id-demo',
    redirectUri: 'com.talerid.example://oauth/callback',
    issuer: 'https://staging.id.taler.tirol/oauth',
  );
  runApp(MyApp(client: client));
}

class MyApp extends StatelessWidget {
  final TalerIdClient client;
  const MyApp({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taler ID — Example',
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF167EF2))),
      home: HomePage(client: client),
    );
  }
}

class HomePage extends StatelessWidget {
  final TalerIdClient client;
  const HomePage({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in with Taler ID')),
      body: ValueListenableBuilder<AuthState>(
        valueListenable: client.authState,
        builder: (ctx, state, _) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!state.isAuthenticated) {
            return Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Taler ID'),
                onPressed: () => client.login(),
              ),
            );
          }
          return _AuthenticatedView(client: client);
        },
      ),
    );
  }
}

class _AuthenticatedView extends StatelessWidget {
  final TalerIdClient client;
  const _AuthenticatedView({required this.client});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserInfo>(
      future: client.getUser(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = snap.data!;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Hello, ${user.name ?? user.sub}', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              if (user.email != null) Text(user.email!),
              const SizedBox(height: 24),
              SelectableText('sub: ${user.sub}'),
              const Spacer(),
              OutlinedButton(
                onPressed: () => client.logout(),
                child: const Text('Logout'),
              ),
            ],
          ),
        );
      },
    );
  }
}
