class ReceiptItemModel {
  final String id;
  final String receiptId;
  final String name;
  final int qty;
  final int unitPrice;
  final int subtotal;
  final String categoryId;
  final String confidence; // 'high', 'medium', 'low'

  // Joined display attributes
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;

  ReceiptItemModel({
    required this.id,
    required this.receiptId,
    required this.name,
    this.qty = 1,
    required this.unitPrice,
    required this.subtotal,
    required this.categoryId,
    this.confidence = 'medium',
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  ReceiptItemModel copyWith({
    String? id,
    String? receiptId,
    String? name,
    int? qty,
    int? unitPrice,
    int? subtotal,
    String? categoryId,
    String? confidence,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
  }) {
    return ReceiptItemModel(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      name: name ?? this.name,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      subtotal: subtotal ?? (qty != null && unitPrice != null ? qty * unitPrice : this.subtotal),
      categoryId: categoryId ?? this.categoryId,
      confidence: confidence ?? this.confidence,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receipt_id': receiptId,
      'name': name,
      'qty': qty,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'category_id': categoryId,
      'confidence': confidence,
    };
  }

  factory ReceiptItemModel.fromMap(Map<String, dynamic> map) {
    return ReceiptItemModel(
      id: map['id'] as String,
      receiptId: map['receipt_id'] as String,
      name: map['name'] as String,
      qty: map['qty'] as int? ?? 1,
      unitPrice: map['unit_price'] as int? ?? 0,
      subtotal: map['subtotal'] as int? ?? 0,
      categoryId: map['category_id'] as String,
      confidence: map['confidence'] as String? ?? 'medium',
      categoryName: map['category_name'] as String?,
      categoryIcon: map['category_icon'] as String?,
      categoryColor: map['category_color'] as String?,
    );
  }
}
