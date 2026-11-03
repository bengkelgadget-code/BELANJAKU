import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/icon_helper.dart';
import '../../budgets/providers/budget_providers.dart';
import '../../reports/providers/report_providers.dart';
import '../../settings/screens/settings_screen.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../wallets/providers/wallet_providers.dart';
import '../../wallets/widgets/transfer_dialog.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting(String userName) {
    final hour = DateTime.now().hour;
    String timeGreeting = 'Selamat malam';
    if (hour >= 5 && hour < 11) {
      timeGreeting = 'Selamat pagi';
    } else if (hour >= 11 && hour < 15) {
      timeGreeting = 'Selamat siang';
    } else if (hour >= 15 && hour < 18) {
      timeGreeting = 'Selamat sore';
    }
    return '$timeGreeting, $userName';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userName = ref.watch(userNameProvider);
    final totalBalanceAsync = ref.watch(totalBalanceProvider);
    final walletsAsync = ref.watch(walletsProvider);
    final summaryAsync = ref.watch(monthSummaryProvider);
    final recentAsync = ref.watch(recentTransactionsProvider);
    final sharesAsync = ref.watch(reportCategorySharesProvider);
    final alertBudgetCountAsync = ref.watch(budgetAlertCountProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(totalBalanceProvider);
            ref.invalidate(walletsProvider);
            ref.invalidate(monthSummaryProvider);
            ref.invalidate(recentTransactionsProvider);
            ref.invalidate(reportCategorySharesProvider);
            ref.invalidate(budgetAlertCountProvider);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // 1. Top Header: Sapaan, Bell Budget Alert, Avatar (§8.3)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/settings'),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'B',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(userName),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormatter.formatShort(DateTime.now()),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Budget Alert Bell
                      alertBudgetCountAsync.when(
                        data: (count) {
                          return Stack(
                            alignment: Alignment.topRight,
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.bell),
                                onPressed: () {
                                  // Switch to budget screen
                                  context.push('/budgets');
                                },
                              ),
                              if (count > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.warning,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.settings),
                        onPressed: () => context.push('/settings'),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. Total Balance Card: Soft Gradient Emerald -> Teal (§8.3 & §8.6)
              Container(
                decoration: BoxDecoration(
                  gradient: isDark ? AppColors.balanceGradientDark : AppColors.balanceGradientLight,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryLight.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Saldo',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    totalBalanceAsync.when(
                      data: (balance) => Text(
                        CurrencyFormatter.format(balance),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      loading: () => const Text(
                        'Rp ...',
                        style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      error: (_, _) => const Text('Rp 0', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 18),
                    // 3 Chips: Masuk bulan ini (hijau), Keluar bulan ini (oranye/merah), Sisa (netral)
                    summaryAsync.when(
                      data: (summary) {
                        return Row(
                          children: [
                            _buildBalanceSummaryChip(
                              label: 'Masuk',
                              amount: summary.totalIncome,
                              textColor: Colors.greenAccent,
                              icon: LucideIcons.arrowDownLeft,
                            ),
                            const SizedBox(width: 8),
                            _buildBalanceSummaryChip(
                              label: 'Keluar',
                              amount: summary.totalExpense,
                              textColor: const Color(0xFFFFB4AB),
                              icon: LucideIcons.arrowUpRight,
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Wallets Horizontal Strip (§8.3)
              walletsAsync.when(
                data: (wallets) {
                  return SizedBox(
                    height: 76,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: wallets.length,
                      itemBuilder: (context, idx) {
                        final w = wallets[idx];
                        return Container(
                          width: 150,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Color(int.parse(w.color)).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  IconHelper.getIcon(w.icon),
                                  size: 16,
                                  color: Color(int.parse(w.color)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      w.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.formatCompact(w.currentBalance),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const SizedBox(height: 76),
                error: (_, _) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),

              // 4. Quick Action Buttons: 4 Circular Buttons (§8.3)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickActionButton(
                    context: context,
                    icon: LucideIcons.plus,
                    label: 'Tambah',
                    color: AppColors.primaryLight,
                    onTap: () => context.push('/add-transaction'),
                  ),
                  _buildQuickActionButton(
                    context: context,
                    icon: LucideIcons.camera,
                    label: 'Scan Struk',
                    color: AppColors.primaryTeal,
                    onTap: () => context.push('/scan'),
                  ),
                  _buildQuickActionButton(
                    context: context,
                    icon: LucideIcons.arrowLeftRight,
                    label: 'Transfer',
                    color: AppColors.info,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => const TransferDialog(),
                      );
                    },
                  ),
                  _buildQuickActionButton(
                    context: context,
                    icon: LucideIcons.pieChart,
                    label: 'Laporan',
                    color: const Color(0xFF8B5CF6),
                    onTap: () => context.push('/reports'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 5. Section "Bulan Ini" - Top 3 Categories (§8.3)
              sharesAsync.when(
                data: (shares) {
                  if (shares.isEmpty) return const SizedBox.shrink();

                  final top3 = shares.take(3).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pengeluaran Terbesar Bulan Ini',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/reports'),
                            child: const Text('Lihat semua'),
                          ),
                        ],
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: top3.map((s) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppColors.getCategoryPastel(s.categoryCode, isDark: isDark),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(IconHelper.getIcon(s.categoryIcon), size: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        s.categoryName,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Text(
                                      '${(s.percentage * 100).toStringAsFixed(0)}% • ${CurrencyFormatter.format(s.totalAmount)}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

              // 6. Section "Terakhir" - 5 Recent Transactions (§8.3)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaksi Terakhir',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/transactions'),
                    child: const Text('Semua'),
                  ),
                ],
              ),

              recentAsync.when(
                data: (recent) {
                  if (recent.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                        child: Column(
                          children: [
                            const Icon(LucideIcons.wallet, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada transaksi bulan ini',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Yuk catat atau foto struk belanja pertamamu!',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(LucideIcons.plus, size: 18),
                              label: const Text('Tambah Transaksi'),
                              onPressed: () => context.push('/add-transaction'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recent.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final item = recent[idx];
                        return ListTile(
                          onTap: () => context.push('/transactions'),
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.getCategoryPastel(item.categoryCode ?? '', isDark: isDark),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.isTransfer ? LucideIcons.arrowLeftRight : IconHelper.getIcon(item.categoryIcon),
                              size: 18,
                              color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                            ),
                          ),
                          title: Text(
                            item.isTransfer
                                ? (item.type == 'transfer_out' ? 'Transfer Keluar' : 'Transfer Masuk')
                                : (item.categoryName ?? 'Lainnya'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            [
                              if (item.merchant != null && item.merchant!.isNotEmpty) item.merchant,
                              if (item.note != null && item.note!.isNotEmpty) item.note,
                              DateFormatter.formatGroupHeader(item.date),
                            ].join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Text(
                            item.isTransfer
                                ? CurrencyFormatter.format(item.amount)
                                : CurrencyFormatter.formatWithSign(item.amount, isIncome: item.isIncome),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: item.isTransfer
                                  ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                  : (item.isIncome ? AppColors.incomeLight : AppColors.expenseLight),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceSummaryChip({
    required String label,
    required int amount,
    required Color textColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            '$label: ${CurrencyFormatter.formatCompact(amount)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
