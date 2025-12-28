import 'package:flutter/foundation.dart';
import 'package:scanapp/services/database_service.dart';
import 'package:scanapp/models/scanned_document.dart';

/// Background indexing service for large datasets
class BackgroundIndexingService {
  static final BackgroundIndexingService _instance =
      BackgroundIndexingService._internal();

  factory BackgroundIndexingService() {
    return _instance;
  }

  BackgroundIndexingService._internal();

  bool _isIndexing = false;
  int _indexProgress = 0;
  int _totalItems = 0;

  bool get isIndexing => _isIndexing;
  int get progress => _indexProgress;
  int get totalItems => _totalItems;

  /// Start background indexing for search optimization
  Future<void> startIndexing() async {
    if (_isIndexing) return;

    _isIndexing = true;
    _indexProgress = 0;

    try {
      // Get all documents for indexing
      final documents = await DatabaseService.getAllDocuments();
      _totalItems = documents.length;

      debugPrint(
          'Starting background indexing for ${documents.length} documents');

      // Create search index asynchronously using compute
      await compute(_buildSearchIndex, documents);

      debugPrint('Background indexing completed');
    } catch (e) {
      debugPrint('Error during background indexing: $e');
    } finally {
      _isIndexing = false;
      _indexProgress = 0;
      _totalItems = 0;
    }
  }

  /// Optimize database queries by running analysis
  Future<void> optimizeDatabaseQueries() async {
    try {
      debugPrint('Starting database optimization...');

      // Run ANALYZE command to update query optimizer statistics
      // This helps SQLite make better decisions about which indexes to use
      await DatabaseService.analyzeDatabase();

      debugPrint('Database optimization completed');
    } catch (e) {
      debugPrint('Error during database optimization: $e');
    }
  }

  /// Vacuum database to reclaim space
  Future<void> vacuumDatabase() async {
    try {
      debugPrint('Starting database vacuum...');

      await DatabaseService.vacuumDatabase();

      debugPrint('Database vacuum completed');
    } catch (e) {
      debugPrint('Error during database vacuum: $e');
    }
  }

  // Isolate functions for heavy computations

  static Map<String, List<String>> _buildSearchIndex(
    List<ScannedDocument> documents,
  ) {
    final index = <String, List<String>>{};

    for (final doc in documents) {
      // Index by title
      final titleWords = doc.title.toLowerCase().split(RegExp(r'\s+'));
      for (final word in titleWords) {
        if (word.isNotEmpty) {
          index.putIfAbsent(word, () => []).add(doc.title);
        }
      }

      // Index by tags
      for (final tag in doc.tags) {
        final tagWords = tag.toLowerCase().split(RegExp(r'\s+'));
        for (final word in tagWords) {
          if (word.isNotEmpty) {
            index.putIfAbsent(word, () => []).add(tag);
          }
        }
      }

      // Index by notes
      if (doc.notes != null && doc.notes!.isNotEmpty) {
        final noteWords = doc.notes!.toLowerCase().split(RegExp(r'\s+'));
        for (final word in noteWords.take(10)) {
          // Limit to first 10 words to avoid indexing spam
          if (word.isNotEmpty) {
            index.putIfAbsent(word, () => []).add(doc.notes!);
          }
        }
      }
    }

    return index;
  }
}
