import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:scanapp/models/scanned_document.dart';
import 'package:scanapp/providers/documents_provider.dart';
import 'package:scanapp/services/pdf_service.dart';

/// Screen for viewing single-image documents with a simplified UI
class SingleImageDetailScreen extends StatelessWidget {
  final ScannedDocument document;

  const SingleImageDetailScreen({
    super.key,
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath =
        document.imagePaths.isNotEmpty ? document.imagePaths.first : null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        elevation: 0,
        title: Text(
          document.title,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer<DocumentsProvider>(
            builder: (context, provider, _) => IconButton(
              icon: Icon(
                document.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: document.isFavorite ? Colors.red : Colors.white,
              ),
              onPressed: () {
                provider.toggleFavorite(document.id!);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _shareDocument(context),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteDialog(context);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Full Image View
          Expanded(
            child: imagePath != null
                ? GestureDetector(
                    onTap: () => _openFullScreen(context, imagePath),
                    child: InteractiveViewer(
                      child: Center(
                        child: _buildImageWidget(imagePath),
                      ),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No image found',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
          ),

          // Bottom Info Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Document Title
                  Text(
                    document.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Date Info
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM dd, yyyy • HH:mm')
                            .format(document.createdAt),
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ],
                  ),

                  if (document.notes != null && document.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes, size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            document.notes!,
                            style: TextStyle(color: Colors.grey[400]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _exportAsPdf(context, imagePath),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Export PDF'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _shareDocument(context),
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String imagePath) {
    try {
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Could not load image',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error loading image: $e');
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_not_supported, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          'Image not found',
          style: TextStyle(color: Colors.grey[400]),
        ),
      ],
    );
  }

  void _openFullScreen(BuildContext context, String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenImageView(imagePath: imagePath),
      ),
    );
  }

  Future<void> _shareDocument(BuildContext context) async {
    if (document.imagePaths.isEmpty) return;

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(document.imagePaths.first)],
          text: document.title,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }

  Future<void> _exportAsPdf(BuildContext context, String? imagePath) async {
    if (imagePath == null) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );

      final pdfBytes = await PdfService.createPdfFromImage(
        imageFile: File(imagePath),
        title: document.title,
      );

      final pdfFile = await PdfService.savePdf(
        pdfBytes: pdfBytes,
        filename: '${document.title.replaceAll(' ', '_')}.pdf',
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        // Show success and share option
        final shouldShare = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('PDF Created'),
            content:
                const Text('PDF has been saved. Would you like to share it?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Share'),
              ),
            ],
          ),
        );

        if (shouldShare == true) {
          await PdfService.sharePdf(pdfFile);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating PDF: $e')),
        );
      }
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<DocumentsProvider>().deleteDocument(document.id!);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close detail screen
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// Full screen image viewer
class _FullScreenImageView extends StatelessWidget {
  final String imagePath;

  const _FullScreenImageView({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.file(
              File(imagePath),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
