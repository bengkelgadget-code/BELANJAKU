import 'dart:math';
import '../../../core/constants/default_categories.dart';
import '../models/receipt_item.dart';

class ParsedReceiptResult {
  final String merchant;
  final DateTime? date;
  final bool isDateGuessed;
  final List<ReceiptItemModel> items;
  final int? detectedSubtotal;
  final int? detectedDiscount;
  final int? detectedTax;
  final int? detectedTotal;
  final int calculatedTotal;
  final bool hasDifferenceWarning;
  final int differenceAmount;
  final String rawText;

  ParsedReceiptResult({
    required this.merchant,
    this.date,
    this.isDateGuessed = false,
    required this.items,
    this.detectedSubtotal,
    this.detectedDiscount,
    this.detectedTax,
    this.detectedTotal,
    required this.calculatedTotal,
    this.hasDifferenceWarning = false,
    this.differenceAmount = 0,
    required this.rawText,
  });
}

class ReceiptParser {
  /// Known merchants for fallback categorization and header detection
  static const List<String> knownMerchants = [
    'INDOMARET',
    'ALFAMART',
    'ALFAMIDI',
    'SUPERINDO',
    'TRANSMART',
    'HYPERMART',
    'LOTTE',
    'WARUNG',
    'RM ',
    'RUMAH MAKAN',
    'RESTO',
    'CAFE',
    'APOTEK',
    'KIMIA FARMA',
    'K-24',
    'SPBU',
    'PERTAMINA',
    'SHELL',
    'STARBUCKS',
    'JANJI JIWA',
    'KOPI KENANGAN',
    'KFC',
    'MCDONALD',
    'PIZZA HUT',
    'BURGER KING',
  ];

  static const List<String> ignoredLinePhrases = [
    'TERIMA KASIH',
    'SELAMAT DATANG',
    'LAYANAN KONSUMEN',
    'CUSTOMER SERVICE',
    'CALL CENTER',
    'KASIR',
    'CASHIER',
    'NPWP',
    'STRUK',
    'RECEIPT',
    'INVOICE',
    'NO.',
    'NOMOR',
    'JL.',
    'JALAN',
    'TELP',
    'WEBSITE',
    'BARCODE',
    'PINTU MASUK',
    'KARTU',
    'DEBIT',
    'KREDIT',
    'QRIS',
    'MEMBER',
    'POIN',
  ];

