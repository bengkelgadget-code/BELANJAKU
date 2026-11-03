import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../models/wallet.dart';
import '../providers/wallet_providers.dart';

class TransferDialog extends ConsumerStatefulWidget {
  const TransferDialog({super.key});

  @override
  ConsumerState<TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends ConsumerState<TransferDialog> {
  Wallet? _fromWallet;
  Wallet? _toWallet;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitTransfer() async {
    final amount = CurrencyFormatter.parse(_amountController.text) ?? 0;
    if (_fromWallet == null || _toWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih dompet asal dan tujuan')),
      );
      return;
    }
    if (_fromWallet!.id == _toWallet!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dompet asal dan tujuan tidak boleh sama')),
      );
      return;
    }
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal transfer')),
      );
      return;
    }

    try {
      HapticFeedback.mediumImpact();
      final repo = ref.read(walletRepositoryProvider);
      await repo.transfer(
        fromWalletId: _fromWallet!.id,
        toWalletId: _toWallet!.id,
        amount: amount,
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      );

      // Invalidate providers
      ref.invalidate(walletsProvider);
      ref.invalidate(totalBalanceProvider);
      ref.invalidate(transactionListProvider);
      ref.invalidate(recentTransactionsProvider);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Transfer ${CurrencyFormatter.format(amount)} dari ${_fromWallet!.name} ke ${_toWallet!.name} berhasil',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal transfer: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsProvider);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(LucideIcons.arrowLeftRight, color: AppColors.primaryLight, size: 22),
          const SizedBox(width: 8),
          Text('Transfer Antar Dompet', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: walletsAsync.when(
          data: (wallets) {
            if (wallets.length < 2) {
              return const Text('Perlu minimal 2 dompet untuk melakukan transfer.');
            }

            _fromWallet ??= wallets.first;
            _toWallet ??= wallets.length > 1 ? wallets[1] : wallets.first;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dari Dompet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: _fromWallet?.id,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: wallets.map((w) {
                    return DropdownMenuItem(
                      value: w.id,
                      child: Text('${w.name} (${CurrencyFormatter.formatCompact(w.currentBalance)})'),
                    );
                  }).toList(),
                  onChanged: (id) {
                    setState(() {
                      _fromWallet = wallets.firstWhere((w) => w.id == id);
                    });
                  },
                ),
                const SizedBox(height: 12),
                const Text('Ke Dompet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: _toWallet?.id,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: wallets.map((w) {
                    return DropdownMenuItem(
                      value: w.id,
                      child: Text('${w.name} (${CurrencyFormatter.formatCompact(w.currentBalance)})'),
                    );
                  }).toList(),
                  onChanged: (id) {
                    setState(() {
                      _toWallet = wallets.firstWhere((w) => w.id == id);
                    });
                  },
                ),
                const SizedBox(height: 12),
                const Text('Nominal Transfer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    hintText: '0',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Catatan (opsional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Misal: Top up e-wallet',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submitTransfer,
          child: const Text('Kirim Transfer'),
        ),
      ],
    );
  }
}
