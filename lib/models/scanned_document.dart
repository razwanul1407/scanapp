import 'dart:convert';

class ScannedDocument {
  int? id;
  String title;
  DateTime createdAt;
  DateTime updatedAt;
  List<String> imagePaths; // Local file paths to scanned images
  String? thumbnailPath; // Path to thumbnail image
  List<String> tags; // For categorization/search
  String? notes; // User notes about the document
  int pageCount;
  int fileSize; // In bytes
  bool isFavorite;
  String? lastExportFormat; // 'pdf', 'jpg', 'png'

  // Phase 3 enhancements
  String? extractedText; // OCR extracted text from all pages
  String? activeFilterPreset; // Name of applied filter preset
  Map<String, dynamic>? metadata; // Custom metadata for advanced features

  ScannedDocument({
    this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.imagePaths,
    this.thumbnailPath,
    required this.tags,
    this.notes,
    required this.pageCount,
    required this.fileSize,
    this.isFavorite = false,
    this.lastExportFormat,
    this.extractedText,
    this.activeFilterPreset,
    this.metadata,
  });

  // Convert to Map for sqflite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'imagePaths': jsonEncode(imagePaths),
      'thumbnailPath': thumbnailPath,
      'tags': jsonEncode(tags),
      'notes': notes,
      'pageCount': pageCount,
      'fileSize': fileSize,
      'isFavorite': isFavorite ? 1 : 0,
      'lastExportFormat': lastExportFormat,
      'extractedText': extractedText,
      'activeFilterPreset': activeFilterPreset,
      'metadata': metadata != null ? jsonEncode(metadata) : null,
    };
  }

  // Create from Map from sqflite
  factory ScannedDocument.fromMap(Map<String, dynamic> map) {
    return ScannedDocument(
      id: map['id'] as int?,
      title: map['title'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      imagePaths:
          List<String>.from(jsonDecode(map['imagePaths'] as String) as List),
      thumbnailPath: map['thumbnailPath'] as String?,
      tags: List<String>.from(jsonDecode(map['tags'] as String) as List),
      notes: map['notes'] as String?,
      pageCount: map['pageCount'] as int,
      fileSize: map['fileSize'] as int,
      isFavorite: (map['isFavorite'] as int) == 1,
      lastExportFormat: map['lastExportFormat'] as String?,
      extractedText: map['extractedText'] as String?,
      activeFilterPreset: map['activeFilterPreset'] as String?,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(
              jsonDecode(map['metadata'] as String) as Map)
          : null,
    );
  }

  @override
  String toString() =>
      'ScannedDocument(id: $id, title: $title, pages: $pageCount)';
}
