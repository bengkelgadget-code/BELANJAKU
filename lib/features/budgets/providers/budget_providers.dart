import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/budget.dart';
import '../repositories/budget_repository.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});

class CurrentBudgetMonthNotifier extends Notifier<String> {
  @override
  String build() => DateFormatter.toYearMonth(DateTime.now());

  void setMonth(String yearMonth) => state = yearMonth;
}

final currentBudgetMonthProvider = NotifierProvider<CurrentBudgetMonthNotifier, String>(
  CurrentBudgetMonthNotifier.new,
);

final monthlyBudgetsProvider = FutureProvider.autoDispose<List<BudgetItem>>((ref) async {
  final repo = ref.watch(budgetRepositoryProvider);
  final yearMonth = ref.watch(currentBudgetMonthProvider);
  return await repo.getBudgetsForMonth(yearMonth);
});

final budgetAlertCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(budgetRepositoryProvider);
  final yearMonth = ref.watch(currentBudgetMonthProvider);
  return await repo.getAlertBudgetCount(yearMonth);
});
