class TransactionItem {
  final String id;
  final String type; // 'income', 'expense', 'transfer_out', 'transfer_in'
  final int amount;
  final String? categoryId;
  final String walletId;
  final DateTime date;
  final String? note;
  final String? merchant;
  final String? receiptId;
  final String? transferPairId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined display properties (from JOIN with categories & wallets)
  final String? categoryName;
  final String? categoryCode;
  final String? categoryIcon;
  final String? categoryColor;
  final String? walletName;

  TransactionItem({
    required this.id,
    required this.type,
    required this.amount,
    this.categoryId,
    required this.walletId,
    required this.date,
    this.note,
    this.merchant,
    this.receiptId,
    this.transferPairId,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
    this.categoryCode,
    this.categoryIcon,
    this.categoryColor,
    this.walletName,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  bool get isTransfer => type == 'transfer_out' || type == 'transfer_in';

  TransactionItem copyWith({
    String? id,
    String? type,
    int? amount,
    String? categoryId,
    String? walletId,
    DateTime? date,
    String? note,
    String? merchant,
    String? receiptId,
    String? transferPairId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryName,
    String? categoryCode,
    String? categoryIcon,
    String? categoryColor,
    String? walletName,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      date: date ?? this.date,
      note: note ?? this.note,
      merchant: merchant ?? this.merchant,
      receiptId: receiptId ?? this.receiptId,
      transferPairId: transferPairId ?? this.transferPairId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryName: categoryName ?? this.categoryName,
      categoryCode: categoryCode ?? this.categoryCode,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      walletName: walletName ?? this.walletName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'category_id': categoryId,
      'wallet_id': walletId,
      'date': date.toIso8601String(),
      'note': note,
      'merchant': merchant,
      'receipt_id': receiptId,
      'transfer_pair_id': transferPairId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'] as String,
      type: map['type'] as String,
      amount: map['amount'] as int,
      categoryId: map['category_id'] as String?,
      walletId: map['wallet_id'] as String,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      merchant: map['merchant'] as String?,
      receiptId: map['receipt_id'] as String?,
      transferPairId: map['transfer_pair_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      categoryName: map['category_name'] as String?,
      categoryCode: map['category_code'] as String?,
      categoryIcon: map['category_icon'] as String?,
      categoryColor: map['category_color'] as String?,
      walletName: map['wallet_name'] as String?,
    );
  }
}
