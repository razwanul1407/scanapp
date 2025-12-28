import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:scanapp/models/scanned_document.dart';
import 'package:scanapp/providers/documents_provider.dart';

class DocumentDetailScreen extends StatefulWidget {
  final ScannedDocument document;

  const DocumentDetailScreen({
    super.key,
    required this.document,
  });

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.title),
        centerTitle: true,
        actions: [
          Consumer<DocumentsProvider>(
            builder: (context, provider, _) => IconButton(
              icon: Icon(
                widget.document.isFavorite
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: widget.document.isFavorite ? Colors.red : null,
              ),
              onPressed: () {
                provider.toggleFavorite(widget.document.id!);
              },
            ),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Delete'),
                onTap: () {
                  _showDeleteDialog(context);
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Image Viewer
          Expanded(
            child: widget.document.imagePaths.isEmpty
                ? Center(
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
                          'No images in this document',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemCount: widget.document.imagePaths.length,
                    itemBuilder: (context, index) {
                      final imagePath = widget.document.imagePaths[index];
                      return GestureDetector(
                        onTap: () {
                          // Full screen image view
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  _FullScreenImageView(imagePath: imagePath),
                            ),
                          );
                        },
                        child: Container(
                          color: Colors.black,
                          child: _buildImageWidget(imagePath),
                        ),
                      );
                    },
                  ),
          ),

          // Page Indicator & Info
          if (widget.document.imagePaths.isNotEmpty)
            Container(
              color: Colors.grey[900],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Page ${_currentPage + 1} of ${widget.document.imagePaths.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.document.imagePaths.length > 1)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left,
                              color: Colors.white),
                          onPressed: _currentPage > 0
                              ? () => _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  )
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right,
                              color: Colors.white),
                          onPressed: _currentPage <
                                  widget.document.imagePaths.length - 1
                              ? () => _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  )
                              : null,
                        ),
                      ],
                    ),
                ],
              ),
            ),

          // Document Info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[900],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Document Details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _buildDetailRow('Title', widget.document.title),
                _buildDetailRow(
                  'Created',
                  DateFormat('MMM dd, yyyy').format(widget.document.createdAt),
                ),
                _buildDetailRow('Pages', '${widget.document.pageCount}'),
                if (widget.document.notes != null &&
                    widget.document.notes!.isNotEmpty)
                  _buildDetailRow('Notes', widget.document.notes!),
              ],
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Could not load image',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            );
          },
        );
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
    }

    return Center(
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
            'Image not found',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
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
              context
                  .read<DocumentsProvider>()
                  .deleteDocument(widget.document.id!);
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
        backgroundColor: Colors.black87,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: InteractiveViewer(
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
