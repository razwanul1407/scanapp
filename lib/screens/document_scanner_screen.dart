import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scanapp/services/document_scanner_service.dart';
import 'package:scanapp/providers/image_editing_provider.dart';
import 'package:scanapp/providers/document_builder_provider.dart';
import 'package:scanapp/l10n/app_localizations.dart';

/// Document scanner screen using native edge detection
class DocumentScannerScreen extends StatefulWidget {
  final Function(List<File>) onImagesScanned;
  final bool allowMultiple;
  final bool isNewSession;

  const DocumentScannerScreen({
    super.key,
    required this.onImagesScanned,
    this.allowMultiple = false,
    this.isNewSession = false,
  });

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  bool _isScanning = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Start scanning immediately when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clear previous session if this is a new scan
      if (widget.isNewSession) {
        context.read<DocumentBuilderProvider>().clearAllImages();
      }
      _startScan();
    });
  }

  Future<void> _startScan() async {
    if (_isScanning || _hasNavigated) return;

    setState(() => _isScanning = true);

    try {
      List<String> imagePaths;

      if (widget.allowMultiple) {
        // Multi-page scanning
        imagePaths = await DocumentScannerService.scanMultiplePages();
      } else {
        // Single page scan
        final path = await DocumentScannerService.scanSinglePage();
        imagePaths = path != null ? [path] : [];
      }

      if (!mounted || _hasNavigated) return;

      if (imagePaths.isNotEmpty) {
        final files = imagePaths.map((p) => File(p)).toList();

        // Load first image into editing provider for preview
        if (files.isNotEmpty && mounted) {
          context.read<ImageEditingProvider>().loadImage(files.first);
        }

        _hasNavigated = true;

        // Small delay to ensure state is ready
        await Future.delayed(const Duration(milliseconds: 100));

        if (mounted) {
          widget.onImagesScanned(files);
        }
      } else {
        // User cancelled - go back
        _hasNavigated = true;
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Scanning error: $e');
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.scanningFailed}: ${e.toString()}')),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // This screen is mainly a launcher for the native scanner
    // Show loading while scanner is being prepared
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              _isScanning ? l10n.openingScanner : l10n.preparing,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
