import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';

class BackupService {
  final Database? _overrideDb;
  BackupService([this._overrideDb]);

  Future<Database> get _db async => _overrideDb ?? await AppDatabase.getInstance();

  /// Create a full standalone ZIP backup containing JSON data + receipt images (§9.2)
  Future<File> createBackupZip() async {
    final db = await _db;

    // 1. Export tables to JSON
    final tables = ['wallets', 'categories', 'transactions', 'receipts', 'receipt_items', 'budgets', 'app_settings'];
    final Map<String, dynamic> backupData = {
      'version': AppDatabase.dbVersion,
      'exported_at': DateTime.now().toIso8601String(),
    };

    for (final table in tables) {
      backupData[table] = await db.query(table);
    }

    final jsonString = jsonEncode(backupData);

    // 2. Prepare Zip Archive
    final archive = Archive();
    final jsonBytes = utf8.encode(jsonString);
    archive.addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));

    // 3. Add receipt images
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(p.join(appDir.path, 'receipts'));
      if (await receiptsDir.exists()) {
        final imageFiles = receiptsDir.listSync().whereType<File>();
        for (final img in imageFiles) {
          final bytes = await img.readAsBytes();
          final name = p.basename(img.path);
          archive.addFile(ArchiveFile('receipts/$name', bytes.length, bytes));
        }
      }
    } catch (_) {}

    // 4. Encode ZIP
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);

    final tempDir = await getTemporaryDirectory();
    final zipPath = p.join(
      tempDir.path,
      'belanjaku_backup_${DateTime.now().millisecondsSinceEpoch}.zip',
    );
    final zipFile = File(zipPath);
    await zipFile.writeAsBytes(zipBytes);

    return zipFile;
  }

  /// Restore from backup zip file (§9.2)
  Future<bool> restoreFromZip(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    ArchiveFile? dataFile;
    final List<ArchiveFile> imageFiles = [];

    for (final file in archive) {
      if (file.name == 'data.json') {
        dataFile = file;
      } else if (file.name.startsWith('receipts/') && !file.isDirectory) {
        imageFiles.add(file);
      }
    }

    if (dataFile == null) {
      throw Exception('Format file backup tidak valid (data.json tidak ditemukan).');
    }

    final content = utf8.decode(dataFile.content as List<int>);
    final Map<String, dynamic> data = jsonDecode(content);

    final db = await _db;

    // Restore tables inside atomic transaction
    await db.transaction((txn) async {
      final tables = ['receipt_items', 'transactions', 'receipts', 'budgets', 'categories', 'wallets'];
      for (final table in tables) {
        await txn.delete(table);
      }

      // Re-insert wallets
      final wallets = data['wallets'] as List? ?? [];
      for (final w in wallets) {
        await txn.insert('wallets', Map<String, dynamic>.from(w));
      }

      // Re-insert categories
      final categories = data['categories'] as List? ?? [];
      for (final c in categories) {
        await txn.insert('categories', Map<String, dynamic>.from(c));
      }

      // Re-insert receipts
      final receipts = data['receipts'] as List? ?? [];
      for (final r in receipts) {
        await txn.insert('receipts', Map<String, dynamic>.from(r));
      }

      // Re-insert receipt items
      final receiptItems = data['receipt_items'] as List? ?? [];
      for (final ri in receiptItems) {
        await txn.insert('receipt_items', Map<String, dynamic>.from(ri));
      }

      // Re-insert transactions
      final txs = data['transactions'] as List? ?? [];
      for (final t in txs) {
        await txn.insert('transactions', Map<String, dynamic>.from(t));
      }

      // Re-insert budgets
      final budgets = data['budgets'] as List? ?? [];
      for (final b in budgets) {
        await txn.insert('budgets', Map<String, dynamic>.from(b));
      }
    });

    // Restore images
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(p.join(appDir.path, 'receipts'));
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      for (final imgFile in imageFiles) {
        final filename = p.basename(imgFile.name);
        final target = File(p.join(receiptsDir.path, filename));
        await target.writeAsBytes(imgFile.content as List<int>);
      }
    } catch (_) {}

    return true;
  }

  Future<void> shareBackup() async {
    final zip = await createBackupZip();
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(zip.path)],
        subject: 'Backup Data BELANJAKU',
      ),
    );
  }
}
