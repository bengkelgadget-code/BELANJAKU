import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/icon_helper.dart';
import '../../wallets/providers/wallet_providers.dart';
import '../models/transaction.dart';
import '../providers/transaction_providers.dart';
import '../repositories/transaction_repository.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearch(String query) {
    final current = ref.read(transactionFilterProvider);
    ref.read(transactionFilterProvider.notifier).setFilter(TransactionFilter(
      searchQuery: query.trim().isEmpty ? null : query.trim(),
      type: current.type,
      categoryIds: current.categoryIds,
      walletId: current.walletId,
      startDate: current.startDate,
      endDate: current.endDate,
    ));
  }

  void _clearFilter() {
    _searchController.clear();
    ref.read(transactionFilterProvider.notifier).clear();
  }

  Future<void> _confirmDelete(TransactionItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: Text(
          'Transaksi "${item.categoryName ?? 'Transfer'}" senilai ${CurrencyFormatter.format(item.amount)} akan dihapus. Saldo dompet akan disesuaikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => ctx.pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      final repo = ref.read(transactionRepositoryProvider);
      await repo.deleteTransaction(item.id);

      // Invalidate providers
      ref.invalidate(transactionListProvider);
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(monthSummaryProvider);
      ref.invalidate(walletsProvider);
      ref.invalidate(totalBalanceProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil dihapus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filter = ref.watch(transactionFilterProvider);
    final transactionsAsync = ref.watch(transactionListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          if (filter.hasActiveFilter)
            TextButton.icon(
              icon: const Icon(LucideIcons.x, size: 16),
              label: const Text('Reset'),
              onPressed: _clearFilter,
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar (§6.2)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _updateSearch,
              decoration: InputDecoration(
                hintText: 'Cari catatan, toko, nominal, kategori...',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          _updateSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // All
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: filter.type == null,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(transactionFilterProvider.notifier).setFilter(TransactionFilter(
                        searchQuery: filter.searchQuery,
                        type: null,
                        categoryIds: filter.categoryIds,
                        walletId: filter.walletId,
                        startDate: filter.startDate,
                        endDate: filter.endDate,
                      ));
                    }
                  },
                ),
                const SizedBox(width: 8),
                // Expense Only
                ChoiceChip(
                  label: const Text('Pengeluaran'),
                  selected: filter.type == 'expense',
                  onSelected: (selected) {
                    ref.read(transactionFilterProvider.notifier).setFilter(TransactionFilter(
                      searchQuery: filter.searchQuery,
                      type: selected ? 'expense' : null,
                      categoryIds: filter.categoryIds,
                      walletId: filter.walletId,
                      startDate: filter.startDate,
                      endDate: filter.endDate,
                    ));
                  },
                ),
                const SizedBox(width: 8),
                // Income Only
                ChoiceChip(
                  label: const Text('Pemasukan'),
                  selected: filter.type == 'income',
                  onSelected: (selected) {
                    ref.read(transactionFilterProvider.notifier).setFilter(TransactionFilter(
                      searchQuery: filter.searchQuery,
                      type: selected ? 'income' : null,
                      categoryIds: filter.categoryIds,
                      walletId: filter.walletId,
                      startDate: filter.startDate,
                      endDate: filter.endDate,
                    ));
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Transaction List grouped by day
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.receipt,
                            size: 64,
                            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            filter.hasActiveFilter
                                ? 'Tidak ada transaksi yang cocok'
                                : 'Belum ada transaksi bulan ini',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            filter.hasActiveFilter
                                ? 'Coba ubah kata kunci atau hapus filter'
                                : 'Mulai catat pengeluaran pertamamu!',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Group by Day
                final Map<String, List<TransactionItem>> grouped = {};
                for (final tx in transactions) {
                  final dayKey = DateFormatter.toIsoDate(tx.date);
                  grouped.putIfAbsent(dayKey, () => []).add(tx);
                }

                final groupKeys = grouped.keys.toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: groupKeys.length,
                  itemBuilder: (context, gIndex) {
                    final dayKey = groupKeys[gIndex];
                    final dayTransactions = grouped[dayKey]!;
                    final sampleDate = dayTransactions.first.date;
                    final headerText = DateFormatter.formatGroupHeader(sampleDate);

                    int dayExpense = 0;
                    int dayIncome = 0;
                    for (final tx in dayTransactions) {
                      if (tx.isExpense) dayExpense += tx.amount;
                      if (tx.isIncome) dayIncome += tx.amount;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Day Header with Subtotal
                        Padding(
                          padding: const EdgeInsets.only(top: 14, bottom: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                headerText,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                              Row(
                                children: [
                                  if (dayIncome > 0)
                                    Text(
                                      '+${CurrencyFormatter.format(dayIncome)} ',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.incomeLight,
                                      ),
                                    ),
                                  if (dayExpense > 0)
                                    Text(
                                      '−${CurrencyFormatter.format(dayExpense)}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.expenseLight,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Day Items
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: dayTransactions.length,
                            separatorBuilder: (_, _) => Divider(
                              height: 1,
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                            itemBuilder: (context, iIndex) {
                              final item = dayTransactions[iIndex];
                              return _buildDismissibleItem(item, isDark);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissibleItem(TransactionItem item, bool isDark) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe Left: Delete
          await _confirmDelete(item);
          return false; // Handled manually
        } else {
          // Swipe Right: Edit
          context.push('/add-transaction', extra: item);
          return false;
        }
      },
      background: Container(
        color: AppColors.info,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Row(
          children: [
            Icon(LucideIcons.pencil, color: Colors.white),
            SizedBox(width: 8),
            Text('Ubah', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: AppColors.danger,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Icon(LucideIcons.trash2, color: Colors.white),
          ],
        ),
      ),
      child: ListTile(
        onTap: () {
          // Show detail modal
          _showDetailModal(item);
        },
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.getCategoryPastel(item.categoryCode ?? '', isDark: isDark),
            shape: BoxShape.circle,
          ),
          child: Icon(
            item.isTransfer ? LucideIcons.arrowLeftRight : IconHelper.getIcon(item.categoryIcon),
            size: 20,
            color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
          ),
        ),
        title: Text(
          item.isTransfer
              ? (item.type == 'transfer_out' ? 'Transfer Keluar' : 'Transfer Masuk')
              : (item.categoryName ?? 'Lainnya'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          [
            if (item.merchant != null && item.merchant!.isNotEmpty) item.merchant,
            if (item.note != null && item.note!.isNotEmpty) item.note,
            item.walletName ?? 'Dompet',
          ].join(' • '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Text(
          item.isTransfer
              ? CurrencyFormatter.format(item.amount)
              : CurrencyFormatter.formatWithSign(item.amount, isIncome: item.isIncome),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: item.isTransfer
                ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                : (item.isIncome ? AppColors.incomeLight : AppColors.expenseLight),
          ),
        ),
      ),
    );
  }

  void _showDetailModal(TransactionItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detail Transaksi',
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.pencil, size: 20),
                    onPressed: () {
                      ctx.pop();
                      context.push('/add-transaction', extra: item);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Nominal', CurrencyFormatter.format(item.amount)),
              _buildDetailRow('Jenis', item.isIncome ? 'Pemasukan' : (item.isExpense ? 'Pengeluaran' : 'Transfer')),
              _buildDetailRow('Kategori', item.categoryName ?? '-'),
              _buildDetailRow('Dompet', item.walletName ?? '-'),
              _buildDetailRow('Tanggal', DateFormatter.formatGroupHeader(item.date)),
              if (item.merchant != null) _buildDetailRow('Toko / Merchant', item.merchant!),
              if (item.note != null) _buildDetailRow('Catatan', item.note!),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                icon: const Icon(LucideIcons.trash2, size: 18),
                label: const Text('Hapus Transaksi'),
                onPressed: () {
                  ctx.pop();
                  _confirmDelete(item);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
