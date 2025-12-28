import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Document filter types similar to CamScanner
enum DocumentFilter {
  original('Original', 'No filter applied'),
  autoEnhance('Auto', 'Automatic enhancement'),
  magicColor('Magic Color', 'Enhanced colors for documents'),
  blackWhite('B&W', 'Black and white document'),
  grayscale('Grayscale', 'Grayscale conversion'),
  highContrast('High Contrast', 'Increased contrast for text');

  const DocumentFilter(this.label, this.description);
  final String label;
  final String description;
}

class ImageProcessor {
  /// Apply brightness adjustment to image
  static Future<Uint8List> adjustBrightness(
      File imageFile, double brightness) async {
    try {
      return await compute(_adjustBrightnessIsolate, {
        'inputPath': imageFile.path,
        'brightness': brightness,
      });
    } catch (e) {
      print('Error adjusting brightness: $e');
      return imageFile.readAsBytesSync();
    }
  }

  /// Apply contrast adjustment to image
  static Future<Uint8List> adjustContrast(
      File imageFile, double contrast) async {
    try {
      return await compute(_adjustContrastIsolate, {
        'inputPath': imageFile.path,
        'contrast': contrast,
      });
    } catch (e) {
      print('Error adjusting contrast: $e');
      return imageFile.readAsBytesSync();
    }
  }

  /// Apply saturation adjustment to image
  static Future<Uint8List> adjustSaturation(
      File imageFile, double saturation) async {
    try {
      return await compute(_adjustSaturationIsolate, {
        'inputPath': imageFile.path,
        'saturation': saturation,
      });
    } catch (e) {
      print('Error adjusting saturation: $e');
      return imageFile.readAsBytesSync();
    }
  }

  /// Convert image to grayscale
  static Future<Uint8List> toGrayscale(File imageFile) async {
    try {
      return await compute(_toGrayscaleIsolate, imageFile.path);
    } catch (e) {
      print('Error converting to grayscale: $e');
      return imageFile.readAsBytesSync();
    }
  }

  /// Apply all adjustments at once (optimized)
  static Future<Uint8List> applyAdjustments({
    required File imageFile,
    double brightness = 0.0,
    double contrast = 0.0,
    double saturation = 0.0,
    bool grayscale = false,
  }) async {
    try {
      return await compute(_applyAllAdjustmentsIsolate, {
        'inputPath': imageFile.path,
        'brightness': brightness,
        'contrast': contrast,
        'saturation': saturation,
        'grayscale': grayscale,
      });
    } catch (e) {
      print('Error applying adjustments: $e');
      return imageFile.readAsBytesSync();
    }
  }

  /// Auto-enhance image (optimize brightness and contrast)
  static Future<Uint8List> autoEnhance(File imageFile) async {
    try {
      return await compute(_autoEnhanceIsolate, imageFile.path);
    } catch (e) {
      print('Error auto-enhancing: $e');
      return imageFile.readAsBytesSync();
    }
  }

  /// Apply document filter (CamScanner-like filters)
  static Future<Uint8List> applyFilter(
    Uint8List imageBytes,
    DocumentFilter filter,
  ) async {
    try {
      return await compute(_applyFilterIsolate, {
        'bytes': imageBytes,
        'filter': filter.index,
      });
    } catch (e) {
      print('Error applying filter: $e');
      return imageBytes;
    }
  }

  /// Apply Magic Color filter - enhanced document scan look
  static Future<Uint8List> applyMagicColor(Uint8List imageBytes) async {
    return applyFilter(imageBytes, DocumentFilter.magicColor);
  }

  /// Apply Black & White document filter
  static Future<Uint8List> applyBlackWhite(Uint8List imageBytes) async {
    return applyFilter(imageBytes, DocumentFilter.blackWhite);
  }

  /// Rotate image by given degrees (0, 90, 180, 270)
  static Future<Uint8List> rotateImage(File imageFile, int degrees) async {
    try {
      return await compute(_rotateImageIsolate, {
        'inputPath': imageFile.path,
        'degrees': degrees,
      });
    } catch (e) {
      print('Error rotating image: $e');
      return imageFile.readAsBytesSync();
    }
  }

  // Isolate functions for background processing

  static Uint8List _adjustBrightnessIsolate(Map<String, dynamic> params) {
    final inputPath = params['inputPath'] as String;
    final brightness = params['brightness'] as double;

    final bytes = File(inputPath).readAsBytesSync();
    final image = img.decodeImage(bytes);

    if (image == null) throw Exception('Failed to decode image');

    // Brightness range: -1.0 to 1.0
    final adjustedImage = img.adjustColor(
      image,
      brightness: (brightness * 255).toInt(),
    );

    return Uint8List.fromList(img.encodeJpg(adjustedImage));
  }

  static Uint8List _adjustContrastIsolate(Map<String, dynamic> params) {
    final inputPath = params['inputPath'] as String;
    final contrast = params['contrast'] as double;

    final bytes = File(inputPath).readAsBytesSync();
    final image = img.decodeImage(bytes);

    if (image == null) throw Exception('Failed to decode image');

    // Contrast range: -1.0 to 1.0
    final adjustedImage = img.adjustColor(
      image,
      contrast: contrast,
    );

    return Uint8List.fromList(img.encodeJpg(adjustedImage));
  }

