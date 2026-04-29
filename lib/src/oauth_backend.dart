import 'package:flutter_appauth/flutter_appauth.dart';

/// Result of an authorization-code-with-PKCE token exchange or refresh.
class OAuthTokens {
  /// The newly minted access token.
  final String accessToken;

  /// The refresh token, if the grant included one (`offline_access` scope).
  final String? refreshToken;

  /// The id_token, if the grant included `openid` scope.
  final String? idToken;

  /// Wall-clock time at which [accessToken] expires.
  final DateTime? expiresAt;

  /// Constructs an [OAuthTokens] response.
  OAuthTokens({
    required this.accessToken,
    this.refreshToken,
    this.idToken,
    this.expiresAt,
  });
}

/// Internal port — abstracts `flutter_appauth` so tests can use a fake.
///
/// Production [TalerIdClient] uses [FlutterAppAuthBackend]; tests inject
/// their own [OAuthBackend] subclass.
abstract class OAuthBackend {
  /// Run the full authorize-and-exchange flow. Throws on cancel / network /
  /// state mismatch — see [TalerIdAuthError] for codes.
  Future<OAuthTokens> authorizeAndExchangeCode({
    required String clientId,
    required String redirectUri,
    required String issuer,
    required List<String> scopes,
  });

  /// Exchange a refresh token for new tokens.
  Future<OAuthTokens> refresh({
    required String clientId,
    required String issuer,
    required String refreshToken,
  });

  /// End the OIDC session in the browser (RP-initiated logout).
  /// Throws on user cancel; does NOT throw on browser dismiss after success.
  Future<void> endSession({
    required String issuer,
    required String idTokenHint,
    required String postLogoutRedirectUri,
  });
}

/// Production backend — wraps [FlutterAppAuth].
class FlutterAppAuthBackend implements OAuthBackend {
  final FlutterAppAuth _appAuth = const FlutterAppAuth();

  /// Constructs a backend that delegates to [FlutterAppAuth].
  FlutterAppAuthBackend();

  @override
  Future<OAuthTokens> authorizeAndExchangeCode({
    required String clientId,
    required String redirectUri,
    required String issuer,
    required List<String> scopes,
  }) async {
    final result = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        clientId,
        redirectUri,
        issuer: issuer,
        scopes: scopes,
        promptValues: const [],
      ),
    );
    return OAuthTokens(
      accessToken: result.accessToken!,
      refreshToken: result.refreshToken,
      idToken: result.idToken,
      expiresAt: result.accessTokenExpirationDateTime,
    );
  }

  @override
  Future<OAuthTokens> refresh({
    required String clientId,
    required String issuer,
    required String refreshToken,
  }) async {
    final result = await _appAuth.token(
      TokenRequest(
        clientId,
        '', // redirectUri unused for refresh grant
        issuer: issuer,
        refreshToken: refreshToken,
        grantType: 'refresh_token',
      ),
    );
    return OAuthTokens(
      accessToken: result.accessToken!,
      refreshToken: result.refreshToken,
      idToken: result.idToken,
      expiresAt: result.accessTokenExpirationDateTime,
    );
  }

  @override
  Future<void> endSession({
    required String issuer,
    required String idTokenHint,
    required String postLogoutRedirectUri,
  }) async {
    await _appAuth.endSession(
      EndSessionRequest(
        idTokenHint: idTokenHint,
        postLogoutRedirectUrl: postLogoutRedirectUri,
        issuer: issuer,
      ),
    );
  }
}
