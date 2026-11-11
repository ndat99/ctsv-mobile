import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/json_response.dart';
import 'scholarship_announcement.dart';

class ScholarshipPage {
  const ScholarshipPage({
    required this.items,
    required this.page,
    required this.hasNext,
  });

  final List<ScholarshipAnnouncement> items;
  final int page;
  final bool hasNext;
}

class ScholarshipRepository {
  const ScholarshipRepository(this.api);

  final ApiClient api;
  static const pageSize = 12;

  Future<ScholarshipPage> list({int page = 0, String query = ''}) async {
    if (page < 0) throw ArgumentError.value(page, 'page');
    final keyword = query.trim();
    if (keyword.length > 200) {
      throw const ApiException(
        'VALIDATION_ERROR',
        'Từ khóa tìm kiếm tối đa 200 ký tự.',
      );
    }
    final path = Uri(
      path: ApiEndpoints.scholarships,
      queryParameters: {
        'page': '$page',
        'size': '$pageSize',
        if (keyword.isNotEmpty) 'q': keyword,
      },
    ).toString();
    final response = await api.request('GET', path);
    try {
      final json = jsonObject(jsonDecode(utf8.decode(response.bodyBytes)));
      final items = json['items'];
      if (items is! List || json['page'] != page || json['size'] != pageSize) {
        throw const FormatException('Invalid scholarship page');
      }
      return ScholarshipPage(
        items: List.unmodifiable(
          items.map(
            (item) => ScholarshipAnnouncement.fromJson(jsonObject(item)),
          ),
        ),
        page: page,
        hasNext: requiredBoolean(json['hasNext']),
      );
    } on FormatException {
      throw _invalidResponse;
    }
  }

  Future<ScholarshipAnnouncement> detail(int id) async {
    final response = await api.request('GET', ApiEndpoints.scholarship(id));
    try {
      final item = ScholarshipAnnouncement.fromJson(
        jsonObject(jsonDecode(utf8.decode(response.bodyBytes))),
      );
      if (item.id != id) {
        throw const FormatException('Announcement ID mismatch');
      }
      return item;
    } on FormatException {
      throw _invalidResponse;
    }
  }

  static const _invalidResponse = ApiException(
    'INVALID_RESPONSE',
    'Dữ liệu thông báo học bổng chưa hợp lệ. Vui lòng thử lại sau.',
  );
}

String scholarshipErrorMessage(Object error) {
  if (error is ApiException) {
    if (error.code == 'STUDENT_PROFILE_REQUIRED') {
      return 'Tài khoản chưa liên kết hồ sơ sinh viên hợp lệ. '
          'Vui lòng liên hệ quản trị viên.';
    }
    if (error.status == 404) {
      return 'Thông báo không còn tồn tại hoặc không còn được công khai.';
    }
    return error.message;
  }
  return 'Chưa tải được thông báo học bổng. Vui lòng thử lại.';
}
