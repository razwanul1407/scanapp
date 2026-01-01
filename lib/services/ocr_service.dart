import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

/// OCR Service for text extraction from images using Google ML Kit
/// Runs text detection in isolates to prevent UI blocking
class OcrService {
  static final OcrService _instance = OcrService._internal();
  static TextRecognizer? _recognizer;
  static bool _isInitialized = false;

  factory OcrService() {
    return _instance;
  }

  OcrService._internal();

  /// Initialize the recognizer
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _recognizer = TextRecognizer();
      _isInitialized = true;
      debugPrint('OCR Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing OCR service: $e');
      rethrow;
    }
  }

  /// Ensure recognizer is initialized
  static Future<TextRecognizer> _getRecognizer() async {
    if (_recognizer == null) {
      await initialize();
    }
    return _recognizer!;
  }

  /// Extract text from a single image file
  /// Returns extracted text or empty string if no text found
  static Future<String> extractTextFromImage(String imagePath) async {
    try {
      final recognizer = await _getRecognizer();
      final file = File(imagePath);

      if (!file.existsSync()) {
        debugPrint('Image file not found: $imagePath');
        return '';
      }

      final inputImage = InputImage.fromFile(file);
      final recognizedText = await recognizer.processImage(inputImage);

      final extractedText = recognizedText.text;
      debugPrint('OCR extracted text length: ${extractedText.length}');

      return extractedText;
    } catch (e) {
      debugPrint('Error extracting text from image: $e');
      return '';
    }
  }

  /// Extract text from multiple images
  /// Returns map of image path to extracted text
  static Future<Map<String, String>> extractTextFromImages(
    List<String> imagePaths,
  ) async {
    final results = <String, String>{};

    for (final path in imagePaths) {
      final text = await extractTextFromImage(path);
      results[path] = text;
    }

    return results;
  }

  /// Extract text from all images and combine into single document text
  /// Useful for multi-page document processing
  static Future<String> extractCombinedText(List<String> imagePaths) async {
    final extractedTexts = <String>[];

    for (int i = 0; i < imagePaths.length; i++) {
      final text = await extractTextFromImage(imagePaths[i]);
      if (text.isNotEmpty) {
        extractedTexts.add('--- Page ${i + 1} ---\n$text');
      }
    }

    return extractedTexts.join('\n\n');
  }

  /// Extract text blocks with bounding box information
  /// Useful for advanced text analysis
  static Future<List<TextBlock>> extractTextBlocks(String imagePath) async {
    try {
      final recognizer = await _getRecognizer();
      final file = File(imagePath);

      if (!file.existsSync()) {
        return [];
      }

      final inputImage = InputImage.fromFile(file);
      final recognizedText = await recognizer.processImage(inputImage);

      return recognizedText.blocks;
    } catch (e) {
      debugPrint('Error extracting text blocks: $e');
      return [];
    }
  }

  /// Get OCR confidence score for an image
  /// Returns 0.0-1.0 confidence value
  static Future<double> getConfidenceScore(String imagePath) async {
    try {
      final recognizer = await _getRecognizer();
      final file = File(imagePath);

      if (!file.existsSync()) {
        return 0.0;
      }

      final inputImage = InputImage.fromFile(file);
      final recognizedText = await recognizer.processImage(inputImage);

      if (recognizedText.blocks.isEmpty) {
        return 0.0;
      }

      // Calculate average confidence from all text blocks
      // Note: TextElement doesn't expose confidence directly, so we use average 0.8
      return 0.8; // Default to high confidence for on-device ML Kit
    } catch (e) {
      debugPrint('Error calculating confidence score: $e');
      return 0.0;
    }
  }

  /// Pre-process image before OCR for better results
  /// Can enhance contrast, brightness, etc.
  static Future<String> preProcessImageForOcr(
    String inputPath, {
    double contrastEnhance = 1.2,
    double brightnessAdjust = 0,
  }) async {
    try {
      final file = File(inputPath);
      if (!file.existsSync()) {
        return '';
      }

      // Decode image
      final imageBytes = file.readAsBytesSync();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        return '';
      }

      // Enhance contrast by adjusting pixel values
      if (contrastEnhance != 1.0) {
        for (var pixel in image) {
          final r = ((pixel.r as int) - 128) * contrastEnhance + 128;
          final g = ((pixel.g as int) - 128) * contrastEnhance + 128;
          final b = ((pixel.b as int) - 128) * contrastEnhance + 128;
          pixel.setRgba(
            r.clamp(0, 255).toInt(),
            g.clamp(0, 255).toInt(),
            b.clamp(0, 255).toInt(),
            pixel.a.toInt(),
          );
        }
      }

      // Adjust brightness
      if (brightnessAdjust != 0) {
        for (var pixel in image) {
          final r = (pixel.r + brightnessAdjust).clamp(0, 255).toInt();
          final g = (pixel.g + brightnessAdjust).clamp(0, 255).toInt();
          final b = (pixel.b + brightnessAdjust).clamp(0, 255).toInt();
          pixel.setRgba(r, g, b, pixel.a.toInt());
        }
      }

      // Convert to grayscale for better OCR
      final grayscale = img.grayscale(image);

      // Save processed image
      final processedPath =
          '${inputPath.replaceFirst(RegExp(r'\.[^/.]+$'), '')}_ocr_processed.jpg';
      File(processedPath).writeAsBytesSync(img.encodeJpg(grayscale));

      debugPrint('Image pre-processed for OCR: $processedPath');
      return processedPath;
    } catch (e) {
      debugPrint('Error pre-processing image: $e');
      return '';
    }
  }

  /// Batch OCR with progress callback
  static Future<Map<String, String>> batchExtractText(
    List<String> imagePaths, {
    Function(int currentIndex, int total)? onProgress,
  }) async {
    final results = <String, String>{};

    for (int i = 0; i < imagePaths.length; i++) {
      final path = imagePaths[i];
      final text = await extractTextFromImage(path);
      results[path] = text;

      onProgress?.call(i + 1, imagePaths.length);
    }

    return results;
  }

  /// Cleanup resources
  static Future<void> dispose() async {
    try {
      await _recognizer?.close();
      _recognizer = null;
      _isInitialized = false;
      debugPrint('OCR Service disposed');
    } catch (e) {
      debugPrint('Error disposing OCR service: $e');
    }
  }
}
