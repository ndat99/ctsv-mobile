String vietnamDateTime(DateTime value) {
  final vietnam = value.toUtc().add(const Duration(hours: 7));
  return '${calendarDate(vietnam)} '
      '${_two(vietnam.hour)}:${_two(vietnam.minute)}';
}

String calendarDate(DateTime value) =>
    '${_two(value.day)}/${_two(value.month)}/${value.year}';

String _two(int value) => value.toString().padLeft(2, '0');
