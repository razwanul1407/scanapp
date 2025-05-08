import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageProcessor {
  static Future<File> applyAdjustments(File imageFile) async {
    try {
      // Process in background isolate
      return await _processInBackground(imageFile);
    } catch (e) {
      print('Error processing image: $e');
      return imageFile; // Return original if processing fails
    }
  }

  static Future<File> _processInBackground(File imageFile) async {
    // Create a temporary file path
    final directory = await getTemporaryDirectory();
    final outputPath =
        path.join(directory.path, 'processed_${path.basename(imageFile.path)}');

    // Process in isolate to avoid UI jank
    final processedBytes = await compute(_processImage, {
      'inputPath': imageFile.path,
      'outputPath': outputPath,
    });

    return File(outputPath)..writeAsBytesSync(processedBytes);
  }

  static Uint8List _processImage(Map<String, dynamic> params) {
    try {
      final inputPath = params['inputPath'] as String;
      final bytes = File(inputPath).readAsBytesSync();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      // Apply brightness (+5%)
      image = img.adjustColor(image, brightness: 15); // 25/255 ≈ 10%

      // Apply contrast (slightly boost)
      image = img.adjustColor(image, contrast: 0.0);

      // Apply sharpness
      image = _applySharpness(image, 0.0);

      return img.encodeJpg(image);
    } catch (e) {
      print('Processing error: $e');
      rethrow;
    }
  }

  static img.Image _applySharpness(img.Image image, double amount) {
    final blurred = img.copyResize(
      img.gaussianBlur(image, radius: 0),
      width: image.width,
      height: image.height,
    );

    final result = img.Image(width: image.width, height: image.height);

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final original = image.getPixel(x, y);
        final blur = blurred.getPixel(x, y);

        final r =
            (original.r + (original.r - blur.r) * amount).clamp(0, 255).toInt();
        final g =
            (original.g + (original.g - blur.g) * amount).clamp(0, 255).toInt();
        final b =
            (original.b + (original.b - blur.b) * amount).clamp(0, 255).toInt();

        result.setPixelRgba(x, y, r, g, b, original.a);
      }
    }
    return result;
  }
}
