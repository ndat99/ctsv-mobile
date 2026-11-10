import 'dart:async';
import 'dart:convert';

import 'package:ctsv_mobile/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'support/auth_fixture.dart';

void main() {
  test('an old account response cannot retry under a new login', () async {
    final oldResponse = Completer<http.Response>();
    var loginCount = 0;
    final fixture = AuthFixture(
      handler: (request) async {
        switch (request.url.path) {
          case '/api/auth/login':
            loginCount++;
            return tokens(
              accessToken: 'access-$loginCount',
              refreshToken: 'refresh-$loginCount',
            );
          case '/api/auth/me':
            return account();
          case '/api/auth/logout':
            return http.Response('', 204);
          case '/api/shcn/lich-hop':
            return oldResponse.future;
          default:
            throw StateError('Unexpected refresh');
        }
      },
    );
    addTearDown(fixture.close);
    await fixture.service.login('first', 'password');
    final read = fixture.api.request('GET', '/api/shcn/lich-hop');
    final rejected = expectLater(
      read,
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'SESSION_CHANGED'),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    await fixture.service.logout();
    await fixture.service.login('second', 'password');
    oldResponse.complete(jsonResponse({'code': 'ACCESS_TOKEN_INVALID'}, 401));
    await rejected;
    final reads = fixture.requests.where(
      (r) => r.url.path == '/api/shcn/lich-hop',
    );
    expect(reads, hasLength(1));
    expect(reads.single.headers['Authorization'], 'Bearer access-1');
    expect(fixture.store.value, contains('refresh-2'));
  });

  test('logout waits for cookie rotation and cannot be undone by it', () async {
    final rotation = Completer<http.Response>();
    final fixture = AuthFixture(
      handler: (request) async {
        switch (request.url.path) {
          case '/api/auth/login':
            return tokens();
          case '/api/auth/me':
            return account();
          case '/api/auth/refresh':
            return rotation.future;
          case '/api/auth/logout':
            return http.Response('', 204);
          default:
            throw StateError('Unexpected endpoint');
        }
      },
    );
    addTearDown(fixture.close);
    await fixture.service.login('sv', 'password');
    final refresh = fixture.service.refresh();
    await Future<void>.delayed(Duration.zero);
    final logout = fixture.service.logout();
    expect(
      fixture.requests.where((r) => r.url.path.endsWith('/logout')),
      isEmpty,
    );
    rotation.complete(
      tokens(accessToken: 'access-B', refreshToken: 'refresh-B'),
    );
    expect(await refresh, isFalse);
    expect(await logout, isNull);
    expect(fixture.store.value, isNull);
    // The consumed token still identifies its session for backend logout.
    expect(fixture.requests.last.headers['Cookie'], 'ctsv_refresh=refresh-A');
  });

  test('failed account lookup does not publish or persist a login', () async {
    final fixture = AuthFixture(
      handler: (request) async {
        if (request.url.path.endsWith('/login')) return tokens();
        if (request.url.path.endsWith('/logout')) return http.Response('', 204);
        return jsonResponse({'code': 'ACCESS_DENIED'}, 403);
      },
    );
    addTearDown(fixture.close);
    await expectLater(
      fixture.service.login('sv', 'password'),
      throwsA(isA<ApiException>()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(fixture.store.value, isNull);
    expect(fixture.requests.last.url.path, '/api/auth/logout');
  });

  test(
    'login sends JSON, Origin/CSRF then verifies /me using Bearer',
    () async {
      final fixture = AuthFixture();
      addTearDown(fixture.close);
      final user = await fixture.service.login(' sv.test ', '  mật khẩu  ');
      expect(user.username, 'sv.test');
      expect(user.studentProfileId, 12);
      final login = fixture.requests.first;
      expect(login.method, 'POST');
      expect(login.headers['Origin'], 'http://localhost:5173');
      expect(login.headers['X-CSRF-Protection'], '1');
      expect(login.headers['Content-Type'], contains('application/json'));
      expect(login.followRedirects, isFalse);
      expect(jsonDecode(login.body), {
        'username': 'sv.test',
        'password': '  mật khẩu  ',
      });
      expect(login.headers['Authorization'], isNull);
      expect(fixture.requests.last.headers['Authorization'], 'Bearer access-A');
      expect(fixture.requests.last.headers['Cookie'], isNull);
      expect(fixture.store.value, contains('refresh-A'));
      expect(fixture.store.value, isNot(contains('access-A')));
      expect(fixture.store.value, isNot(contains('mật khẩu')));
    },
  );

  test('bad credentials preserve no session and are never retried', () async {
    final fixture = AuthFixture(
      handler: (_) async =>
          jsonResponse({'code': 'AUTHENTICATION_FAILED'}, 401),
    );
    addTearDown(fixture.close);
    await expectLater(
      fixture.service.login('sv.test', 'bad'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          contains('Tên đăng nhập hoặc mật khẩu'),
        ),
      ),
    );
    expect(fixture.requests, hasLength(1));
    expect(fixture.store.value, isNull);
  });

  test('network failure does not repeat a login request', () async {
    final fixture = AuthFixture(
      handler: (_) async {
        throw http.ClientException('offline');
      },
    );
    addTearDown(fixture.close);
    await expectLater(
      fixture.service.login('sv', 'password'),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'NETWORK_ERROR'),
      ),
    );
    expect(fixture.requests, hasLength(1));
    expect(fixture.store.value, isNull);
  });

  test('timeout covers response and late completion never signs in', () async {
    final pending = Completer<http.Response>();
    final fixture = AuthFixture(
      timeout: const Duration(milliseconds: 10),
      handler: (_) => pending.future,
    );
    addTearDown(fixture.close);
    await expectLater(
      fixture.service.login('sv', 'password'),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'REQUEST_TIMEOUT'),
      ),
    );
    pending.complete(tokens());
    await Future<void>.delayed(Duration.zero);
    expect(fixture.store.value, isNull);
    expect(fixture.requests, hasLength(1));
  });

  test(
    'restoration rotates saved cookie and obtains current account',
    () async {
      final initial = AuthFixture();
      await initial.service.login('sv', 'password');
      initial.close();
      final restored = AuthFixture(
        store: initial.store,
        handler: (request) async {
          if (request.url.path.endsWith('/refresh')) {
            expect(request.headers['Cookie'], 'ctsv_refresh=refresh-A');
            expect(request.headers['Authorization'], isNull);
            expect(request.headers['X-CSRF-Protection'], '1');
            expect(jsonDecode(request.body), isEmpty);
            return tokens(accessToken: 'access-B', refreshToken: 'refresh-B');
          }
          expect(request.headers['Authorization'], 'Bearer access-B');
          return account(username: 'restored.student');
        },
      );
      addTearDown(restored.close);
      expect((await restored.service.restore())?.username, 'restored.student');
      expect(restored.store.value, contains('refresh-B'));
      expect(restored.requests.map((r) => r.url.path), [
        '/api/auth/refresh',
        '/api/auth/me',
      ]);
    },
  );

  test(
    'corrupt, expired and different-server sessions are cleared locally',
    () async {
      for (final raw in [
        '{broken',
        jsonEncode({
          'version': 1,
          'token': 'refresh-A',
          'origin': 'http://different:8080',
          'secure': false,
          'expiresAt': '2027-01-01T00:00:00Z',
        }),
        jsonEncode({
          'version': 1,
          'token': 'refresh-A',
          'origin': 'http://localhost:8080',
          'secure': false,
          'expiresAt': AuthFixture.now.toIso8601String(),
        }),
      ]) {
        final store = MemorySessionStore()..value = raw;
        final fixture = AuthFixture(store: store);
        expect(await fixture.service.restore(), isNull);
        expect(store.value, isNull);
        expect(fixture.requests, isEmpty);
        fixture.close();
      }
    },
  );

  test(
    'concurrent 401 requests rotate once and replay each read once',
    () async {
      var refreshCount = 0;
      var rejected = 0;
      final bothRejected = Completer<void>();
      final fixture = AuthFixture(
        handler: (request) async {
          switch (request.url.path) {
            case '/api/auth/login':
              return tokens();
            case '/api/auth/me':
              return account();
            case '/api/auth/refresh':
              refreshCount++;
              await bothRejected.future;
              return tokens(accessToken: 'access-B', refreshToken: 'refresh-B');
            default:
              expect(request.headers['Cookie'], isNull);
              if (request.headers['Authorization'] == 'Bearer access-A') {
                if (++rejected == 2) bothRejected.complete();
                return jsonResponse({'code': 'ACCESS_TOKEN_INVALID'}, 401);
              }
              expect(request.headers['Authorization'], 'Bearer access-B');
              return jsonResponse({'ok': true});
          }
        },
      );
      addTearDown(fixture.close);
      await fixture.service.login('sv', 'password');
      final results = await Future.wait([
        fixture.api.request('GET', '/api/shcn/lich-hop'),
        fixture.api.request('GET', '/api/hoc-bong/tai-tro/thong-bao'),
      ]);
      expect(results.every((r) => r.statusCode == 200), isTrue);
      expect(refreshCount, 1);
      expect(rejected, 2);
      expect(fixture.store.value, contains('refresh-B'));
    },
  );

  test('invalid refresh clears session and notifies expiration', () async {
    final fixture = AuthFixture(
      handler: (request) async {
        if (request.url.path.endsWith('/login')) return tokens();
        if (request.url.path.endsWith('/me')) return account();
        return jsonResponse({'code': 'REFRESH_TOKEN_REUSED'}, 401);
      },
    );
    addTearDown(fixture.close);
    var expired = false;
    fixture.service.onSessionExpired = () => expired = true;
    await fixture.service.login('sv', 'password');
    expect(await fixture.service.refresh(), isFalse);
    expect(expired, isTrue);
    expect(fixture.store.value, isNull);
  });

  test(
    'temporary refresh failure preserves cookie for an explicit retry',
    () async {
      final fixture = AuthFixture(
        handler: (request) async {
          if (request.url.path.endsWith('/login')) return tokens();
          if (request.url.path.endsWith('/me')) return account();
          throw http.ClientException('offline');
        },
      );
      addTearDown(fixture.close);
      await fixture.service.login('sv', 'password');
      final saved = fixture.store.value;
      await expectLater(
        fixture.service.refresh(),
        throwsA(isA<ApiException>()),
      );
      expect(fixture.store.value, saved);
      expect(
        fixture.requests.where((r) => r.url.path.endsWith('/refresh')),
        hasLength(1),
      );
    },
  );

  test(
    'logout deletes persistence and sends scoped cookie to backend',
    () async {
      final fixture = AuthFixture();
      addTearDown(fixture.close);
      await fixture.service.login('sv', 'password');
      expect(await fixture.service.logout(), isNull);
      final logout = fixture.requests.last;
      expect(logout.url.path, '/api/auth/logout');
      expect(logout.headers['Cookie'], 'ctsv_refresh=refresh-A');
      expect(logout.headers['Origin'], 'http://localhost:5173');
      expect(logout.headers['X-CSRF-Protection'], '1');
      expect(fixture.store.value, isNull);
    },
  );

  test(
    'offline logout clears local session and reports server uncertainty',
    () async {
      final fixture = AuthFixture(
        handler: (request) async {
          if (request.url.path.endsWith('/login')) return tokens();
          if (request.url.path.endsWith('/me')) return account();
          throw http.ClientException('offline');
        },
      );
      addTearDown(fixture.close);
      await fixture.service.login('sv', 'password');
      expect(
        await fixture.service.logout(),
        contains('Đã đăng xuất trên thiết bị'),
      );
      expect(fixture.store.value, isNull);
    },
  );

  test(
    'failed local deletion does not falsely report a successful logout',
    () async {
      final fixture = AuthFixture();
      addTearDown(fixture.close);
      await fixture.service.login('sv', 'password');
      fixture.store.failClear = true;
      await expectLater(fixture.service.logout(), throwsA(isA<ApiException>()));
      expect(fixture.store.value, isNotNull);
      await fixture.api.request('GET', '/api/auth/me');
      expect(fixture.requests.last.headers['Authorization'], 'Bearer access-A');
      expect(
        fixture.requests.where((r) => r.url.path.endsWith('/logout')),
        isEmpty,
      );
    },
  );

  test(
    'failed secure write never completes login and revokes created session',
    () async {
      final fixture = AuthFixture(
        store: MemorySessionStore()..failWrite = true,
      );
      addTearDown(fixture.close);
      await expectLater(
        fixture.service.login('sv', 'password'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'SESSION_STORAGE_ERROR',
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(fixture.store.value, isNull);
      expect(fixture.requests.last.url.path, '/api/auth/logout');
    },
  );

  test('secure cookies cannot be reused over an HTTP backend', () async {
    final fixture = AuthFixture(handler: (_) async => tokens(secure: true));
    addTearDown(fixture.close);
    await expectLater(
      fixture.service.login('sv', 'password'),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'HTTPS_REQUIRED'),
      ),
    );
    expect(fixture.store.value, isNull);
  });

  test(
    'redirects and server errors never repeat login or persist a session',
    () async {
      for (final status in [302, 403, 500]) {
        final fixture = AuthFixture(
          handler: (_) async => http.Response('error', status),
        );
        await expectLater(
          fixture.service.login('sv', 'password'),
          throwsA(isA<ApiException>()),
        );
        expect(fixture.requests, hasLength(1));
        expect(fixture.store.value, isNull);
        fixture.close();
      }
    },
  );
}
