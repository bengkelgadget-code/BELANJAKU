import 'package:flutter_test/flutter_test.dart';
import 'package:belanjaku/features/scan/services/receipt_parser.dart';

void main() {
  group('ReceiptParser Tests (§7.3, §7.5, & Lampiran A)', () {
    // 1. Lampiran A Indomaret with Discount (Mandatory PRD Example)
    test('1. Lampiran A: Indomaret receipt with discount (4 items, Rp108.500)', () {
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

    // 2. SPBU Pertamina Single Item
    test('2. SPBU Pertamina single item receipt', () {
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

    // 3. Restaurant with PB1 Tax and multi-line item
    test('3. Restaurant with PB1 Tax and multi-line item', () {
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

    // 4. User correction takes precedence
    test('4. User correction takes precedence over dictionary (§7.5 Rule 1)', () {
      const rawText = '''
INDOMARET
INDOMIE GORENG  3.500
TOTAL  3.500
''';

      final userLearned = {'indomie goreng': 'cat_exp_rumah'};
      final result = ReceiptParser.parse(rawText, userLearnedCategories: userLearned);

      expect(result.items.length, 1);
      expect(result.items[0].categoryId, 'cat_exp_rumah');
    });

    // 5. Detects difference warning
    test('5. Detects difference warning when discrepancy exceeds Rp 1.000', () {
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

    // 6. Alfamart receipt with member discount and PPN
    test('6. Alfamart receipt with potongan harga & item sembako', () {
      const rawText = '''
ALFAMART DIPONEGORO
31/10/2026 14:20
----------------------------
GULA PASIR 1KG  17.500
BERAS MERAH 2KG  32.000
POTONGAN HARGA  -2.000
----------------------------
TOTAL HARGA  47.500
BAYAR TUNAI  50.000
KEMBALIAN  2.500
''';

      final result = ReceiptParser.parse(rawText);

      expect(result.merchant, contains('ALFAMART'));
      expect(result.items.length, 2);
      expect(result.items[0].name, 'GULA PASIR 1KG');
      expect(result.items[0].subtotal, 17500);
      expect(result.items[0].categoryId, 'cat_exp_sembako');
      expect(result.items[1].name, 'BERAS MERAH 2KG');
      expect(result.items[1].categoryId, 'cat_exp_sembako');
      expect(result.detectedDiscount, 2000);
      expect(result.detectedTotal, 47500);
      expect(result.calculatedTotal, 47500);
      expect(result.hasDifferenceWarning, isFalse);
    });

    // 7. Apotek Kimia Farma (Kesehatan)
    test('7. Apotek receipt categorized as kesehatan', () {
      const rawText = '''
APOTEK KIMIA FARMA
28/10/2026 19:45
----------------------------
PARACETAMOL 500MG  8.500
VITAMIN C 500MG 2 X 15.000  30.000
OBAT BATUK SIRUP  25.000
----------------------------
TOTAL  63.500
DEBIT BCA  63.500
''';

      final result = ReceiptParser.parse(rawText);

      expect(result.merchant, contains('APOTEK KIMIA FARMA'));
      expect(result.items.length, 3);
      for (final item in result.items) {
        expect(item.categoryId, 'cat_exp_kesehatan');
      }
      expect(result.detectedTotal, 63500);
      expect(result.calculatedTotal, 63500);
    });

    // 8. Toko Buku / Alat Tulis (Pendidikan)
    test('8. Stationery & book receipt categorized as pendidikan', () {
      const rawText = '''
TOKO BUKU GRAMEDIA
25/10/2026 16:10
----------------------------
BUKU TULIS KIKY 10S  45.000
PULPEN STANDARD BIRU 3 X 4.000  12.000
KERTAS HVS A4 80GR  55.000
----------------------------
TOTAL  112.000
''';

      final result = ReceiptParser.parse(rawText);

      expect(result.items.length, 3);
      for (final item in result.items) {
        expect(item.categoryId, 'cat_exp_pendidikan');
      }
      expect(result.detectedTotal, 112000);
    });

    // 9. Supermarket long receipt (10 items)
    test('9. Supermarket multi-item long receipt parses all items without error', () {
      const rawText = '''
SUPERINDO FRESH
20/10/2026 11:00
----------------------------
TELUR AYAM 1KG  28.000
ROTI TAWAR  15.000
SUSU UHT FULL CREAM 1L  21.000
PASTA GIGI PEPSODENT  12.500
SHAMPOO CLEAR 160ML  26.000
DETERJEN BUBUK 800G  19.500
BISKUIT ROMA  8.000
SNACK CHITATO  11.500
TEH CELUP SOSRO  7.500
AIR MINERAL 1.5L  6.000
----------------------------
TOTAL  155.000
''';

      final result = ReceiptParser.parse(rawText);

      expect(result.items.length, 10);
      expect(result.detectedTotal, 155000);
      expect(result.calculatedTotal, 155000);
      expect(result.hasDifferenceWarning, isFalse);
    });

    // 10. Thermal folded/faded receipt without total line (calculated fallback)
    test('10. Folded/faded thermal receipt without total falls back to sum of items', () {
      const rawText = '''
WARUNG KOPI JAGO
----------------------------
ES KOPI SUSU GULA AREN  18.000
ROTI BAKAR COKLAT  15.000
(BAGIAN BAWAH TERLIPAT / PUDAR)
''';

      final result = ReceiptParser.parse(rawText);

      expect(result.items.length, 2);
      expect(result.detectedTotal, isNull);
      expect(result.calculatedTotal, 33000);
      expect(result.hasDifferenceWarning, isFalse);
    });
  });
}
