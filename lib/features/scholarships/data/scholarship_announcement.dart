import '../../../core/network/json_response.dart';

class ScholarshipAnnouncement {
  const ScholarshipAnnouncement({
    required this.id,
    required this.title,
    required this.sponsor,
    required this.schoolYear,
    required this.conditions,
    required this.amount,
    required this.opensAt,
    required this.deadline,
    required this.state,
    required this.acceptingApplications,
    required this.form,
  });

  final int id;
  final String title;
  final String sponsor;
  final String schoolYear;
  final Object? conditions;
  final num? amount;
  final DateTime opensAt;
  final DateTime deadline;
  final String state;
  final bool acceptingApplications;
  final ScholarshipForm? form;

  factory ScholarshipAnnouncement.fromJson(Map<String, dynamic> json) {
    final amount = json['giaTri'];
    if (amount != null && (amount is! num || !amount.isFinite || amount < 0)) {
      throw const FormatException('Invalid scholarship amount');
    }
    return ScholarshipAnnouncement(
      id: positiveInteger(json['thongBaoId']),
      title: requiredText(json['tenHocBong']),
      sponsor: requiredText(json['nhaTaiTro']),
      schoolYear: requiredText(json['namHoc']),
      conditions: json['dieuKien'],
      amount: amount as num?,
      opensAt: jsonInstant(json['moNhanLuc']),
      deadline: jsonInstant(json['hanNopLuc']),
      state: requiredText(json['trangThai']),
      acceptingApplications: requiredBoolean(json['dangNhanHoSo']),
      form: json['form'] == null
          ? null
          : ScholarshipForm.fromJson(jsonObject(json['form'])),
    );
  }
}

class ScholarshipForm {
  const ScholarshipForm({
    required this.id,
    required this.name,
    required this.version,
    required this.fields,
  });

  final int id;
  final String name;
  final int version;
  final List<ScholarshipField> fields;

  factory ScholarshipForm.fromJson(Map<String, dynamic> json) {
    final definition = jsonObject(json['dinhNghia']);
    final fields = definition['fields'];
    if (fields is! List) throw const FormatException('Invalid form fields');
    final rules = json['quyTac'] == null
        ? <String, dynamic>{}
        : jsonObject(json['quyTac']);
    final fieldRules = rules['fields'] == null
        ? <String, dynamic>{}
        : jsonObject(rules['fields']);
    return ScholarshipForm(
      id: positiveInteger(json['formId']),
      name: requiredText(json['ten']),
      version: positiveInteger(json['phienBan']),
      fields: List.unmodifiable(
        fields.map((value) {
          final field = jsonObject(value);
          final code = requiredText(field['code']);
          final options = field['options'];
          if (options != null &&
              (options is! List || options.any((item) => item is! String))) {
            throw const FormatException('Invalid form options');
          }
          return ScholarshipField(
            label: requiredText(field['label']),
            type: requiredText(field['type']),
            required: field['required'] == null
                ? false
                : requiredBoolean(field['required']),
            options: List.unmodifiable((options as List? ?? []).cast<String>()),
            rules: Map.unmodifiable(
              fieldRules[code] == null
                  ? <String, dynamic>{}
                  : jsonObject(fieldRules[code]),
            ),
          );
        }),
      ),
    );
  }
}

class ScholarshipField {
  const ScholarshipField({
    required this.label,
    required this.type,
    required this.required,
    required this.options,
    required this.rules,
  });

  final String label;
  final String type;
  final bool required;
  final List<String> options;
  final Map<String, dynamic> rules;
}
