import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'image_preprocessor.dart';
import 'receipt_parser.dart';

class ReceiptOcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Performs full receipt scanning pipeline:
  /// 1. Copies photo to app storage
  /// 2. Preprocesses image (grayscale & contrast)
  /// 3. Extracts text via Google ML Kit
  /// 4. Parses items, merchant, date, totals via ReceiptParser
  Future<ParsedReceiptResult> processReceiptImage(
    File sourceImage, {
    Map<String, String>? userLearnedCategories,
    Map<String, String>? categoryCodeToIdMap,
  }) async {
    // 1. Save to app directory
    final appDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory(p.join(appDir.path, 'receipts'));
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }

    final filename = 'receipt_${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4().substring(0, 8)}.jpg';
    final savedPath = p.join(receiptsDir.path, filename);

    // 2. Preprocess image
    final preprocessedFile = await ImagePreprocessor.prepareForOcr(sourceImage, savedPath);

    // 3. Perform ML Kit Text Recognition
    String rawOcrText = '';
    try {
      final inputImage = InputImage.fromFilePath(preprocessedFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      rawOcrText = recognizedText.text;
    } catch (e) {
      // In case ML Kit fails or runs in a mock environment
      rawOcrText = '';
    }

    // 4. Parse with pure parser
    return ReceiptParser.parse(
      rawOcrText,
      userLearnedCategories: userLearnedCategories,
      categoryCodeToIdMap: categoryCodeToIdMap,
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}
