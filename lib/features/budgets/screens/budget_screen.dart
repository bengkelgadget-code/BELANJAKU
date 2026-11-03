import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/icon_helper.dart';
import '../models/budget.dart';
import '../providers/budget_providers.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  Future<void> _editBudgetDialog(BuildContext context, WidgetRef ref, BudgetItem budget) async {
    final controller = TextEditingController(
      text: budget.amount > 0 ? budget.amount.toString() : '',
    );

    final updated = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Atur Anggaran ${budget.categoryName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan batas anggaran bulanan untuk kategori ini (isi 0 jika tidak dibatasi):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                prefixText: 'Rp ',
                hintText: '0',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = CurrencyFormatter.parse(controller.text) ?? 0;
              Navigator.pop(ctx, val);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (updated != null) {
      HapticFeedback.lightImpact();
      final repo = ref.read(budgetRepositoryProvider);
      final currentMonth = ref.read(currentBudgetMonthProvider);
      await repo.setBudget(
        categoryId: budget.categoryId,
        yearMonth: currentMonth,
        amount: updated,
      );
      ref.invalidate(monthlyBudgetsProvider);
      ref.invalidate(budgetAlertCountProvider);
    }
  }

  Future<void> _copyFromPrevMonth(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(budgetRepositoryProvider);
    final currentMonth = ref.read(currentBudgetMonthProvider);
    final count = await repo.copyBudgetsFromPreviousMonth(currentMonth);

    ref.invalidate(monthlyBudgetsProvider);
    ref.invalidate(budgetAlertCountProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count anggaran berhasil disalin dari bulan lalu')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentMonth = ref.watch(currentBudgetMonthProvider);
    final budgetsAsync = ref.watch(monthlyBudgetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anggaran Bulanan'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.copy),
            tooltip: 'Salin dari bulan lalu',
            onPressed: () => _copyFromPrevMonth(context, ref),
          ),
        ],
      ),
      body: budgetsAsync.when(
        data: (budgets) {
          int totalBudget = 0;
          int totalSpent = 0;
          for (final b in budgets) {
            totalBudget += b.amount;
            totalSpent += b.spent;
          }

          final overallProgress = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Month Indicator Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Periode $currentMonth',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: overallProgress >= 1.0
                                  ? AppColors.danger.withValues(alpha: 0.15)
                                  : (overallProgress >= 0.8
                                      ? AppColors.warning.withValues(alpha: 0.15)
                                      : AppColors.primaryLight.withValues(alpha: 0.15)),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${(overallProgress * 100).toStringAsFixed(0)}% Terpakai',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: overallProgress >= 1.0
                                    ? AppColors.danger
                                    : (overallProgress >= 0.8 ? AppColors.warning : AppColors.primaryLight),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Anggaran', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(
                                CurrencyFormatter.format(totalBudget),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Total Terpakai', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(
                                CurrencyFormatter.format(totalSpent),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.expenseLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: overallProgress,
                          minHeight: 8,
                          backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            overallProgress >= 1.0
                                ? AppColors.danger
                                : (overallProgress >= 0.8 ? AppColors.warning : AppColors.primaryLight),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Anggaran per Kategori',
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              ...budgets.map((b) {
                Color statusColor = AppColors.primaryLight;
                String statusLabel = 'Aman';
                if (b.isExceeded) {
                  statusColor = AppColors.danger;
                  statusLabel = 'Habis';
                } else if (b.isWarning) {
                  statusColor = AppColors.warning;
                  statusLabel = 'Waspada (≥80%)';
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _editBudgetDialog(context, ref, b),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.getCategoryPastel(b.categoryCode ?? '', isDark: isDark),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  IconHelper.getIcon(b.categoryIcon),
                                  size: 18,
                                  color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b.categoryName ?? '',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      b.amount > 0
                                          ? 'Sisa ${CurrencyFormatter.format(b.remaining)} • $statusLabel'
                                          : 'Belum ada batas anggaran',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: b.amount > 0 ? statusColor : Colors.grey,
                                        fontWeight: b.amount > 0 ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(b.spent),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.expenseLight,
                                    ),
                                  ),
                                  Text(
                                    b.amount > 0 ? '/ ${CurrencyFormatter.format(b.amount)}' : 'Tanpa batas',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              const Icon(LucideIcons.pencil, size: 14, color: Colors.grey),
                            ],
                          ),
                          if (b.amount > 0) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: b.percentage.clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
      ),
    );
  }
}
