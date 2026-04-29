/// Discriminator for [TalerIdAuthError] — every error has one.
enum TalerIdErrorCode {
  /// No active session; integrator should call `login()`.
  loginRequired,

  /// Granted consent has expired or never existed; integrator should call `login()`.
  consentRequired,

  /// Network-level failure (connection refused, timeout, DNS, etc.).
  network,

  /// Misconfiguration — missing or malformed `clientId`/`redirectUri`/etc.
  config,

  /// User dismissed the in-app browser before completing OAuth.
  userCancelled,

  /// Token endpoint returned 4xx (typically `invalid_grant`/`invalid_request`).
  invalidGrant,
}

/// Single error class for all SDK error paths. Discriminate via [code].
class TalerIdAuthError implements Exception {
  /// The error category.
  final TalerIdErrorCode code;

  /// Human-readable message; defaults to the code's [TalerIdErrorCode.name].
  final String message;

  /// Underlying cause, if any (network exception, platform error, etc.).
  final Object? cause;

  /// Constructs a new error. [message] defaults to the code's [TalerIdErrorCode.name].
  TalerIdAuthError({
    required this.code,
    String? message,
    this.cause,
  }) : message = message ?? code.name;

  @override
  String toString() =>
      'TalerIdAuthError(code: ${code.name}, message: $message)';
}
