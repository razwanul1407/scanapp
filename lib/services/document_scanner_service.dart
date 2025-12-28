import 'dart:io';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for scanning documents with automatic edge detection and cropping
class DocumentScannerService {
  /// Scan a single document page
  /// Returns the path to the scanned image, or null if cancelled
  static Future<String?> scanSinglePage() async {
    if (!await _requestCameraPermission()) {
      debugPrint('Camera permission denied');
      return null;
    }

    try {
      final images = await CunningDocumentScanner.getPictures(
        noOfPages: 1,
        isGalleryImportAllowed: true,
      );

      if (images != null && images.isNotEmpty) {
        debugPrint('Scanned image: ${images.first}');
        return images.first;
      }
      debugPrint('No images returned from scanner');
      return null;
    } catch (e, stack) {
      debugPrint('Error scanning document: $e');
      debugPrint('Stack trace: $stack');
      rethrow;
    }
  }

  /// Scan multiple document pages
  /// Returns list of paths to scanned images, or empty list if cancelled
  static Future<List<String>> scanMultiplePages({int? maxPages}) async {
    if (!await _requestCameraPermission()) {
      debugPrint('Camera permission denied');
      return [];
    }

    try {
      final images = await CunningDocumentScanner.getPictures(
        noOfPages: maxPages ?? 10,
        isGalleryImportAllowed: true,
      );

      debugPrint('Scanned ${images?.length ?? 0} images');
      return images ?? [];
    } catch (e, stack) {
      debugPrint('Error scanning documents: $e');
      debugPrint('Stack trace: $stack');
      rethrow;
    }
  }

  /// Import from gallery and apply edge detection
  static Future<String?> importFromGallery() async {
    if (!await _requestStoragePermission()) {
      return null;
    }

    try {
      final images = await CunningDocumentScanner.getPictures(
        noOfPages: 1,
        isGalleryImportAllowed: true,
      );

      if (images != null && images.isNotEmpty) {
        return images.first;
      }
      return null;
    } catch (e) {
      print('Error importing from gallery: $e');
      return null;
    }
  }

  /// Request camera permission
  static Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request storage permission (for gallery access)
  static Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
    }
    return true;
  }

  /// Check if camera permission is granted
  static Future<bool> hasCameraPermission() async {
    return await Permission.camera.isGranted;
  }
}
