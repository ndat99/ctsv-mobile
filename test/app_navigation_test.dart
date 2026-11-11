import 'package:ctsv_mobile/app/ctsv_app.dart';
import 'package:ctsv_mobile/core/config/app_config.dart';
import 'package:ctsv_mobile/features/auth/application/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/auth_fixture.dart';

void main() {
  testWidgets('student shell opens each module and returns home', (
    tester,
  ) async {
    final fixture = AuthFixture();
    final auth = AuthController(fixture.service);
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      CtsvApp(
        config: AppConfig(apiBaseUri: Uri.parse('http://localhost:8080')),
        auth: auth,
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('login-username')), 'sv.test');
    await tester.enterText(find.byKey(const Key('login-password')), 'password');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-page')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-training-score')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('training-score-page')), findsOneWidget);
    expect(find.text('Chức năng chưa được triển khai.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-tuition-reduction')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tuition-reduction-page')), findsOneWidget);
    expect(find.text('Chức năng chưa được triển khai.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-schedules')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('schedule-page')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-scholarships')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('scholarships-page')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-page')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
