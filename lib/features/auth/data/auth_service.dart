import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'auth_user.dart';
import 'session_store.dart';

class AuthService {
  AuthService({
    required this.api,
    required this.store,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    api.renewSession = refresh;
  }

  final ApiClient api;
  final SessionStore store;
  final DateTime Function() _now;
  void Function()? onSessionExpired;
  _RefreshSession? _session;
  Future<bool>? _refreshFlight;
  int _epoch = 0;

  Future<AuthUser?> restore() async {
    final raw = await _storage(store.read);
    if (raw == null) return null;
    try {
      _session = _RefreshSession.fromJson(jsonDecode(raw));
    } on FormatException {
      await _forget();
      return null;
    }
    if (!_session!.isUsable(api.config.apiBaseUri, _now())) {
      await _forget();
      return null;
    }
    if (!await refresh()) return null;
    return _currentUser();
  }

  Future<AuthUser> login(String username, String password) async {
    ++_epoch;
    await _waitForRefresh();
    api.beginSession();
    _session = null;
    await _storage(store.clear);
    _RefreshSession? created;
    try {
      final response = await api.request(
        'POST',
        ApiEndpoints.login,
        authenticated: false,
        body: {'username': username.trim(), 'password': password},
      );
      created = _cookie(response);
      api.setAccessToken(_accessToken(response));
      final user = await _currentUser();
      await _storage(() => store.write(jsonEncode(created!.toJson())));
      _session = created;
      return user;
    } catch (_) {
      api.beginSession();
      if (created != null) unawaited(_revoke(created).catchError((_) {}));
      rethrow;
    }
  }

  /// Concurrent 401 responses share one cookie rotation. Never retry network failures.
  Future<bool> refresh() {
    final existing = _refreshFlight;
    if (existing != null) return existing;
    final future = _refresh();
    _refreshFlight = future;
    return future.whenComplete(() {
      if (identical(_refreshFlight, future)) _refreshFlight = null;
    });
  }

  Future<bool> _refresh() async {
    final session = _session;
    if (session == null || !session.isUsable(api.config.apiBaseUri, _now())) {
      await _expire();
      return false;
    }
    final epoch = _epoch;
    try {
      final response = await api.request(
        'POST',
        ApiEndpoints.refresh,
        authenticated: false,
        body: const {},
        cookie: session.cookieHeader,
      );
      if (epoch != _epoch) return false;
      final rotated = _cookie(response);
      final accessToken = _accessToken(response);
      await _storage(() => store.write(jsonEncode(rotated.toJson())));
      _session = rotated;
      api.setAccessToken(accessToken);
      return true;
    } on ApiException catch (error) {
      if (error.status == 401 && epoch == _epoch) {
        await _expire();
        return false;
      }
      rethrow;
    }
  }

  /// Local sign-out must clear encrypted persistence before reporting success.
  /// Returns a warning if the server could not revoke the already-cleared local session.
  Future<String?> logout() async {
    ++_epoch;
    await _waitForRefresh();
    final session = _session;
    await _forget();
    if (session == null) return null;
    try {
      await _revoke(session);
      return null;
    } catch (_) {
      return 'Đã đăng xuất trên thiết bị. Chưa thể thu hồi phiên trên máy chủ do lỗi kết nối.';
    }
  }

  Future<void> _waitForRefresh() async {
    try {
      await _refreshFlight;
    } catch (_) {
      // A new login/logout owns the next session; the previous renewal cannot publish it.
    }
  }

  Future<void> _revoke(_RefreshSession session) async {
    await api.request(
      'POST',
      ApiEndpoints.logout,
      authenticated: false,
      cookie: session.cookieHeader,
    );
  }

  Future<void> _forget() async {
    await _storage(store.clear);
    api.beginSession();
    _session = null;
  }

  Future<void> _expire() async {
    api.beginSession();
    _session = null;
    try {
      await _forget();
    } finally {
      onSessionExpired?.call();
    }
  }

  Future<AuthUser> _currentUser() async {
    final response = await api.request('GET', ApiEndpoints.currentUser);
    try {
      return AuthUser.fromJson(_object(response));
    } on Object {
      throw _invalidResponse;
    }
  }

  String _accessToken(http.Response response) {
    try {
      final body = _object(response);
      final token = body['accessToken'];
      if (token is! String ||
          token.isEmpty ||
          token.contains(RegExp(r'\s')) ||
          body['tokenType'] != 'Bearer' ||
          body['expiresIn'] is! num ||
          (body['expiresIn'] as num) <= 0) {
        throw const FormatException();
      }
      return token;
    } on Object {
      throw _invalidResponse;
    }
  }

  _RefreshSession _cookie(http.Response response) {
    try {
      final raw = response.headers['set-cookie'];
      if (raw == null) throw const FormatException();
      final cookie = Cookie.fromSetCookieValue(raw);
      if (cookie.name != 'ctsv_refresh' ||
          cookie.value.isEmpty ||
          !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(cookie.value) ||
          cookie.path != '/api/auth' ||
          cookie.maxAge == null ||
          cookie.maxAge! <= 0) {
        throw const FormatException();
      }
      if (cookie.secure && api.config.apiBaseUri.scheme != 'https') {
        throw const ApiException(
          'HTTPS_REQUIRED',
          'Máy chủ yêu cầu kết nối HTTPS để đăng nhập.',
        );
      }
      return _RefreshSession(
        token: cookie.value,
        origin: api.config.apiBaseUri.origin,
        secure: cookie.secure,
        expiresAt: _now().toUtc().add(Duration(seconds: cookie.maxAge!)),
      );
    } on ApiException {
      rethrow;
    } on Object {
      throw _invalidResponse;
    }
  }

  static Map<String, dynamic> _object(http.Response response) =>
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

  static Future<T> _storage<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (_) {
      throw const ApiException(
        'SESSION_STORAGE_ERROR',
        'Không truy cập được vùng lưu phiên an toàn trên thiết bị. Vui lòng thử lại.',
      );
    }
  }

  static const _invalidResponse = ApiException(
    'AUTH_RESPONSE_INVALID',
    'Phản hồi đăng nhập từ máy chủ không hợp lệ. Vui lòng thử lại.',
  );

  void close() => api.close();
}

class _RefreshSession {
  const _RefreshSession({
    required this.token,
    required this.origin,
    required this.secure,
    required this.expiresAt,
  });

  final String token;
  final String origin;
  final bool secure;
  final DateTime expiresAt;
  String get cookieHeader => 'ctsv_refresh=$token';

  bool isUsable(Uri api, DateTime now) =>
      origin == api.origin &&
      (!secure || api.scheme == 'https') &&
      now.toUtc().isBefore(expiresAt);

  Map<String, Object> toJson() => {
    'version': 1,
    'token': token,
    'origin': origin,
    'secure': secure,
    'expiresAt': expiresAt.toIso8601String(),
  };

  factory _RefreshSession.fromJson(Object? value) {
    if (value is! Map ||
        value['version'] != 1 ||
        value['token'] is! String ||
        !(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value['token'] as String)) ||
        value['origin'] is! String ||
        value['secure'] is! bool ||
        value['expiresAt'] is! String) {
      throw const FormatException('Invalid saved session');
    }
    return _RefreshSession(
      token: value['token'] as String,
      origin: value['origin'] as String,
      secure: value['secure'] as bool,
      expiresAt: DateTime.parse(value['expiresAt'] as String),
    );
  }
}
