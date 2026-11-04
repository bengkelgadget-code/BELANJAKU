import 'package:sqflite/sqflite.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../models/transaction.dart';

class TransactionFilter {
  final String? searchQuery;
  final String? type; // 'income', 'expense', or null (all)
  final List<String>? categoryIds;
  final String? walletId;
  final DateTime? startDate;
  final DateTime? endDate;

  const TransactionFilter({
    this.searchQuery,
    this.type,
    this.categoryIds,
    this.walletId,
    this.startDate,
    this.endDate,
  });

  bool get hasActiveFilter =>
      (searchQuery != null && searchQuery!.isNotEmpty) ||
      type != null ||
      (categoryIds != null && categoryIds!.isNotEmpty) ||
      walletId != null ||
      startDate != null ||
      endDate != null;
}

class TransactionSummary {
  final int totalIncome;
  final int totalExpense;
  int get net => totalIncome - totalExpense;

  const TransactionSummary({
    required this.totalIncome,
    required this.totalExpense,
  });
}

class TransactionRepository {
  final Database? _overrideDb;
  TransactionRepository([this._overrideDb]);

  Future<Database> get _db async => _overrideDb ?? await AppDatabase.getInstance();

  Future<List<TransactionItem>> getTransactions({
    TransactionFilter? filter,
    int? limit,
    int? offset,
  }) async {
    final db = await _db;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (filter != null) {
      if (filter.type != null) {
        conditions.add('t.type = ?');
        args.add(filter.type);
      }
      if (filter.walletId != null) {
        conditions.add('t.wallet_id = ?');
        args.add(filter.walletId);
      }
      if (filter.categoryIds != null && filter.categoryIds!.isNotEmpty) {
        final placeholders = List.filled(filter.categoryIds!.length, '?').join(',');
        conditions.add('t.category_id IN ($placeholders)');
        args.addAll(filter.categoryIds!);
      }
      if (filter.startDate != null) {
        conditions.add('t.date >= ?');
        args.add(filter.startDate!.toIso8601String());
      }
      if (filter.endDate != null) {
        conditions.add('t.date <= ?');
        args.add(filter.endDate!.toIso8601String());
      }
      if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
        final q = '%${filter.searchQuery!.trim()}%';
        // Match note, merchant, category name, or nominal amount
        conditions.add('''
          (
            t.note LIKE ? OR 
            t.merchant LIKE ? OR 
            c.name LIKE ? OR 
            CAST(t.amount AS TEXT) LIKE ?
          )
        ''');
        args.addAll([q, q, q, q]);
      }
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final limitClause = limit != null ? 'LIMIT $limit' : '';
    final offsetClause = offset != null ? 'OFFSET $offset' : '';

    final query = '''
      SELECT 
        t.*,
        c.name AS category_name,
        c.code AS category_code,
        c.icon AS category_icon,
        c.color AS category_color,
        w.name AS wallet_name
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      LEFT JOIN wallets w ON t.wallet_id = w.id
      $whereClause
      ORDER BY t.date DESC, t.created_at DESC
      $limitClause
      $offsetClause
    ''';

    final results = await db.rawQuery(query, args);
    return results.map((row) => TransactionItem.fromMap(row)).toList();
  }

  Future<TransactionItem?> getTransactionById(String id) async {
    final db = await _db;
    final query = '''
      SELECT 
        t.*,
        c.name AS category_name,
        c.code AS category_code,
        c.icon AS category_icon,
        c.color AS category_color,
        w.name AS wallet_name
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      LEFT JOIN wallets w ON t.wallet_id = w.id
      WHERE t.id = ?
    ''';
    final results = await db.rawQuery(query, [id]);
    if (results.isEmpty) return null;
    return TransactionItem.fromMap(results.first);
  }

  Future<void> insertTransaction(TransactionItem item) async {
    _validateTransaction(item);
    final db = await _db;
    await db.insert('transactions', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTransaction(TransactionItem item) async {
    _validateTransaction(item);
    final db = await _db;
    await db.update(
      'transactions',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await _db;
    final item = await getTransactionById(id);
    if (item == null) return;

    await db.transaction((txn) async {
      // If it's a transfer, also delete its paired transaction
      if (item.transferPairId != null) {
        await txn.delete('transactions', where: 'id = ?', whereArgs: [item.transferPairId]);
      }
      await txn.delete('transactions', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Batch insert transactions (e.g. from receipt review saving per item)
  Future<void> insertTransactionsBatch(List<TransactionItem> items) async {
    final db = await _db;
    await db.transaction((txn) async {
      for (final item in items) {
        _validateTransaction(item);
        await txn.insert('transactions', item.toMap());
      }
    });
  }

  /// Summary for given date range (excludes transfers!)
  Future<TransactionSummary> getSummary({DateTime? startDate, DateTime? endDate}) async {
    final db = await _db;
    final conditions = <String>['type IN (\'income\', \'expense\')'];
    final args = <dynamic>[];

    if (startDate != null) {
      conditions.add('date >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add('date <= ?');
      args.add(endDate.toIso8601String());
    }

    final whereClause = 'WHERE ${conditions.join(' AND ')}';
    final query = '''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS total_income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS total_expense
      FROM transactions
      $whereClause
    ''';

    final result = await db.rawQuery(query, args);
    if (result.isEmpty) {
      return const TransactionSummary(totalIncome: 0, totalExpense: 0);
    }

    return TransactionSummary(
      totalIncome: result.first['total_income'] as int? ?? 0,
      totalExpense: result.first['total_expense'] as int? ?? 0,
    );
  }

  void _validateTransaction(TransactionItem item) {
    if (item.amount <= 0) {
      throw Exception('Nominal harus lebih dari Rp 0.');
    }
    if (item.amount > AppConstants.maxAmount) {
      throw Exception('Nominal melebihi batas maksimum.');
    }
  }
}
