import 'dart:io';
import 'package:image/image.dart' as img;

class ImagePreprocessor {
  /// Preprocesses an image file for optimal OCR recognition on thermal receipts:
  /// - Resizes if larger than 1600px (keeps aspect ratio)
  /// - Grayscale conversion
  /// - Contrast enhancement
  /// - Saves to processed path and returns file
  static Future<File> prepareForOcr(File rawImageFile, String destinationPath) async {
    final bytes = await rawImageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return rawImageFile;

    // 1. Resize if dimension exceeds 1600px
    img.Image processed = decoded;
    const maxDim = 1600;
    if (processed.width > maxDim || processed.height > maxDim) {
      if (processed.width > processed.height) {
        processed = img.copyResize(processed, width: maxDim);
      } else {
        processed = img.copyResize(processed, height: maxDim);
      }
    }

    // 2. Grayscale conversion for thermal receipts
    processed = img.grayscale(processed);

    // 3. Contrast enhancement
    processed = img.adjustColor(processed, contrast: 1.25);

    // 4. Save as high quality JPEG (85%)
    final encoded = img.encodeJpg(processed, quality: 85);
    final outFile = File(destinationPath);
    await outFile.writeAsBytes(encoded);
    return outFile;
  }
}
