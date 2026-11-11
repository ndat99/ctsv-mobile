Map<String, dynamic> jsonObject(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Expected a JSON object');
  }
  return value;
}

int positiveInteger(Object? value) {
  if (value is! int || value <= 0) {
    throw const FormatException('Expected a positive integer');
  }
  return value;
}

int nonNegativeInteger(Object? value) {
  if (value is! int || value < 0) {
    throw const FormatException('Expected a non-negative integer');
  }
  return value;
}

String requiredText(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Expected text');
  }
  return value;
}

String? nullableText(Object? value) {
  if (value == null) return null;
  if (value is! String) throw const FormatException('Expected nullable text');
  return value.trim().isEmpty ? null : value;
}

bool requiredBoolean(Object? value) {
  if (value is! bool) throw const FormatException('Expected a boolean');
  return value;
}

DateTime jsonInstant(Object? value) {
  final text = requiredText(value);
  if (!RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(text)) {
    throw const FormatException('Expected an instant with a time zone');
  }
  return DateTime.parse(text).toUtc();
}

/// A meeting's LocalDate is a calendar date, independent of device time zone.
DateTime jsonDate(Object? value) {
  final text = requiredText(value);
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
    throw const FormatException('Expected a calendar date');
  }
  final date = DateTime.parse('${text}T00:00:00Z');
  if (date.toIso8601String().split('T').first != text) {
    throw const FormatException('Invalid calendar date');
  }
  return date;
}
