import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:scanapp/services/image_processor.dart';

class ImageEditingProvider extends ChangeNotifier {
  File? _originalImage;
  Uint8List? _currentImageBytes;
  Uint8List? _baseImageBytes; // Base image before filters

  double _brightness = 0.0;
  double _contrast = 0.0;
  double _saturation = 0.0;
  bool _isGrayscale = false;
  int _rotation = 0;
  DocumentFilter _currentFilter = DocumentFilter.original;

  bool _isProcessing = false;

  File? get originalImage => _originalImage;
  Uint8List? get currentImageBytes => _currentImageBytes;
  Uint8List? get processedImageBytes => _currentImageBytes;

  double get brightness => _brightness;
  double get contrast => _contrast;
  double get saturation => _saturation;
  bool get isGrayscale => _isGrayscale;
  int get rotation => _rotation;
  DocumentFilter get currentFilter => _currentFilter;
  bool get isProcessing => _isProcessing;

  bool get hasChanges =>
      _brightness != 0.0 ||
      _contrast != 0.0 ||
      _saturation != 0.0 ||
      _isGrayscale ||
      _rotation != 0 ||
      _currentFilter != DocumentFilter.original;

  /// Load image for editing
  void loadImage(File imageFile) {
    _originalImage = imageFile;
    _currentImageBytes = imageFile.readAsBytesSync();
    _baseImageBytes = _currentImageBytes;
    _resetAdjustments();
    notifyListeners();
  }

  /// Load image from bytes (for scanned images)
  void loadImageFromBytes(Uint8List bytes, File? sourceFile) {
    _originalImage = sourceFile;
    _currentImageBytes = bytes;
    _baseImageBytes = bytes;
    _resetAdjustments();
    notifyListeners();
  }

  /// Apply document filter (CamScanner-like)
  Future<void> applyDocumentFilter(DocumentFilter filter) async {
    if (_baseImageBytes == null) return;

    _isProcessing = true;
    _currentFilter = filter;
    notifyListeners();

    try {
      _currentImageBytes = await ImageProcessor.applyFilter(
        _baseImageBytes!,
        filter,
      );
    } catch (e) {
      print('Error applying filter: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Update brightness
  Future<void> setBrightness(double value) async {
    _brightness = value;
    await _applyAdjustments();
  }

  /// Update contrast
  Future<void> setContrast(double value) async {
    _contrast = value;
    await _applyAdjustments();
  }

  /// Update saturation
  Future<void> setSaturation(double value) async {
    _saturation = value;
    await _applyAdjustments();
  }

  /// Toggle grayscale
  Future<void> toggleGrayscale() async {
    _isGrayscale = !_isGrayscale;
    await _applyAdjustments();
  }

  /// Rotate image
  Future<void> rotate(int degrees) async {
    if (_currentImageBytes == null) return;

    _isProcessing = true;
    notifyListeners();

    try {
      // Save current bytes to temp file for rotation
      final tempFile = await ImageProcessor.saveProcessedImage(
        imageBytes: _currentImageBytes!,
        filename: 'temp_rotate_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final rotated = await ImageProcessor.rotateImage(tempFile, degrees);
      _currentImageBytes = rotated;
      _baseImageBytes = rotated; // Update base for filters
      _rotation = (_rotation + degrees) % 360;
    } catch (e) {
      print('Error rotating: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Auto-enhance image
  Future<void> autoEnhance() async {
    if (_originalImage == null) return;

    _isProcessing = true;
    notifyListeners();

    try {
      _currentImageBytes = await ImageProcessor.autoEnhance(_originalImage!);
      _brightness = 0.0;
      _contrast = 0.0;
      _saturation = 0.0;
    } catch (e) {
      print('Error auto-enhancing: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Reset all adjustments
  void resetAdjustments() {
    _resetAdjustments();
    notifyListeners();
  }

  /// Get edited image file
  Future<File> getEditedImageFile() async {
    if (_currentImageBytes == null) {
      throw Exception('No image loaded');
    }

    return await ImageProcessor.saveProcessedImage(
      imageBytes: _currentImageBytes!,
      filename: 'edited_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }

  // Private methods

  void _resetAdjustments() {
    _brightness = 0.0;
    _contrast = 0.0;
    _saturation = 0.0;
    _isGrayscale = false;
    _rotation = 0;
    _currentFilter = DocumentFilter.original;

    if (_originalImage != null) {
      _currentImageBytes = _originalImage!.readAsBytesSync();
      _baseImageBytes = _currentImageBytes;
    }
  }

  Future<void> _applyAdjustments() async {
    if (_originalImage == null) return;

    _isProcessing = true;
    notifyListeners();

    try {
      _currentImageBytes = await ImageProcessor.applyAdjustments(
        imageFile: _originalImage!,
        brightness: _brightness,
        contrast: _contrast,
        saturation: _saturation,
        grayscale: _isGrayscale,
      );

      // Note: Rotation would be applied here if needed
      // For now, we'll handle it separately in the UI
    } catch (e) {
      print('Error applying adjustments: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
