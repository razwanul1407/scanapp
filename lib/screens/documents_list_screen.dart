import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scanapp/models/scanned_document.dart';
import 'package:scanapp/providers/documents_provider.dart';
import 'package:scanapp/screens/document_detail_screen.dart';
import 'package:scanapp/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

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
      if (mounted) {
        context.read<DocumentsProvider>().loadDocuments();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myDocuments),
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
                        hintText: l10n.searchDocuments,
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
                                Text(l10n.sortByDate),
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
                                Text(l10n.sortByName),
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
                                Text(l10n.sortBySize),
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

              // Documents List/Grid with Sections
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
                                  l10n.noDocumentsFound,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.add),
                                  label: Text(
                                    l10n.scanYourFirstDocument,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildDocumentsList(
                            context, provider, l10n, _isGridView),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    int docId,
    DocumentsProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteDocument),
        content: Text(
          AppLocalizations.of(context).deleteConfirmation,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              provider.deleteDocument(docId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context).documentDeleted),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList(
    BuildContext context,
    DocumentsProvider provider,
    AppLocalizations l10n,
    bool isGridView,
  ) {
    // Separate documents into scanned and OCR
    final scannedDocs =
        provider.documents.where((doc) => !doc.tags.contains('ocr')).toList();
    final ocrDocs =
        provider.documents.where((doc) => doc.tags.contains('ocr')).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Scanned Documents Section
        if (scannedDocs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.document_scanner,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Scanned Documents',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          ...scannedDocs
              .map((doc) => _buildDocumentCard(context, doc, provider)),
          Divider(height: 24, thickness: 1),
        ],

        // OCR Documents Section
        if (ocrDocs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.text_fields, color: Colors.green),
                const SizedBox(width: 12),
                Text(
                  'OCR Extractions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          ...ocrDocs.map((doc) => _buildDocumentCard(context, doc, provider)),
        ],

        // Empty state for both
        if (scannedDocs.isEmpty && ocrDocs.isEmpty)
          Center(
            child: Text(l10n.noDocumentsFound),
          ),
      ],
    );
  }

  Widget _buildDocumentCard(
    BuildContext context,
    ScannedDocument doc,
    DocumentsProvider provider,
  ) {
    final isOcr = doc.tags.contains('ocr');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isOcr ? Colors.green.shade100 : Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isOcr ? Icons.text_fields : Icons.image,
            color: isOcr ? Colors.green : Colors.blue,
          ),
        ),
        title: Text(doc.title),
        subtitle: Text(
          '${doc.pageCount} ${doc.pageCount == 1 ? 'page' : 'pages'} • ${DateFormat('MMM dd, yyyy').format(doc.createdAt)}',
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('View'),
              onTap: () {
                if (isOcr && doc.imagePaths.isNotEmpty) {
                  // OCR files - show text preview
                  _showTextPreview(context, doc);
                } else if (!isOcr && doc.imagePaths.isNotEmpty) {
                  // Scanned documents - show image
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DocumentDetailScreen(document: doc),
                    ),
                  );
                }
              },
            ),
            PopupMenuItem(
              child: const Text('Delete'),
              onTap: () {
                if (doc.id != null) {
                  _showDeleteDialog(context, doc.id!, provider);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTextPreview(BuildContext context, ScannedDocument doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(doc.title),
        content: SingleChildScrollView(
          child: SelectableText(
            doc.extractedText ?? 'No text content',
            style: const TextStyle(height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
