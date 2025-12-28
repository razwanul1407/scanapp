import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scanapp/providers/image_editing_provider.dart';
import 'package:scanapp/providers/document_builder_provider.dart';
import 'package:scanapp/services/image_processor.dart';
import 'package:scanapp/routes/app_router.dart';
import 'package:scanapp/l10n/app_localizations.dart';

class ImageEditingScreen extends StatefulWidget {
  final VoidCallback onEditComplete;

  const ImageEditingScreen({
    super.key,
    required this.onEditComplete,
  });

  @override
  State<ImageEditingScreen> createState() => _ImageEditingScreenState();
}

class _ImageEditingScreenState extends State<ImageEditingScreen> {
  DocumentFilter _selectedFilter = DocumentFilter.original;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editScan),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() => _selectedFilter = DocumentFilter.original);
              context.read<ImageEditingProvider>().resetAdjustments();
            },
            icon: const Icon(Icons.refresh),
            label: Text(l10n.reset),
          ),
        ],
      ),
      body: Consumer<ImageEditingProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Image Preview - Expanded
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: provider.currentImageBytes != null
                        ? Image.memory(
                            provider.currentImageBytes!,
                            fit: BoxFit.contain,
                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),

              // Document Filters (CamScanner-like)
              Container(
                height: 100,
                color: Colors.grey[100],
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: DocumentFilter.values.length,
                  itemBuilder: (context, index) {
                    final filter = DocumentFilter.values[index];
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: provider.isProcessing
                            ? null
                            : () => _applyFilter(provider, filter),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey[300]!,
                                  width: isSelected ? 3 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Icon(
                                _getFilterIcon(filter),
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getFilterLabel(filter, l10n),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Quick Actions: Rotate
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: provider.isProcessing
                            ? null
                            : () => provider.rotate(90),
                        icon: const Icon(Icons.rotate_left),
                        label: Text(l10n.rotateLeft),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: provider.isProcessing
                            ? null
                            : () => provider.rotate(-90),
                        icon: const Icon(Icons.rotate_right),
                        label: Text(l10n.rotateRight),
                      ),
                    ),
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
                          // Clear everything and go back to home
                          context
                              .read<DocumentBuilderProvider>()
                              .clearAllImages();
                          context
                              .read<ImageEditingProvider>()
                              .resetAdjustments();
                          context.go(AppRouter.home);
                        },
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: provider.isProcessing
                            ? null
                            : () {
                                Navigator.pop(context);
                                widget.onEditComplete();
                              },
                        child: provider.isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(l10n.done),
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

  Future<void> _applyFilter(
      ImageEditingProvider provider, DocumentFilter filter) async {
    setState(() => _selectedFilter = filter);
    await provider.applyDocumentFilter(filter);
  }

  IconData _getFilterIcon(DocumentFilter filter) {
    switch (filter) {
      case DocumentFilter.original:
        return Icons.image;
      case DocumentFilter.autoEnhance:
        return Icons.auto_fix_high;
      case DocumentFilter.magicColor:
        return Icons.auto_awesome;
      case DocumentFilter.blackWhite:
        return Icons.filter_b_and_w;
      case DocumentFilter.grayscale:
        return Icons.gradient;
      case DocumentFilter.highContrast:
        return Icons.contrast;
    }
  }

  String _getFilterLabel(DocumentFilter filter, AppLocalizations l10n) {
    switch (filter) {
      case DocumentFilter.original:
        return l10n.original;
      case DocumentFilter.autoEnhance:
        return l10n.autoEnhance;
      case DocumentFilter.magicColor:
        return l10n.magicColor;
      case DocumentFilter.blackWhite:
        return l10n.blackWhite;
      case DocumentFilter.grayscale:
        return l10n.grayscale;
      case DocumentFilter.highContrast:
        return l10n.highContrast;
    }
  }
}
