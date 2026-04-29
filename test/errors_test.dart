import 'package:flutter_test/flutter_test.dart';
import 'package:talerid_oauth/src/errors.dart';

void main() {
  group('TalerIdAuthError', () {
    test('is an Exception with code, message, and optional cause', () {
      final inner = StateError('boom');
      final err = TalerIdAuthError(
        code: TalerIdErrorCode.network,
        message: 'OAuth token request failed',
        cause: inner,
      );
      expect(err, isA<Exception>());
      expect(err.code, TalerIdErrorCode.network);
      expect(err.message, 'OAuth token request failed');
      expect(err.cause, inner);
    });

    test('uses code name as default message when none given', () {
      final err = TalerIdAuthError(code: TalerIdErrorCode.userCancelled);
      expect(err.message, 'userCancelled');
    });

    test('toString includes the code name', () {
      final err = TalerIdAuthError(code: TalerIdErrorCode.invalidGrant);
      expect(err.toString(), contains('invalidGrant'));
    });

    test('all error codes are present', () {
      const expected = {
        TalerIdErrorCode.loginRequired,
        TalerIdErrorCode.consentRequired,
        TalerIdErrorCode.network,
        TalerIdErrorCode.config,
        TalerIdErrorCode.userCancelled,
        TalerIdErrorCode.invalidGrant,
      };
      expect(TalerIdErrorCode.values.toSet(), expected);
    });
  });
}
