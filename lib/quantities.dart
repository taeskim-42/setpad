import 'package:intl/intl.dart';

/// Mark display rounding explicitly; it must not masquerade as an exact value.
String formatRoundedQuantity(
  double value,
  String locale, {
  bool signed = false,
}) {
  final formatter = NumberFormat('0.##', locale);
  final text = formatter.format(value);
  final approximate = formatter.parse(text).toDouble() != value;
  return '${approximate ? '≈' : ''}${signed && value >= 0 ? '+' : ''}$text';
}

/// Compare recorded decimal weights without binary floating-point boundaries.
/// The kilogram equivalent of one pound is exactly 0.45359237.
int compareWeights(
  double left,
  String leftUnit,
  double right,
  String rightUnit,
) {
  (BigInt, BigInt) kilograms(double value, String unit) {
    if (!value.isFinite || !['kg', 'lb'].contains(unit)) {
      throw const FormatException('Invalid weight comparison');
    }
    final parts = value.toString().toLowerCase().split('e');
    final decimal = parts.first.split('.');
    final scale =
        (decimal.length == 2 ? decimal.last.length : 0) -
        (parts.length == 2 ? int.parse(parts.last) : 0);
    var numerator = BigInt.parse(decimal.join());
    var denominator = BigInt.one;
    if (scale > 0) {
      denominator = BigInt.from(10).pow(scale);
    } else if (scale < 0) {
      numerator *= BigInt.from(10).pow(-scale);
    }
    if (unit == 'lb') {
      numerator *= BigInt.from(45359237);
      denominator *= BigInt.from(100000000);
    }
    return (numerator, denominator);
  }

  final (ln, ld) = kilograms(left, leftUnit);
  final (rn, rd) = kilograms(right, rightUnit);
  return (ln * rd).compareTo(rn * ld);
}