  static Uint8List _adjustSaturationIsolate(Map<String, dynamic> params) {
    final inputPath = params['inputPath'] as String;
    final saturation = params['saturation'] as double;

    final bytes = File(inputPath).readAsBytesSync();
    final image = img.decodeImage(bytes);

    if (image == null) throw Exception('Failed to decode image');

    // Saturation adjustment
    final adjustedImage = img.adjustColor(
      image,
      saturation: saturation,
    );

    return Uint8List.fromList(img.encodeJpg(adjustedImage));
  }

  static Uint8List _toGrayscaleIsolate(String inputPath) {
    final bytes = File(inputPath).readAsBytesSync();
    final image = img.decodeImage(bytes);

    if (image == null) throw Exception('Failed to decode image');

    final grayscale = img.grayscale(image);

    return Uint8List.fromList(img.encodeJpg(grayscale));
  }

  static Uint8List _applyAllAdjustmentsIsolate(Map<String, dynamic> params) {
    final inputPath = params['inputPath'] as String;
    final brightness = params['brightness'] as double;
    final contrast = params['contrast'] as double;
    final saturation = params['saturation'] as double;
    final grayscale = params['grayscale'] as bool;

    final bytes = File(inputPath).readAsBytesSync();
    var image = img.decodeImage(bytes);

    if (image == null) throw Exception('Failed to decode image');

    // Apply adjustments in order
    if (brightness != 0.0) {
      image = img.adjustColor(
        image,
        brightness: (brightness * 255).toInt(),
      );
    }

    if (contrast != 0.0) {
      image = img.adjustColor(
        image,
        contrast: contrast,
      );
    }

    if (saturation != 0.0) {
      image = img.adjustColor(
        image,
        saturation: saturation,
      );
    }

    if (grayscale) {
      image = img.grayscale(image);
    }

    return Uint8List.fromList(img.encodeJpg(image));
  }

  static Uint8List _autoEnhanceIsolate(String inputPath) {
    final bytes = File(inputPath).readAsBytesSync();
    var image = img.decodeImage(bytes);

    if (image == null) throw Exception('Failed to decode image');

    // Simple auto-enhance: boost contrast and brightness slightly
    image = img.adjustColor(
      image,
      brightness: 10,
      contrast: 0.15,
    );

    return Uint8List.fromList(img.encodeJpg(image));
  }

  /// Apply document filter in isolate
  static Uint8List _applyFilterIsolate(Map<String, dynamic> params) {
    final bytes = params['bytes'] as Uint8List;
    final filterIndex = params['filter'] as int;
    final filter = DocumentFilter.values[filterIndex];

    var image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');

    switch (filter) {
      case DocumentFilter.original:
        // No changes
        break;

      case DocumentFilter.autoEnhance:
        // Slight brightness and contrast boost
        image = img.adjustColor(
          image,
          brightness: 10,
          contrast: 0.15,
        );
        break;

      case DocumentFilter.magicColor:
        // CamScanner-like magic color: increased contrast, slight saturation
        image = img.adjustColor(
          image,
          contrast: 0.3,
          saturation: 0.1,
          brightness: 15,
        );
        // Apply slight sharpening
        image = img.convolution(image, filter: [
          0,
          -0.5,
          0,
          -0.5,
          3,
          -0.5,
          0,
          -0.5,
          0,
        ]);
        break;

      case DocumentFilter.blackWhite:
        // High contrast black & white for documents
        image = img.grayscale(image);
        image = img.adjustColor(image, contrast: 0.5, brightness: 20);
        // Apply threshold for cleaner B&W
        for (int y = 0; y < image.height; y++) {
          for (int x = 0; x < image.width; x++) {
            final pixel = image.getPixel(x, y);
            final gray = img.getLuminance(pixel);
            final newValue = gray > 140 ? 255 : 0;
            image.setPixel(
              x,
              y,
              img.ColorRgba8(newValue, newValue, newValue, 255),
            );
          }
        }
        break;

      case DocumentFilter.grayscale:
        image = img.grayscale(image);
        break;

      case DocumentFilter.highContrast:
        // High contrast for better text readability
        image = img.adjustColor(
          image,
          contrast: 0.4,
          brightness: 5,
        );
        break;
    }

    return Uint8List.fromList(img.encodeJpg(image, quality: 90));
  }

  static Uint8List _rotateImageIsolate(Map<String, dynamic> params) {
    final inputPath = params['inputPath'] as String;
    final degrees = params['degrees'] as int;

    final bytes = File(inputPath).readAsBytesSync();
    var image = img.decodeImage(bytes);

    if (image == null) throw Exception('Failed to decode image');

    // Normalize degrees
    final normalizedDegrees = ((degrees % 360) + 360) % 360;

    switch (normalizedDegrees) {
      case 90:
        image = img.copyRotate(image, angle: 90);
        break;
      case 180:
        image = img.copyRotate(image, angle: 180);
        break;
      case 270:
        image = img.copyRotate(image, angle: 270);
        break;
      default:
        // 0 or other
        break;
    }

    return Uint8List.fromList(img.encodeJpg(image));
  }

  /// Save processed image to file
  static Future<File> saveProcessedImage({
    required Uint8List imageBytes,
    required String filename,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final filepath = path.join(directory.path, 'scans', filename);

    final file = File(filepath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(imageBytes);

    return file;
  }

  /// Get file size in bytes
  static Future<int> getImageFileSize(File imageFile) async {
    final stat = await imageFile.stat();
    return stat.size;
  }
}
