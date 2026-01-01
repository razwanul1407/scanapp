import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:scanapp/models/scanned_document.dart';

class DatabaseService {
  static Database? _database;
  static const int _schemaVersion = 2;
  static bool _fts5Available = false;

  static Future<Database> _getDatabase() async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'scanapp.db');

    _database = await openDatabase(
      path,
      version: _schemaVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );

    return _database!;
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add Phase 3 columns
      await db.execute(
          'ALTER TABLE scanned_documents ADD COLUMN extractedText TEXT');
      await db.execute(
          'ALTER TABLE scanned_documents ADD COLUMN activeFilterPreset TEXT');
      await db
          .execute('ALTER TABLE scanned_documents ADD COLUMN metadata TEXT');

      // Try to create FTS5 virtual table (optional - not all devices support it)
      await _tryCreateFts5Table(db, populateExisting: true);
    }
  }

  /// Try to create FTS5 table, fail gracefully if not supported
  static Future<void> _tryCreateFts5Table(Database db,
      {bool populateExisting = false}) async {
    try {
      // Create FTS5 virtual table for full-text search
      await db.execute('''
        CREATE VIRTUAL TABLE IF NOT EXISTS scanned_documents_fts USING fts5(
          id UNINDEXED,
          title,
          notes,
          extractedText,
          tags
        )
      ''');

      if (populateExisting) {
        // Populate FTS table with existing data
        await db.rawQuery('''
          INSERT INTO scanned_documents_fts(id, title, notes, extractedText, tags)
          SELECT id, title, COALESCE(notes, ''), COALESCE(extractedText, ''), 
                 COALESCE((SELECT group_concat(value) FROM json_each(tags)), '')
          FROM scanned_documents
        ''');
      }

      _fts5Available = true;
      debugPrint('FTS5 full-text search enabled');
    } catch (e) {
      _fts5Available = false;
      debugPrint(
          'FTS5 not available on this device. Using basic search instead. Error: $e');
    }
  }

  static Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS scanned_documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        imagePaths TEXT NOT NULL,
        thumbnailPath TEXT,
        tags TEXT NOT NULL,
        notes TEXT,
        pageCount INTEGER NOT NULL,
        fileSize INTEGER NOT NULL,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        lastExportFormat TEXT,
        extractedText TEXT,
        activeFilterPreset TEXT,
        metadata TEXT
      )
    ''');

    // Add indexes for frequently queried columns
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_title ON scanned_documents(title)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_isFavorite ON scanned_documents(isFavorite)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_createdAt ON scanned_documents(createdAt DESC)');

    // Try to create FTS5 virtual table (optional - not all devices support it)
    await _tryCreateFts5Table(db);
  }

  static Future<void> initialize() async {
    await _getDatabase();
    debugPrint('Database initialized');
  }

  // Save Document
  static Future<int> saveDocument(ScannedDocument doc) async {
    final db = await _getDatabase();
    return await db.insert('scanned_documents', doc.toMap());
  }

  // Get All Documents
  static Future<List<ScannedDocument>> getAllDocuments() async {
    final db = await _getDatabase();
    final maps = await db.query('scanned_documents');
    return maps.map((map) => ScannedDocument.fromMap(map)).toList();
  }

  // Get Document by ID
  static Future<ScannedDocument?> getDocument(int id) async {
    final db = await _getDatabase();
    final maps = await db.query(
      'scanned_documents',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ScannedDocument.fromMap(maps.first);
  }

  // Delete Document
  static Future<int> deleteDocument(int id) async {
    final db = await _getDatabase();
    return await db.delete(
      'scanned_documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update Document
  static Future<int> updateDocument(ScannedDocument doc) async {
    final db = await _getDatabase();
    return await db.update(
      'scanned_documents',
      doc.toMap(),
      where: 'id = ?',
      whereArgs: [doc.id],
    );
  }

  // Search Documents (optimized - uses SQL WHERE instead of loading all)
  static Future<List<ScannedDocument>> searchDocuments(String query) async {
    final db = await _getDatabase();
    final lowerQuery = '%${query.toLowerCase()}%';

    // Use SQL LIKE search for title (uses index)
    final maps = await db.rawQuery(
      '''
      SELECT * FROM scanned_documents 
      WHERE LOWER(title) LIKE ? OR LOWER(notes) LIKE ?
      ORDER BY createdAt DESC
      ''',
      [lowerQuery, lowerQuery],
    );

    return maps.map((map) => ScannedDocument.fromMap(map)).toList();
  }

  // Full-text search using FTS5 (Phase 3)
  static Future<List<ScannedDocument>> fullTextSearch(String query) async {
    if (query.trim().isEmpty) {
      return getAllDocuments();
    }

    // If FTS5 is not available, fall back to basic search
    if (!_fts5Available) {
      debugPrint('FTS5 not available, using basic LIKE search');
      return searchDocuments(query);
    }

    final db = await _getDatabase();

    try {
      // FTS5 search with prefix matching
      final searchQuery = '$query*';

      final results = await db.rawQuery(
        '''
        SELECT DISTINCT d.* FROM scanned_documents d
        WHERE d.id IN (
          SELECT id FROM scanned_documents_fts 
          WHERE scanned_documents_fts MATCH ?
        )
        ORDER BY d.createdAt DESC
        ''',
        [searchQuery],
      );

      return results.map((map) => ScannedDocument.fromMap(map)).toList();
    } catch (e) {
      debugPrint('FTS5 search failed, falling back to basic search: $e');
      return searchDocuments(query);
    }
  }

  // Advanced search with multiple filters (Phase 3)
  static Future<List<ScannedDocument>> advancedSearch({
    String? query,
    List<String>? tags,
    bool? isFavorite,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? sortBy = 'createdAt',
    bool ascending = false,
  }) async {
    final db = await _getDatabase();

    String whereClause = '1 = 1';
    List<dynamic> whereArgs = [];

    if (query != null && query.isNotEmpty) {
      whereClause +=
          ' AND (LOWER(title) LIKE ? OR LOWER(notes) LIKE ? OR LOWER(extractedText) LIKE ?)';
      final lowerQuery = '%${query.toLowerCase()}%';
      whereArgs.addAll([lowerQuery, lowerQuery, lowerQuery]);
    }

    if (isFavorite != null) {
      whereClause += ' AND isFavorite = ?';
      whereArgs.add(isFavorite ? 1 : 0);
    }

    if (dateFrom != null) {
      whereClause += ' AND createdAt >= ?';
      whereArgs.add(dateFrom.toIso8601String());
    }

    if (dateTo != null) {
      whereClause += ' AND createdAt <= ?';
      whereArgs.add(dateTo.toIso8601String());
    }

    final orderDirection = ascending ? 'ASC' : 'DESC';
    final orderBy = '$sortBy $orderDirection';

    var maps = await db.query(
      'scanned_documents',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );

    var documents = maps.map((map) => ScannedDocument.fromMap(map)).toList();

    // Filter by tags (client-side since tags are JSON)
    if (tags != null && tags.isNotEmpty) {
      documents = documents
          .where((doc) => tags.every((tag) => doc.tags.contains(tag)))
          .toList();
    }

    return documents;
  }

  // Get Favorite Documents (optimized with index)
  static Future<List<ScannedDocument>> getFavoriteDocuments() async {
    final db = await _getDatabase();
    final maps = await db.query(
      'scanned_documents',
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => ScannedDocument.fromMap(map)).toList();
  }

  // Toggle Favorite Status
  static Future<void> toggleFavorite(int id) async {
    final doc = await getDocument(id);
    if (doc != null) {
      doc.isFavorite = !doc.isFavorite;
      await updateDocument(doc);
    }
  }

  // Get Documents by Tag
  static Future<List<ScannedDocument>> getDocumentsByTag(String tag) async {
    final allDocs = await getAllDocuments();
    return allDocs.where((doc) => doc.tags.contains(tag)).toList();
  }

  // Get All Tags
  static Future<List<String>> getAllTags() async {
    final allDocs = await getAllDocuments();
    final tags = <String>{};
    for (final doc in allDocs) {
      tags.addAll(doc.tags);
    }
    return tags.toList();
  }

  // Batch Operations (Phase 3)

  /// Delete multiple documents by IDs
  static Future<int> deleteDocuments(List<int> ids) async {
    if (ids.isEmpty) return 0;

    final db = await _getDatabase();
    final placeholders = List.filled(ids.length, '?').join(',');

    return await db.delete(
      'scanned_documents',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  /// Update tags for multiple documents
  static Future<void> batchUpdateTags(List<int> ids, List<String> tagsToAdd,
      {bool replace = false}) async {
    if (ids.isEmpty) return;

    for (final id in ids) {
      final doc = await getDocument(id);
      if (doc != null) {
        if (replace) {
          doc.tags = tagsToAdd;
        } else {
          doc.tags = {...doc.tags, ...tagsToAdd}.toList();
        }
        doc.updatedAt = DateTime.now();
        await updateDocument(doc);
      }
    }
  }

  /// Batch update favorite status
  static Future<void> batchToggleFavorite(
      List<int> ids, bool isFavorite) async {
    if (ids.isEmpty) return;

    for (final id in ids) {
      final doc = await getDocument(id);
      if (doc != null) {
        doc.isFavorite = isFavorite;
        doc.updatedAt = DateTime.now();
        await updateDocument(doc);
      }
    }
  }

  /// Get total size of documents by IDs (for batch operations info)
  static Future<int> getTotalSizeOfDocuments(List<int> ids) async {
    if (ids.isEmpty) return 0;

    int totalSize = 0;
    for (final id in ids) {
      final doc = await getDocument(id);
      if (doc != null) {
        totalSize += doc.fileSize;
      }
    }
    return totalSize;
  }

  /// Batch update extracted text (for OCR)
  static Future<void> batchUpdateExtractedText(
      Map<int, String> idToTextMap) async {
    if (idToTextMap.isEmpty) return;

    for (final entry in idToTextMap.entries) {
      final doc = await getDocument(entry.key);
      if (doc != null) {
        doc.extractedText = entry.value;
        doc.updatedAt = DateTime.now();
        await updateDocument(doc);
      }
    }
  }

  // Optimize Database

  /// Analyze database for query optimization
  static Future<void> analyzeDatabase() async {
    final db = await _getDatabase();
    try {
      await db.execute('ANALYZE');
      debugPrint('Database analysis completed');
    } catch (e) {
      debugPrint('Error analyzing database: $e');
    }
  }

  /// Vacuum database to reclaim space
  static Future<void> vacuumDatabase() async {
    final db = await _getDatabase();
    try {
      await db.execute('VACUUM');
      debugPrint('Database vacuum completed');
    } catch (e) {
      debugPrint('Error vacuuming database: $e');
    }
  }

  // Close Database
  static Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
