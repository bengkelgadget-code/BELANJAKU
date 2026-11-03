import 'dart:io';
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
import '../../transactions/models/transaction.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../wallets/models/wallet.dart';
import '../../wallets/providers/wallet_providers.dart';
import '../models/receipt.dart';
import '../models/receipt_item.dart';
import '../repositories/receipt_repository.dart';
import '../services/receipt_parser.dart';

class ScanReviewScreen extends ConsumerStatefulWidget {
  final ParsedReceiptResult parsedResult;
  final String imagePath;

  const ScanReviewScreen({
    super.key,
    required this.parsedResult,
    required this.imagePath,
  });

  @override
  ConsumerState<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends ConsumerState<ScanReviewScreen> {
  late TextEditingController _merchantController;
  late DateTime _receiptDate;
  late List<ReceiptItemModel> _items;
  Wallet? _selectedWallet;
  bool _saveAsSingleCombined = false;
  bool _showImagePreview = true;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(text: widget.parsedResult.merchant);
    _receiptDate = widget.parsedResult.date ?? DateTime.now();
    _items = List.from(widget.parsedResult.items);
  }

  @override
  void dispose() {
    _merchantController.dispose();
    super.dispose();
  }

  int get _calculatedItemsTotal => _items.fold(0, (sum, item) => sum + item.subtotal);

