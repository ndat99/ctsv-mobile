import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({
    required this.config,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  final AppConfig config;
  final Duration timeout;
  final http.Client _client;
  String? _accessToken;
  int _generation = 0;
  Future<bool> Function()? renewSession;

  void beginSession() {
    _generation++;
    _accessToken = null;
  }

  void setAccessToken(String? token) => _accessToken = token;

  Future<http.Response> request(
    String method,
    String path, {
    Map<String, Object?>? body,
    bool authenticated = true,
    String? cookie,
  }) async {
    final generation = _generation;
    final previousToken = _accessToken;
    var response = await _send(method, path, body, authenticated, cookie);
    if (generation != _generation) throw _sessionChanged;
    if (response.statusCode == 401 && authenticated && renewSession != null) {
      final changedToken =
          _accessToken != null && _accessToken != previousToken;
      if (changedToken || await renewSession!()) {
        if (generation != _generation) throw _sessionChanged;
        response = await _send(method, path, body, authenticated, cookie);
      }
    }
    if (generation != _generation) throw _sessionChanged;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromResponse(response);
    }
    return response;
  }

  Future<http.Response> _send(
    String method,
    String path,
    Map<String, Object?>? body,
    bool authenticated,
    String? cookie,
  ) async {
    final cancel = Completer<void>();
    final request = http.AbortableRequest(
      method,
      config.endpoint(path),
      abortTrigger: cancel.future,
    )..followRedirects = false;
    request.headers['Accept'] = 'application/json';
    if (authenticated && _accessToken != null) {
      request.headers['Authorization'] = 'Bearer $_accessToken';
    }
    if (path.startsWith('/api/auth/') && method != 'GET') {
      request.headers['Origin'] = config.authOrigin.origin;
      request.headers['X-CSRF-Protection'] = '1';
    }
    if (cookie != null) {
      if (!path.startsWith('/api/auth/')) {
        throw ArgumentError('Auth cookie scope');
      }
      request.headers['Cookie'] = cookie;
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }
    try {
      return await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
    } on TimeoutException {
      if (!cancel.isCompleted) cancel.complete();
      throw const ApiException(
        'REQUEST_TIMEOUT',
        'Máy chủ phản hồi quá lâu. Vui lòng thử lại.',
      );
    } on http.ClientException {
      throw const ApiException(
        'NETWORK_ERROR',
        'Không kết nối được máy chủ. Vui lòng kiểm tra kết nối rồi thử lại.',
      );
    }
  }

  static const _sessionChanged = ApiException(
    'SESSION_CHANGED',
    'Phiên đăng nhập đã thay đổi. Vui lòng thực hiện lại thao tác.',
  );

  void close() => _client.close();
}
