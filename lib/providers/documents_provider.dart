import 'package:flutter/material.dart';
import 'package:scanapp/services/database_service.dart';
import 'package:scanapp/models/scanned_document.dart';

class DocumentsProvider extends ChangeNotifier {
  List<ScannedDocument> _documents = [];
  List<ScannedDocument> _filteredDocuments = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortBy = 'date'; // 'date', 'name', 'size'

  // Pagination
  static const int _pageSize = 30;
  int _currentPage = 0;
  List<ScannedDocument> _paginatedDocuments = [];

  List<ScannedDocument> get documents => _paginatedDocuments;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  int get documentCount => _filteredDocuments.length;
  int get totalCount => _documents.length;
  int get currentPage => _currentPage;
  bool get hasNextPage =>
      (_currentPage + 1) * _pageSize < _filteredDocuments.length;
  bool get hasPreviousPage => _currentPage > 0;

  /// Load all documents from database
  Future<void> loadDocuments() async {
    _isLoading = true;
    _currentPage = 0;
    notifyListeners();

    try {
      _documents = await DatabaseService.getAllDocuments();
      await _applyFilter();
      _updatePaginatedList();
    } catch (e) {
      debugPrint('Error loading documents: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load next page of documents
  void loadNextPage() {
    if (hasNextPage) {
      _currentPage++;
      _updatePaginatedList();
      notifyListeners();
    }
  }

  /// Load previous page of documents
  void loadPreviousPage() {
    if (hasPreviousPage) {
      _currentPage--;
      _updatePaginatedList();
      notifyListeners();
    }
  }

  /// Reset to first page
  void resetPagination() {
    _currentPage = 0;
    _updatePaginatedList();
    notifyListeners();
  }

  void _updatePaginatedList() {
    final startIndex = _currentPage * _pageSize;
    final endIndex = startIndex + _pageSize;
    final maxIndex = _filteredDocuments.length;

    if (startIndex >= maxIndex) {
      _paginatedDocuments = [];
      return;
    }

    _paginatedDocuments = _filteredDocuments.sublist(
      startIndex,
      endIndex > maxIndex ? maxIndex : endIndex,
    );
  }

  /// Save a new document
  Future<int> saveDocument({
    required String title,
    required List<String> imagePaths,
    required String? thumbnailPath,
    List<String>? tags,
    String? notes,
  }) async {
    try {
      final doc = ScannedDocument(
        title: title,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imagePaths: imagePaths,
        thumbnailPath: thumbnailPath,
        tags: tags ?? [],
        notes: notes,
        pageCount: imagePaths.length,
        fileSize: 0, // Will be calculated
        isFavorite: false,
      );

      final id = await DatabaseService.saveDocument(doc);
      await loadDocuments();
      return id;
    } catch (e) {
      debugPrint('Error saving document: $e');
      rethrow;
    }
  }

  /// Update existing document
  Future<void> updateDocument({
    required int id,
    String? title,
    List<String>? imagePaths,
    String? notes,
    List<String>? tags,
  }) async {
    try {
      final doc = await DatabaseService.getDocument(id);
      if (doc != null) {
        if (title != null) doc.title = title;
        if (imagePaths != null) {
          doc.imagePaths = imagePaths;
          doc.pageCount = imagePaths.length;
        }
        if (notes != null) doc.notes = notes;
        if (tags != null) doc.tags = tags;
        doc.updatedAt = DateTime.now();

        await DatabaseService.saveDocument(doc);
        await loadDocuments();
      }
    } catch (e) {
      debugPrint('Error updating document: $e');
      rethrow;
    }
  }

  /// Delete document
  Future<void> deleteDocument(int id) async {
    try {
      await DatabaseService.deleteDocument(id);
      await loadDocuments();
    } catch (e) {
      debugPrint('Error deleting document: $e');
      rethrow;
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(int id) async {
    try {
      await DatabaseService.toggleFavorite(id);
      await loadDocuments();
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      rethrow;
    }
  }

  /// Search documents
  void searchDocuments(String query) {
    _searchQuery = query;
    _currentPage = 0; // Reset to first page on new search
    _applyFilter();
    notifyListeners();
  }

  /// Sort documents
  void sortDocuments(String sortBy) {
    _sortBy = sortBy;
    _currentPage = 0; // Reset to first page on new sort
    _applySort();
    _updatePaginatedList();
    notifyListeners();
  }

  /// Get favorite documents
  List<ScannedDocument> getFavoriteDocuments() {
    return _documents.where((doc) => doc.isFavorite).toList();
  }

  /// Get all tags
  Future<List<String>> getAllTags() async {
    return await DatabaseService.getAllTags();
  }

  // Private methods

  Future<void> _applyFilter() async {
    if (_searchQuery.isEmpty) {
      _filteredDocuments = List.from(_documents);
    } else {
      _filteredDocuments = await DatabaseService.searchDocuments(_searchQuery);
    }
    _applySort();
    _updatePaginatedList();
  }

  void _applySort() {
    switch (_sortBy) {
      case 'name':
        _filteredDocuments.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'size':
        _filteredDocuments.sort((a, b) => b.fileSize.compareTo(a.fileSize));
        break;
      case 'date':
      default:
        _filteredDocuments.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
    }
  }
}