  int get _finalTotal {
    int total = _calculatedItemsTotal;
    if (widget.parsedResult.detectedDiscount != null) {
      total -= widget.parsedResult.detectedDiscount!;
    }
    if (widget.parsedResult.detectedTax != null) {
      total += widget.parsedResult.detectedTax!;
    }
    return total > 0 ? total : 0;
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (ctx) {
        final nameCtrl = TextEditingController();
        final priceCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Tambah Item Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Nama Barang',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  hintText: 'Harga',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => ctx.pop(), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final price = CurrencyFormatter.parse(priceCtrl.text) ?? 0;
                if (name.isNotEmpty && price > 0) {
                  setState(() {
                    _items.add(ReceiptItemModel(
                      id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
                      receiptId: '',
                      name: name,
                      qty: 1,
                      unitPrice: price,
                      subtotal: price,
                      categoryId: 'cat_exp_sembako',
                      confidence: 'high',
                    ));
                  });
                  ctx.pop();
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  void _editItem(int index) {
    final item = _items[index];
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(text: item.unitPrice.toString());
    int qty = item.qty;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Ubah Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Barang',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Harga Satuan',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Jumlah (Qty):'),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.minusCircle),
                        onPressed: qty > 1
                            ? () {
                                setDialogState(() => qty--);
                              }
                            : null,
                      ),
                      Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(LucideIcons.plusCircle),
                        onPressed: () {
                          setDialogState(() => qty++);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => ctx.pop(), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final unitPrice = CurrencyFormatter.parse(priceCtrl.text) ?? 0;
                if (name.isNotEmpty && unitPrice > 0) {
                  setState(() {
                    _items[index] = item.copyWith(
                      name: name,
                      qty: qty,
                      unitPrice: unitPrice,
                      subtotal: qty * unitPrice,
                    );
                  });
                  ctx.pop();
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _changeCategoryForItem(int index, List<Category> allCategories) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Pilih Kategori untuk Item Ini',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: allCategories.length,
                itemBuilder: (ctx, cIdx) {
                  final cat = allCategories[cIdx];
                  return ListTile(
                    leading: Icon(IconHelper.getIcon(cat.icon)),
                    title: Text(cat.name),
                    onTap: () async {
                      final item = _items[index];
                      setState(() {
                        _items[index] = item.copyWith(categoryId: cat.id);
                      });

                      // Learn user correction (§7.5 Rule 1)
                      final repo = ReceiptRepository();
                      await repo.recordUserCorrection(item.name, cat.id);

                      if (ctx.mounted) ctx.pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAll() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada item yang dapat disimpan.')),
      );
      return;
    }

    if (_selectedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih dompet pembayaran terlebih dahulu.')),
      );
      return;
    }

    final receiptRepo = ReceiptRepository();
    final txRepo = ref.read(transactionRepositoryProvider);

    // Duplicate check (§7.4)
    final isDup = await receiptRepo.checkPossibleDuplicate(
      merchant: _merchantController.text.trim(),
      total: _finalTotal,
    );

    if (isDup && mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Struk Kemungkinan Duplikat'),
          content: const Text(
            'Struk dari toko ini dengan nominal yang sama sudah pernah disimpan baru-baru ini. Tetap simpan?',
          ),
          actions: [
            TextButton(onPressed: () => ctx.pop(false), child: const Text('Batal')),
            ElevatedButton(onPressed: () => ctx.pop(true), child: const Text('Tetap Simpan')),
          ],
        ),
      );
      if (proceed != true) return;
    }

    HapticFeedback.mediumImpact();

    final receiptId = const Uuid().v4();
    final now = DateTime.now();
    final merchantName = _merchantController.text.trim();

    // 1. Create Receipt entity
    final receipt = Receipt(
      id: receiptId,
      imagePath: widget.imagePath,
      merchant: merchantName,
      receiptDate: _receiptDate,
      detectedTotal: widget.parsedResult.detectedTotal,
      calculatedTotal: _finalTotal,
      rawOcrText: widget.parsedResult.rawText,
      createdAt: now,
    );

    // 2. Prepare Receipt Items
    final receiptItems = _items.map((it) {
      return ReceiptItemModel(
        id: const Uuid().v4(),
        receiptId: receiptId,
        name: it.name,
        qty: it.qty,
        unitPrice: it.unitPrice,
        subtotal: it.subtotal,
        categoryId: it.categoryId,
        confidence: it.confidence,
      );
    }).toList();

    await receiptRepo.insertReceiptWithItems(receipt: receipt, items: receiptItems);

    // 3. Create Transactions (§7.6)
    if (_saveAsSingleCombined) {
      // Alternatif: 1 transaksi gabungan
      // Find category of most expensive item
      final sortedItems = List<ReceiptItemModel>.from(_items)
        ..sort((a, b) => b.subtotal.compareTo(a.subtotal));
      final mainCategory = sortedItems.first.categoryId;

      await txRepo.insertTransaction(TransactionItem(
        id: const Uuid().v4(),
        type: 'expense',
        amount: _finalTotal,
        categoryId: mainCategory,
        walletId: _selectedWallet!.id,
        date: _receiptDate,
        note: 'Struk $merchantName — ${_items.length} item',
        merchant: merchantName,
        receiptId: receiptId,
        createdAt: now,
        updatedAt: now,
      ));
    } else {
      // Default (§7.6): Simpan per item
      final List<TransactionItem> txList = [];
      for (final item in _items) {
        txList.add(TransactionItem(
          id: const Uuid().v4(),
          type: 'expense',
          amount: item.subtotal,
          categoryId: item.categoryId,
          walletId: _selectedWallet!.id,
          date: _receiptDate,
          note: '${item.name} (${item.qty}x)',
          merchant: merchantName,
          receiptId: receiptId,
          createdAt: now,
          updatedAt: now,
        ));
      }
      await txRepo.insertTransactionsBatch(txList);
    }

    // Refresh providers
    ref.invalidate(transactionListProvider);
    ref.invalidate(recentTransactionsProvider);
    ref.invalidate(monthSummaryProvider);
    ref.invalidate(walletsProvider);
    ref.invalidate(totalBalanceProvider);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Struk tersimpan — ${_items.length} item, total ${CurrencyFormatter.format(_finalTotal)}'),
        action: SnackBarAction(
          label: 'Lihat',
          onPressed: () {
            context.push('/transactions');
          },
        ),
      ),
    );

    // Return to main screen
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletsAsync = ref.watch(walletsProvider);
    final categoriesAsync = ref.watch(categoriesProvider('expense'));

    final hasDifferenceWarning = widget.parsedResult.hasDifferenceWarning ||
        (widget.parsedResult.detectedTotal != null &&
            (widget.parsedResult.detectedTotal! - _finalTotal).abs() > 1000);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Hasil Scan Struk'),
        actions: [
          IconButton(
            icon: Icon(_showImagePreview ? LucideIcons.eyeOff : LucideIcons.eye),
            tooltip: 'Tampilkan/Sembunyikan Foto',
            onPressed: () {
              setState(() {
                _showImagePreview = !_showImagePreview;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // Photo Thumbnail preview (§7.1 langkah 5)
                  if (_showImagePreview && File(widget.imagePath).existsSync())
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Image.file(
                            File(widget.imagePath),
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xB3000000),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Foto Asli', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Merchant Name & Date Field
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          TextField(
                            controller: _merchantController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Toko / Kasir',
                              prefixIcon: Icon(LucideIcons.store, size: 20),
                              border: InputBorder.none,
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(LucideIcons.calendar, size: 20),
                            title: Text('Tanggal: ${DateFormatter.formatGroupHeader(_receiptDate)}'),
                            subtitle: widget.parsedResult.isDateGuessed
                                ? const Text(
                                    'Tanggal tidak terbaca jelas, silakan cek ulang',
                                    style: TextStyle(color: Colors.amber, fontSize: 11),
                                  )
                                : null,
                            trailing: const Icon(LucideIcons.chevronRight, size: 18),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _receiptDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _receiptDate = picked);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Discrepancy Warning Banner (§7.3b)
                  if (hasDifferenceWarning && widget.parsedResult.detectedTotal != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.warning),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.alertTriangle, color: AppColors.warning, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Total struk tercatat ${CurrencyFormatter.format(widget.parsedResult.detectedTotal!)}, '
                              'tetapi hitungan item Rp$_calculatedItemsTotal. '
                              'Periksa kembali harga dan baris item.',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Wallet Selector Chip
                  Row(
                    children: [
                      const Text('Bayar dari: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: walletsAsync.when(
                          data: (wallets) {
                            if (_selectedWallet == null && wallets.isNotEmpty) {
                              _selectedWallet = wallets.first;
                            }
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: wallets.map((w) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      avatar: Icon(IconHelper.getIcon(w.icon), size: 14),
                                      label: Text(w.name),
                                      selected: _selectedWallet?.id == w.id,
                                      onSelected: (selected) {
                                        if (selected) setState(() => _selectedWallet = w);
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
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Header for Items + Add Item button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Item Struk (${_items.length})',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        icon: const Icon(LucideIcons.plus, size: 16),
                        label: const Text('Tambah item'),
                        onPressed: _addItem,
                      ),
                    ],
                  ),

                  // Items List (§7.1 langkah 5)
                  categoriesAsync.when(
                    data: (categories) {
                      final catMap = {for (var c in categories) c.id: c};

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final cat = catMap[item.categoryId] ?? categories.first;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Category Icon Tap to Change
                                  GestureDetector(
                                    onTap: () => _changeCategoryForItem(index, categories),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.getCategoryPastel(cat.code, isDark: isDark),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(IconHelper.getIcon(cat.icon), size: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Name & Qty
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            if (item.confidence == 'low')
                                              Container(
                                                width: 8,
                                                height: 8,
                                                margin: const EdgeInsets.only(right: 6),
                                                decoration: const BoxDecoration(
                                                  color: Colors.amber,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            Expanded(
                                              child: Text(
                                                item.name,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${item.qty} x ${CurrencyFormatter.format(item.unitPrice)} • ${cat.name}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Subtotal
                                  Text(
                                    CurrencyFormatter.format(item.subtotal),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(LucideIcons.pencil, size: 16),
                                    onPressed: () => _editItem(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.danger),
                                    onPressed: () {
                                      setState(() {
                                        _items.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const SizedBox.shrink(),
                  ),

                  // Discount / Tax breakdown
                  if (widget.parsedResult.detectedDiscount != null && widget.parsedResult.detectedDiscount! > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Diskon Terdeteksi', style: TextStyle(color: Colors.green, fontSize: 13)),
                          Text(
                            '−${CurrencyFormatter.format(widget.parsedResult.detectedDiscount!)}',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                  if (widget.parsedResult.detectedTax != null && widget.parsedResult.detectedTax! > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Pajak (PB1/PPN)', style: TextStyle(fontSize: 13)),
                          Text(
                            '+${CurrencyFormatter.format(widget.parsedResult.detectedTax!)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Save Mode Switcher (§7.6)
                  CheckboxListTile(
                    title: const Text('Simpan sebagai 1 transaksi gabungan', style: TextStyle(fontSize: 13)),
                    subtitle: const Text(
                      'Jika dicentang, semua item digabung menjadi satu transaksi total',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: _saveAsSingleCombined,
                    onChanged: (val) {
                      setState(() {
                        _saveAsSingleCombined = val ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            // Bottom Sticky Save Bar (§7.1 langkah 5)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Akhir', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      Text(
                        CurrencyFormatter.format(_finalTotal),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _items.isNotEmpty ? _saveAll : null,
                    child: Text(
                      _saveAsSingleCombined
                          ? 'Simpan sebagai 1 Transaksi (${CurrencyFormatter.format(_finalTotal)})'
                          : 'Simpan Semua (${_items.length} Transaksi)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
