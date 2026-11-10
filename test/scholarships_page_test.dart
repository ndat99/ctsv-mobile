import 'dart:async';

import 'package:ctsv_mobile/app/ctsv_app.dart';
import 'package:ctsv_mobile/features/auth/application/auth_controller.dart';
import 'package:ctsv_mobile/features/auth/data/auth_user.dart';
import 'package:ctsv_mobile/features/scholarships/data/scholarship_repository.dart';
import 'package:ctsv_mobile/features/scholarships/presentation/scholarships_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'support/auth_fixture.dart';
import 'support/scholarship_fixture.dart';

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
        body: ScholarshipsPage(
          repository: ScholarshipRepository(fixture.api),
          user: user ?? scholarshipUser(),
        ),
      ),
    ),
  );
}

Future<AuthController> openApp(WidgetTester tester, AuthFixture fixture) async {
  final auth = AuthController(fixture.service);
  addTearDown(auth.dispose);
  await tester.pumpWidget(CtsvApp(config: fixture.api.config, auth: auth));
  await tester.pumpAndSettle();
  await auth.login('sv.test', 'password');
  await tester.pumpAndSettle();
  // Do not fetch the scholarship API until the student opens the tab.
  expect(
    fixture.requests.where((r) => r.url.path.startsWith(scholarshipPath)),
    isEmpty,
  );
  await tester.tap(find.byKey(const Key('nav-scholarships')));
  await tester.pumpAndSettle();
  return auth;
}

