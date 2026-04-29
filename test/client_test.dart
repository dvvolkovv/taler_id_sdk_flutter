import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:talerid_oauth/talerid_oauth.dart';
import 'package:talerid_oauth/src/oauth_backend.dart';

class FakeOAuthBackend implements OAuthBackend {
  OAuthTokens? nextAuthorizeResult;
  Object? nextAuthorizeError;
  OAuthTokens? nextRefreshResult;
  Object? nextRefreshError;
  bool endSessionCalled = false;

  @override
  Future<OAuthTokens> authorizeAndExchangeCode({
    required String clientId,
    required String redirectUri,
    required String issuer,
    required List<String> scopes,
  }) async {
    if (nextAuthorizeError != null) throw nextAuthorizeError!;
    return nextAuthorizeResult!;
  }

  @override
  Future<OAuthTokens> refresh({
    required String clientId,
    required String issuer,
    required String refreshToken,
  }) async {
    if (nextRefreshError != null) throw nextRefreshError!;
    return nextRefreshResult!;
  }

  @override
  Future<void> endSession({
    required String issuer,
    required String idTokenHint,
    required String postLogoutRedirectUri,
  }) async {
    endSessionCalled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TalerIdClient — skeleton', () {
    late MemoryStorage storage;
    late FakeOAuthBackend backend;

    setUp(() {
      storage = MemoryStorage();
      backend = FakeOAuthBackend();
    });

    test('create() throws config when clientId empty', () async {
      expect(
        () => TalerIdClient.create(
          clientId: '',
          redirectUri: 'app://cb',
          storage: storage,
          backend: backend,
        ),
        throwsA(isA<TalerIdAuthError>()
            .having((e) => e.code, 'code', TalerIdErrorCode.config)),
      );
    });

    test('create() throws config when redirectUri empty', () async {
      expect(
        () => TalerIdClient.create(
          clientId: 'c',
          redirectUri: '',
          storage: storage,
          backend: backend,
        ),
        throwsA(isA<TalerIdAuthError>()
            .having((e) => e.code, 'code', TalerIdErrorCode.config)),
      );
    });

    test('isAuthenticated false on empty storage', () async {
      final client = await TalerIdClient.create(
        clientId: 'c',
        redirectUri: 'app://cb',
        storage: storage,
        backend: backend,
      );
      expect(client.isAuthenticated, isFalse);
    });

    test('isAuthenticated true when access_token + future expires_at present',
        () async {
      await storage.set('talerid:access_token', 'AT');
      await storage.set(
        'talerid:expires_at',
        DateTime.now()
            .add(const Duration(minutes: 1))
            .millisecondsSinceEpoch
            .toString(),
      );
      final client = await TalerIdClient.create(
        clientId: 'c',
        redirectUri: 'app://cb',
        storage: storage,
        backend: backend,
      );
      expect(client.isAuthenticated, isTrue);
    });

    test('authState is a ValueListenable<AuthState>', () async {
      final client = await TalerIdClient.create(
        clientId: 'c',
        redirectUri: 'app://cb',
        storage: storage,
        backend: backend,
      );
      expect(client.authState, isA<ValueListenable<AuthState>>());
      expect(client.authState.value.isAuthenticated, isFalse);
    });
  });

  group('TalerIdClient — login', () {
    late MemoryStorage storage;
    late FakeOAuthBackend backend;
    late TalerIdClient client;

    setUp(() async {
      storage = MemoryStorage();
      backend = FakeOAuthBackend();
      client = await TalerIdClient.create(
        clientId: 'c',
        redirectUri: 'app://cb',
        storage: storage,
        backend: backend,
      );
    });

    test('stores tokens, emits authenticated state, returns when done',
        () async {
      backend.nextAuthorizeResult = OAuthTokens(
        accessToken: 'AT',
        refreshToken: 'RT',
        idToken: 'IT',
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      );

      await client.login();

      expect(client.isAuthenticated, isTrue);
      expect(client.authState.value.isAuthenticated, isTrue);
      expect(await storage.get('talerid:access_token'), 'AT');
      expect(await storage.get('talerid:refresh_token'), 'RT');
      expect(await storage.get('talerid:id_token'), 'IT');
      final expires = int.parse((await storage.get('talerid:expires_at'))!);
      expect(expires, greaterThan(DateTime.now().millisecondsSinceEpoch));
    });

    test('maps backend cancellation to TalerIdAuthError', () async {
      backend.nextAuthorizeError = StateError('User cancelled flow');
      await expectLater(
        client.login(),
        throwsA(isA<TalerIdAuthError>()),
      );
      // Even on error, state stays unauthenticated.
      expect(client.isAuthenticated, isFalse);
    });

    test('isLoading is true during login flow', () async {
      var sawLoading = false;
      client.authState.addListener(() {
        if (client.authState.value.isLoading) sawLoading = true;
      });
      backend.nextAuthorizeResult = OAuthTokens(
        accessToken: 'AT',
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      );
      await client.login();
      expect(sawLoading, isTrue);
      expect(client.authState.value.isLoading, isFalse);
    });
  });

  group('TalerIdClient — getAccessToken / getUser', () {
    late MemoryStorage storage;
    late FakeOAuthBackend backend;

    Future<TalerIdClient> makeClient({http.Client? httpClient}) =>
        TalerIdClient.create(
          clientId: 'c',
          redirectUri: 'app://cb',
          storage: storage,
          backend: backend,
          httpClient: httpClient,
        );

    setUp(() async {
      storage = MemoryStorage();
      backend = FakeOAuthBackend();
      await storage.set('talerid:access_token', 'AT');
      await storage.set(
        'talerid:expires_at',
        DateTime.now()
            .add(const Duration(minutes: 1))
            .millisecondsSinceEpoch
            .toString(),
      );
    });

    test('getAccessToken returns cached token when not near expiry', () async {
      final client = await makeClient();
      expect(await client.getAccessToken(), 'AT');
    });

    test('getAccessToken throws loginRequired when no token in storage',
        () async {
      await storage.remove('talerid:access_token');
      await storage.remove('talerid:expires_at');
      final client = await makeClient();
      await expectLater(
        client.getAccessToken(),
        throwsA(isA<TalerIdAuthError>()
            .having((e) => e.code, 'code', TalerIdErrorCode.loginRequired)),
      );
    });

    test('getUser fetches /oauth/me with Bearer header, caches result',
        () async {
      var calls = 0;
      final mockHttp = MockClient((req) async {
        calls += 1;
        expect(req.url.toString(), 'https://id.taler.tirol/oauth/me');
        expect(req.headers['authorization'], 'Bearer AT');
        return http.Response(
          jsonEncode({'sub': 'user-1', 'email': 'u@x.com'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final client = await makeClient(httpClient: mockHttp);
      final user = await client.getUser();
      expect(user.sub, 'user-1');
      expect(user.email, 'u@x.com');
      expect(calls, 1);

      // second call hits cache
      final user2 = await client.getUser();
      expect(user2, equals(user));
      expect(calls, 1);
    });

    test('getUser throws network on fetch failure', () async {
      final mockHttp = MockClient((req) async {
        throw http.ClientException('Failed to fetch');
      });
      final client = await makeClient(httpClient: mockHttp);
      await expectLater(
        client.getUser(),
        throwsA(isA<TalerIdAuthError>()
            .having((e) => e.code, 'code', TalerIdErrorCode.network)),
      );
    });
  });
}
