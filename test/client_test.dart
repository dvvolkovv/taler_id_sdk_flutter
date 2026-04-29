import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
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

    test('isAuthenticated true when access_token + future expires_at present', () async {
      await storage.set('talerid:access_token', 'AT');
      await storage.set(
        'talerid:expires_at',
        DateTime.now().add(const Duration(minutes: 1)).millisecondsSinceEpoch.toString(),
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
}
