import 'package:flutter_test/flutter_test.dart';
import 'package:belanjaku/features/scan/services/receipt_parser.dart';

void main() {
  group('ReceiptParser Tests (§7.3, §7.5, & Lampiran A)', () {
    test('Lampiran A: Indomaret receipt with discount', () {
      const rawText = '''
INDOMARET
Jl. Test No. 1, Samarinda
03/11/2026 20:09
----------------------------
INDOMIE GORENG 2 X 3.500  7.000
BERAS 5KG  62.000
MINYAK GORENG 2L  34.500
KOPI SUSU  10.000
----------------------------
SUBTOTAL  113.500
DISKON  -5.000
TOTAL  108.500
TUNAI  110.000
KEMBALI  1.500
TERIMA KASIH
''';

      final result = ReceiptParser.parse(rawText);

      expect(result.merchant, contains('INDOMARET'));
      expect(result.date?.year, 2026);
      expect(result.date?.month, 11);
      expect(result.date?.day, 3);

      expect(result.items.length, 4);

      // Check item 1: INDOMIE GORENG
      expect(result.items[0].name, 'INDOMIE GORENG');
      expect(result.items[0].qty, 2);
      expect(result.items[0].unitPrice, 3500);
      expect(result.items[0].subtotal, 7000);

      // Check item 2: BERAS 5KG
      expect(result.items[1].name, 'BERAS 5KG');
      expect(result.items[1].subtotal, 62000);
      expect(result.items[1].categoryId, 'cat_exp_sembako');

      // Check item 3: MINYAK GORENG
      expect(result.items[2].name, 'MINYAK GORENG 2L');
      expect(result.items[2].subtotal, 34500);
      expect(result.items[2].categoryId, 'cat_exp_sembako');

      // Check item 4: KOPI SUSU
      expect(result.items[3].name, 'KOPI SUSU');
      expect(result.items[3].subtotal, 10000);
      expect(result.items[3].categoryId, 'cat_exp_makan');

      // Totals
      expect(result.detectedSubtotal, 113500);
      expect(result.detectedDiscount, 5000);
      expect(result.detectedTotal, 108500);
      expect(result.calculatedTotal, 108500);
      expect(result.hasDifferenceWarning, isFalse);
    });

    test('SPBU Pertamina single item receipt', () {
      const rawText = '''
SPBU PERTAMINA 64.751.01
JL. M. YAMIN SAMARINDA
02/11/2026 08:30
----------------------------
PERTALITE  50.000
----------------------------
TOTAL  50.000
CASH  50.000
KEMBALI  0
''';

      final result = ReceiptParser.parse(rawText);

      expect(result.merchant, contains('SPBU PERTAMINA'));
      expect(result.items.length, 1);
      expect(result.items[0].name, 'PERTALITE');
      expect(result.items[0].subtotal, 50000);
      expect(result.items[0].categoryId, 'cat_exp_transport');
      expect(result.detectedTotal, 50000);
      expect(result.hasDifferenceWarning, isFalse);
    });

    test('Restaurant with PB1 Tax and multi-line item', () {
      const rawText = '''
RM SEDERHANA PADANG
01/11/2026 13:15
----------------------------
AYAM POP
24.000
RENDANG DAGING  28.000
ES TEH MANIS  6.000
----------------------------
SUBTOTAL  58.000
PB1 10%  5.800
TOTAL  63.800
''';

      final result = ReceiptParser.parse(rawText);

      expect(result.items.length, 3);
      expect(result.items[0].name, 'AYAM POP');
      expect(result.items[0].subtotal, 24000);
      expect(result.items[0].categoryId, 'cat_exp_makan');

      expect(result.detectedTax, 5800);
      expect(result.detectedTotal, 63800);
      expect(result.calculatedTotal, 63800);
      expect(result.hasDifferenceWarning, isFalse);
    });

    test('User correction takes precedence over dictionary (§7.5 Rule 1)', () {
      const rawText = '''
INDOMARET
INDOMIE GORENG  3.500
TOTAL  3.500
''';

      // Normally "indomie goreng" matches EXP_MAKAN or EXP_SEMBAKO.
      // If user corrected it to EXP_RUMAH ('cat_exp_rumah'):
      final userLearned = {'indomie goreng': 'cat_exp_rumah'};

      final result = ReceiptParser.parse(rawText, userLearnedCategories: userLearned);

      expect(result.items.length, 1);
      expect(result.items[0].categoryId, 'cat_exp_rumah');
    });

    test('Detects difference warning when discrepancy exceeds Rp 1.000', () {
      const rawText = '''
MINIMARKET
BARANG A  10.000
BARANG B  10.000
TOTAL  35.000
''';

      final result = ReceiptParser.parse(rawText);

      expect(result.items.length, 2);
      expect(result.calculatedTotal, 20000);
      expect(result.detectedTotal, 35000);
      expect(result.hasDifferenceWarning, isTrue);
      expect(result.differenceAmount, 15000);
    });
  });
}
