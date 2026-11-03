import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/date_formatter.dart';
import '../../transactions/repositories/transaction_repository.dart';

class ExportService {
  final TransactionRepository _txRepo;

  ExportService([TransactionRepository? txRepo]) : _txRepo = txRepo ?? TransactionRepository();

  /// Export transactions to standard CSV format (§9.2):
  /// Tanggal, Jenis, Kategori, Dompet, Nominal, Catatan, Toko
  Future<File> exportToCsv() async {
    final transactions = await _txRepo.getTransactions();

    final List<List<dynamic>> rows = [
      ['Tanggal', 'Jenis', 'Kategori', 'Dompet', 'Nominal', 'Catatan', 'Toko'],
    ];

    for (final tx in transactions) {
      String typeLabel = tx.type;
      if (tx.isIncome) typeLabel = 'Pemasukan';
      if (tx.isExpense) typeLabel = 'Pengeluaran';
      if (tx.type == 'transfer_out') typeLabel = 'Transfer Keluar';
      if (tx.type == 'transfer_in') typeLabel = 'Transfer Masuk';

      rows.add([
        DateFormatter.toIsoDate(tx.date),
        typeLabel,
        tx.categoryName ?? (tx.isTransfer ? 'Transfer' : '-'),
        tx.walletName ?? '-',
        tx.amount, // Pure integer without Rp or dots
        tx.note ?? '',
        tx.merchant ?? '',
      ]);
    }

    final csvString = csv.encode(rows);

    final tempDir = await getTemporaryDirectory();
    final fileName = 'belanjaku_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(p.join(tempDir.path, fileName));
    await file.writeAsString(csvString);

    return file;
  }

  /// Share CSV file
  Future<void> shareCsv() async {
    final file = await exportToCsv();
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Export Data Transaksi BELANJAKU',
      ),
    );
  }
}
