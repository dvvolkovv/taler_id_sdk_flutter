import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Pluggable token storage. Implementations must persist the value verbatim.
/// All operations are async because production storages hit platform channels.
abstract class Storage {
  /// Reads the value at [key], or `null` if absent.
  Future<String?> get(String key);

  /// Writes [value] to [key], overwriting any prior value.
  Future<void> set(String key, String value);

  /// Removes [key] if present; no-op if absent.
  Future<void> remove(String key);
}

/// Default storage. Wraps [FlutterSecureStorage] —
/// Keychain on iOS, encrypted SharedPreferences on Android.
class SecureStorage implements Storage {
  final FlutterSecureStorage _inner;

  /// Constructs a SecureStorage with platform-best-practice options.
  SecureStorage()
      : _inner = const FlutterSecureStorage(
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  @override
  Future<String?> get(String key) => _inner.read(key: key);

  @override
  Future<void> set(String key, String value) =>
      _inner.write(key: key, value: value);

  @override
  Future<void> remove(String key) => _inner.delete(key: key);
}

/// In-memory adapter — useful for tests or environments where persistence is undesired.
/// Each instance has its own backing map; data does not survive process restart.
class MemoryStorage implements Storage {
  final Map<String, String> _store = {};

  @override
  Future<String?> get(String key) async => _store[key];

  @override
  Future<void> set(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _store.remove(key);
  }
}
