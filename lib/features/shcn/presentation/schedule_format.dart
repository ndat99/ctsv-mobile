import '../../../core/format/date_format.dart';
import '../data/shcn_schedule.dart';

String scheduleDate(DateTime? value) =>
    value == null ? 'Chưa chọn ngày' : calendarDate(value);

String schedulePeriods(int? first, int? last) =>
    first == null || last == null ? 'Chưa chọn tiết' : 'Tiết $first–$last';

String scheduleModality(String? value) => switch (value) {
  'ONLINE' => 'Trực tuyến',
  'OFFLINE' => 'Trực tiếp',
  _ => 'Chưa chọn hình thức',
};

String scheduleConfirmation(ShcnSchedule item, {DateTime? now}) {
  if (item.confirmationState == 'CHUA_CHOT' &&
      !item.deadline.isAfter(now ?? DateTime.now())) {
    return 'Quá hạn chốt lịch';
  }
  return switch (item.confirmationState) {
    'CHUA_CHOT' => 'Chưa chốt',
    'DA_CHOT' => 'Đã chốt',
    'QUA_HAN' => 'Quá hạn chốt lịch',
    'DA_HUY' => 'Đã hủy lịch',
    'DA_GAN_MAC_DINH' => 'Đã gán mặc định do quá hạn',
    _ => 'Chưa xác định',
  };
}

String scheduleRoomState(String state) => switch (state) {
  'CHUA_XEP' => 'Chưa xếp phòng',
  'DANG_XEP' => 'Đang xếp phòng',
  'DA_GIU' => 'Đang giữ phòng',
  'DA_XEP' || 'DA_DAT' => 'Đã xếp phòng',
  'KHONG_CAN' => 'Không cần phòng',
  'THAT_BAI' || 'XEP_THAT_BAI' => 'Xếp phòng thất bại',
  'DA_HUY' => 'Đã hủy đặt phòng',
  _ => 'Chưa xác định trạng thái phòng',
};

String scheduleLocation(ShcnSchedule item) {
  if (item.modality == null) return 'Chưa chọn hình thức';
  if (item.modality == 'ONLINE') {
    if (item.meetingLink == null) return 'Chưa có link họp';
    return safeMeetingLink(item.meetingLink) ?? 'Link họp chưa hợp lệ';
  }
  if (item.roomState == 'DA_XEP' || item.roomState == 'DA_DAT') {
    return item.published
        ? item.room ?? 'Chưa có phòng'
        : 'Đã xếp phòng · Chờ công bố';
  }
  return scheduleRoomState(item.roomState);
}

String? safeMeetingLink(String? value) {
  if (value == null || RegExp(r'[\s\x00-\x1f\x7f]').hasMatch(value)) {
    return null;
  }
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !{'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  return value;
}

String? publishedMeetingLink(ShcnSchedule item) =>
    item.published &&
        item.modality == 'ONLINE' &&
        item.confirmationState != 'DA_HUY'
    ? safeMeetingLink(item.meetingLink)
    : null;

String scheduleChangeState(ShcnSchedule item) {
  if (item.hasPendingChange) {
    return 'Chờ xử lý yêu cầu đổi lịch${item.pendingChanges > 1 ? ' (${item.pendingChanges})' : ''}';
  }
  return switch (item.changeRequest?.state) {
    null => 'Không có yêu cầu đổi lịch',
    'CHAP_NHAN' => 'Yêu cầu đổi lịch đã được chấp nhận',
    'TU_CHOI' => 'Yêu cầu đổi lịch bị từ chối',
    'DA_RUT' => 'Yêu cầu đổi lịch đã rút',
    _ => 'Đang cập nhật yêu cầu đổi lịch',
  };
}
