import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scanapp/providers/image_editing_provider.dart';
import 'package:scanapp/providers/document_builder_provider.dart';
import 'package:scanapp/services/image_processor.dart';
import 'package:scanapp/services/ocr_service.dart';
import 'package:scanapp/routes/app_router.dart';
import 'package:scanapp/l10n/app_localizations.dart';

class ImageEditingScreen extends StatefulWidget {
  final VoidCallback onEditComplete;
  final int initialTabIndex;

  const ImageEditingScreen({
    super.key,
    required this.onEditComplete,
    this.initialTabIndex = 0, // 0 = Filter, 1 = OCR
  });

  @override
  State<ImageEditingScreen> createState() => _ImageEditingScreenState();
}

class _ImageEditingScreenState extends State<ImageEditingScreen> {
  DocumentFilter _selectedFilter = DocumentFilter.original;
  String _extractedText = '';
  bool _ocrProcessing = false;
  int _currentImageIndex = 0;
  late PageController _filterPageController;
  late PageController _ocrPageController;

  @override
  void initState() {
    super.initState();
    _filterPageController = PageController();
    _ocrPageController = PageController();

    // Sync page controllers when either one changes
    _filterPageController.addListener(() {
      if (_filterPageController.hasClients && _ocrPageController.hasClients) {
        _ocrPageController.jumpToPage(_filterPageController.page!.round());
      }
    });

    _ocrPageController.addListener(() {
      if (_filterPageController.hasClients && _ocrPageController.hasClients) {
        _filterPageController.jumpToPage(_ocrPageController.page!.round());
      }
    });
  }

