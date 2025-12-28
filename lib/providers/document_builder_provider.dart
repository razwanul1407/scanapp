import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scanapp/services/database_service.dart';
import 'package:scanapp/models/scanned_document.dart';

class DocumentBuilderProvider extends ChangeNotifier {
  final List<File> _scannedImages = [];
  String _documentTitle = 'Scanned Document';
  String _selectedExportFormat = 'pdf'; // 'pdf', 'jpg', 'png'
  bool _isExporting = false;

  List<File> get scannedImages => _scannedImages;
  String get documentTitle => _documentTitle;
  String get selectedExportFormat => _selectedExportFormat;
  bool get isExporting => _isExporting;
  int get pageCount => _scannedImages.length;
  bool get isEmpty => _scannedImages.isEmpty;
  bool get hasMultiplePages => _scannedImages.length > 1;

  /// Add scanned image to document
  void addImage(File imageFile) {
    _scannedImages.add(imageFile);
    notifyListeners();
  }

  /// Add multiple images
  void addImages(List<File> imageFiles) {
    _scannedImages.addAll(imageFiles);
    notifyListeners();
  }

  /// Remove image at index
  void removeImage(int index) {
    if (index >= 0 && index < _scannedImages.length) {
      _scannedImages.removeAt(index);
      notifyListeners();
    }
  }

  /// Reorder images
  void reorderImages(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final image = _scannedImages.removeAt(oldIndex);
    _scannedImages.insert(newIndex, image);
    notifyListeners();
  }

  /// Replace image at index
  void replaceImage(int index, File newImage) {
    if (index >= 0 && index < _scannedImages.length) {
      _scannedImages[index] = newImage;
      notifyListeners();
    }
  }

  /// Set document title
  void setDocumentTitle(String title) {
    _documentTitle = title.isEmpty ? 'Scanned Document' : title;
    notifyListeners();
  }

  /// Set export format
  void setExportFormat(String format) {
    if (['pdf', 'jpg', 'png'].contains(format)) {
      _selectedExportFormat = format;
      notifyListeners();
    }
  }

  /// Set exporting state
  void setExporting(bool value) {
    _isExporting = value;
    notifyListeners();
  }

  /// Clear all images
  void clearAllImages() {
    _scannedImages.clear();
    notifyListeners();
  }

  /// Get image at index
  File? getImage(int index) {
    if (index >= 0 && index < _scannedImages.length) {
      return _scannedImages[index];
    }
    return null;
  }

  /// Export document (placeholder - implementation in service)
  Future<File?> exportDocument() async {
    setExporting(true);

    try {
      // Export logic will be handled by service
      // This provider just manages the state
      await Future.delayed(const Duration(seconds: 1)); // Simulate export
      return null;
    } finally {
      setExporting(false);
    }
  }

  /// Undo (remove last added image)
  void undoLastImage() {
    if (_scannedImages.isNotEmpty) {
      _scannedImages.removeLast();
      notifyListeners();
    }
  }

  /// Check if document is ready to export
  bool get isReadyToExport =>
      _scannedImages.isNotEmpty && _documentTitle.isNotEmpty;

  /// Save document to database
  Future<int> saveDocument() async {
    try {
      final imagePaths = _scannedImages.map((f) => f.path).toList();

      final id = await DatabaseService.saveDocument(
        ScannedDocument(
          title: _documentTitle,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          imagePaths: imagePaths,
          thumbnailPath: imagePaths.isNotEmpty ? imagePaths.first : null,
          tags: [],
          notes: 'Exported as $_selectedExportFormat',
          pageCount: _scannedImages.length,
          fileSize: 0,
          isFavorite: false,
          lastExportFormat: _selectedExportFormat,
        ),
      );

      print('Document saved to database with id: $id');
      return id;
    } catch (e) {
      print('Error saving document: $e');
      rethrow;
    }
  }
}
