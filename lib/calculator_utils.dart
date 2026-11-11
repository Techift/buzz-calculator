const _ones = [
  'zero',
  'one',
  'two',
  'three',
  'four',
  'five',
  'six',
  'seven',
  'eight',
  'nine',
  'ten',
  'eleven',
  'twelve',
  'thirteen',
  'fourteen',
  'fifteen',
  'sixteen',
  'seventeen',
  'eighteen',
  'nineteen',
];

const _tens = [
  '',
  '',
  'twenty',
  'thirty',
  'forty',
  'fifty',
  'sixty',
  'seventy',
  'eighty',
  'ninety',
];

const _scales = [
  '',
  'thousand',
  'million',
  'billion',
  'trillion',
  'quadrillion',
  'quintillion',
  'sextillion',
  'septillion',
  'octillion',
  'nonillion',
  'decillion',
  'undecillion',
  'duodecillion',
  'tredecillion',
  'quattuordecillion',
  'quindecillion',
  'sexdecillion',
  'septendecillion',
  'octodecillion',
  'novemdecillion',
  'vigintillion',
];

String numberToEnglish(String value) {
  final match = RegExp(
    r'^([+-]?)(\d+)(?:\.(\d*))?(?:[eE]([+-]?\d+))?$',
  ).firstMatch(value.replaceAll(',', '').trim());
  if (match == null) {
    throw FormatException('Invalid numeric result: $value');
  }

  final negative = match.group(1) == '-';
  final wholeDigits = match.group(2)!;
  final decimalDigits = match.group(3) ?? '';
  final exponent = int.parse(match.group(4) ?? '0');
  final digits = '$wholeDigits$decimalDigits';
  final decimalPosition = wholeDigits.length + exponent;

  final whole = decimalPosition <= 0
      ? '0'
      : decimalPosition >= digits.length
      ? '$digits${List.filled(decimalPosition - digits.length, '0').join()}'
      : digits.substring(0, decimalPosition);
  final fraction = decimalPosition <= 0
      ? '${List.filled(-decimalPosition, '0').join()}$digits'
      : decimalPosition >= digits.length
      ? ''
      : digits.substring(decimalPosition);

  final wholeWords = _integerToEnglish(BigInt.parse(whole));
  final fractionWords = fraction.isEmpty
      ? ''
      : ' point ${fraction.split('').map((digit) => _ones[int.parse(digit)]).join(' ')}';
  final words = '${negative ? 'negative ' : ''}$wholeWords$fractionWords';
  return '${words[0].toUpperCase()}${words.substring(1)}';
}

String _integerToEnglish(BigInt value) {
  if (value == BigInt.zero) return _ones[0];

  final groups = <String>[];
  var remaining = value;
  var scale = 0;
  while (remaining > BigInt.zero) {
    if (scale >= _scales.length) {
      throw RangeError('Number is too large to translate.');
    }

    final group = (remaining % BigInt.from(1000)).toInt();
    if (group > 0) {
      final scaleName = _scales[scale];
      groups.insert(
        0,
        '${_threeDigitGroupToEnglish(group)}${scaleName.isEmpty ? '' : ' $scaleName'}',
      );
    }
    remaining ~/= BigInt.from(1000);
    scale++;
  }
  return groups.join(', ');
}

String _threeDigitGroupToEnglish(int value) {
  final words = <String>[];
  final hundreds = value ~/ 100;
  final remainder = value % 100;
  if (hundreds > 0) {
    words.add('${_ones[hundreds]} hundred');
    if (remainder > 0) words.add('and');
  }

  if (remainder < 20) {
    if (remainder > 0 || value == 0) words.add(_ones[remainder]);
  } else {
    final ten = remainder ~/ 10;
    final one = remainder % 10;
    words.add(one == 0 ? _tens[ten] : '${_tens[ten]}-${_ones[one]}');
  }
  return words.join(' ');
}

String formatCalculationResult(num value) {
  if (!value.isFinite) return 'Error';
  if (value == 0) return '0';

  var formatted = value.toStringAsPrecision(12);
  if (formatted.contains('e')) {
    final parts = formatted.split('e');
    var mantissa = parts[0];
    if (mantissa.contains('.')) {
      mantissa = mantissa.replaceFirst(RegExp(r'0+$'), '');
      mantissa = mantissa.replaceFirst(RegExp(r'\.$'), '');
    }
    formatted = '$mantissa e${parts[1]}'.replaceAll(' ', '');
  } else if (formatted.contains('.')) {
    formatted = formatted.replaceFirst(RegExp(r'0+$'), '');
    formatted = formatted.replaceFirst(RegExp(r'\.$'), '');
  }
  return formatted;
}
