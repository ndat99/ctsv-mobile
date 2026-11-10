import 'package:ctsv_mobile/app/ctsv_app.dart';
import 'package:ctsv_mobile/core/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('student shell opens each module and returns home', (
    tester,
  ) async {
    await tester.pumpWidget(
      CtsvApp(
        config: AppConfig(apiBaseUri: Uri.parse('http://localhost:8080')),
      ),
    );
    expect(find.byKey(const Key('home-page')), findsOneWidget);

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
