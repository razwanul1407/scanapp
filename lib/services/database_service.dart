import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:scanapp/models/scanned_document.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> _getDatabase() async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'scanapp.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );

    return _database!;
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
        lastExportFormat TEXT
      )
    ''');
  }

  static Future<void> initialize() async {
    await _getDatabase();
    print('Database initialized');
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

  // Search Documents
  static Future<List<ScannedDocument>> searchDocuments(String query) async {
    final db = await _getDatabase();
    final lowerQuery = query.toLowerCase();

    final maps = await db.query('scanned_documents');
    final results = maps
        .map((map) => ScannedDocument.fromMap(map))
        .where((doc) =>
            doc.title.toLowerCase().contains(lowerQuery) ||
            doc.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
            (doc.notes?.toLowerCase() ?? '').contains(lowerQuery))
        .toList();

    return results;
  }

  // Get Favorite Documents
  static Future<List<ScannedDocument>> getFavoriteDocuments() async {
    final db = await _getDatabase();
    final maps = await db.query(
      'scanned_documents',
      where: 'isFavorite = ?',
      whereArgs: [1],
    );
    return maps.map((map) => ScannedDocument.fromMap(map)).toList();
  }

  // Toggle Favorite Status
  static Future<void> toggleFavorite(int id) async {
    final db = await _getDatabase();
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

  // Close Database
  static Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