void main() {
  testWidgets('loading, pagination and refresh use the requested page', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    var first = true;
    final fixture = scholarshipFixture(
      read: (request) async {
        if (first) {
          first = false;
          return pending.future;
        }
        final page = int.parse(request.url.queryParameters['page']!);
        return jsonResponse(
          scholarshipPageJson(
            page: page,
            hasNext: page == 0,
            items: [
              announcementJson(id: 11 + page, title: 'Học bổng trang $page'),
            ],
          ),
        );
      },
    );
    await openPage(tester, fixture);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(jsonResponse(scholarshipPageJson(hasNext: true)));
    await tester.pumpAndSettle();
    expect(find.text('5.000.000 ₫'), findsOneWidget);
    expect(find.text('Hạn nộp: 01/12/2026 00:00'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('scholarships-next')));
    await tester.tap(find.byKey(const Key('scholarships-next')));
    await tester.pumpAndSettle();
    expect(find.text('Học bổng trang 1'), findsOneWidget);
    expect(find.text('Trang 2'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('scholarships-next')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('scholarships-refresh')));
    await tester.pumpAndSettle();
    expect(find.text('Học bổng trang 0'), findsOneWidget);
    expect(fixture.requests.map((r) => r.url.queryParameters['page']), [
      '0',
      '1',
      '0',
    ]);
  });

  testWidgets('network retry stays on the failed next page', (tester) async {
    var failed = false;
    final fixture = scholarshipFixture(
      read: (request) async {
        final page = int.parse(request.url.queryParameters['page']!);
        if (page == 1 && !failed) {
          failed = true;
          throw http.ClientException('offline');
        }
        return jsonResponse(
          scholarshipPageJson(page: page, hasNext: page == 0),
        );
      },
    );
    await openPage(tester, fixture);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('scholarships-next')));
    await tester.tap(find.byKey(const Key('scholarships-next')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Không kết nối được máy chủ'), findsOneWidget);
    expect(find.text('Học bổng Tiếp sức đến trường'), findsNothing);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Trang 2'), findsOneWidget);
    expect(fixture.requests.map((r) => r.url.queryParameters['page']), [
      '0',
      '1',
      '1',
    ]);
  });

  testWidgets(
    'empty list has no fabricated data and supports pull to refresh',
    (tester) async {
      final fixture = scholarshipFixture(
        read: (_) async => jsonResponse(scholarshipPageJson(items: [])),
      );
      await openPage(tester, fixture);
      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa có thông báo học bổng'), findsOneWidget);
      expect(find.text('Xem chi tiết'), findsNothing);
      await tester.drag(find.byType(ListView), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(fixture.requests, hasLength(2));
    },
  );

  for (final user in [
    scholarshipUser(permission: false),
    scholarshipUser(studentProfileId: null),
  ]) {
    testWidgets(
      'missing student access does not fetch data: ${user.studentProfileId}/${user.permissions}',
      (tester) async {
        final fixture = scholarshipFixture(
          read: (_) async => jsonResponse(scholarshipPageJson()),
        );
        await openPage(tester, fixture, user: user);
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.lock_outline), findsOneWidget);
        expect(fixture.requests, isEmpty);
      },
    );
  }

  testWidgets('backend permission denial is an error, not an empty list', (
    tester,
  ) async {
    final fixture = scholarshipFixture(
      read: (_) async =>
          jsonResponse({'code': 'STUDENT_PROFILE_REQUIRED'}, 403),
    );
    await openPage(tester, fixture);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('chưa liên kết hồ sơ sinh viên'),
      findsOneWidget,
    );
    expect(find.textContaining('Chưa có thông báo học bổng'), findsNothing);
  });

  testWidgets(
    'detail shows current content and read-only form then returns to list',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = scholarshipFixture(
        read: (request) async {
          if (request.url.path == scholarshipPath) {
            return jsonResponse(scholarshipPageJson());
          }
          return jsonResponse(
            announcementJson(
              title: 'Thông báo đã cập nhật',
              accepting: false,
              form: {
                'formId': 9,
                'ten': 'Hồ sơ tài trợ',
                'phienBan': 2,
                'dinhNghia': {
                  'fields': [
                    {
                      'code': 'minhChung',
                      'label': 'Giấy xác nhận',
                      'type': 'FILE',
                      'required': true,
                    },
                  ],
                },
                'quyTac': {
                  'fields': {
                    'minhChung': {
                      'maxFiles': 1,
                      'allowedExtensions': ['pdf'],
                    },
                  },
                },
              },
            ),
          );
        },
      );
      await openPage(tester, fixture);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('scholarship-11')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('scholarship-detail')), findsOneWidget);
      expect(find.text('Thông báo đã cập nhật'), findsOneWidget);
      expect(find.text('Không nhận hồ sơ'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Nội dung và điều kiện'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('diemToiThieu: 3.2'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Giấy xác nhận (Bắt buộc)'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Đuôi tệp: pdf'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Nộp hồ sơ'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('scholarship-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('scholarships-page')), findsOneWidget);
      expect(fixture.requests, hasLength(2));
      expect(fixture.requests.every((r) => r.method == 'GET'), isTrue);
    },
  );

  testWidgets(
    'removed announcement has an explicit message and Android back works',
    (tester) async {
      final fixture = scholarshipFixture(
        read: (request) async => request.url.path == scholarshipPath
            ? jsonResponse(scholarshipPageJson())
            : jsonResponse({'code': 'HBTT_NOT_FOUND'}, 404),
      );
      await openPage(tester, fixture);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('scholarship-11')));
      await tester.pumpAndSettle();
      expect(find.textContaining('không còn được công khai'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('scholarships-page')), findsOneWidget);
    },
  );

  testWidgets('expired session removes the detail and returns to login', (
    tester,
  ) async {
    var expired = false;
    final fixture = scholarshipFixture(
      sessionExpired: () => expired,
      read: (request) async {
        if (request.url.path == scholarshipPath) {
          return jsonResponse(scholarshipPageJson());
        }
        expired = true;
        return jsonResponse({'code': 'UNAUTHENTICATED'}, 401);
      },
    );
    await openApp(tester, fixture);
    await tester.tap(find.byKey(const Key('scholarship-11')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-submit')), findsOneWidget);
    expect(find.byKey(const Key('scholarship-detail')), findsNothing);
    expect(fixture.store.value, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('logout discards late detail responses', (tester) async {
    final pending = Completer<http.Response>();
    final fixture = scholarshipFixture(
      read: (request) async => request.url.path == scholarshipPath
          ? jsonResponse(scholarshipPageJson())
          : pending.future,
    );
    final auth = await openApp(tester, fixture);
    await tester.tap(find.byKey(const Key('scholarship-11')));
    await tester.pump();
    await auth.logout();
    await tester.pumpAndSettle();
    pending.complete(jsonResponse(announcementJson()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-submit')), findsOneWidget);
    expect(find.text('Học bổng Tiếp sức đến trường'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
