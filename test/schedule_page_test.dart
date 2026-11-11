import 'dart:async';

import 'package:ctsv_mobile/app/ctsv_app.dart';
import 'package:ctsv_mobile/features/auth/application/auth_controller.dart';
import 'package:ctsv_mobile/features/auth/data/auth_user.dart';
import 'package:ctsv_mobile/features/shcn/data/schedule_repository.dart';
import 'package:ctsv_mobile/features/shcn/presentation/schedule_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'support/auth_fixture.dart';
import 'support/schedule_fixture.dart';

Future<void> openPage(
  WidgetTester tester,
  AuthFixture fixture, {
  AuthUser? user,
}) async {
  addTearDown(fixture.close);
  fixture.api.setAccessToken('student-token');
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SchedulePage(
          repository: ScheduleRepository(fixture.api),
          user: user ?? scheduleUser(),
        ),
      ),
    ),
  );
}

Future<Finder> revealKey(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  return finder;
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = await revealKey(tester, key);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<AuthController> openApp(WidgetTester tester, AuthFixture fixture) async {
  final auth = AuthController(fixture.service);
  addTearDown(auth.dispose);
  await tester.pumpWidget(CtsvApp(config: fixture.api.config, auth: auth));
  await tester.pumpAndSettle();
  await auth.login('sv.test', 'password');
  await tester.pumpAndSettle();
  expect(
    fixture.requests.where((r) => r.url.path.startsWith(schedulePath)),
    isEmpty,
  );
  await tapKey(tester, 'nav-schedules');
  return auth;
}

void main() {
  testWidgets(
    'loading, server pagination and refresh display scoped schedules',
    (tester) async {
      final pending = Completer<http.Response>();
      var first = true;
      final fixture = scheduleFixture(
        read: (request) async {
          if (first) {
            first = false;
            return pending.future;
          }
          final page = int.parse(request.url.queryParameters['page']!);
          return jsonResponse(
            schedulePageJson(
              page: page,
              total: 21,
              items: [
                scheduleJson(id: page + 5)..['tenDot'] = 'Lịch trang $page',
              ],
            ),
          );
        },
      );
      await openPage(tester, fixture);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete(jsonResponse(schedulePageJson(total: 21)));
      await tester.pumpAndSettle();
      expect(find.text('Lịch đã công bố'), findsOneWidget);
      expect(find.text('03/12/2026 · Tiết 11–12'), findsOneWidget);
      expect(find.text('A111'), findsOneWidget);
      await tapKey(tester, 'schedules-next');
      expect(find.text('Lịch trang 1'), findsOneWidget);
      await revealKey(tester, 'schedules-next');
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('schedules-next')))
            .onPressed,
        isNull,
      );
      await tapKey(tester, 'schedules-previous');
      await tapKey(tester, 'schedules-refresh');
      expect(find.text('Lịch trang 0'), findsOneWidget);
      expect(fixture.requests.map((r) => r.url.queryParameters['page']), [
        '0',
        '1',
        '0',
        '0',
      ]);
    },
  );

  testWidgets('failed next page retries that page without showing stale data', (
    tester,
  ) async {
    var failed = false;
    final fixture = scheduleFixture(
      read: (request) async {
        final page = int.parse(request.url.queryParameters['page']!);
        if (page == 1 && !failed) {
          failed = true;
          throw http.ClientException('offline');
        }
        return jsonResponse(schedulePageJson(page: page, total: 21));
      },
    );
    await openPage(tester, fixture);
    await tester.pumpAndSettle();
    await tapKey(tester, 'schedules-next');
    expect(find.textContaining('Không kết nối được máy chủ'), findsOneWidget);
    expect(find.text('A111'), findsNothing);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(fixture.requests.map((r) => r.url.queryParameters['page']), [
      '0',
      '1',
      '1',
    ]);
  });

  testWidgets('empty list stays empty and pull refresh remains available', (
    tester,
  ) async {
    final fixture = scheduleFixture(
      read: (_) async => jsonResponse(schedulePageJson(items: [], total: 0)),
    );
    await openPage(tester, fixture);
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa có lịch SHCN'), findsOneWidget);
    expect(find.text('Xem chi tiết'), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(fixture.requests, hasLength(2));
  });

  for (final user in [
    scheduleUser(permission: false),
    scheduleUser(studentProfileId: null),
  ]) {
    testWidgets(
      'missing student access makes no schedule request: ${user.studentProfileId}/${user.permissions}',
      (tester) async {
        final fixture = scheduleFixture(
          read: (_) async => jsonResponse(schedulePageJson()),
        );
        await openPage(tester, fixture, user: user);
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.lock_outline), findsOneWidget);
        expect(fixture.requests, isEmpty);
      },
    );
  }

  testWidgets('server permission denial is not an empty schedule', (
    tester,
  ) async {
    final fixture = scheduleFixture(
      read: (_) async => jsonResponse({'code': 'ACCESS_DENIED'}, 403),
    );
    await openPage(tester, fixture);
    await tester.pumpAndSettle();
    expect(find.textContaining('chưa có quyền'), findsOneWidget);
    expect(find.textContaining('Chưa có lịch SHCN'), findsNothing);
  });

  testWidgets(
    'unpublished detail keeps current and proposed dates separate on a small phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = scheduleFixture(
        read: (request) async => request.url.path == schedulePath
            ? jsonResponse(schedulePageJson())
            : jsonResponse(
                scheduleJson(
                  published: false,
                  changeRequest: changeRequestJson(),
                ),
              ),
      );
      await openPage(tester, fixture);
      await tester.pumpAndSettle();
      await tapKey(tester, 'schedule-5');
      expect(find.text('Nguyện vọng chưa công bố'), findsOneWidget);
      expect(find.text('03/12/2026 · Tiết 11–12'), findsOneWidget);
      expect(find.text('A111'), findsNothing);
      expect(find.byKey(const Key('schedule-copy-link')), findsNothing);
      await tester.scrollUntilVisible(
        find.text('05/12/2026 · Tiết 7–8'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Chờ xử lý yêu cầu đổi lịch'), findsOneWidget);
      expect(find.text('05/12/2026 · Tiết 7–8'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Chốt lịch họp'), findsNothing);
      expect(tester.takeException(), isNull);
      await tapKey(tester, 'schedule-back');
      expect(find.byKey(const Key('schedule-page')), findsOneWidget);
      expect(fixture.requests.every((r) => r.method == 'GET'), isTrue);
    },
  );

  testWidgets('published online detail copies a valid meeting URL', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final fixture = scheduleFixture(
      read: (request) async => request.url.path == schedulePath
          ? jsonResponse(schedulePageJson(items: [scheduleJson(online: true)]))
          : jsonResponse(scheduleJson(online: true)),
    );
    await openPage(tester, fixture);
    await tester.pumpAndSettle();
    await tapKey(tester, 'schedule-5');
    await tapKey(tester, 'schedule-copy-link');
    expect(copied, 'https://meet.example.com/shcn');
    expect(find.text('Đã sao chép link họp'), findsOneWidget);
  });

  testWidgets(
    'removed detail reports out of scope and Android back returns to list',
    (tester) async {
      final fixture = scheduleFixture(
        read: (request) async => request.url.path == schedulePath
            ? jsonResponse(schedulePageJson())
            : jsonResponse({'code': 'SHCN_KHONG_TIM_THAY'}, 404),
      );
      await openPage(tester, fixture);
      await tester.pumpAndSettle();
      await tapKey(tester, 'schedule-5');
      expect(
        find.textContaining('không còn thuộc phạm vi được xem'),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('schedule-page')), findsOneWidget);
    },
  );

  testWidgets('late list response cannot replace a newer refresh', (
    tester,
  ) async {
    final old = Completer<http.Response>();
    var calls = 0;
    final fixture = scheduleFixture(
      read: (_) async {
        calls++;
        if (calls == 1) return old.future;
        return jsonResponse(
          schedulePageJson(items: [scheduleJson()..['tenDot'] = 'Lịch mới']),
        );
      },
    );
    await openPage(tester, fixture);
    final refresh = tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    await tester.pumpAndSettle();
    await refresh;
    old.complete(jsonResponse(schedulePageJson()));
    await tester.pumpAndSettle();
    expect(find.text('Lịch mới'), findsOneWidget);
    expect(find.text('Sinh hoạt chủ nhiệm học kỳ I'), findsNothing);
  });

  testWidgets('expired session closes schedule detail and returns to login', (
    tester,
  ) async {
    var expired = false;
    final fixture = scheduleFixture(
      sessionExpired: () => expired,
      read: (request) async {
        if (request.url.path == schedulePath) {
          return jsonResponse(schedulePageJson());
        }
        expired = true;
        return jsonResponse({'code': 'UNAUTHENTICATED'}, 401);
      },
    );
    await openApp(tester, fixture);
    await tapKey(tester, 'schedule-5');
    expect(find.byKey(const Key('login-submit')), findsOneWidget);
    expect(find.byKey(const Key('schedule-detail')), findsNothing);
    expect(fixture.store.value, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('logout removes late detail data', (tester) async {
    final pending = Completer<http.Response>();
    final fixture = scheduleFixture(
      read: (request) async => request.url.path == schedulePath
          ? jsonResponse(schedulePageJson())
          : pending.future,
    );
    final auth = await openApp(tester, fixture);
    await revealKey(tester, 'schedule-5');
    await tester.tap(find.byKey(const Key('schedule-5')));
    await tester.pump();
    expect(fixture.requests.last.url.path, '$schedulePath/5');
    expect(find.byKey(const Key('schedule-detail')), findsOneWidget);
    await auth.logout();
    await tester.pumpAndSettle();
    pending.complete(jsonResponse(scheduleJson()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-submit')), findsOneWidget);
    expect(find.byKey(const Key('schedule-detail')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back ignores an inactive schedule detail when switching tabs', (
    tester,
  ) async {
    final fixture = scheduleFixture(
      read: (request) async => request.url.path == schedulePath
          ? jsonResponse(schedulePageJson())
          : jsonResponse(scheduleJson()),
    );
    await openApp(tester, fixture);
    await tapKey(tester, 'schedule-5');
    await tapKey(tester, 'nav-scholarships');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tapKey(tester, 'nav-schedules');
    expect(find.byKey(const Key('schedule-detail')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('schedule-page')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
