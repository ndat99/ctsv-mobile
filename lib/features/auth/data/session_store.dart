import 'package:flutter/services.dart';

abstract interface class SessionStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

/// Android encrypts this payload with a non-exportable Android Keystore key.
class SecureSessionStore implements SessionStore {
  const SecureSessionStore();

  static const _channel = MethodChannel('vn.edu.dut.ctsv.mobile/session');

  @override
  Future<String?> read() => _channel.invokeMethod<String>('read');

  @override
  Future<void> write(String value) =>
      _channel.invokeMethod<void>('write', value);

  @override
  Future<void> clear() => _channel.invokeMethod<void>('delete');
}
