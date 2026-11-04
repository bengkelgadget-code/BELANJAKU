import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:belanjaku/core/database/app_database.dart';
import 'package:belanjaku/core/utils/date_formatter.dart';
import 'package:belanjaku/features/transactions/models/transaction.dart';
import 'package:belanjaku/features/transactions/repositories/transaction_repository.dart';
import 'package:belanjaku/features/wallets/repositories/wallet_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late WalletRepository walletRepo;
  late TransactionRepository txRepo;

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await AppDatabase.getInstance(db);
    walletRepo = WalletRepository(db);
    txRepo = TransactionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DateFormatter Safety Tests', () {
    test('DateFormatter formatting does not throw on current or past dates', () {
      final now = DateTime.now();
      expect(() => DateFormatter.formatShort(now), returnsNormally);
      expect(DateFormatter.formatShort(now), isNotEmpty);
      expect(() => DateFormatter.formatGroupHeader(now), returnsNormally);
      expect(DateFormatter.formatGroupHeader(now), 'Hari ini');
      expect(() => DateFormatter.formatMonthYear(now), returnsNormally);
      expect(DateFormatter.formatMonthYear(now), isNotEmpty);
      expect(() => DateFormatter.formatTime(now), returnsNormally);
      expect(DateFormatter.formatTime(now), isNotEmpty);
    });
  });

  group('Home Data Flow & Gaji Rp3.000.000 Verification', () {
    test('Initial balance is 0 and recent transactions is empty', () async {
      final total = await walletRepo.getTotalBalance();
      expect(total, 0);

      final recent = await txRepo.getTransactions(limit: 5);
      expect(recent, isEmpty);
    });

    test('Adding Gaji Rp3.000.000 reflects in balance, recent list, and summary', () async {
      final now = DateTime.now();
      final tx = TransactionItem(
        id: 'tx_gaji_test_flow',
        type: 'income',
        amount: 3000000,
        categoryId: 'cat_inc_gaji',
        walletId: 'w_tunai',
        date: now,
        note: 'Gaji Bulanan',
        createdAt: now,
        updatedAt: now,
      );

      await txRepo.insertTransaction(tx);

      // 1. Total balance must include 3.000.000
      final total = await walletRepo.getTotalBalance();
      expect(total, 3000000);

      // 2. Wallets strip must show Tunai: 3.000.000
      final wallets = await walletRepo.getWallets(onlyActive: true);
      final tunai = wallets.firstWhere((w) => w.id == 'w_tunai');
      expect(tunai.currentBalance, 3000000);

      // 3. Recent transactions must contain Gaji at top
      final recent = await txRepo.getTransactions(limit: 5);
      expect(recent.length, 1);
      expect(recent.first.id, 'tx_gaji_test_flow');
      expect(recent.first.amount, 3000000);
      expect(recent.first.categoryName, 'Gaji');

      // 4. Summary must show totalIncome 3.000.000
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final summary = await txRepo.getSummary(startDate: startOfMonth, endDate: endOfMonth);
      expect(summary.totalIncome, 3000000);
      expect(summary.totalExpense, 0);
      expect(summary.net, 3000000);

      // 5. Delete transaction (simulates user deleting from transaction screen)
      await txRepo.deleteTransaction(tx.id);

      // 6. Balance and recent list corrected back to 0
      final totalAfterDelete = await walletRepo.getTotalBalance();
      expect(totalAfterDelete, 0);

      final recentAfterDelete = await txRepo.getTransactions(limit: 5);
      expect(recentAfterDelete, isEmpty);
    });
  });
}
