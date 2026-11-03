import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/icon_helper.dart';
import '../../categories/models/category.dart';
import '../../categories/providers/category_providers.dart';
import '../../wallets/models/wallet.dart';
import '../../wallets/providers/wallet_providers.dart';
import '../models/transaction.dart';
import '../providers/transaction_providers.dart';
import '../widgets/numpad_widget.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionItem? existingItem; // If editing

  const AddTransactionScreen({super.key, this.existingItem});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  late bool _isExpense;
  String _amountString = '';
  Category? _selectedCategory;
  Wallet? _selectedWallet;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _isExpense = item.type == 'expense';
      _amountString = item.amount.toString();
      _selectedDate = item.date;
      _noteController.text = item.note ?? '';
      _merchantController.text = item.merchant ?? '';
    } else {
      _isExpense = true; // Default Keluar (§6.1)
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_amountString.length >= 12) return; // Limit to max digits
    setState(() {
      if (_amountString == '0' && digit != '00') {
        _amountString = digit;
      } else {
        _amountString += digit;
      }
    });
  }

  void _onDeletePressed() {
    if (_amountString.isNotEmpty) {
      setState(() {
        _amountString = _amountString.substring(0, _amountString.length - 1);
      });
    }
  }

  int get _currentAmount => int.tryParse(_amountString) ?? 0;

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now, // Tanggal tidak boleh masa depan (§6.1)
      helpText: 'PILIH TANGGAL TRANSAKSI',
      cancelText: 'BATAL',
      confirmText: 'PILIH',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_currentAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nominal dulu.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih kategori transaksi.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_selectedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih dompet pembayaran.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    final repo = ref.read(transactionRepositoryProvider);
    final now = DateTime.now();
    final isEdit = widget.existingItem != null;

    final tx = TransactionItem(
      id: widget.existingItem?.id ?? const Uuid().v4(),
      type: _isExpense ? 'expense' : 'income',
      amount: _currentAmount,
      categoryId: _selectedCategory!.id,
      walletId: _selectedWallet!.id,
      date: _selectedDate,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      merchant: _merchantController.text.trim().isNotEmpty ? _merchantController.text.trim() : null,
      receiptId: widget.existingItem?.receiptId,
      createdAt: widget.existingItem?.createdAt ?? now,
      updatedAt: now,
    );

    if (isEdit) {
      await repo.updateTransaction(tx);
    } else {
      await repo.insertTransaction(tx);
    }

    // Refresh providers
    ref.invalidate(transactionListProvider);
    ref.invalidate(recentTransactionsProvider);
    ref.invalidate(monthSummaryProvider);
    ref.invalidate(walletsProvider);
    ref.invalidate(totalBalanceProvider);

    if (!mounted) return;

    // Snackbar with Undo (Urungkan) for 4 seconds (§6.1)
    final catName = _selectedCategory!.name;
    final formattedAmount = CurrencyFormatter.format(_currentAmount);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tersimpan — $catName $formattedAmount'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Urungkan',
          textColor: Colors.amberAccent,
          onPressed: () async {
            if (isEdit) {
              await repo.updateTransaction(widget.existingItem!);
            } else {
              await repo.deleteTransaction(tx.id);
            }
            ref.invalidate(transactionListProvider);
            ref.invalidate(recentTransactionsProvider);
            ref.invalidate(monthSummaryProvider);
            ref.invalidate(walletsProvider);
            ref.invalidate(totalBalanceProvider);
          },
        ),
      ),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider(_isExpense ? 'expense' : 'income'));
    final walletsAsync = ref.watch(walletsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingItem != null ? 'Ubah Transaksi' : 'Tambah Transaksi'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Toggle: Masuk / Keluar (§8.3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!_isExpense) {
                            setState(() {
                              _isExpense = true;
                              _selectedCategory = null;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isExpense ? AppColors.expenseLight : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Center(
                            child: Text(
                              'Pengeluaran',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                color: _isExpense
                                    ? Colors.white
                                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_isExpense) {
                            setState(() {
                              _isExpense = false;
                              _selectedCategory = null;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isExpense ? AppColors.incomeLight : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Center(
                            child: Text(
                              'Pemasukan',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                color: !_isExpense
                                    ? Colors.white
                                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Large Amount Display
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Text(
                    CurrencyFormatter.format(_currentAmount),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: _isExpense ? AppColors.expenseLight : AppColors.incomeLight,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentAmount == 0 ? 'Ketik nominal via numpad' : 'Rupiah',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Middle Scrollable Area: Category Grid, Wallets, Date & Note
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // Category Grid
                  Text(
                    'Kategori',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  categoriesAsync.when(
                    data: (categories) {
                      // Auto-select first or matching
                      if (_selectedCategory == null && categories.isNotEmpty) {
                        if (widget.existingItem != null) {
                          _selectedCategory = categories.firstWhere(
                            (c) => c.id == widget.existingItem!.categoryId,
                            orElse: () => categories.first,
                          );
                        } else {
                          _selectedCategory = categories.first;
                        }
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isSelected = _selectedCategory?.id == cat.id;
                          final pastelColor = AppColors.getCategoryPastel(cat.code, isDark: isDark);

                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedCategory = cat;
                              });
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? (_isExpense ? AppColors.expenseLight : AppColors.incomeLight)
                                            : pastelColor,
                                        shape: BoxShape.circle,
                                        border: isSelected
                                            ? Border.all(color: Colors.white, width: 2)
                                            : null,
                                      ),
                                      child: Icon(
                                        IconHelper.getIcon(cat.icon),
                                        size: 22,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark ? Colors.white70 : AppColors.textPrimaryLight),
                                      ),
                                    ),
                                    if (isSelected)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.check,
                                            size: 12,
                                            color: _isExpense ? AppColors.expenseLight : AppColors.incomeLight,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cat.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Gagal memuat kategori: $e'),
                  ),

                  const SizedBox(height: 16),

                  // Wallet Chips
                  Text(
                    'Dompet',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  walletsAsync.when(
                    data: (wallets) {
                      if (_selectedWallet == null && wallets.isNotEmpty) {
                        if (widget.existingItem != null) {
                          _selectedWallet = wallets.firstWhere(
                            (w) => w.id == widget.existingItem!.walletId,
                            orElse: () => wallets.first,
                          );
                        } else {
                          _selectedWallet = wallets.first;
                        }
                      }

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: wallets.map((w) {
                            final isSelected = _selectedWallet?.id == w.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                avatar: Icon(IconHelper.getIcon(w.icon), size: 16),
                                label: Text('${w.name} (${CurrencyFormatter.formatCompact(w.currentBalance)})'),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedWallet = w;
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 16),

                  // Date & Optional Note
                  Row(
                    children: [
                      // Date Chip
                      ActionChip(
                        avatar: const Icon(LucideIcons.calendar, size: 16),
                        label: Text(DateFormatter.formatGroupHeader(_selectedDate)),
                        onPressed: _selectDate,
                      ),
                      const SizedBox(width: 8),
                      // Optional Merchant / Toko
                      Expanded(
                        child: TextField(
                          controller: _merchantController,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Nama Toko (opsional)',
                            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Catatan (opsional)',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Numpad Widget
            NumpadWidget(
              onDigitPressed: _onDigitPressed,
              onDeletePressed: _onDeletePressed,
            ),

            // Full-width Bottom Save Button (§8.2 rule 3)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _currentAmount > 0 ? _saveTransaction : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isExpense ? AppColors.expenseLight : AppColors.incomeLight,
                  disabledBackgroundColor: Colors.grey.shade400,
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: Text(
                  _currentAmount > 0
                      ? 'Simpan ${CurrencyFormatter.format(_currentAmount)}'
                      : 'Masukkan nominal dulu',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
