class CategoryExpenseShare {
  final String categoryId;
  final String categoryName;
  final String categoryCode;
  final String categoryIcon;
  final String categoryColor;
  final int totalAmount;
  final double percentage;

  const CategoryExpenseShare({
    required this.categoryId,
    required this.categoryName,
    required this.categoryCode,
    required this.categoryIcon,
    required this.categoryColor,
    required this.totalAmount,
    required this.percentage,
  });
}

class TrendBarItem {
  final String label; // e.g. "Sen", "03 Nov", "Minggu 1", "Nov"
  final DateTime date;
  final int expenseAmount;
  final int incomeAmount;

  const TrendBarItem({
    required this.label,
    required this.date,
    required this.expenseAmount,
    this.incomeAmount = 0,
  });
}

class CategoryComparisonItem {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final int currentAmount;
  final int previousAmount;
  final int difference; // current - previous
  final double percentageChange; // ((current - previous) / previous) * 100

  const CategoryComparisonItem({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.currentAmount,
    required this.previousAmount,
    required this.difference,
    required this.percentageChange,
  });
}
