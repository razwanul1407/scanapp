import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_service.dart';
import '../services/pdf_service.dart';
import '../widgets/image_source_dialog.dart';
import '../widgets/pdf_preview_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImageService _imageService = ImageService();
  final PdfService _pdfService = PdfService();
  bool _isProcessing = false;

  Future<void> _showImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (context) => ImageSourceDialog(
        onCameraSelected: () async {
          Navigator.pop(context);
          await _imageService.pickImage(
            context,
            source: ImageSource.camera,
            onImagePicked: _updateImage,
          );
        },
        onGallerySelected: () async {
          Navigator.pop(context);
          await _imageService.pickImage(
            context,
            source: ImageSource.gallery,
            onImagePicked: _updateImage,
          );
        },
      ),
    );
  }

  void _updateImage(File? image) {
    setState(() {
      _imageService.croppedImage = image;
    });
  }

  Future<void> _createPdfAndShare() async {
    setState(() => _isProcessing = true);
    await _pdfService.createAndSharePdf(
      context,
      _imageService.croppedImage,
      onComplete: () => setState(
        () => _isProcessing = false,
      ),
    );
  }

  Future<void> _savePdfToStorage() async {
    setState(() => _isProcessing = true);
    await _pdfService.savePdfToStorage(
      context,
      _imageService.croppedImage,
      onComplete: () => setState(() => _isProcessing = false),
    );
    _clearSelection();
  }

  void _clearSelection() {
    setState(() {
      _imageService.clearSelection();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Creator'),
        actions: _imageService.croppedImage != null
            ? [
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSelection,
                ),
              ]
            : null,
      ),
      body: Center(
        child: _isProcessing
            ? const CircularProgressIndicator()
            : PdfPreviewWidget(
                image: _imageService.croppedImage,
                onSave: _savePdfToStorage,
                onShare: _createPdfAndShare,
              ),
      ),
      floatingActionButton: _imageService.croppedImage == null
          ? FloatingActionButton.extended(
              onPressed: _showImageSourceDialog,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Add Image'),
            )
          : null,
    );
  }
}
