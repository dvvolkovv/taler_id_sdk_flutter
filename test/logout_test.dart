import 'package:flutter_test/flutter_test.dart';
import 'package:talerid_oauth/talerid_oauth.dart';

import 'client_test.dart' show FakeOAuthBackend;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TalerIdClient — logout', () {
    late MemoryStorage storage;
    late FakeOAuthBackend backend;

    setUp(() async {
      storage = MemoryStorage();
      backend = FakeOAuthBackend();
      await storage.set('talerid:access_token', 'AT');
      await storage.set('talerid:refresh_token', 'RT');
      await storage.set('talerid:id_token', 'IT');
      await storage.set(
        'talerid:expires_at',
        DateTime.now().add(const Duration(minutes: 1)).millisecondsSinceEpoch.toString(),
      );
      await storage.set('talerid:user', '{"sub":"u"}');
    });

    test('silent logout clears storage and emits unauthenticated state', () async {
      final client = await TalerIdClient.create(
        clientId: 'c',
        redirectUri: 'app://cb',
        storage: storage,
        backend: backend,
      );
      expect(client.isAuthenticated, isTrue);

      await client.logout();

      expect(client.isAuthenticated, isFalse);
      expect(await storage.get('talerid:access_token'), isNull);
      expect(await storage.get('talerid:user'), isNull);
      expect(backend.endSessionCalled, isFalse);
    });

    test('logout(endSession: true) calls backend.endSession with id_token_hint', () async {
      final client = await TalerIdClient.create(
        clientId: 'c',
        redirectUri: 'app://cb',
        storage: storage,
        backend: backend,
      );
      await client.logout(endSession: true);
      expect(backend.endSessionCalled, isTrue);
      // Storage still cleared.
      expect(await storage.get('talerid:access_token'), isNull);
    });

    test('logout when not authenticated is a no-op (idempotent)', () async {
      // Drain storage first.
      await storage.remove('talerid:access_token');
      await storage.remove('talerid:refresh_token');
      await storage.remove('talerid:id_token');
      await storage.remove('talerid:expires_at');
      await storage.remove('talerid:user');

      final client = await TalerIdClient.create(
        clientId: 'c',
        redirectUri: 'app://cb',
        storage: storage,
        backend: backend,
      );
      await client.logout();
      expect(client.isAuthenticated, isFalse);
    });
  });
}
