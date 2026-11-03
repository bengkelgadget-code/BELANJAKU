import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../models/wallet.dart';

class WalletRepository {
  final Database? _overrideDb;
  WalletRepository([this._overrideDb]);

  Future<Database> get _db async => _overrideDb ?? await AppDatabase.getInstance();

  /// Retrieve wallets with real-time computed balances
  Future<List<Wallet>> getWallets({bool onlyActive = false}) async {
    final db = await _db;
    final whereClause = onlyActive ? 'WHERE w.is_active = 1' : '';

    final query = '''
      SELECT 
        w.*,
        (
          w.initial_balance 
          + COALESCE((SELECT SUM(amount) FROM transactions WHERE wallet_id = w.id AND type = 'income'), 0)
          - COALESCE((SELECT SUM(amount) FROM transactions WHERE wallet_id = w.id AND type = 'expense'), 0)
          + COALESCE((SELECT SUM(amount) FROM transactions WHERE wallet_id = w.id AND type = 'transfer_in'), 0)
          - COALESCE((SELECT SUM(amount) FROM transactions WHERE wallet_id = w.id AND type = 'transfer_out'), 0)
        ) AS current_balance
      FROM wallets w
      $whereClause
      ORDER BY w.is_active DESC, w.created_at ASC
    ''';

    final result = await db.rawQuery(query);
    return result.map((row) {
      final balance = row['current_balance'] as int? ?? 0;
      return Wallet.fromMap(row, currentBalance: balance);
    }).toList();
  }

  /// Get total combined balance across all active wallets
  Future<int> getTotalBalance() async {
    final wallets = await getWallets(onlyActive: true);
    return wallets.fold<int>(0, (sum, w) => sum + w.currentBalance);
  }

  Future<Wallet?> getWalletById(String id) async {
    final db = await _db;
    final query = '''
      SELECT 
        w.*,
        (
          w.initial_balance 
          + COALESCE((SELECT SUM(amount) FROM transactions WHERE wallet_id = w.id AND type = 'income'), 0)
          - COALESCE((SELECT SUM(amount) FROM transactions WHERE wallet_id = w.id AND type = 'expense'), 0)
          + COALESCE((SELECT SUM(amount) FROM transactions WHERE wallet_id = w.id AND type = 'transfer_in'), 0)
          - COALESCE((SELECT SUM(amount) FROM transactions WHERE wallet_id = w.id AND type = 'transfer_out'), 0)
        ) AS current_balance
      FROM wallets w
      WHERE w.id = ?
    ''';
    final result = await db.rawQuery(query, [id]);
    if (result.isEmpty) return null;
    final row = result.first;
    return Wallet.fromMap(row, currentBalance: row['current_balance'] as int? ?? 0);
  }

  Future<void> insertWallet(Wallet wallet) async {
    final db = await _db;
    await db.insert('wallets', wallet.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateWallet(Wallet wallet) async {
    final db = await _db;
    await db.update(
      'wallets',
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
  }

  /// Check transaction count before deletion (§10 Rule 5)
  Future<int> getTransactionCountForWallet(String walletId) async {
    final db = await _db;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM transactions WHERE wallet_id = ?',
      [walletId],
    ));
    return count ?? 0;
  }

  Future<void> deleteWallet(String walletId) async {
    final count = await getTransactionCountForWallet(walletId);
    if (count > 0) {
      throw Exception(
        'Dompet ini masih punya $count transaksi. Pindahkan atau hapus transaksinya dulu sebelum menghapus dompet.',
      );
    }
    final db = await _db;
    await db.delete('wallets', where: 'id = ?', whereArgs: [walletId]);
  }

  Future<void> toggleWalletActive(String walletId, bool isActive) async {
    final db = await _db;
    await db.update(
      'wallets',
      {'is_active': isActive ? 1 : 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [walletId],
    );
  }

  /// Transfer between wallets (PRD §6.3):
  /// Creates 2 paired transactions (transfer_out & transfer_in)
  Future<void> transfer({
    required String fromWalletId,
    required String toWalletId,
    required int amount,
    String? note,
    DateTime? date,
  }) async {
    if (fromWalletId == toWalletId) {
      throw Exception('Dompet asal dan tujuan tidak boleh sama.');
    }
    if (amount <= 0) {
      throw Exception('Nominal transfer harus lebih dari 0.');
    }

    final db = await _db;
    final now = DateTime.now();
    final txDate = (date ?? now).toIso8601String();
    final outId = const Uuid().v4();
    final inId = const Uuid().v4();

    await db.transaction((txn) async {
      // Outgoing transaction
      await txn.insert('transactions', {
        'id': outId,
        'type': 'transfer_out',
        'amount': amount,
        'category_id': null,
        'wallet_id': fromWalletId,
        'date': txDate,
        'note': note ?? 'Transfer keluar',
        'merchant': null,
        'receipt_id': null,
        'transfer_pair_id': inId,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      // Incoming transaction
      await txn.insert('transactions', {
        'id': inId,
        'type': 'transfer_in',
        'amount': amount,
        'category_id': null,
        'wallet_id': toWalletId,
        'date': txDate,
        'note': note ?? 'Transfer masuk',
        'merchant': null,
        'receipt_id': null,
        'transfer_pair_id': outId,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
    });
  }
}
