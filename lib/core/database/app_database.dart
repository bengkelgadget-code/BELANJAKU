import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/default_categories.dart';
import '../constants/default_wallets.dart';

class AppDatabase {
  static const String dbName = 'belanjaku.db';
  static const int dbVersion = 1;

  static Database? _database;

  static Future<Database> getInstance([Database? overrideDb]) async {
    if (overrideDb != null) {
      _database = overrideDb;
      await createTables(overrideDb);
      return overrideDb;
    }
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  static Future<void> createTables(Database db) async {
    await _onCreate(db, dbVersion);
  }

  static Future<Database> _initDatabase() async {
    String dbPath;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      dbPath = p.join(docDir.path, dbName);
    } catch (_) {
      // Fallback for tests or platforms without path_provider
      final basePath = await getDatabasesPath();
      dbPath = p.join(basePath, dbName);
    }

    return await openDatabase(
      dbPath,
      version: dbVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // 1. Wallets table
    batch.execute('''
      CREATE TABLE wallets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        initial_balance INTEGER NOT NULL DEFAULT 0,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 2. Categories table
    batch.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        is_built_in INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        keywords TEXT NOT NULL DEFAULT '[]'
      )
    ''');

    // 3. Transactions table
    batch.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL, -- 'income', 'expense', 'transfer_out', 'transfer_in'
        amount INTEGER NOT NULL,
        category_id TEXT,
        wallet_id TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        merchant TEXT,
        receipt_id TEXT,
        transfer_pair_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 4. Receipts table
    batch.execute('''
      CREATE TABLE receipts (
        id TEXT PRIMARY KEY,
        image_path TEXT NOT NULL,
        merchant TEXT,
        receipt_date TEXT,
        detected_total INTEGER,
        calculated_total INTEGER NOT NULL,
        raw_ocr_text TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 5. Receipt Items table
    batch.execute('''
      CREATE TABLE receipt_items (
        id TEXT PRIMARY KEY,
        receipt_id TEXT NOT NULL,
        name TEXT NOT NULL,
        qty INTEGER NOT NULL DEFAULT 1,
        unit_price INTEGER NOT NULL DEFAULT 0,
        subtotal INTEGER NOT NULL DEFAULT 0,
        category_id TEXT NOT NULL,
        confidence TEXT NOT NULL DEFAULT 'medium'
      )
    ''');

    // 6. Budgets table
    batch.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        year_month TEXT NOT NULL, -- 'YYYY-MM'
        amount INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(category_id, year_month)
      )
    ''');

    // 7. App Settings table
    batch.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // 8. User Learning table (OCR keyword to category learning)
    batch.execute('''
      CREATE TABLE user_category_learning (
        id TEXT PRIMARY KEY,
        item_keyword TEXT UNIQUE NOT NULL,
        category_id TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Indexes
    batch.execute('CREATE INDEX idx_transactions_date ON transactions(date DESC)');
    batch.execute('CREATE INDEX idx_transactions_wallet ON transactions(wallet_id)');
    batch.execute('CREATE INDEX idx_transactions_category ON transactions(category_id)');
    batch.execute('CREATE INDEX idx_receipt_items_receipt ON receipt_items(receipt_id)');
    batch.execute('CREATE INDEX idx_budgets_lookup ON budgets(category_id, year_month)');

    // Insert Default Wallets
    for (final wallet in DefaultWallets.wallets) {
      batch.insert('wallets', wallet.toMap());
    }

    // Insert Default Categories
    for (final category in DefaultCategories.allCategories) {
      batch.insert('categories', category.toMap());
    }

    // Insert Default App Settings
    batch.insert('app_settings', {'key': 'user_name', 'value': 'boy'});
    batch.insert('app_settings', {'key': 'theme_mode', 'value': 'system'});
    batch.insert('app_settings', {'key': 'biometric_enabled', 'value': '0'});
    batch.insert('app_settings', {'key': 'default_wallet_id', 'value': 'w_tunai'});

    await batch.commit(noResult: true);
  }

  /// Close database (useful for testing & resets)
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
