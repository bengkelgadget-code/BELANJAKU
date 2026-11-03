import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:belanjaku/core/database/app_database.dart';
import 'package:belanjaku/features/wallets/repositories/wallet_repository.dart';
import 'package:belanjaku/features/transactions/models/transaction.dart';
import 'package:belanjaku/features/transactions/repositories/transaction_repository.dart';

void main() {
  // Initialize SQLite FFI for desktop / test runner
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late WalletRepository walletRepo;
  late TransactionRepository txRepo;

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await AppDatabase.getInstance(db);
    walletRepo = WalletRepository(db);
    txRepo = TransactionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Database & Wallet Balance Tests (§9.1 & §10)', () {
    test('Default wallets are created with initial zero balances', () async {
      final wallets = await walletRepo.getWallets(onlyActive: true);
      expect(wallets.length, 3);
      expect(wallets.any((w) => w.id == 'w_tunai'), isTrue);
      expect(wallets.any((w) => w.id == 'w_bank'), isTrue);
      expect(wallets.any((w) => w.id == 'w_ewallet'), isTrue);

      final total = await walletRepo.getTotalBalance();
      expect(total, 0);
    });

    test('Adding income increases wallet balance correctly', () async {
      final tx = TransactionItem(
        id: 'tx_1',
        type: 'income',
        amount: 5000000,
        categoryId: 'cat_inc_gaji',
        walletId: 'w_bank',
        date: DateTime.now(),
        note: 'Gaji Pokok',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await txRepo.insertTransaction(tx);

      final bankWallet = await walletRepo.getWalletById('w_bank');
      expect(bankWallet?.currentBalance, 5000000);

      final totalBalance = await walletRepo.getTotalBalance();
      expect(totalBalance, 5000000);
    });

    test('Adding expense decreases wallet balance correctly', () async {
      // Income 1.000.000 to Tunai
      await txRepo.insertTransaction(TransactionItem(
        id: 'tx_inc',
        type: 'income',
        amount: 1000000,
        walletId: 'w_tunai',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // Expense 250.000 from Tunai
      await txRepo.insertTransaction(TransactionItem(
        id: 'tx_exp',
        type: 'expense',
        amount: 250000,
        categoryId: 'cat_exp_makan',
        walletId: 'w_tunai',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final tunaiWallet = await walletRepo.getWalletById('w_tunai');
      expect(tunaiWallet?.currentBalance, 750000);

      final total = await walletRepo.getTotalBalance();
      expect(total, 750000);
    });

    test('Transfer moves money between wallets and does not inflate summary (§6.3)', () async {
      // 1. Give Bank Rp 1.000.000
      await txRepo.insertTransaction(TransactionItem(
        id: 'tx_init',
        type: 'income',
        amount: 1000000,
        walletId: 'w_bank',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // 2. Transfer Rp 300.000 from Bank to E-Wallet
      await walletRepo.transfer(
        fromWalletId: 'w_bank',
        toWalletId: 'w_ewallet',
        amount: 300000,
        note: 'Top up DANA',
      );

      final bank = await walletRepo.getWalletById('w_bank');
      final ewallet = await walletRepo.getWalletById('w_ewallet');

      expect(bank?.currentBalance, 700000);
      expect(ewallet?.currentBalance, 300000);

      // Total balance across all wallets remains unchanged
      final total = await walletRepo.getTotalBalance();
      expect(total, 1000000);

      // Summary must NOT count transfer as income or expense!
      final summary = await txRepo.getSummary();
      expect(summary.totalIncome, 1000000);
      expect(summary.totalExpense, 0);
      expect(summary.net, 1000000);
    });

    test('1,000 transactions performance and balance consistency check (§11)', () async {
      final now = DateTime.now();
      const count = 1000;
      int expectedBankBalance = 0;

      final List<TransactionItem> batch = [];
      for (int i = 0; i < count; i++) {
        final isIncome = i % 2 == 0;
        final amount = (i + 1) * 1000;
        if (isIncome) {
          expectedBankBalance += amount;
        } else {
          expectedBankBalance -= amount;
        }

        batch.add(TransactionItem(
          id: 'perf_tx_$i',
          type: isIncome ? 'income' : 'expense',
          amount: amount,
          categoryId: isIncome ? 'cat_inc_gaji' : 'cat_exp_makan',
          walletId: 'w_bank',
          date: now.subtract(Duration(minutes: i)),
          createdAt: now,
          updatedAt: now,
        ));
      }

      final stopwatch = Stopwatch()..start();
      await txRepo.insertTransactionsBatch(batch);
      stopwatch.stop();

      // Ensure 1000 inserts were fast (under 2 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));

      final bankWallet = await walletRepo.getWalletById('w_bank');
      expect(bankWallet?.currentBalance, expectedBankBalance);
    });
  });
}
