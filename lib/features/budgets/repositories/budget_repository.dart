import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../models/budget.dart';

class BudgetRepository {
  final Database? _overrideDb;
  BudgetRepository([this._overrideDb]);

  Future<Database> get _db async => _overrideDb ?? await AppDatabase.getInstance();

  /// Retrieve budgets for a specific month (e.g. "2026-11"),
  /// along with actual spent amounts computed from transactions.
  Future<List<BudgetItem>> getBudgetsForMonth(String yearMonth) async {
    final db = await _db;

    final query = '''
      SELECT 
        c.id AS category_id,
        c.name AS category_name,
        c.code AS category_code,
        c.icon AS category_icon,
        c.color AS category_color,
        b.id AS budget_id,
        b.year_month,
        COALESCE(b.amount, 0) AS budget_amount,
        COALESCE(b.created_at, '') AS created_at,
        COALESCE(b.updated_at, '') AS updated_at,
        COALESCE((
          SELECT SUM(t.amount) 
          FROM transactions t 
          WHERE t.category_id = c.id 
            AND t.type = 'expense'
            AND strftime('%Y-%m', t.date) = ?
        ), 0) AS total_spent
      FROM categories c
      LEFT JOIN budgets b ON b.category_id = c.id AND b.year_month = ?
      WHERE c.type = 'expense' AND c.is_active = 1
      ORDER BY budget_amount DESC, total_spent DESC, c.sort_order ASC
    ''';

    final results = await db.rawQuery(query, [yearMonth, yearMonth]);

    return results.map((row) {
      final now = DateTime.now();
      final budgetId = row['budget_id'] as String? ?? const Uuid().v4();
      final createdAtStr = row['created_at'] as String?;
      final updatedAtStr = row['updated_at'] as String?;

      return BudgetItem(
        id: budgetId,
        categoryId: row['category_id'] as String,
        yearMonth: yearMonth,
        amount: row['budget_amount'] as int? ?? 0,
        createdAt: (createdAtStr != null && createdAtStr.isNotEmpty)
            ? DateTime.parse(createdAtStr)
            : now,
        updatedAt: (updatedAtStr != null && updatedAtStr.isNotEmpty)
            ? DateTime.parse(updatedAtStr)
            : now,
        spent: row['total_spent'] as int? ?? 0,
        categoryName: row['category_name'] as String?,
        categoryCode: row['category_code'] as String?,
        categoryIcon: row['category_icon'] as String?,
        categoryColor: row['category_color'] as String?,
      );
    }).toList();
  }

  /// Set or update budget for category and month
  Future<void> setBudget({
    required String categoryId,
    required String yearMonth,
    required int amount,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();

    await db.rawInsert('''
      INSERT INTO budgets (id, category_id, year_month, amount, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(category_id, year_month) DO UPDATE SET
        amount = excluded.amount,
        updated_at = excluded.updated_at
    ''', [
      const Uuid().v4(),
      categoryId,
      yearMonth,
      amount,
      now,
      now,
    ]);
  }

  /// Copy budgets from previous month if not set
  Future<int> copyBudgetsFromPreviousMonth(String currentYearMonth) async {
    final parts = currentYearMonth.split('-');
    if (parts.length != 2) return 0;
    int year = int.parse(parts[0]);
    int month = int.parse(parts[1]);

    if (month == 1) {
      year -= 1;
      month = 12;
    } else {
      month -= 1;
    }
    final prevYearMonth = '$year-${month.toString().padLeft(2, '0')}';

    final db = await _db;
    final prevBudgets = await db.query(
      'budgets',
      where: 'year_month = ? AND amount > 0',
      whereArgs: [prevYearMonth],
    );

    int copied = 0;
    for (final b in prevBudgets) {
      final catId = b['category_id'] as String;
      final amount = b['amount'] as int;
      await setBudget(categoryId: catId, yearMonth: currentYearMonth, amount: amount);
      copied++;
    }
    return copied;
  }

  /// Check count of categories exceeding >= 80% (for badge on home bell icon)
  Future<int> getAlertBudgetCount(String yearMonth) async {
    final budgets = await getBudgetsForMonth(yearMonth);
    return budgets.where((b) => b.amount > 0 && b.isWarning || b.isExceeded).length;
  }
}
