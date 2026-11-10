import 'package:ctsv_mobile/features/auth/data/auth_user.dart';
import 'package:http/http.dart' as http;

import 'auth_fixture.dart';

const scholarshipPath = '/api/hoc-bong/tai-tro/thong-bao';

Map<String, Object?> announcementJson({
  int id = 11,
  String title = 'Học bổng Tiếp sức đến trường',
  bool accepting = true,
  Object? conditions = const {
    'noiDung': 'Dành cho sinh viên có hoàn cảnh khó khăn.',
    'diemToiThieu': 3.2,
    'doiTuong': ['Sinh viên năm hai', 'Sinh viên năm ba'],
  },
  Object? form,
}) => {
  'thongBaoId': id,
  'tenHocBong': title,
  'nhaTaiTro': 'Quỹ Tiếp sức',
  'namHoc': '2026-2027',
  'dieuKien': conditions,
  'giaTri': 5000000,
  'moNhanLuc': '2026-11-01T00:00:00Z',
  'hanNopLuc': '2026-11-30T17:00:00Z',
  'trangThai': 'DANG_NHAN_HO_SO',
  'dangNhanHoSo': accepting,
  'form': form,
};

Map<String, Object?> scholarshipPageJson({
  List<Map<String, Object?>>? items,
  int page = 0,
  bool hasNext = false,
}) => {
  'items': items ?? [announcementJson()],
  'page': page,
  'size': 12,
  'hasNext': hasNext,
};

AuthUser scholarshipUser({
  bool permission = true,
  int? studentProfileId = 12,
}) => AuthUser(
  id: 1,
  username: 'sv.test',
  roles: const {'SINH_VIEN'},
  permissions: {if (permission) 'HB_TT_XEM'},
  studentProfileId: studentProfileId,
);

AuthFixture scholarshipFixture({
  required Future<http.Response> Function(http.Request) read,
  bool Function()? sessionExpired,
}) => AuthFixture(
  handler: (request) async {
    return switch (request.url.path) {
      '/api/auth/login' => tokens(),
      '/api/auth/me' => account(),
      '/api/auth/refresh' =>
        sessionExpired?.call() == true
            ? jsonResponse({'code': 'UNAUTHENTICATED'}, 401)
            : tokens(accessToken: 'access-B', refreshToken: 'refresh-B'),
      '/api/auth/logout' => http.Response('', 204),
      _ => read(request),
    };
  },
);
