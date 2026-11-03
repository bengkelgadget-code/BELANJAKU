import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../models/receipt.dart';
import '../models/receipt_item.dart';

class ReceiptRepository {
  final Database? _overrideDb;
  ReceiptRepository([this._overrideDb]);

  Future<Database> get _db async => _overrideDb ?? await AppDatabase.getInstance();

  Future<void> insertReceiptWithItems({
    required Receipt receipt,
    required List<ReceiptItemModel> items,
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert('receipts', receipt.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      for (final item in items) {
        await txn.insert('receipt_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<Receipt?> getReceiptById(String id) async {
    final db = await _db;
    final results = await db.query('receipts', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return Receipt.fromMap(results.first);
  }

  Future<List<ReceiptItemModel>> getReceiptItems(String receiptId) async {
    final db = await _db;
    final query = '''
      SELECT 
        ri.*,
        c.name AS category_name,
        c.icon AS category_icon,
        c.color AS category_color
      FROM receipt_items ri
      LEFT JOIN categories c ON ri.category_id = c.id
      WHERE ri.receipt_id = ?
    ''';
    final results = await db.rawQuery(query, [receiptId]);
    return results.map((r) => ReceiptItemModel.fromMap(r)).toList();
  }

  /// Delete receipt (§9.1 & §10):
  /// Either delete transactions linked to receipt, or retain transactions and unlink receiptId.
  Future<void> deleteReceipt(String receiptId, {bool deleteTransactions = false}) async {
    final db = await _db;
    await db.transaction((txn) async {
      if (deleteTransactions) {
        await txn.delete('transactions', where: 'receipt_id = ?', whereArgs: [receiptId]);
      } else {
        await txn.update(
          'transactions',
          {'receipt_id': null, 'note': 'Foto struk telah dihapus'},
          where: 'receipt_id = ?',
          whereArgs: [receiptId],
        );
      }
      await txn.delete('receipt_items', where: 'receipt_id = ?', whereArgs: [receiptId]);
      await txn.delete('receipts', where: 'id = ?', whereArgs: [receiptId]);
    });
  }

  /// Check potential duplicate within recent time (§7.4)
  Future<bool> checkPossibleDuplicate({
    required String merchant,
    required int total,
    DateTime? date,
  }) async {
    final db = await _db;
    // Check if receipt with same merchant and calculated_total or detected_total exists in last 24h
    final query = '''
      SELECT COUNT(*) as count 
      FROM receipts 
      WHERE (merchant = ? AND (calculated_total = ? OR detected_total = ?))
         OR (detected_total = ? AND calculated_total = ?)
    ''';
    final results = await db.rawQuery(query, [merchant, total, total, total, total]);
    final count = Sqflite.firstIntValue(results) ?? 0;
    return count > 0;
  }

  /// Record user category correction for machine learning (§7.5 Rule 1)
  Future<void> recordUserCorrection(String itemName, String categoryId) async {
    final db = await _db;
    final keyword = itemName.trim().toLowerCase();
    if (keyword.isEmpty) return;

    final now = DateTime.now().toIso8601String();
    await db.rawInsert('''
      INSERT INTO user_category_learning (id, item_keyword, category_id, updated_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(item_keyword) DO UPDATE SET
        category_id = excluded.category_id,
        updated_at = excluded.updated_at
    ''', [const Uuid().v4(), keyword, categoryId, now]);
  }

  /// Retrieve learned category if user previously corrected this item
  Future<String?> getLearnedCategoryId(String itemName) async {
    final db = await _db;
    final keyword = itemName.trim().toLowerCase();
    final results = await db.query(
      'user_category_learning',
      where: 'item_keyword = ?',
      whereArgs: [keyword],
    );
    if (results.isNotEmpty) {
      return results.first['category_id'] as String?;
    }
    return null;
  }
}
