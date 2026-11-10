import 'package:ctsv_mobile/features/auth/data/session_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('vn.edu.dut.ctsv.mobile/session');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'secure storage adapter uses the native read/write/delete contract',
    () async {
      String? stored;
      final methods = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        methods.add(call.method);
        switch (call.method) {
          case 'read':
            return stored;
          case 'write':
            stored = call.arguments as String;
            return null;
          case 'delete':
            stored = null;
            return null;
        }
        throw MissingPluginException();
      });
      const store = SecureSessionStore();
      expect(await store.read(), isNull);
      await store.write('encrypted-by-native-layer');
      expect(await store.read(), 'encrypted-by-native-layer');
      await store.clear();
      expect(await store.read(), isNull);
      expect(methods, ['read', 'write', 'read', 'delete', 'read']);
    },
  );
}
