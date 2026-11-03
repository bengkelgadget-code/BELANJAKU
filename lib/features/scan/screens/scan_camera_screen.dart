import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../categories/providers/category_providers.dart';
import '../services/receipt_ocr_service.dart';

class ScanCameraScreen extends ConsumerStatefulWidget {
  const ScanCameraScreen({super.key});

  @override
  ConsumerState<ScanCameraScreen> createState() => _ScanCameraScreenState();
}

class _ScanCameraScreenState extends ConsumerState<ScanCameraScreen> {
  final ImagePicker _picker = ImagePicker();
  final ReceiptOcrService _ocrService = ReceiptOcrService();
  bool _isProcessing = false;
  String _processingStatus = 'Membaca struk…';

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isProcessing = true;
        _processingStatus = 'Membaca struk…';
      });

      // Prepare category map and learned user dictionary
      final categoriesAsync = await ref.read(allCategoriesProvider.future);
      final categoryCodeToIdMap = {for (var c in categoriesAsync) c.code: c.id};

      final file = File(pickedFile.path);

      // Timeout / status update after 4s (§7.1)
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted && _isProcessing) {
          setState(() {
            _processingStatus = 'Masih dibaca, struk panjang…';
          });
        }
      });

      final parsed = await _ocrService.processReceiptImage(
        file,
        categoryCodeToIdMap: categoryCodeToIdMap,
      );

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      // Navigate to Review Screen (§7.1)
      context.push('/scan-review', extra: {
        'parsedResult': parsed,
        'imagePath': file.path,
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses struk: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Scan Nota / Struk', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Guidance Frame & Instructions (§7.1 langkah 2)
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Posisikan struk di dalam bingkai, pastikan harga terbaca jelas',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Rectangular Guide Frame
                Expanded(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryLight, width: 2.5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              LucideIcons.scanLine,
                              size: 80,
                              color: AppColors.primaryLight.withValues(alpha: 0.3),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Text(
                                'Struk cetak / kasir',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Shutter & Actions Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery Button
                      IconButton(
                        icon: const Icon(LucideIcons.image, color: Colors.white, size: 28),
                        onPressed: _isProcessing ? null : () => _pickImage(ImageSource.gallery),
                        tooltip: 'Ambil dari Galeri',
                      ),

                      // Large Shutter Button
                      GestureDetector(
                        onTap: _isProcessing ? null : () => _pickImage(ImageSource.camera),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            color: AppColors.primaryLight,
                          ),
                          child: const Icon(LucideIcons.camera, color: Colors.white, size: 32),
                        ),
                      ),

                      // Flash / Info
                      IconButton(
                        icon: const Icon(LucideIcons.helpCircle, color: Colors.white, size: 28),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Tips Scan Struk'),
                              content: const Text(
                                '1. Pastikan cahaya cukup dan struk tidak berbayang.\n'
                                '2. Struk tulisan tangan belum didukung MVP.\n'
                                '3. Nama toko dan total akan terdeteksi otomatis.',
                              ),
                              actions: [
                                TextButton(onPressed: () => ctx.pop(), child: const Text('Mengerti')),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Processing Loading Overlay (§7.1 langkah 4)
          if (_isProcessing)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primaryLight),
                    const SizedBox(height: 20),
                    Text(
                      _processingStatus,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mengekstrak nama toko, tanggal, item & harga',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
