/// Exact decimal input, with six fractional digits and twelve whole digits.
/// The bounded format rejects non-finite values, exponents and currency symbols.
BigInt? parseDecimal(String input) {
  final text = input.trim();
  if (!RegExp(r'^(?:\d{1,12}(?:\.\d{0,6})?|\.\d{1,6})$').hasMatch(text)) {
    return null;
  }
  final parts = text.split('.');
  final whole = parts.first.isEmpty ? '0' : parts.first;
  final fraction = parts.length == 2 ? parts[1] : '';
  return BigInt.parse('$whole${fraction.padRight(6, '0')}');
}

String? decimalError(String value, {required bool positive}) {
  final parsed = parseDecimal(value);
  if (parsed == null) {
    return 'Enter a number (up to 12 digits and 6 decimals).';
  }
  if (positive && parsed == BigInt.zero) {
    return 'Quantity must be greater than 0.';
  }
  return null;
}

/// Round half up once per ingredient, then sum these displayed cent amounts.
BigInt ingredientCents(String quantity, String price) {
  final product = parseDecimal(quantity)! * parseDecimal(price)!;
  final divisor = BigInt.from(10000000000);
  return (product + divisor ~/ BigInt.two) ~/ divisor;
}

BigInt servingCents(BigInt total, int servings) {
  final divisor = BigInt.from(servings);
  return (total * BigInt.two + divisor) ~/ (divisor * BigInt.two);
}

String formatMoney(BigInt cents) =>
    '\$${cents ~/ BigInt.from(100)}.${(cents % BigInt.from(100)).toString().padLeft(2, '0')}';

int? parseServings(String text) {
  if (!RegExp(r'^\d{1,6}$').hasMatch(text.trim())) return null;
  final value = int.parse(text.trim());
  return value > 0 ? value : null;
}
