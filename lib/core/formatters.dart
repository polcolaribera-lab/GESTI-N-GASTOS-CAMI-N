const _monthNames = <String>[
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

const _shortMonthNames = <String>[
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

String monthName(DateTime date, {bool includeYear = true}) {
  final month = _monthNames[date.month - 1];
  return includeYear ? '$month ${date.year}' : month;
}

String shortDate(DateTime date) {
  return '${date.day} ${_shortMonthNames[date.month - 1]}';
}

String fullDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String euro(double value, {bool showDecimals = true}) {
  final fixed = value.toStringAsFixed(showDecimals ? 2 : 0);
  final parts = fixed.split('.');
  final digits = parts.first;
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    final positionFromEnd = digits.length - index;
    buffer.write(digits[index]);
    if (positionFromEnd > 1 && (positionFromEnd - 1) % 3 == 0) {
      buffer.write('.');
    }
  }

  if (showDecimals) {
    buffer.write(',${parts.last}');
  }
  return '${buffer.toString()} €';
}
