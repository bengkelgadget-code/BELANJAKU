import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../wallets/models/wallet.dart';
import '../../wallets/providers/wallet_providers.dart';
import '../services/backup_service.dart';
import '../services/export_service.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setThemeMode(ThemeMode mode) => state = mode;
}

final appThemeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class UserNameNotifier extends Notifier<String> {
  @override
  String build() => AppConstants.defaultUserName;

  void setUserName(String name) => state = name;
}

final userNameProvider = NotifierProvider<UserNameNotifier, String>(
  UserNameNotifier.new,
);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _editUserName(BuildContext context, WidgetRef ref) async {
    final currentName = ref.read(userNameProvider);
    final ctrl = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Nama Panggilan'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Nama Anda',
            hintText: 'Misal: boy',
          ),
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => ctx.pop(ctrl.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      ref.read(userNameProvider.notifier).setUserName(newName);
    }
  }

  Future<void> _addNewWalletDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();
    String type = 'bank';

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tambah Dompet Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Dompet (misal: BCA, Mandiri, ShopeePay)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: InputDecoration(
                  labelText: 'Jenis',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'bank', child: Text('Bank')),
                  DropdownMenuItem(value: 'ewallet', child: Text('E-Wallet')),
                  DropdownMenuItem(value: 'cash', child: Text('Tunai')),
                  DropdownMenuItem(value: 'other', child: Text('Lainnya')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => type = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: balanceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Saldo Awal',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => ctx.pop(false), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  ctx.pop(true);
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );

    if (created == true) {
      final repo = ref.read(walletRepositoryProvider);
      final initialBal = int.tryParse(balanceCtrl.text.replaceAll('.', '')) ?? 0;
      final now = DateTime.now();

      final newWallet = Wallet(
        id: 'w_${DateTime.now().millisecondsSinceEpoch}',
        name: nameCtrl.text.trim(),
        type: type,
        initialBalance: initialBal,
        icon: type == 'bank' ? 'landmark' : (type == 'ewallet' ? 'smartphone' : 'wallet'),
        color: '0xFF059669',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      await repo.insertWallet(newWallet);
      ref.invalidate(walletsProvider);
      ref.invalidate(totalBalanceProvider);
    }
  }

  Future<void> _exportCsv(BuildContext context) async {
    try {
      final exportService = ExportService();
      await exportService.shareCsv();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor data: $e')),
        );
      }
    }
  }

  Future<void> _backupData(BuildContext context) async {
    try {
      final backupService = BackupService();
      await backupService.shareBackup();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat backup: $e')),
        );
      }
    }
  }

  Future<void> _restoreData(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result.isEmpty || result.first.path == null) return;

      if (!context.mounted) return;

      // Confirm 2x (§9.2)
      final confirm1 = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restore Data?'),
          content: const Text(
            'Data saat ini akan digantikan dengan data dari file backup. Lanjutkan?',
          ),
          actions: [
            TextButton(onPressed: () => ctx.pop(false), child: const Text('Batal')),
            ElevatedButton(onPressed: () => ctx.pop(true), child: const Text('Lanjutkan')),
          ],
        ),
      );

      if (confirm1 != true || !context.mounted) return;

      final confirm2 = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Konfirmasi Penggantian Data'),
          content: const Text(
            'PERINGATAN: Tindakan ini tidak dapat dibatalkan. Semua transaksi lama akan ditimpa.',
          ),
          actions: [
            TextButton(onPressed: () => ctx.pop(false), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => ctx.pop(true),
              child: const Text('Ya, Timpa Data'),
            ),
          ],
        ),
      );

      if (confirm2 != true) return;

      final backupService = BackupService();
      final file = File(result.first.path!);
      await backupService.restoreFromZip(file);

      // Invalidate all providers
      ref.invalidate(walletsProvider);
      ref.invalidate(totalBalanceProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil dipulihkan dari backup')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal restore: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final walletsAsync = ref.watch(walletsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Profile card
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(LucideIcons.user, color: Colors.white),
              ),
              title: Text(
                userName,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: const Text('Pengguna BELANJAKU'),
              trailing: IconButton(
                icon: const Icon(LucideIcons.pencil, size: 18),
                onPressed: () => _editUserName(context, ref),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Wallets Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dompet Saya',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Tambah Dompet'),
                onPressed: () => _addNewWalletDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 6),
          walletsAsync.when(
            data: (wallets) {
              return Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: wallets.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final w = wallets[i];
                    return ListTile(
                      leading: Icon(
                        w.type == 'bank'
                            ? LucideIcons.landmark
                            : (w.type == 'ewallet' ? LucideIcons.smartphone : LucideIcons.wallet),
                      ),
                      title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Tipe: ${w.type.toUpperCase()}'),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),

          const SizedBox(height: 16),

          // Data & Backup Section
          Text(
            'Data & Cadangan',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.fileSpreadsheet, color: AppColors.primaryLight),
                  title: const Text('Export ke CSV / Excel'),
                  subtitle: const Text('Buka riwayat di spreadsheet'),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () => _exportCsv(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.downloadCloud, color: AppColors.info),
                  title: const Text('Backup Data Lengkap (ZIP)'),
                  subtitle: const Text('Cadangkan data dan foto struk lokal'),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () => _backupData(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.uploadCloud, color: AppColors.warning),
                  title: const Text('Restore dari Backup'),
                  subtitle: const Text('Pulihkan data dari file ZIP sebelumnya'),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () => _restoreData(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Appearance Section
          Text(
            'Tampilan',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Card(
            child: ListTile(
              leading: const Icon(LucideIcons.moon),
              title: const Text('Tema Aplikasi'),
              subtitle: Text(
                themeMode == ThemeMode.system
                    ? 'Mengikuti Sistem'
                    : (themeMode == ThemeMode.dark ? 'Mode Gelap' : 'Mode Terang'),
              ),
              trailing: DropdownButton<ThemeMode>(
                value: themeMode,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: ThemeMode.system, child: Text('Sistem')),
                  DropdownMenuItem(value: ThemeMode.light, child: Text('Terang')),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Gelap')),
                ],
                onChanged: (mode) {
                  if (mode != null) {
                    ref.read(appThemeModeProvider.notifier).setThemeMode(mode);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // About Section (§10 & §12)
          Text(
            'Tentang Aplikasi',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.wallet, color: AppColors.primaryLight, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appName,
                            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Versi ${AppConstants.appVersion}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Aplikasi pencatatan keuangan pribadi dan scan struk otomatis.\n'
                    '100% Local-First & Offline. Foto dan data keuangan tersimpan aman di perangkat Anda.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
