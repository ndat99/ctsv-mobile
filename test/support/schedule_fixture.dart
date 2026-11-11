import 'package:ctsv_mobile/features/auth/data/auth_user.dart';
import 'package:http/http.dart' as http;

import 'auth_fixture.dart';

const schedulePath = '/api/shcn/lich-hop';

Map<String, Object?> scheduleJson({
  int id = 5,
  bool published = true,
  bool online = false,
  Map<String, Object?>? changeRequest,
}) => {
  'id': id,
  'maDot': 1,
  'tenDot': 'Sinh hoạt chủ nhiệm học kỳ I',
  'maHocKy': '2610',
  'maLop': 'CLASS_A',
  'tenLop': 'Lớp A',
  'maGiaoVien': 'GV_A',
  'lanHop': 1,
  'ngayHop': '2026-12-03',
  'tietDau': 11,
  'tietCuoi': 12,
  'hinhThuc': online ? 'ONLINE' : 'OFFLINE',
  'trangThaiChot': 'DA_CHOT',
  'trangThaiPhong': online ? 'KHONG_CAN' : 'DA_XEP',
  'loaiLich': published ? 'LICH_CONG_BO' : 'NGUYEN_VONG',
  'maPhong': online ? null : 'A111',
  'linkHop': online ? 'https://meet.example.com/shcn' : null,
  'ngayXacNhan': '2026-11-12T16:00:00Z',
  'phienBanLich': 1,
  'hanChot': '2026-11-23T15:30:00Z',
  'khungChoPhep': {
    'ngayBatDau': '2026-11-30',
    'ngayKetThuc': '2026-12-14',
    'cacKhungTiet': [
      {'tietDau': 11, 'tietCuoi': 12},
    ],
    'hinhThucChoPhep': 'CA_HAI',
  },
  'coTheChot': false,
  'coTheGuiYeuCauDoiLich': false,
  'yeuCauDoiLich': changeRequest,
  'soYeuCauChoXuLy': changeRequest?['trangThai'] == 'CHO_XU_LY' ? 1 : 0,
};

Map<String, Object?> changeRequestJson({String state = 'CHO_XU_LY'}) => {
  'id': 7,
  'trangThai': state,
  'ngayDeNghi': '2026-12-05',
  'tietDauDeNghi': 7,
  'tietCuoiDeNghi': 8,
  'hinhThucDeNghi': 'ONLINE',
  'linkHopDeNghi': 'https://meet.example.com/proposed',
  'lyDo': 'Lớp trùng lịch thực hành.',
  'lyDoXuLy': state == 'TU_CHOI' ? 'Chưa phù hợp khung đợt.' : null,
  'ngayTao': '2026-11-13T17:00:00Z',
  'ngayXuLy': state == 'CHO_XU_LY' ? null : '2026-11-14T17:00:00Z',
};

Map<String, Object?> schedulePageJson({
  List<Map<String, Object?>>? items,
  int page = 0,
  int total = 1,
}) => {
  'items': items ?? [scheduleJson()],
  'page': page,
  'size': 20,
  'total': total,
};

AuthUser scheduleUser({bool permission = true, int? studentProfileId = 12}) =>
    AuthUser(
      id: 1,
      username: 'sv.test',
      roles: const {'SINH_VIEN'},
      permissions: {if (permission) 'SHCN_LICH_XEM'},
      studentProfileId: studentProfileId,
    );

AuthFixture scheduleFixture({
  required Future<http.Response> Function(http.Request) read,
  bool Function()? sessionExpired,
}) => AuthFixture(
  handler: (request) async => switch (request.url.path) {
    '/api/auth/login' => tokens(),
    '/api/auth/me' => account(),
    '/api/auth/refresh' =>
      sessionExpired?.call() == true
          ? jsonResponse({'code': 'UNAUTHENTICATED'}, 401)
          : tokens(accessToken: 'access-B', refreshToken: 'refresh-B'),
    '/api/auth/logout' => http.Response('', 204),
    '/api/hoc-bong/tai-tro/thong-bao' => jsonResponse({
      'items': [],
      'page': 0,
      'size': 12,
      'hasNext': false,
    }),
    _ => read(request),
  },
);
