import '../../../core/network/json_response.dart';

class ShcnSchedule {
  const ShcnSchedule({
    required this.id,
    required this.roundId,
    required this.roundName,
    required this.semester,
    required this.classCode,
    required this.className,
    required this.teacherCode,
    required this.meetingNumber,
    required this.date,
    required this.firstPeriod,
    required this.lastPeriod,
    required this.modality,
    required this.confirmationState,
    required this.roomState,
    required this.kind,
    required this.room,
    required this.meetingLink,
    required this.confirmedAt,
    required this.deadline,
    required this.changeRequest,
    required this.pendingChanges,
  });

  final int id;
  final int roundId;
  final String roundName;
  final String semester;
  final String classCode;
  final String? className;
  final String teacherCode;
  final int meetingNumber;
  final DateTime? date;
  final int? firstPeriod;
  final int? lastPeriod;
  final String? modality;
  final String confirmationState;
  final String roomState;
  final String kind;
  final String? room;
  final String? meetingLink;
  final DateTime? confirmedAt;
  final DateTime deadline;
  final ScheduleChangeRequest? changeRequest;
  final int pendingChanges;

  bool get published => kind == 'LICH_CONG_BO';
  bool get hasPendingChange =>
      pendingChanges > 0 || changeRequest?.state == 'CHO_XU_LY';

  factory ShcnSchedule.fromJson(Map<String, dynamic> json) {
    final first = json['tietDau'] == null
        ? null
        : positiveInteger(json['tietDau']);
    final last = json['tietCuoi'] == null
        ? null
        : positiveInteger(json['tietCuoi']);
    _validatePeriods(first, last);
    return ShcnSchedule(
      id: positiveInteger(json['id']),
      roundId: positiveInteger(json['maDot']),
      roundName: requiredText(json['tenDot']),
      semester: requiredText(json['maHocKy']),
      classCode: requiredText(json['maLop']),
      className: nullableText(json['tenLop']),
      teacherCode: requiredText(json['maGiaoVien']),
      meetingNumber: positiveInteger(json['lanHop']),
      date: json['ngayHop'] == null ? null : jsonDate(json['ngayHop']),
      firstPeriod: first,
      lastPeriod: last,
      modality: nullableText(json['hinhThuc']),
      confirmationState: requiredText(json['trangThaiChot']),
      roomState: requiredText(json['trangThaiPhong']),
      kind: requiredText(json['loaiLich']),
      room: nullableText(json['maPhong']),
      meetingLink: nullableText(json['linkHop']),
      confirmedAt: json['ngayXacNhan'] == null
          ? null
          : jsonInstant(json['ngayXacNhan']),
      deadline: jsonInstant(json['hanChot']),
      changeRequest: json['yeuCauDoiLich'] == null
          ? null
          : ScheduleChangeRequest.fromJson(jsonObject(json['yeuCauDoiLich'])),
      pendingChanges: nonNegativeInteger(json['soYeuCauChoXuLy']),
    );
  }
}

class ScheduleChangeRequest {
  const ScheduleChangeRequest({
    required this.state,
    required this.date,
    required this.firstPeriod,
    required this.lastPeriod,
    required this.modality,
    required this.meetingLink,
    required this.reason,
    required this.result,
    required this.createdAt,
    required this.processedAt,
  });

  final String state;
  final DateTime date;
  final int firstPeriod;
  final int lastPeriod;
  final String modality;
  final String? meetingLink;
  final String reason;
  final String? result;
  final DateTime createdAt;
  final DateTime? processedAt;

  factory ScheduleChangeRequest.fromJson(Map<String, dynamic> json) {
    final first = positiveInteger(json['tietDauDeNghi']);
    final last = positiveInteger(json['tietCuoiDeNghi']);
    _validatePeriods(first, last);
    return ScheduleChangeRequest(
      state: requiredText(json['trangThai']),
      date: jsonDate(json['ngayDeNghi']),
      firstPeriod: first,
      lastPeriod: last,
      modality: requiredText(json['hinhThucDeNghi']),
      meetingLink: nullableText(json['linkHopDeNghi']),
      reason: requiredText(json['lyDo']),
      result: nullableText(json['lyDoXuLy']),
      createdAt: jsonInstant(json['ngayTao']),
      processedAt: json['ngayXuLy'] == null
          ? null
          : jsonInstant(json['ngayXuLy']),
    );
  }
}

void _validatePeriods(int? first, int? last) {
  if ((first == null) != (last == null) ||
      (first != null && last != null && last < first)) {
    throw const FormatException('Invalid meeting periods');
  }
}
