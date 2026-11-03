class Receipt {
  final String id;
  final String imagePath;
  final String merchant;
  final DateTime? receiptDate;
  final int? detectedTotal;
  final int calculatedTotal;
  final String? rawOcrText;
  final DateTime createdAt;

  Receipt({
    required this.id,
    required this.imagePath,
    required this.merchant,
    this.receiptDate,
    this.detectedTotal,
    required this.calculatedTotal,
    this.rawOcrText,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image_path': imagePath,
      'merchant': merchant,
      'receipt_date': receiptDate?.toIso8601String(),
      'detected_total': detectedTotal,
      'calculated_total': calculatedTotal,
      'raw_ocr_text': rawOcrText,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      id: map['id'] as String,
      imagePath: map['image_path'] as String,
      merchant: map['merchant'] as String? ?? '',
      receiptDate: map['receipt_date'] != null
          ? DateTime.tryParse(map['receipt_date'] as String)
          : null,
      detectedTotal: map['detected_total'] as int?,
      calculatedTotal: map['calculated_total'] as int? ?? 0,
      rawOcrText: map['raw_ocr_text'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
