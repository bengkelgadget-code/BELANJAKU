import 'package:flutter_test/flutter_test.dart';
import 'package:belanjaku/core/utils/currency_formatter.dart';
import 'package:belanjaku/core/utils/date_formatter.dart';

void main() {
  group('CurrencyFormatter Tests (§8.4)', () {
    test('Formats positive nominal correctly with dots and Rp', () {
      expect(CurrencyFormatter.format(1250000), 'Rp 1.250.000');
      expect(CurrencyFormatter.format(50000), 'Rp 50.000');
      expect(CurrencyFormatter.format(0), 'Rp 0');
    });

    test('Formats negative nominal with minus in front of Rp', () {
      expect(CurrencyFormatter.format(-50000), '−Rp 50.000');
    });

    test('Formats with explicit sign', () {
      expect(CurrencyFormatter.formatWithSign(100000, isIncome: true), '+Rp 100.000');
      expect(CurrencyFormatter.formatWithSign(100000, isIncome: false), '−Rp 100.000');
    });

    test('Parses raw text to integer correctly', () {
      expect(CurrencyFormatter.parse('1.250.000'), 1250000);
      expect(CurrencyFormatter.parse('Rp 50.000'), 50000);
      expect(CurrencyFormatter.parse('abc'), isNull);
    });
  });

  group('DateFormatter Tests', () {
    test('Group header shows Hari ini and Kemarin', () {
      final now = DateTime.now();
      expect(DateFormatter.formatGroupHeader(now), 'Hari ini');

      final yesterday = now.subtract(const Duration(days: 1));
      expect(DateFormatter.formatGroupHeader(yesterday), 'Kemarin');
    });

    test('Formats ISO strings correctly', () {
      final date = DateTime(2026, 11, 3);
      expect(DateFormatter.toIsoDate(date), '2026-11-03');
      expect(DateFormatter.toYearMonth(date), '2026-11');
    });
  });
}
