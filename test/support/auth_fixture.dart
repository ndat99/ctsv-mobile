import 'dart:convert';

import 'package:ctsv_mobile/core/config/app_config.dart';
import 'package:ctsv_mobile/core/network/api_client.dart';
import 'package:ctsv_mobile/features/auth/data/auth_service.dart';
import 'package:ctsv_mobile/features/auth/data/session_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MemorySessionStore implements SessionStore {
  String? value;
  bool failWrite = false;
  bool failClear = false;
  bool failRead = false;

  @override
  Future<String?> read() async {
    if (failRead) throw StateError('read failed');
    return value;
  }

  @override
  Future<void> write(String value) async {
    if (failWrite) throw StateError('write failed');
    this.value = value;
  }

  @override
  Future<void> clear() async {
    if (failClear) throw StateError('clear failed');
    value = null;
  }
}

class AuthFixture {
  AuthFixture({
    Future<http.Response> Function(http.Request)? handler,
    MemorySessionStore? store,
    Duration timeout = const Duration(seconds: 20),
    String origin = 'http://localhost:8080',
  }) : store = store ?? MemorySessionStore() {
    api = ApiClient(
      config: AppConfig(apiBaseUri: Uri.parse(origin)),
      timeout: timeout,
      client: MockClient((request) async {
        requests.add(request);
        if (handler != null) return handler(request);
        return switch (request.url.path) {
          '/api/auth/login' => tokens(),
          '/api/auth/refresh' => tokens(
            accessToken: 'access-B',
            refreshToken: 'refresh-B',
          ),
          '/api/auth/me' => account(),
          '/api/auth/logout' => http.Response('', 204),
          _ => jsonResponse({'code': 'UNAUTHORIZED'}, 401),
        };
      }),
    );
    service = AuthService(api: api, store: this.store, now: () => now);
  }

  static final now = DateTime.utc(2026, 11, 10, 12);
  final MemorySessionStore store;
  final requests = <http.Request>[];
  late final ApiClient api;
  late final AuthService service;

  void close() => service.close();
}

http.Response jsonResponse(Map<String, Object?> body, [int status = 200]) =>
    http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

http.Response tokens({
  String accessToken = 'access-A',
  String refreshToken = 'refresh-A',
  bool secure = false,
}) => http.Response(
  jsonEncode({
    'accessToken': accessToken,
    'tokenType': 'Bearer',
    'expiresIn': 900,
  }),
  200,
  headers: {
    'content-type': 'application/json; charset=utf-8',
    'set-cookie':
        'ctsv_refresh=$refreshToken; Path=/api/auth; Max-Age=604800; '
        'HttpOnly; SameSite=Lax${secure ? '; Secure' : ''}',
  },
);

http.Response account({String username = 'sv.test'}) => jsonResponse({
  'id': 1,
  'maTaiKhoan': 'SV_TEST',
  'username': username,
  'hoSoSVID': 12,
  'hoSoCanBoID': null,
  'roles': ['SINH_VIEN'],
  'permissions': ['SHCN_LICH_XEM', 'HB_TT_XEM'],
});
