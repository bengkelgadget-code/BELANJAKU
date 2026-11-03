import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Format rupiah integer:
  /// e.g. 1250000 -> "Rp 1.250.000"
  /// e.g. -50000 -> "−Rp 50.000"
  static String format(int amount) {
    if (amount < 0) {
      final positiveFormatted = _formatter.format(amount.abs()).trim();
      return '−$positiveFormatted';
    }
    return _formatter.format(amount).trim();
  }

  /// Format with explicit +/- sign
  static String formatWithSign(int amount, {required bool isIncome}) {
    final formatted = format(amount.abs());
    return isIncome ? '+$formatted' : '−$formatted';
  }

  /// Parse text like "1.250.000" or "Rp 1.250.000" into integer
  static int? parse(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }

  /// Format compact for mini badges: e.g. 1.500.000 -> "Rp 1,5 jt"
  static String formatCompact(int amount) {
    if (amount.abs() >= 1000000000) {
      final val = (amount / 1000000000).toStringAsFixed(1).replaceAll('.0', '').replaceAll('.', ',');
      return 'Rp $val M';
    } else if (amount.abs() >= 1000000) {
      final val = (amount / 1000000).toStringAsFixed(1).replaceAll('.0', '').replaceAll('.', ',');
      return 'Rp $val jt';
    } else if (amount.abs() >= 1000) {
      final val = (amount / 1000).toStringAsFixed(1).replaceAll('.0', '').replaceAll('.', ',');
      return 'Rp $val rb';
    }
    return format(amount);
  }
}
