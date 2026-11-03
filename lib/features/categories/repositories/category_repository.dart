import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../models/category.dart';

class CategoryRepository {
  final Database? _overrideDb;
  CategoryRepository([this._overrideDb]);

  Future<Database> get _db async => _overrideDb ?? await AppDatabase.getInstance();

  Future<List<Category>> getCategories({String? type, bool onlyActive = false}) async {
    final db = await _db;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (type != null) {
      conditions.add('type = ?');
      args.add(type);
    }
    if (onlyActive) {
      conditions.add('is_active = 1');
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final results = await db.rawQuery('''
      SELECT * FROM categories
      $whereClause
      ORDER BY sort_order ASC, is_built_in DESC, name ASC
    ''', args);

    return results.map((e) => Category.fromMap(e)).toList();
  }

  Future<Category?> getCategoryById(String id) async {
    final db = await _db;
    final results = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return Category.fromMap(results.first);
  }

  Future<Category?> getCategoryByCode(String code) async {
    final db = await _db;
    final results = await db.query('categories', where: 'code = ?', whereArgs: [code]);
    if (results.isEmpty) return null;
    return Category.fromMap(results.first);
  }

  Future<void> insertCustomCategory(Category category) async {
    final db = await _db;
    final code = category.code.isNotEmpty
        ? category.code
        : 'CUS_${DateTime.now().millisecondsSinceEpoch}';
    final id = category.id.isNotEmpty ? category.id : const Uuid().v4();

    final toInsert = category.copyWith(
      id: id,
      code: code,
      isBuiltIn: false,
    );

    await db.insert('categories', toInsert.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateCategory(Category category) async {
    final db = await _db;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> toggleCategoryActive(String id, bool isActive) async {
    final db = await _db;
    await db.update(
      'categories',
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete custom category (§10 Rule 6)
  /// Reassigns affected transactions to EXP_LAIN or INC_LAIN
  Future<int> deleteCustomCategory(String id) async {
    final db = await _db;
    final cat = await getCategoryById(id);
    if (cat == null) return 0;
    if (cat.isBuiltIn) {
      throw Exception('Kategori bawaan tidak dapat dihapus, hanya bisa dinonaktifkan.');
    }

    // Find fallback category id
    final fallbackCode = cat.type == 'income' ? 'INC_LAIN' : 'EXP_LAIN';
    final fallbackCat = await getCategoryByCode(fallbackCode);
    final fallbackId = fallbackCat?.id ?? 'cat_exp_lain';

    int affectedCount = 0;
    await db.transaction((txn) async {
      final affected = await txn.rawQuery(
        'SELECT COUNT(*) as count FROM transactions WHERE category_id = ?',
        [id],
      );
      affectedCount = Sqflite.firstIntValue(affected) ?? 0;

      // Reassign transactions
      if (affectedCount > 0) {
        await txn.update(
          'transactions',
          {'category_id': fallbackId},
          where: 'category_id = ?',
          whereArgs: [id],
        );
      }

      // Delete from categories
      await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
    });

    return affectedCount;
  }
}
