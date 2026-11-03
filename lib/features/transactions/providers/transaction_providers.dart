import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

class TransactionFilterNotifier extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => const TransactionFilter();

  void setFilter(TransactionFilter filter) => state = filter;
  void clear() => state = const TransactionFilter();
}

final transactionFilterProvider = NotifierProvider<TransactionFilterNotifier, TransactionFilter>(
  TransactionFilterNotifier.new,
);

final transactionListProvider = FutureProvider.autoDispose<List<TransactionItem>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final filter = ref.watch(transactionFilterProvider);
  return await repo.getTransactions(filter: filter);
});

final recentTransactionsProvider = FutureProvider.autoDispose<List<TransactionItem>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return await repo.getTransactions(limit: 5);
});

final monthSummaryProvider = FutureProvider.autoDispose<TransactionSummary>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  return await repo.getSummary(startDate: startOfMonth, endDate: endOfMonth);
});
