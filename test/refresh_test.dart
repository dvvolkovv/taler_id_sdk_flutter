import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:talerid_oauth/talerid_oauth.dart';
import 'package:talerid_oauth/src/oauth_backend.dart';

import 'client_test.dart' show FakeOAuthBackend;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TalerIdClient — refresh', () {
    late MemoryStorage storage;
    late FakeOAuthBackend backend;

    Future<TalerIdClient> makeClient() => TalerIdClient.create(
          clientId: 'c',
          redirectUri: 'app://cb',
          storage: storage,
          backend: backend,
        );

    setUp(() async {
      storage = MemoryStorage();
      backend = FakeOAuthBackend();
      await storage.set('talerid:access_token', 'OLD');
      await storage.set('talerid:refresh_token', 'RT');
      await storage.set(
        'talerid:expires_at',
        DateTime.now().add(const Duration(seconds: 5)).millisecondsSinceEpoch.toString(),
      );
    });

    test('refreshes when access_token is within 30s of expiry', () async {
      backend.nextRefreshResult = OAuthTokens(
        accessToken: 'NEW',
        refreshToken: 'RT2',
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      );
      final client = await makeClient();
      final token = await client.getAccessToken();
      expect(token, 'NEW');
      expect(await storage.get('talerid:access_token'), 'NEW');
      expect(await storage.get('talerid:refresh_token'), 'RT2');
    });

    test('two concurrent getAccessToken calls share one refresh', () async {
      final completer = Completer<OAuthTokens>();
      final blocking = _BlockingBackend(completer);

      final client = await TalerIdClient.create(
        clientId: 'c',
        redirectUri: 'app://cb',
        storage: storage,
        backend: blocking,
      );

      final p1 = client.getAccessToken();
      final p2 = client.getAccessToken();

      completer.complete(OAuthTokens(
        accessToken: 'NEW',
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      ));

      final results = await Future.wait([p1, p2]);
      expect(results, ['NEW', 'NEW']);
      expect(blocking.refreshCalls, 1);
    });

    test('refresh failure clears storage and throws loginRequired', () async {
      backend.nextRefreshError = StateError('invalid_grant');
      final client = await makeClient();
      await expectLater(
        client.getAccessToken(),
        throwsA(isA<TalerIdAuthError>()
            .having((e) => e.code, 'code', TalerIdErrorCode.loginRequired)),
      );
      expect(await storage.get('talerid:access_token'), isNull);
      expect(await storage.get('talerid:refresh_token'), isNull);
      expect(client.authState.value.isAuthenticated, isFalse);
    });

    test('does NOT refresh when access_token has >30s of life left', () async {
      await storage.set(
        'talerid:expires_at',
        DateTime.now().add(const Duration(minutes: 1)).millisecondsSinceEpoch.toString(),
      );
      final client = await makeClient();
      final token = await client.getAccessToken();
      expect(token, 'OLD');
    });
  });
}

class _BlockingBackend extends FakeOAuthBackend {
  final Completer<OAuthTokens> _completer;
  int refreshCalls = 0;

  _BlockingBackend(this._completer);

  @override
  Future<OAuthTokens> refresh({
    required String clientId,
    required String issuer,
    required String refreshToken,
  }) {
    refreshCalls += 1;
    return _completer.future;
  }
}
