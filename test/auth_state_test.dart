import 'package:flutter_test/flutter_test.dart';
import 'package:talerid_oauth/src/auth_state.dart';

void main() {
  group('UserInfo', () {
    test('exposes sub and arbitrary claims', () {
      final user = const UserInfo(
          sub: 'u-1', claims: {'email': 'u@example.com', 'name': 'Alice'});
      expect(user.sub, 'u-1');
      expect(user.email, 'u@example.com');
      expect(user.name, 'Alice');
      expect(user.claim<String>('email'), 'u@example.com');
      expect(user.claim<String>('missing'), isNull);
    });

    test('equality is value-based', () {
      final a = const UserInfo(sub: 'u-1', claims: {'email': 'a'});
      final b = const UserInfo(sub: 'u-1', claims: {'email': 'a'});
      expect(a, equals(b));
    });

    test('serializes to and from JSON', () {
      final user = const UserInfo(sub: 'u-1', claims: {'email': 'u@x.com'});
      final json = user.toJson();
      final restored = UserInfo.fromJson(json);
      expect(restored, equals(user));
    });
  });

  group('AuthState', () {
    test('equality reflects all fields', () {
      const a = AuthState(user: null, isAuthenticated: false, isLoading: true);
      const b = AuthState(user: null, isAuthenticated: false, isLoading: true);
      const c = AuthState(user: null, isAuthenticated: false, isLoading: false);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
