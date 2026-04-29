import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_state.dart';
import 'errors.dart';
import 'oauth_backend.dart';
import 'storage.dart';

const String _kPrefix = 'talerid:';
const String _kAccess = '${_kPrefix}access_token';
// ignore: unused_element
const String _kRefresh = '${_kPrefix}refresh_token';
// ignore: unused_element
const String _kId = '${_kPrefix}id_token';
const String _kExpires = '${_kPrefix}expires_at';
const String _kUser = '${_kPrefix}user';

const String _defaultIssuer = 'https://id.taler.tirol/oauth';
const String _defaultScope = 'openid profile email';

/// Optional logger callback. Levels: `'debug'`, `'info'`, `'warn'`, `'error'`.
typedef LogCallback = void Function(String level, String message, [Object? meta]);

/// Browser SDK for Sign in with Taler ID.
///
/// Use [TalerIdClient.create] to construct an instance, then call [login],
/// [getUser], [getAccessToken], [logout] as needed. Subscribe to [authState]
/// for reactive UI.
class TalerIdClient {
  /// OAuth client_id from Taler ID registration.
  final String clientId;

  /// Custom URL scheme registered in your iOS/Android app.
  final String redirectUri;

  /// Space-separated OAuth scopes.
  final String scope;

  /// Issuer base URL (`https://id.taler.tirol/oauth` by default).
  final String issuer;

  /// Token storage layer; defaults to [SecureStorage].
  final Storage storage;

  final OAuthBackend _backend; // ignore: unused_field
  final http.Client _http; // ignore: unused_field
  final LogCallback _log; // ignore: unused_field

  final ValueNotifier<AuthState> _state;

  /// Reactive auth state. Use with [ValueListenableBuilder].
  ValueListenable<AuthState> get authState => _state;

  TalerIdClient._({
    required this.clientId,
    required this.redirectUri,
    required this.scope,
    required this.issuer,
    required this.storage,
    required OAuthBackend backend,
    http.Client? httpClient,
    LogCallback? onLog,
    required AuthState initialState,
  })  : _backend = backend,
        _http = httpClient ?? http.Client(),
        _log = onLog ?? ((_, __, [___]) {}),
        _state = ValueNotifier<AuthState>(initialState);

  /// Async factory: validates config, hydrates state from [storage], returns a ready client.
  ///
  /// Throws [TalerIdAuthError] with [TalerIdErrorCode.config] when [clientId] or
  /// [redirectUri] are empty.
  static Future<TalerIdClient> create({
    required String clientId,
    required String redirectUri,
    String scope = _defaultScope,
    String issuer = _defaultIssuer,
    Storage? storage,
    OAuthBackend? backend,
    http.Client? httpClient,
    LogCallback? onLog,
  }) async {
    if (clientId.isEmpty) {
      throw TalerIdAuthError(
          code: TalerIdErrorCode.config, message: 'clientId is required');
    }
    if (redirectUri.isEmpty) {
      throw TalerIdAuthError(
          code: TalerIdErrorCode.config, message: 'redirectUri is required');
    }
    final s = storage ?? SecureStorage();
    final b = backend ?? FlutterAppAuthBackend();

    final access = await s.get(_kAccess);
    final expiresRaw = await s.get(_kExpires);
    final userJson = await s.get(_kUser);

    final expiresAt = int.tryParse(expiresRaw ?? '');
    final isAuthed = access != null &&
        expiresAt != null &&
        expiresAt > DateTime.now().millisecondsSinceEpoch;

    final user = (userJson != null) ? UserInfo.fromJsonString(userJson) : null;

    final initial = AuthState(
      user: user,
      isAuthenticated: isAuthed,
      isLoading: false,
    );

    return TalerIdClient._(
      clientId: clientId,
      redirectUri: redirectUri,
      scope: scope,
      issuer: issuer,
      storage: s,
      backend: b,
      httpClient: httpClient,
      onLog: onLog,
      initialState: initial,
    );
  }

  /// Sync — reads from in-memory cache derived from the most recent storage write.
  bool get isAuthenticated => _state.value.isAuthenticated;

  /// Internal helper used by future tasks. Replaces the current state and
  /// notifies listeners only when the new state differs by [AuthState] equality.
  // ignore: unused_element
  void _emit(AuthState next) {
    if (next != _state.value) _state.value = next;
  }
}
