import 'package:ctsv_mobile/core/network/api_exception.dart';
import 'package:ctsv_mobile/features/scholarships/data/scholarship_announcement.dart';
import 'package:ctsv_mobile/features/scholarships/data/scholarship_repository.dart';
import 'package:ctsv_mobile/features/scholarships/presentation/scholarship_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'support/auth_fixture.dart';
import 'support/scholarship_fixture.dart';

void main() {
  test(
    'list uses student bearer token and backend pagination contract',
    () async {
      final fixture = scholarshipFixture(
        read: (request) async {
          expect(request.method, 'GET');
          expect(request.url.path, scholarshipPath);
          expect(request.url.queryParameters, {'page': '2', 'size': '12'});
          expect(request.headers['Authorization'], 'Bearer student-token');
          expect(request.headers.containsKey('Cookie'), isFalse);
          return jsonResponse(scholarshipPageJson(page: 2, hasNext: true));
        },
      );
      addTearDown(fixture.close);
      fixture.api.setAccessToken('student-token');
      final result = await ScholarshipRepository(fixture.api).list(page: 2);
      expect(result.page, 2);
      expect(result.hasNext, isTrue);
      expect(result.items.single.title, 'Học bổng Tiếp sức đến trường');
      expect(result.items.single.form, isNull);
    },
  );

  test('empty response stays empty without synthetic announcements', () async {
    final fixture = scholarshipFixture(
      read: (_) async => jsonResponse(scholarshipPageJson(items: [])),
    );
    addTearDown(fixture.close);
    final result = await ScholarshipRepository(fixture.api).list();
    expect(result.items, isEmpty);
    expect(result.hasNext, isFalse);
  });

  test('detail parses all seven form types and nullable rules', () async {
    const types = [
      'TEXT',
      'NUMBER',
      'DATE',
      'BOOLEAN',
      'SELECT',
      'MULTI_SELECT',
      'FILE',
    ];
    final fixture = scholarshipFixture(
      read: (request) async {
        expect(request.url.path, '$scholarshipPath/11');
        return jsonResponse(
          announcementJson(
            form: {
              'formId': 9,
              'ten': 'Biểu mẫu học bổng',
              'phienBan': 2,
              'dinhNghia': {
                'fields': [
                  for (final type in types)
                    {
                      'code': type,
                      'label': type,
                      'type': type,
                      'required': true,
                      if (type == 'SELECT' || type == 'MULTI_SELECT')
                        'options': ['A', 'B'],
                    },
                ],
              },
              'quyTac': null,
            },
          ),
        );
      },
    );
    addTearDown(fixture.close);
    final item = await ScholarshipRepository(fixture.api).detail(11);
    expect(item.form!.fields.map((field) => field.type), types);
    expect(item.form!.fields.every((field) => field.required), isTrue);
    expect(item.form!.fields[4].options, ['A', 'B']);
    expect(item.form!.fields.first.rules, isEmpty);
  });

  test(
    'invalid JSON, mismatched IDs and invalid pages are not shown',
    () async {
      final responses = [
        http.Response('<html>proxy</html>', 200),
        jsonResponse(announcementJson(id: 12)),
        jsonResponse(scholarshipPageJson(page: 3)),
        jsonResponse(
          scholarshipPageJson()
            ..['items'] = [announcementJson()..['dangNhanHoSo'] = 'true'],
        ),
      ];
      final fixture = scholarshipFixture(
        read: (_) async => responses.removeAt(0),
      );
      addTearDown(fixture.close);
      final repository = ScholarshipRepository(fixture.api);
      final invalid = isA<ApiException>().having(
        (e) => e.code,
        'code',
        'INVALID_RESPONSE',
      );
      await expectLater(repository.list(), throwsA(invalid));
      await expectLater(repository.detail(11), throwsA(invalid));
      await expectLater(repository.list(), throwsA(invalid));
      await expectLater(repository.list(), throwsA(invalid));
      await expectLater(repository.list(page: -1), throwsArgumentError);
      await expectLater(repository.detail(0), throwsArgumentError);
      expect(fixture.requests, hasLength(4));
    },
  );

  test('network, permission and not found errors remain distinct', () async {
    var call = 0;
    final fixture = scholarshipFixture(
      read: (_) async {
        call++;
        if (call == 1) throw http.ClientException('offline');
        return jsonResponse({
          'code': call == 2 ? 'ACCESS_DENIED' : 'HBTT_NOT_FOUND',
        }, call == 2 ? 403 : 404);
      },
    );
    addTearDown(fixture.close);
    final repository = ScholarshipRepository(fixture.api);
    await expectLater(
      repository.list(),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'NETWORK_ERROR'),
      ),
    );
    await expectLater(
      repository.list(),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 403)),
    );
    try {
      await repository.detail(11);
      fail('Expected not found');
    } catch (error) {
      expect(
        scholarshipErrorMessage(error),
        contains('không còn được công khai'),
      );
    }
    expect(fixture.requests, hasLength(3));
  });

  test(
    'Vietnamese formatting preserves dates, amounts and structured conditions',
    () {
      expect(
        scholarshipDateTime(DateTime.parse('2026-11-30T17:00:00Z')),
        '01/12/2026 00:00',
      );
      expect(
        scholarshipDateTime(DateTime.parse('2026-12-01T00:00:00+07:00')),
        '01/12/2026 00:00',
      );
      expect(scholarshipMoney(5000000), '5.000.000 ₫');
      expect(scholarshipMoney(1250000.5), '1.250.000,50 ₫');
      expect(scholarshipMoney(null), 'Chưa công bố');
      final item = ScholarshipAnnouncement.fromJson(announcementJson());
      final content = scholarshipContent(item.conditions);
      expect(content, contains('hoàn cảnh khó khăn'));
      expect(content, contains('diemToiThieu: 3.2'));
      expect(content, contains('• Sinh viên năm hai'));
      expect(scholarshipContent(null), isEmpty);
      expect(scholarshipContent(true), 'Có');
    },
  );
}
