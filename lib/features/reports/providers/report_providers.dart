import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/report_data.dart';
import '../repositories/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository();
});

class ReportPeriodIndexNotifier extends Notifier<int> {
  @override
  int build() => 1; // 0: Week, 1: Month, 2: Year

  void setPeriod(int index) => state = index;
}

final reportPeriodIndexProvider = NotifierProvider<ReportPeriodIndexNotifier, int>(
  ReportPeriodIndexNotifier.new,
);

final reportCategorySharesProvider = FutureProvider.autoDispose<List<CategoryExpenseShare>>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  final period = ref.watch(reportPeriodIndexProvider);
  final now = DateTime.now();

  DateTime start;
  DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

  if (period == 0) {
    // 7 days
    start = now.subtract(const Duration(days: 6));
  } else if (period == 1) {
    // Month
    start = DateTime(now.year, now.month, 1);
  } else {
    // Year
    start = DateTime(now.year, 1, 1);
  }

  return await repo.getCategoryShares(startDate: start, endDate: end);
});

final reportDailyTrendProvider = FutureProvider.autoDispose<List<TrendBarItem>>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  return await repo.getDailyTrend(endDate: DateTime.now(), days: 7);
});

final reportMonthComparisonProvider = FutureProvider.autoDispose<List<CategoryComparisonItem>>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  final currentYearMonth = DateFormatter.toYearMonth(DateTime.now());
  return await repo.getMonthComparison(currentYearMonth);
});
