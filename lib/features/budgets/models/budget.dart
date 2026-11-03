class BudgetItem {
  final String id;
  final String categoryId;
  final String yearMonth; // 'YYYY-MM'
  final int amount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed & Joined
  final int spent;
  final String? categoryName;
  final String? categoryCode;
  final String? categoryIcon;
  final String? categoryColor;

  BudgetItem({
    required this.id,
    required this.categoryId,
    required this.yearMonth,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
    this.spent = 0,
    this.categoryName,
    this.categoryCode,
    this.categoryIcon,
    this.categoryColor,
  });

  int get remaining => amount - spent;
  double get percentage => amount > 0 ? (spent / amount).clamp(0.0, 2.0) : 0.0;
  bool get isWarning => percentage >= 0.8 && percentage < 1.0;
  bool get isExceeded => percentage >= 1.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'year_month': yearMonth,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BudgetItem.fromMap(Map<String, dynamic> map, {int spent = 0}) {
    return BudgetItem(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      yearMonth: map['year_month'] as String,
      amount: map['amount'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      spent: spent,
      categoryName: map['category_name'] as String?,
      categoryCode: map['category_code'] as String?,
      categoryIcon: map['category_icon'] as String?,
      categoryColor: map['category_color'] as String?,
    );
  }
}