  @override
  void dispose() {
    _filterPageController.dispose();
    _ocrPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<DocumentBuilderProvider>(
      builder: (context, builderProvider, _) {
        final totalImages = builderProvider.scannedImages.length;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (mounted) {
              context.read<DocumentBuilderProvider>().clearAllImages();
              context.read<ImageEditingProvider>().resetAdjustments();
              context.go(AppRouter.home);
            }
          },
          child: DefaultTabController(
            length: 2,
            initialIndex: widget.initialTabIndex,
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  '${l10n.editScan} (${_currentImageIndex + 1}/$totalImages)',
                  style: const TextStyle(fontSize: 16),
                ),
                centerTitle: true,
                bottom: TabBar(
                  tabs: [
                    Tab(text: l10n.filter),
                    Tab(text: l10n.ocrTab),
                  ],
                ),
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
              body: TabBarView(
                children: [
                  _buildFilterTab(context, l10n, totalImages),
                  _buildOcrTab(context, l10n, totalImages),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterTab(
      BuildContext context, AppLocalizations l10n, int totalImages) {
    return Consumer2<ImageEditingProvider, DocumentBuilderProvider>(
      builder: (context, imageProvider, builderProvider, _) {
        return Column(
          children: [
            // Image Preview with Navigation
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _filterPageController,
                      onPageChanged: (index) {
                        setState(() => _currentImageIndex = index);
                        if (builderProvider.scannedImages.isNotEmpty &&
                            index < builderProvider.scannedImages.length) {
                          imageProvider
                              .loadImage(builderProvider.scannedImages[index]);
                        }
                      },
                      itemCount: builderProvider.scannedImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: imageProvider.currentImageBytes != null
                                ? Image.memory(
                                    imageProvider.currentImageBytes!,
                                    fit: BoxFit.contain,
                                  )
                                : const Center(
                                    child: CircularProgressIndicator()),
                          ),
                        );
                      },
                    ),
                  ),
                  // Page indicator
                  if (totalImages > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_currentImageIndex > 0)
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () {
                                _filterPageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          Text(
                            '${_currentImageIndex + 1} / $totalImages',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (_currentImageIndex < totalImages - 1)
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () {
                                _filterPageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Document Filters
            SizedBox(
              height: 100,
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
                      onTap: imageProvider.isProcessing
                          ? null
                          : () => _applyFilter(imageProvider, filter),
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
                              color: isSelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.1)
                                  : Colors.grey[200],
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: imageProvider.isProcessing
                          ? null
                          : () => imageProvider.rotate(90),
                      icon: const Icon(Icons.rotate_left),
                      label: Text(l10n.rotateLeft),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: imageProvider.isProcessing
                          ? null
                          : () => imageProvider.rotate(-90),
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
                        context
                            .read<DocumentBuilderProvider>()
                            .clearAllImages();
                        context.read<ImageEditingProvider>().resetAdjustments();
                        context.go(AppRouter.home);
                      },
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: imageProvider.isProcessing
                          ? null
                          : () {
                              Navigator.pop(context);
                              widget.onEditComplete();
                            },
                      child: imageProvider.isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
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
    );
  }

  Widget _buildOcrTab(
      BuildContext context, AppLocalizations l10n, int totalImages) {
    return Consumer2<ImageEditingProvider, DocumentBuilderProvider>(
      builder: (context, imageProvider, builderProvider, _) {
        return Column(
          children: [
            // Image Preview with Navigation
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _ocrPageController,
                      onPageChanged: (index) {
                        setState(() => _currentImageIndex = index);
                        if (builderProvider.scannedImages.isNotEmpty &&
                            index < builderProvider.scannedImages.length) {
                          imageProvider
                              .loadImage(builderProvider.scannedImages[index]);
                        }
                      },
                      itemCount: builderProvider.scannedImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: imageProvider.currentImageBytes != null
                                ? Image.memory(
                                    imageProvider.currentImageBytes!,
                                    fit: BoxFit.contain,
                                  )
                                : const Center(
                                    child: CircularProgressIndicator()),
                          ),
                        );
                      },
                    ),
                  ),
                  // Page indicator
                  if (totalImages > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_currentImageIndex > 0)
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () {
                                _ocrPageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          Text(
                            '${_currentImageIndex + 1} / $totalImages',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (_currentImageIndex < totalImages - 1)
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () {
                                _ocrPageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Extracted Text Display
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.extractedText,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (_extractedText.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.content_copy),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.copiedToClipboard)),
                              );
                            },
                            tooltip: 'Copy text',
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _extractedText.isEmpty && !_ocrProcessing
                              ? l10n.noTextExtracted
                              : _extractedText,
                          style: const TextStyle(height: 1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // OCR Action Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _extractedText = '';
                              _ocrProcessing = false;
                            });
                          },
                          child: Text(l10n.clear),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _ocrProcessing
                              ? null
                              : () => _extractTextWithOcr(context),
                          icon: _ocrProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.text_fields),
                          label: Text(_ocrProcessing
                              ? l10n.processing
                              : l10n.extractText),
                        ),
                      ),
                    ],
                  ),
                  // Done button - shows only when text is extracted
                  if (_extractedText.isNotEmpty && !_ocrProcessing) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to text export screen
                          context.push(
                            AppRouter.textExport,
                            extra: _extractedText,
                          );
                        },
                        child: Text(l10n.done),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _extractTextWithOcr(BuildContext context) async {
    final provider = context.read<ImageEditingProvider>();
    final l10n = AppLocalizations.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (provider.originalImage == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('No image available')),
      );
      return;
    }

    setState(() => _ocrProcessing = true);

    try {
      await OcrService.initialize();

      final text = await OcrService.extractTextFromImage(
        provider.originalImage!.path,
      );

      if (mounted) {
        setState(() {
          _extractedText = text;
          _ocrProcessing = false;
        });

        if (text.isEmpty) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(l10n.noTextFound)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _ocrProcessing = false);
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('${l10n.ocrError}: $e')),
        );
      }
    }
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
      case DocumentFilter.sepia:
        return Icons.filter_vintage;
      case DocumentFilter.blur:
        return Icons.blur_on;
      case DocumentFilter.sharpen:
        return Icons.settings_sharp;
      case DocumentFilter.invert:
        return Icons.invert_colors;
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
      case DocumentFilter.sepia:
        return 'Sepia';
      case DocumentFilter.blur:
        return 'Blur';
      case DocumentFilter.sharpen:
        return 'Sharpen';
      case DocumentFilter.invert:
        return 'Invert';
    }
  }
}
