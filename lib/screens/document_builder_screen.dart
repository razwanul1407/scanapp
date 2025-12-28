import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scanapp/providers/document_builder_provider.dart';
import 'package:scanapp/routes/app_router.dart';
import 'package:scanapp/services/pdf_service.dart';
import 'package:scanapp/l10n/app_localizations.dart';

class DocumentBuilderScreen extends StatefulWidget {
  final VoidCallback onDocumentBuilt;

  const DocumentBuilderScreen({
    super.key,
    required this.onDocumentBuilt,
  });

  @override
  State<DocumentBuilderScreen> createState() => _DocumentBuilderScreenState();
}

class _DocumentBuilderScreenState extends State<DocumentBuilderScreen> {
  late TextEditingController _titleController;
  String _selectedExportFormat = 'pdf';
  CompressionQuality _selectedCompression = CompressionQuality.medium;
  String _estimatedSize = '';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: context.read<DocumentBuilderProvider>().documentTitle,
    );
    _updateEstimatedSize();
  }

  Future<void> _updateEstimatedSize() async {
    final provider = context.read<DocumentBuilderProvider>();
    if (provider.scannedImages.isEmpty) {
      setState(() => _estimatedSize = '');
      return;
    }

    final size = await PdfService.estimatePdfSize(
      imageFiles: provider.scannedImages,
      compression: _selectedCompression,
    );
    if (mounted) {
      setState(() => _estimatedSize = PdfService.formatFileSize(size));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _scanMorePages(BuildContext context) {
    // Navigate to camera in "add more" mode
    // The router will handle returning to document builder after capture
    context.push(AppRouter.cameraAddMore);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.buildDocument),
        centerTitle: true,
      ),
      body: Consumer<DocumentBuilderProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Document Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _titleController,
                  onChanged: (value) => provider.setDocumentTitle(value),
                  decoration: InputDecoration(
                    labelText: l10n.documentTitle,
                    hintText: l10n.enterDocumentName,
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // Image List with Reordering
              Expanded(
                child: provider.scannedImages.isEmpty
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
                              l10n.noImages,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => _scanMorePages(context),
                              icon: const Icon(Icons.add_a_photo),
                              label: Text(l10n.scanDocument),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Add More Pages Button
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _scanMorePages(context),
                                icon: const Icon(Icons.add_a_photo),
                                label: Text(
                                    '${l10n.scanMorePages} (${provider.pageCount} ${l10n.pagesAdded})'),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ),
                          // Image List
                          Expanded(
                            child: ReorderableListView(
                              onReorder: (oldIndex, newIndex) {
                                provider.reorderImages(oldIndex, newIndex);
                              },
                              children: [
                                for (int i = 0;
                                    i < provider.scannedImages.length;
                                    i++)
                                  _buildImageTile(
                                    key: ValueKey(i),
                                    index: i,
                                    imagePath: provider.scannedImages[i],
                                    onRemove: () => provider.removeImage(i),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),

              // Export Format Selection
              Container(
                color: Colors.grey[100],
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.exportFormat,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildFormatOption(
                          format: 'pdf',
                          icon: Icons.picture_as_pdf,
                          label: 'PDF',
                        ),
                        const SizedBox(width: 12),
                        _buildFormatOption(
                          format: 'png',
                          icon: Icons.image,
                          label: 'PNG',
                        ),
                        const SizedBox(width: 12),
                        _buildFormatOption(
                          format: 'jpg',
                          icon: Icons.photo,
                          label: 'JPEG',
                        ),
                      ],
                    ),

                    // Compression Quality (only for PDF)
                    if (_selectedExportFormat == 'pdf') ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.compression,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_estimatedSize.isNotEmpty)
                            Text(
                              'Est. size: $_estimatedSize',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: CompressionQuality.values.map((quality) {
                          final isSelected = _selectedCompression == quality;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: quality != CompressionQuality.values.last
                                    ? 8
                                    : 0,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  setState(
                                      () => _selectedCompression = quality);
                                  _updateEstimatedSize();
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    color: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.1)
                                        : Colors.transparent,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getCompressionLabel(quality, l10n),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Clear and go back to home
                          context
                              .read<DocumentBuilderProvider>()
                              .clearAllImages();
                          context.go(AppRouter.home);
                        },
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: provider.isReadyToExport
                            ? () async {
                                provider.setExportFormat(
                                  _selectedExportFormat,
                                );

                                // Show loading dialog
                                if (context.mounted) {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const AlertDialog(
                                      content: SizedBox(
                                        height: 100,
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                try {
                                  // Save document to database
                                  await provider.saveDocument();

                                  if (context.mounted) {
                                    Navigator.pop(
                                        context); // Close loading dialog
                                    widget.onDocumentBuilt();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    Navigator.pop(
                                        context); // Close loading dialog
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Error saving document: $e')),
                                    );
                                  }
                                }
                              }
                            : null,
                        child: Text(l10n.exportAndSave),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImageTile({
    required Key key,
    required int index,
    required File imagePath,
    required VoidCallback onRemove,
  }) {
    final l10n = AppLocalizations.of(context);
    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: index,
          child: Icon(
            Icons.drag_handle,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text('${l10n.page} ${index + 1}'),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onRemove,
        ),
      ),
    );
  }

  String _getCompressionLabel(
      CompressionQuality quality, AppLocalizations l10n) {
    switch (quality) {
      case CompressionQuality.high:
        return l10n.high;
      case CompressionQuality.medium:
        return l10n.medium;
      case CompressionQuality.low:
        return l10n.low;
    }
  }

  Widget _buildFormatOption({
    required String format,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedExportFormat == format;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedExportFormat = format;
          });
          context.read<DocumentBuilderProvider>().setExportFormat(format);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[600],
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