  /// Pure parse method: accepts raw text and category lookup dictionary
  static ParsedReceiptResult parse(
    String rawText, {
    Map<String, String>? userLearnedCategories,
    Map<String, String>? categoryCodeToIdMap,
  }) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !_isDashedOrSeparator(l))
        .toList();

    String detectedMerchant = _detectMerchant(lines);
    DateTime? detectedDate = _detectDate(lines);
    bool isDateGuessed = false;
    if (detectedDate == null) {
      detectedDate = DateTime.now();
      isDateGuessed = true;
    }

    int? detectedSubtotal;
    int? detectedDiscount;
    int? detectedTax;
    int? detectedTotal;

    // Scan for totals, discounts, taxes, cash, change
    final itemCandidateLines = <String>[];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final upper = line.toUpperCase();

      if (_isTotalLine(upper)) {
        final amount = _extractLastNumber(line);
        if (amount != null) {
          if (upper.contains('SUBTOTAL') || upper.contains('SUB TOTAL')) {
            detectedSubtotal ??= amount;
          } else {
            detectedTotal ??= amount;
          }
        }
        continue;
      }

      if (_isDiscountLine(upper)) {
        final amount = _extractLastNumber(line);
        if (amount != null) {
          detectedDiscount = (detectedDiscount ?? 0) + amount.abs();
        }
        continue;
      }

      if (_isTaxLine(upper)) {
        final amount = _extractLastNumber(line);
        if (amount != null) {
          detectedTax = (detectedTax ?? 0) + amount.abs();
        }
        continue;
      }

      if (_isCashOrChangeLine(upper)) {
        // Skip cash/change lines
        continue;
      }

      if (_isIgnoredLine(upper)) {
        continue;
      }

      // If it looks like merchant name header, skip
      if (detectedMerchant.isNotEmpty && upper.contains(detectedMerchant.toUpperCase())) {
        continue;
      }

      itemCandidateLines.add(line);
    }

    // Parse items from candidate lines (supports multi-line item merging)
    final items = _parseItems(
      itemCandidateLines,
      merchant: detectedMerchant,
      userLearnedCategories: userLearnedCategories,
      categoryCodeToIdMap: categoryCodeToIdMap,
    );

    int calculatedTotal = items.fold(0, (sum, item) => sum + item.subtotal);
    if (detectedDiscount != null) {
      calculatedTotal -= detectedDiscount;
    }
    if (detectedTax != null) {
      calculatedTotal += detectedTax;
    }

    // Difference check (§7.3b)
    bool hasDiffWarning = false;
    int diffAmount = 0;
    if (detectedTotal != null) {
      diffAmount = (detectedTotal - calculatedTotal).abs();
      if (diffAmount > 1000) {
        hasDiffWarning = true;
      }
    }

    return ParsedReceiptResult(
      merchant: detectedMerchant,
      date: detectedDate,
      isDateGuessed: isDateGuessed,
      items: items,
      detectedSubtotal: detectedSubtotal,
      detectedDiscount: detectedDiscount,
      detectedTax: detectedTax,
      detectedTotal: detectedTotal,
      calculatedTotal: calculatedTotal > 0 ? calculatedTotal : (detectedTotal ?? 0),
      hasDifferenceWarning: hasDiffWarning,
      differenceAmount: diffAmount,
      rawText: rawText,
    );
  }

  // --- Helper parsing routines ---

  static bool _isDashedOrSeparator(String s) {
    final cleaned = s.replaceAll(RegExp(r'[\s\-_=\*\.+]'), '');
    return cleaned.isEmpty;
  }

  static bool _isTotalLine(String upper) {
    return upper.contains('GRAND TOTAL') ||
        upper.contains('TOTAL BAYAR') ||
        upper.contains('JUMLAH BAYAR') ||
        upper.contains('SUBTOTAL') ||
        upper.contains('SUB TOTAL') ||
        upper.startsWith('TOTAL') ||
        upper.endsWith('TOTAL') ||
        upper.contains(' TOTAL ') ||
        upper.contains('JUMLAH');
  }

  static bool _isDiscountLine(String upper) {
    return upper.contains('DISKON') ||
        upper.contains('DISC') ||
        upper.contains('POTONGAN') ||
        upper.contains('VOUCHER') ||
        upper.contains('HEMAT');
  }

  static bool _isTaxLine(String upper) {
    return upper.contains('PPN') ||
        upper.contains('PB1') ||
        upper.contains('TAX') ||
        upper.contains('SERVICE CHARGE') ||
        upper.contains('BIAYA LAYANAN');
  }

  static bool _isCashOrChangeLine(String upper) {
    return upper.contains('TUNAI') ||
        upper.contains('CASH') ||
        upper.contains('KEMBALI') ||
        upper.contains('CHANGE') ||
        upper.contains('KEMBALIAN') ||
        upper.contains('BAYAR');
  }

  static bool _isIgnoredLine(String upper) {
    for (final phrase in ignoredLinePhrases) {
      if (upper.contains(phrase)) return true;
    }
    // Barcode numbers (long sequence of digits)
    if (RegExp(r'^\d{8,}$').hasMatch(upper.replaceAll(' ', ''))) return true;
    return false;
  }

  static String _detectMerchant(List<String> lines) {
    // First check first 4 lines for known brands
    final checkLimit = min(lines.length, 5);
    for (int i = 0; i < checkLimit; i++) {
      final upper = lines[i].toUpperCase();
      for (final m in knownMerchants) {
        if (upper.contains(m)) {
          return lines[i].trim();
        }
      }
    }

    // Otherwise, pick first all-uppercase line that is not a date or address
    for (int i = 0; i < checkLimit; i++) {
      final line = lines[i].trim();
      if (line.length >= 3 &&
          line == line.toUpperCase() &&
          !line.contains('/') &&
          !line.contains(':') &&
          !RegExp(r'\d{3,}').hasMatch(line)) {
        return line;
      }
    }

    return '';
  }

  static DateTime? _detectDate(List<String> lines) {
    // Look for formats: DD/MM/YYYY, DD-MM-YYYY, YYYY/MM/DD, DD MMM YYYY
    final dateRegex1 = RegExp(r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})');
    final dateRegex2 = RegExp(r'(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})');
    final timeRegex = RegExp(r'(\d{1,2}):(\d{2})');

    DateTime? foundDate;
    int hour = 12;
    int minute = 0;

    for (final line in lines) {
      final tMatch = timeRegex.firstMatch(line);
      if (tMatch != null) {
        hour = int.tryParse(tMatch.group(1)!) ?? 12;
        minute = int.tryParse(tMatch.group(2)!) ?? 0;
      }

      final match1 = dateRegex1.firstMatch(line);
      if (match1 != null) {
        final d = int.tryParse(match1.group(1)!);
        final m = int.tryParse(match1.group(2)!);
        final y = int.tryParse(match1.group(3)!);
        if (d != null && m != null && y != null && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
          foundDate = DateTime(y, m, d, hour, minute);
          break;
        }
      }

      final match2 = dateRegex2.firstMatch(line);
      if (match2 != null) {
        final y = int.tryParse(match2.group(1)!);
        final m = int.tryParse(match2.group(2)!);
        final d = int.tryParse(match2.group(3)!);
        if (d != null && m != null && y != null && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
          foundDate = DateTime(y, m, d, hour, minute);
          break;
        }
      }
    }

    return foundDate;
  }

  static List<ReceiptItemModel> _parseItems(
    List<String> lines, {
    required String merchant,
    Map<String, String>? userLearnedCategories,
    Map<String, String>? categoryCodeToIdMap,
  }) {
    final List<ReceiptItemModel> items = [];
    int index = 0;

    // Pattern 1: Qty x UnitPrice Total (e.g. "INDOMIE GORENG 2 X 3.500  7.000" or "2x3500")
    final qtyPattern = RegExp(
      r'^(.*?)\s+(\d+)\s*[xX]\s*([0-9.,]+)\s+([0-9.,]+)$',
    );

    // Pattern 2: Name + Price at end (e.g. "BERAS 5KG  62.000")
    final simplePattern = RegExp(
      r'^(.*?)\s+([0-9.,]+)$',
    );

    while (index < lines.length) {
      final line = lines[index].trim();
      index++;

      if (line.isEmpty) continue;

      // Try Pattern 1 (Qty x Price)
      final match1 = qtyPattern.firstMatch(line);
      if (match1 != null) {
        final name = match1.group(1)!.trim();
        final qty = int.tryParse(match1.group(2)!) ?? 1;
        final unitPrice = _cleanPrice(match1.group(3)!);
        final subtotal = _cleanPrice(match1.group(4)!);

        if (name.isNotEmpty && subtotal > 0) {
          final catId = _resolveCategory(
            name,
            merchant: merchant,
            userLearnedCategories: userLearnedCategories,
            categoryCodeToIdMap: categoryCodeToIdMap,
          );
          items.add(ReceiptItemModel(
            id: 'item_${items.length + 1}',
            receiptId: '',
            name: name,
            qty: qty,
            unitPrice: unitPrice > 0 ? unitPrice : (subtotal ~/ max(1, qty)),
            subtotal: subtotal,
            categoryId: catId,
            confidence: 'high',
          ));
          continue;
        }
      }

      // Try Pattern 2 (Name + Price)
      final match2 = simplePattern.firstMatch(line);
      if (match2 != null) {
        final rawName = match2.group(1)!.trim();
        final price = _cleanPrice(match2.group(2)!);

        // Ensure price is realistic rupiah (> 100) and name doesn't look like date/time
        if (rawName.length >= 2 && price >= 100 && !rawName.contains(':')) {
          final catId = _resolveCategory(
            rawName,
            merchant: merchant,
            userLearnedCategories: userLearnedCategories,
            categoryCodeToIdMap: categoryCodeToIdMap,
          );
          items.add(ReceiptItemModel(
            id: 'item_${items.length + 1}',
            receiptId: '',
            name: rawName,
            qty: 1,
            unitPrice: price,
            subtotal: price,
            categoryId: catId,
            confidence: 'medium',
          ));
          continue;
        }
      }

      // Try Multi-line Item: Name on current line, next line is pure price
      if (index < lines.length) {
        final nextLine = lines[index].trim();
        final nextPrice = _cleanPrice(nextLine);
        if (nextPrice >= 100 && _isPureNumberString(nextLine)) {
          index++; // Consume next line
          final catId = _resolveCategory(
            line,
            merchant: merchant,
            userLearnedCategories: userLearnedCategories,
            categoryCodeToIdMap: categoryCodeToIdMap,
          );
          items.add(ReceiptItemModel(
            id: 'item_${items.length + 1}',
            receiptId: '',
            name: line,
            qty: 1,
            unitPrice: nextPrice,
            subtotal: nextPrice,
            categoryId: catId,
            confidence: 'medium',
          ));
          continue;
        }
      }
    }

    return items;
  }

  static bool _isPureNumberString(String s) {
    final cleaned = s.replaceAll(RegExp(r'[\s.,Rp]'), '');
    return cleaned.isNotEmpty && RegExp(r'^\d+$').hasMatch(cleaned);
  }

  static int _cleanPrice(String text) {
    // Indonesian format: 12.500 or 12,500 or 12500
    var cleaned = text.replaceAll('Rp', '').replaceAll(' ', '').trim();
    // If it has both dot and comma (e.g. 1.250,00), remove comma part or dots
    if (cleaned.contains('.') && cleaned.contains(',')) {
      cleaned = cleaned.split(',')[0].replaceAll('.', '');
    } else if (cleaned.contains('.')) {
      // 12.500 -> 12500
      cleaned = cleaned.replaceAll('.', '');
    } else if (cleaned.contains(',')) {
      // 12,500 -> 12500
      cleaned = cleaned.replaceAll(',', '');
    }
    return int.tryParse(cleaned) ?? 0;
  }

  static int? _extractLastNumber(String line) {
    final regex = RegExp(r'([0-9.,]+)$');
    final match = regex.firstMatch(line.trim());
    if (match != null) {
      final p = _cleanPrice(match.group(1)!);
      if (p > 0) return p;
    }
    return null;
  }

  /// Resolve Category following PRD §7.5 rules in order:
  /// 1. User learned correction
  /// 2. Keyword substring matching
  /// 3. Default merchant matching
  /// 4. Fallback EXP_LAIN
  static String _resolveCategory(
    String itemName, {
    required String merchant,
    Map<String, String>? userLearnedCategories,
    Map<String, String>? categoryCodeToIdMap,
  }) {
    final itemLower = itemName.toLowerCase().trim();

    // 1. User learned correction
    if (userLearnedCategories != null) {
      for (final entry in userLearnedCategories.entries) {
        if (itemLower.contains(entry.key.toLowerCase())) {
          return entry.value;
        }
      }
    }

    // 2. Keyword dictionary lookup
    for (final cat in DefaultCategories.expenseCategories) {
      for (final kw in cat.keywords) {
        if (itemLower.contains(kw.toLowerCase())) {
          return categoryCodeToIdMap?[cat.code] ?? cat.id;
        }
      }
    }

    // 3. Default merchant match
    final merchUpper = merchant.toUpperCase();
    if (merchUpper.contains('SPBU') || merchUpper.contains('PERTAMINA') || merchUpper.contains('SHELL')) {
      return categoryCodeToIdMap?['EXP_TRANSPORT'] ?? 'cat_exp_transport';
    }
    if (merchUpper.contains('APOTEK') || merchUpper.contains('KIMIA FARMA') || merchUpper.contains('K-24')) {
      return categoryCodeToIdMap?['EXP_KESEHATAN'] ?? 'cat_exp_kesehatan';
    }
    if (merchUpper.contains('INDOMARET') || merchUpper.contains('ALFAMART') || merchUpper.contains('ALFAMIDI') || merchUpper.contains('SUPERINDO')) {
      return categoryCodeToIdMap?['EXP_SEMBAKO'] ?? 'cat_exp_sembako';
    }
    if (merchUpper.contains('WARUNG') || merchUpper.contains('RM') || merchUpper.contains('RESTO') || merchUpper.contains('CAFE')) {
      return categoryCodeToIdMap?['EXP_MAKAN'] ?? 'cat_exp_makan';
    }

    // 4. Fallback
    return categoryCodeToIdMap?['EXP_LAIN'] ?? 'cat_exp_lain';
  }
}
