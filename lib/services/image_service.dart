import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageService {
  /// Pick image from gallery
  static Future<File?> pickFromGallery() async {
    try {
      // Note: In real implementation, use image_picker package
      // This is placeholder for image selection logic
      return null;
    } catch (e) {
      print('Error picking from gallery: $e');
      return null;
    }
  }

  /// Detect document edges (using edge_detection package)
  static Future<File?> detectDocumentEdges(String imagePath) async {
    try {
      // Note: edge_detection package has platform-specific implementation
      // For now, return null as placeholder
      // In production, implement using:
      // final croppedImagePath = await EdgeDetection.detectEdges(imagePath: imagePath);
      return null;
    } catch (e) {
      print('Error detecting edges: $e');
      return null;
    }
  }

  /// Save image to local storage with timestamp
  static Future<File> saveImage(File imageFile, {String? customName}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final scansDir = Directory('${directory.path}/scans');

      if (!await scansDir.exists()) {
        await scansDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = customName ?? 'scan_$timestamp.jpg';
      final filepath = path.join(scansDir.path, filename);

      final savedFile = await imageFile.copy(filepath);
      return savedFile;
    } catch (e) {
      print('Error saving image: $e');
      rethrow;
    }
  }

  /// Create thumbnail from image
  static Future<File?> createThumbnail(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final thumbDir = Directory('${directory.path}/thumbnails');

      if (!await thumbDir.exists()) {
        await thumbDir.create(recursive: true);
      }

      final filename =
          'thumb_${path.basenameWithoutExtension(imageFile.path)}.jpg';
      final thumbPath = path.join(thumbDir.path, filename);

      // For now, just copy the image as thumbnail
      // In production, you'd resize and optimize the image
      final thumbFile = await imageFile.copy(thumbPath);
      return thumbFile;
    } catch (e) {
      print('Error creating thumbnail: $e');
      return null;
    }
  }

  /// Delete image file
  static Future<bool> deleteImage(File imageFile) async {
    try {
      if (await imageFile.exists()) {
        await imageFile.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Get image file size in bytes
  static Future<int> getImageFileSize(File imageFile) async {
    try {
      final stat = await imageFile.stat();
      return stat.size;
    } catch (e) {
      print('Error getting file size: $e');
      return 0;
    }
  }

  /// Verify image file exists and is readable
  static Future<bool> verifyImageFile(File imageFile) async {
    try {
      return await imageFile.exists();
    } catch (e) {
      print('Error verifying image: $e');
      return false;
    }
  }
}
