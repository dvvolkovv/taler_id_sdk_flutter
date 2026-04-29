import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:talerid_oauth/src/storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MemoryStorage', () {
    test('round-trips get/set/remove', () async {
      final s = MemoryStorage();
      expect(await s.get('talerid:k'), isNull);
      await s.set('talerid:k', 'v');
      expect(await s.get('talerid:k'), 'v');
      await s.remove('talerid:k');
      expect(await s.get('talerid:k'), isNull);
    });

    test('isolated per instance', () async {
      final a = MemoryStorage();
      final b = MemoryStorage();
      await a.set('talerid:k', 'v');
      expect(await b.get('talerid:k'), isNull);
    });
  });

  group('SecureStorage', () {
    setUp(() {
      // flutter_secure_storage uses a method channel — mock it.
      const channel =
          MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
      final store = <String, String>{};
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        final args =
            (call.arguments as Map?)?.cast<String, Object?>() ?? const {};
        switch (call.method) {
          case 'write':
            store[args['key'] as String] = args['value'] as String;
            return null;
          case 'read':
            return store[args['key'] as String];
          case 'delete':
            store.remove(args['key'] as String);
            return null;
          case 'readAll':
            return Map<String, String>.from(store);
          case 'deleteAll':
            store.clear();
            return null;
        }
        return null;
      });
    });

    test('round-trips get/set/remove via flutter_secure_storage channel',
        () async {
      final s = SecureStorage();
      expect(await s.get('talerid:k'), isNull);
      await s.set('talerid:k', 'v');
      expect(await s.get('talerid:k'), 'v');
      await s.remove('talerid:k');
      expect(await s.get('talerid:k'), isNull);
    });
  });
}
