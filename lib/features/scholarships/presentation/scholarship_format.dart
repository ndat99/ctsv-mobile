import '../../../core/format/date_format.dart';
import '../data/scholarship_announcement.dart';

String scholarshipDateTime(DateTime value) => vietnamDateTime(value);

String scholarshipMoney(num? value) {
  if (value == null) return 'Chưa công bố';
  final parts = (value is int ? value.toString() : value.toStringAsFixed(2))
      .split('.');
  final grouped = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  final fraction = parts.length > 1 && parts[1] != '00' ? ',${parts[1]}' : '';
  return '$grouped$fraction ₫';
}

String scholarshipState(String state) => switch (state) {
  'DANG_NHAN_HO_SO' => 'Đang trong đợt nhận hồ sơ',
  'DANG_XET_DUYET' => 'Đang xét duyệt',
  'CHO_HOI_DONG' => 'Chờ hội đồng',
  'KY_BIEN_BAN' => 'Đang ký biên bản',
  'KY_DANH_SACH' => 'Đang ký danh sách',
  'CHO_CONG_BO' => 'Chờ công bố',
  'DA_CONG_BO' => 'Đã công bố',
  _ => 'Đang cập nhật',
};

/// Conditions are arbitrary JSON in the backend contract. Preserve every entry
/// as plain text, including conditions outside the usual `noiDung` field.
String scholarshipContent(Object? value) {
  if (value == null) return '';
  if (value is bool) return value ? 'Có' : 'Không';
  if (value is List) {
    return value
        .map(scholarshipContent)
        .where((text) => text.isNotEmpty)
        .map((text) => '• $text')
        .join('\n');
  }
  if (value is Map) {
    return value.entries
        .map((entry) {
          final text = scholarshipContent(entry.value);
          if (text.isEmpty) return '';
          final label = switch (entry.key) {
            'noiDung' || 'description' => 'Nội dung',
            'dieuKien' || 'conditions' => 'Điều kiện',
            'doiTuong' => 'Đối tượng',
            'ghiChu' => 'Ghi chú',
            _ => entry.key.toString(),
          };
          return '$label: $text';
        })
        .where((text) => text.isNotEmpty)
        .join('\n\n');
  }
  return value.toString();
}

String scholarshipFieldDescription(ScholarshipField field) {
  final type = switch (field.type) {
    'TEXT' => 'Văn bản',
    'NUMBER' => 'Số',
    'DATE' => 'Ngày',
    'BOOLEAN' => 'Có / Không',
    'SELECT' => 'Chọn một',
    'MULTI_SELECT' => 'Chọn nhiều',
    'FILE' => 'Tệp minh chứng',
    _ => 'Thông tin bổ sung',
  };
  final lines = <String>[type];
  if (field.options.isNotEmpty) {
    lines.add('Lựa chọn: ${field.options.join(', ')}');
  }
  const labels = {
    'minLength': 'Số ký tự tối thiểu',
    'maxLength': 'Số ký tự tối đa',
    'min': 'Giá trị tối thiểu',
    'max': 'Giá trị tối đa',
    'maxFiles': 'Số tệp tối đa',
    'maxBytes': 'Dung lượng tối đa mỗi tệp (byte)',
    'allowedMimeTypes': 'Loại tệp',
    'allowedExtensions': 'Đuôi tệp',
  };
  for (final entry in field.rules.entries) {
    lines.add(
      '${labels[entry.key] ?? entry.key}: '
      '${entry.value is List ? (entry.value as List).join(', ') : scholarshipContent(entry.value)}',
    );
  }
  return lines.join('\n');
}
