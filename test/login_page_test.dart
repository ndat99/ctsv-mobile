import 'dart:async';

import 'package:ctsv_mobile/app/ctsv_app.dart';
import 'package:ctsv_mobile/features/auth/application/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'support/auth_fixture.dart';

Future<AuthController> openApp(WidgetTester tester, AuthFixture fixture) async {
  final auth = AuthController(fixture.service);
  addTearDown(auth.dispose);
  await tester.pumpWidget(CtsvApp(config: fixture.api.config, auth: auth));
  await tester.pumpAndSettle();
  return auth;
}

Future<void> fillLogin(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('login-username')), 'sv.test');
  await tester.enterText(find.byKey(const Key('login-password')), 'password');
}

void main() {
  testWidgets('empty fields validate before any network request', (
    tester,
  ) async {
    final fixture = AuthFixture();
    await openApp(tester, fixture);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập tên đăng nhập.'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu.'), findsOneWidget);
    expect(fixture.requests, isEmpty);
  });

  testWidgets('bad credentials show a useful error and retain entered text', (
    tester,
  ) async {
    final fixture = AuthFixture(
      handler: (_) async =>
          jsonResponse({'code': 'AUTHENTICATION_FAILED'}, 401),
    );
    await openApp(tester, fixture);
    await fillLogin(tester);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Tên đăng nhập hoặc mật khẩu không đúng'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('home-page')), findsNothing);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('login-username')))
          .controller!
          .text,
      'sv.test',
    );
    expect(fixture.requests, hasLength(1));
  });

  testWidgets('password is obscured and can be shown explicitly', (
    tester,
  ) async {
    await openApp(tester, AuthFixture());
    final password = find.descendant(
      of: find.byKey(const Key('login-password')),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(password).obscureText, isTrue);
    await tester.tap(find.byTooltip('Hiện mật khẩu'));
    await tester.pump();
    expect(tester.widget<TextField>(password).obscureText, isFalse);
    expect(find.byTooltip('Ẩn mật khẩu'), findsOneWidget);
  });

  testWidgets('sending disables repeated submissions and then opens home', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    final fixture = AuthFixture(
      handler: (request) async {
        if (request.url.path.endsWith('/login')) return pending.future;
        return account();
      },
    );
    await openApp(tester, fixture);
    await fillLogin(tester);
    final submit = find.byKey(const Key('login-submit'));
    await tester.tap(submit);
    await tester.pump();
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    await tester.tap(submit);
    expect(
      fixture.requests.where((r) => r.url.path.endsWith('/login')),
      hasLength(1),
    );
    pending.complete(tokens());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-page')), findsOneWidget);
    expect(find.text('Xin chào, sv.test'), findsOneWidget);
  });

  testWidgets('logout returns to login and clears stored session', (
    tester,
  ) async {
    final fixture = AuthFixture();
    await openApp(tester, fixture);
    await fillLogin(tester);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('logout')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-submit')), findsOneWidget);
    expect(find.byKey(const Key('home-page')), findsNothing);
    expect(fixture.store.value, isNull);
    expect(fixture.requests.last.url.path, '/api/auth/logout');
  });

  testWidgets(
    'existing encrypted session restores without entering credentials',
    (tester) async {
      final original = AuthFixture();
      await original.service.login('sv', 'password');
      original.close();
      final fixture = AuthFixture(store: original.store);
      await openApp(tester, fixture);
      expect(find.byKey(const Key('home-page')), findsOneWidget);
      expect(find.byKey(const Key('login-submit')), findsNothing);
      expect(fixture.requests.first.url.path, '/api/auth/refresh');
    },
  );

  testWidgets('restore network error offers explicit retry and login again', (
    tester,
  ) async {
    final original = AuthFixture();
    await original.service.login('sv', 'password');
    original.close();
    final fixture = AuthFixture(
      store: original.store,
      handler: (_) async {
        throw http.ClientException('offline');
      },
    );
    await openApp(tester, fixture);
    expect(find.text('Chưa thể khôi phục phiên đăng nhập'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(fixture.store.value, isNotNull);
    await tester.tap(find.text('Đăng nhập lại'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-submit')), findsOneWidget);
    expect(fixture.store.value, isNull);
  });

  testWidgets('login fits a small phone viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await openApp(tester, AuthFixture());
    expect(find.byKey(const Key('login-submit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
