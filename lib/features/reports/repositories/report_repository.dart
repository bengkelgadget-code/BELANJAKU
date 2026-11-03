import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../models/report_data.dart';

class ReportRepository {
  final Database? _overrideDb;
  ReportRepository([this._overrideDb]);

  Future<Database> get _db async => _overrideDb ?? await AppDatabase.getInstance();

  /// Retrieve top category expenses + "Lainnya" for donut chart
  Future<List<CategoryExpenseShare>> getCategoryShares({
    required DateTime startDate,
    required DateTime endDate,
    int topN = 5,
  }) async {
    final db = await _db;
    final startStr = startDate.toIso8601String();
    final endStr = endDate.toIso8601String();

    final query = '''
      SELECT 
        c.id AS category_id,
        c.name AS category_name,
        c.code AS category_code,
        c.icon AS category_icon,
        c.color AS category_color,
        SUM(t.amount) AS total_amount
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      WHERE t.type = 'expense'
        AND t.date >= ? AND t.date <= ?
      GROUP BY c.id
      ORDER BY total_amount DESC
    ''';

    final results = await db.rawQuery(query, [startStr, endStr]);
    if (results.isEmpty) return [];

    final totalExpense = results.fold<int>(
      0,
      (sum, row) => sum + (row['total_amount'] as int? ?? 0),
    );

    if (totalExpense == 0) return [];

    final List<CategoryExpenseShare> shares = [];
    int otherAmount = 0;

    for (int i = 0; i < results.length; i++) {
      final row = results[i];
      final amount = row['total_amount'] as int? ?? 0;

      if (i < topN) {
        shares.add(CategoryExpenseShare(
          categoryId: row['category_id'] as String,
          categoryName: row['category_name'] as String,
          categoryCode: row['category_code'] as String,
          categoryIcon: row['category_icon'] as String,
          categoryColor: row['category_color'] as String,
          totalAmount: amount,
          percentage: amount / totalExpense,
        ));
      } else {
        otherAmount += amount;
      }
    }

    if (otherAmount > 0) {
      shares.add(CategoryExpenseShare(
        categoryId: 'other_combined',
        categoryName: 'Lainnya',
        categoryCode: 'EXP_LAIN',
        categoryIcon: 'more-horizontal',
        categoryColor: '0xFF9CA3AF',
        totalAmount: otherAmount,
        percentage: otherAmount / totalExpense,
      ));
    }

    return shares;
  }

  /// Daily trend for last N days (default 7 days)
  Future<List<TrendBarItem>> getDailyTrend({required DateTime endDate, int days = 7}) async {
    final db = await _db;
    final startDate = endDate.subtract(Duration(days: days - 1));
    final startStr = DateTime(startDate.year, startDate.month, startDate.day).toIso8601String();
    final endStr = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59).toIso8601String();

    final query = '''
      SELECT 
        substr(date, 1, 10) AS day_str,
        SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) AS expense_amount,
        SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) AS income_amount
      FROM transactions
      WHERE date >= ? AND date <= ?
      GROUP BY day_str
      ORDER BY day_str ASC
    ''';

    final results = await db.rawQuery(query, [startStr, endStr]);
    final Map<String, Map<String, int>> map = {};
    for (final r in results) {
      final d = r['day_str'] as String;
      map[d] = {
        'expense': r['expense_amount'] as int? ?? 0,
        'income': r['income_amount'] as int? ?? 0,
      };
    }

    final dayLabels = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    final List<TrendBarItem> list = [];

    for (int i = 0; i < days; i++) {
      final curDate = startDate.add(Duration(days: i));
      final dateKey = curDate.toIso8601String().substring(0, 10);
      final label = dayLabels[curDate.weekday % 7];
      final exp = map[dateKey]?['expense'] ?? 0;
      final inc = map[dateKey]?['income'] ?? 0;

      list.add(TrendBarItem(
        label: label,
        date: curDate,
        expenseAmount: exp,
        incomeAmount: inc,
      ));
    }

    return list;
  }

  /// Comparison this month vs last month per category (§6.5)
  Future<List<CategoryComparisonItem>> getMonthComparison(String currentYearMonth) async {
    final db = await _db;
    final parts = currentYearMonth.split('-');
    if (parts.length != 2) return [];

    int year = int.parse(parts[0]);
    int month = int.parse(parts[1]);

    int prevYear = month == 1 ? year - 1 : year;
    int prevMonth = month == 1 ? 12 : month - 1;
    final prevYearMonth = '$prevYear-${prevMonth.toString().padLeft(2, '0')}';

    final query = '''
      SELECT 
        c.id AS category_id,
        c.name AS category_name,
        c.icon AS category_icon,
        c.color AS category_color,
        COALESCE(SUM(CASE WHEN strftime('%Y-%m', t.date) = ? THEN t.amount ELSE 0 END), 0) AS current_amount,
        COALESCE(SUM(CASE WHEN strftime('%Y-%m', t.date) = ? THEN t.amount ELSE 0 END), 0) AS prev_amount
      FROM categories c
      LEFT JOIN transactions t ON t.category_id = c.id AND t.type = 'expense'
      WHERE c.type = 'expense'
      GROUP BY c.id
      HAVING current_amount > 0 OR prev_amount > 0
      ORDER BY current_amount DESC
    ''';

    final results = await db.rawQuery(query, [currentYearMonth, prevYearMonth]);

    return results.map((r) {
      final current = r['current_amount'] as int? ?? 0;
      final prev = r['prev_amount'] as int? ?? 0;
      final diff = current - prev;
      final double pct = prev > 0 ? (diff / prev) * 100 : (current > 0 ? 100.0 : 0.0);

      return CategoryComparisonItem(
        categoryId: r['category_id'] as String,
        categoryName: r['category_name'] as String,
        categoryIcon: r['category_icon'] as String,
        categoryColor: r['category_color'] as String,
        currentAmount: current,
        previousAmount: prev,
        difference: diff,
        percentageChange: pct,
      );
    }).toList();
  }
}
