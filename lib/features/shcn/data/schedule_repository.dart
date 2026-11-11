import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/json_response.dart';
import 'shcn_schedule.dart';

class ScheduleResult {
  const ScheduleResult({
    required this.items,
    required this.page,
    required this.total,
  });

  final List<ShcnSchedule> items;
  final int page;
  final int total;
  bool get hasNext => (page + 1) * ScheduleRepository.pageSize < total;
  int get pageCount =>
      total == 0 ? 1 : (total / ScheduleRepository.pageSize).ceil();
}

class ScheduleRepository {
  const ScheduleRepository(this.api);

  final ApiClient api;
  static const pageSize = 20;

  Future<ScheduleResult> list({int page = 0}) async {
    if (page < 0) throw ArgumentError.value(page, 'page');
    final response = await api.request(
      'GET',
      '${ApiEndpoints.schedules}?page=$page&size=$pageSize',
    );
    try {
      final json = jsonObject(jsonDecode(utf8.decode(response.bodyBytes)));
      final items = json['items'];
      final total = nonNegativeInteger(json['total']);
      if (items is! List ||
          items.length > pageSize ||
          json['page'] != page ||
          json['size'] != pageSize ||
          total < items.length) {
        throw const FormatException('Invalid schedule page');
      }
      final schedules = items
          .map((item) => ShcnSchedule.fromJson(jsonObject(item)))
          .toList();
      if (schedules.map((item) => item.id).toSet().length != schedules.length) {
        throw const FormatException('Duplicate schedule IDs');
      }
      return ScheduleResult(
        items: List.unmodifiable(schedules),
        page: page,
        total: total,
      );
    } on FormatException {
      throw _invalidResponse;
    }
  }

  Future<ShcnSchedule> detail(int id) async {
    final response = await api.request('GET', ApiEndpoints.schedule(id));
    try {
      final item = ShcnSchedule.fromJson(
        jsonObject(jsonDecode(utf8.decode(response.bodyBytes))),
      );
      if (item.id != id) throw const FormatException('Schedule ID mismatch');
      return item;
    } on FormatException {
      throw _invalidResponse;
    }
  }

  static const _invalidResponse = ApiException(
    'INVALID_RESPONSE',
    'Dữ liệu lịch SHCN chưa hợp lệ. Vui lòng tải lại.',
  );
}

String scheduleErrorMessage(Object error) {
  if (error is ApiException) {
    if (error.status == 404) {
      return 'Lịch không còn tồn tại hoặc không còn thuộc phạm vi được xem.';
    }
    if (error.code == 'SHCN_CAU_HINH_KHONG_HOP_LE') {
      return 'Cấu hình lịch chưa hợp lệ. Vui lòng liên hệ chuyên viên CTSV.';
    }
    return error.message;
  }
  return 'Chưa tải được lịch SHCN. Vui lòng thử lại.';
}
