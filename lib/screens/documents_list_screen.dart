import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scanapp/providers/documents_provider.dart';
import 'package:scanapp/screens/document_detail_screen.dart';
import 'package:scanapp/screens/single_image_detail_screen.dart';
import 'package:scanapp/services/pdf_service.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class DocumentsListScreen extends StatefulWidget {
  const DocumentsListScreen({super.key});

  @override
  State<DocumentsListScreen> createState() => _DocumentsListScreenState();
}

class _DocumentsListScreenState extends State<DocumentsListScreen> {
  late TextEditingController _searchController;
  bool _isGridView = true;
  String _sortBy = 'date';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    Future.microtask(() {
      context.read<DocumentsProvider>().loadDocuments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.list : Icons.grid_view,
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: Consumer<DocumentsProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => provider.searchDocuments(value),
                      decoration: InputDecoration(
                        hintText: 'Search documents...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.searchDocuments('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Sort Dropdown
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButton<String>(
                        value: _sortBy,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: 'date',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text('Sort by Date'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'name',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.abc,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text('Sort by Name'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'size',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.storage,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text('Sort by Size'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _sortBy = value;
                            });
                            provider.sortDocuments(value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Documents List/Grid
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.documents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.document_scanner,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No documents found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.add),
                                  label: const Text(
                                    'Scan Your First Document',
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _isGridView
                            ? GridView.builder(
                                padding: const EdgeInsets.all(12),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.75,
                                ),
                                itemCount: provider.documents.length,
                                itemBuilder: (context, index) {
                                  final doc = provider.documents[index];
                                  return _buildDocumentCard(
                                    doc: doc,
                                    provider: provider,
                                  );
                                },
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: provider.documents.length,
                                itemBuilder: (context, index) {
                                  final doc = provider.documents[index];
                                  return _buildDocumentListItem(
                                    doc: doc,
                                    provider: provider,
                                  );
                                },
                              ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Navigate to appropriate screen based on document's image count
  void _navigateToDocument(dynamic doc) {
    // Check if document has single image or multiple images
    final isSingleImage = doc.imagePaths.length == 1;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => isSingleImage
            ? SingleImageDetailScreen(document: doc)
            : DocumentDetailScreen(document: doc),
      ),
    );
  }

  Widget _buildDocumentCard({
    required dynamic doc,
    required DocumentsProvider provider,
  }) {
    return GestureDetector(
      onTap: () => _navigateToDocument(doc),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Stack(
                  children: [
                    // Show first image as thumbnail
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: doc.imagePaths.isNotEmpty &&
                              File(doc.imagePaths.first).existsSync()
                          ? Image.file(
                              File(doc.imagePaths.first),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : Center(
                              child: Icon(
                                Icons.document_scanner,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                            ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => provider.toggleFavorite(doc.id),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            doc.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('MMM dd, yyyy').format(doc.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Share action
                            _shareDocument(doc.id, provider);
                          },
                          icon: const Icon(Icons.share, size: 14),
                          label: const Text('Share'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentListItem({
    required dynamic doc,
    required DocumentsProvider provider,
  }) {
    return GestureDetector(
      onTap: () => _navigateToDocument(doc),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: doc.imagePaths.isNotEmpty &&
                      File(doc.imagePaths.first).existsSync()
                  ? Image.file(
                      File(doc.imagePaths.first),
                      fit: BoxFit.cover,
                      width: 50,
                      height: 50,
                    )
                  : Center(
                      child: Icon(
                        Icons.document_scanner,
                        size: 28,
                        color: Colors.grey[400],
                      ),
                    ),
            ),
          ),
          title: Text(
            doc.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM dd, yyyy').format(doc.createdAt),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                '${doc.pageCount} page${doc.pageCount > 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(
                      doc.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      doc.isFavorite ? 'Remove Favorite' : 'Add to Favorite',
                    ),
                  ],
                ),
                onTap: () => provider.toggleFavorite(doc.id),
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.share, size: 18),
                    SizedBox(width: 12),
                    Text('Share'),
                  ],
                ),
                onTap: () {
                  // Share action
                  _shareDocument(doc.id, provider);
                },
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 18),
                    SizedBox(width: 12),
                    Text('Delete'),
                  ],
                ),
                onTap: () => _showDeleteDialog(context, doc.id, provider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareDocument(int docId, DocumentsProvider provider) async {
    final doc = provider.documents.firstWhere((d) => d.id == docId);

    try {
      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing document...')),
      );

      // Convert image paths to File objects
      final imageFiles = doc.imagePaths.map((path) => File(path)).toList();

      // Create PDF from document images
      final pdfBytes = await PdfService.createMultiPagePdf(
        imageFiles: imageFiles,
        title: doc.title,
      );

      // Share the PDF
      await PdfService.sharePdfBytes(
        pdfBytes: pdfBytes,
        filename: doc.title,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document shared successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteDialog(
    BuildContext context,
    int docId,
    DocumentsProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text(
          'Are you sure you want to delete this document? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteDocument(docId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Document deleted'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
