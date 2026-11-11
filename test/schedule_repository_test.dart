import 'package:ctsv_mobile/core/format/date_format.dart';
import 'package:ctsv_mobile/core/network/api_exception.dart';
import 'package:ctsv_mobile/features/shcn/data/schedule_repository.dart';
import 'package:ctsv_mobile/features/shcn/data/shcn_schedule.dart';
import 'package:ctsv_mobile/features/shcn/presentation/schedule_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'support/auth_fixture.dart';
import 'support/schedule_fixture.dart';

void main() {
  test('authenticated list/detail preserve server class scope and total pagination', () async {
    final fixture = scheduleFixture(
      read: (request) async => request.url.path == schedulePath
          ? jsonResponse(schedulePageJson(page: 1, total: 21))
          : jsonResponse(scheduleJson()),
    );
    addTearDown(fixture.close);
    fixture.api.setAccessToken('student-token');
    final repository = ScheduleRepository(fixture.api);
    final page = await repository.list(page: 1);
    expect(page.pageCount, 2);
    expect(page.hasNext, isFalse);
    expect(page.total, 21);
    final detail = await repository.detail(page.items.single.id);
    expect(detail.classCode, 'CLASS_A');
    expect(fixture.requests.first.url.queryParameters, {
      'page': '1',
      'size': '20',
    });
    expect(fixture.requests.last.url.path, '$schedulePath/5');
    for (final request in fixture.requests) {
      expect(request.method, 'GET');
      expect(request.headers['Authorization'], 'Bearer student-token');
      expect(request.headers.containsKey('Cookie'), isFalse);
      expect(request.body, isEmpty);
    }
  });

  test(
    'empty pages stay empty and use total rather than HBTT hasNext',
    () async {
      final fixture = scheduleFixture(
        read: (_) async => jsonResponse(schedulePageJson(items: [], total: 0)),
      );
      addTearDown(fixture.close);
      final page = await ScheduleRepository(fixture.api).list();
      expect(page.items, isEmpty);
      expect(page.pageCount, 1);
      expect(page.hasNext, isFalse);
    },
  );

  test(
    'invalid response, duplicate IDs and wrong details are rejected',
    () async {
      final responses = [
        http.Response('<html>proxy</html>', 200),
        jsonResponse(schedulePageJson(page: 2)),
        jsonResponse(schedulePageJson(total: -1)),
        jsonResponse(
          schedulePageJson(items: [scheduleJson(), scheduleJson()], total: 2),
        ),
        jsonResponse(
          schedulePageJson(items: [scheduleJson()..['ngayHop'] = '2026-02-30']),
        ),
        jsonResponse(
          schedulePageJson(items: [scheduleJson()..['tietCuoi'] = 9]),
        ),
        jsonResponse(scheduleJson(id: 99)),
      ];
      final fixture = scheduleFixture(read: (_) async => responses.removeAt(0));
      addTearDown(fixture.close);
      final repository = ScheduleRepository(fixture.api);
      final invalid = isA<ApiException>().having(
        (e) => e.code,
        'code',
        'INVALID_RESPONSE',
      );
      for (var i = 0; i < 6; i++) {
        await expectLater(repository.list(), throwsA(invalid));
      }
      await expectLater(repository.detail(5), throwsA(invalid));
      await expectLater(repository.list(page: -1), throwsArgumentError);
      await expectLater(repository.detail(0), throwsArgumentError);
      expect(fixture.requests, hasLength(7));
    },
  );

  test(
    'network, forbidden, out of scope and configuration failures are distinct',
    () async {
      var call = 0;
      final fixture = scheduleFixture(
        read: (_) async {
          call++;
          if (call == 1) throw http.ClientException('offline');
          return switch (call) {
            2 => jsonResponse({'code': 'ACCESS_DENIED'}, 403),
            3 => jsonResponse({'code': 'SHCN_KHONG_TIM_THAY'}, 404),
            _ => jsonResponse({'code': 'SHCN_CAU_HINH_KHONG_HOP_LE'}, 500),
          };
        },
      );
      addTearDown(fixture.close);
      final repository = ScheduleRepository(fixture.api);
      for (final message in [
        'Không kết nối được',
        'chưa có quyền',
        'phạm vi được xem',
        'liên hệ chuyên viên',
      ]) {
        try {
          await repository.detail(5);
          fail('Expected a read error');
        } catch (error) {
          expect(scheduleErrorMessage(error), contains(message));
        }
      }
      expect(fixture.requests, hasLength(4));
    },
  );

  test('confirmed wishes never expose provisional rooms as official', () {
    final wish = ShcnSchedule.fromJson(scheduleJson(published: false));
    expect(wish.published, isFalse);
    expect(scheduleLocation(wish), 'Đã xếp phòng · Chờ công bố');
    expect(scheduleLocation(wish), isNot(contains('A111')));
    for (final state in [
      'CHUA_XEP',
      'DANG_XEP',
      'DA_GIU',
      'THAT_BAI',
      'XEP_THAT_BAI',
      'DA_HUY',
    ]) {
      final item = ShcnSchedule.fromJson(
        scheduleJson()..['trangThaiPhong'] = state,
      );
      expect(scheduleLocation(item), scheduleRoomState(state));
      expect(scheduleLocation(item), isNot(contains('A111')));
    }
    expect(scheduleLocation(ShcnSchedule.fromJson(scheduleJson())), 'A111');
    expect(
      scheduleLocation(
        ShcnSchedule.fromJson(scheduleJson()..['maPhong'] = null),
      ),
      'Chưa có phòng',
    );
  });

  test('only published online schedules offer a safe meeting link', () {
    final wish = ShcnSchedule.fromJson(
      scheduleJson(published: false, online: true),
    );
    expect(publishedMeetingLink(wish), isNull);
    final published = ShcnSchedule.fromJson(scheduleJson(online: true));
    expect(publishedMeetingLink(published), 'https://meet.example.com/shcn');
    expect(
      publishedMeetingLink(
        ShcnSchedule.fromJson(
          scheduleJson(online: true)..['trangThaiChot'] = 'DA_HUY',
        ),
      ),
      isNull,
    );
    for (final link in [
      null,
      '',
      'javascript:alert(1)',
      'data:text/html,hi',
      'https://user:pass@example.com',
      'https://example.com/a b',
      'example.com/abc',
      'https://example.com/\n',
    ]) {
      expect(safeMeetingLink(link), isNull, reason: '$link');
    }
    expect(safeMeetingLink('http://example.com/abc'), 'http://example.com/abc');
  });

  test(
    'calendar dates and unconfirmed fields do not turn into real meetings',
    () {
      final json = scheduleJson()
        ..['ngayHop'] = null
        ..['tietDau'] = null
        ..['tietCuoi'] = null
        ..['hinhThuc'] = null
        ..['trangThaiChot'] = 'CHUA_CHOT';
      final item = ShcnSchedule.fromJson(json);
      expect(scheduleDate(item.date), 'Chưa chọn ngày');
      expect(
        schedulePeriods(item.firstPeriod, item.lastPeriod),
        'Chưa chọn tiết',
      );
      expect(scheduleLocation(item), 'Chưa chọn hình thức');
      expect(
        scheduleConfirmation(item, now: DateTime.utc(2026, 11, 11)),
        'Chưa chốt',
      );
      expect(
        scheduleConfirmation(item, now: item.deadline),
        'Quá hạn chốt lịch',
      );
      expect(
        scheduleDate(ShcnSchedule.fromJson(scheduleJson()).date),
        '03/12/2026',
      );
      expect(
        vietnamDateTime(DateTime.parse('2026-11-23T17:00:00Z')),
        '24/11/2026 00:00',
      );
      expect(
        scheduleConfirmation(
          ShcnSchedule.fromJson(
            scheduleJson()..['trangThaiChot'] = 'DA_GAN_MAC_DINH',
          ),
        ),
        'Đã gán mặc định do quá hạn',
      );
    },
  );

  test(
    'pending and decided change requests preserve the actual meeting date',
    () {
      for (final state in ['CHO_XU_LY', 'CHAP_NHAN', 'TU_CHOI', 'DA_RUT']) {
        final item = ShcnSchedule.fromJson(
          scheduleJson(changeRequest: changeRequestJson(state: state)),
        );
        expect(scheduleDate(item.date), '03/12/2026');
        expect(scheduleDate(item.changeRequest!.date), '05/12/2026');
        expect(item.hasPendingChange, state == 'CHO_XU_LY');
        expect(scheduleChangeState(item), isNot(contains('Không có yêu cầu')));
        if (state == 'TU_CHOI') {
          expect(item.changeRequest!.result, 'Chưa phù hợp khung đợt.');
        }
      }
      final item = ShcnSchedule.fromJson(
        scheduleJson(changeRequest: changeRequestJson())
          ..['soYeuCauChoXuLy'] = 2,
      );
      expect(scheduleChangeState(item), contains('(2)'));
    },
  );
}
