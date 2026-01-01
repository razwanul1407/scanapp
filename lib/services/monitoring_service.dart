import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Monitoring & Analytics Service for Phase 3
/// Tracks performance metrics, storage usage, and app statistics
class MonitoringService extends ChangeNotifier {
  // Performance metrics
  double _lastImportDuration = 0.0; // milliseconds
  double _lastExportDuration = 0.0; // milliseconds
  double _lastOcrDuration = 0.0; // milliseconds
  double _lastSearchDuration = 0.0; // milliseconds

  // Storage metrics
  int _usedStorage = 0; // bytes
  int _availableStorage = 0; // bytes
  int _totalCacheSize = 0; // bytes
  int _totalDocumentsSize = 0; // bytes

  // Event counts
  int _totalImports = 0;
  int _totalExports = 0;
  int _totalOcrOperations = 0;
  int _totalSearches = 0;
  int _totalDocumentsProcessed = 0;

  // Errors tracking
  final List<String> _recentErrors = [];
  static const int _maxErrorsToKeep = 50;

  // Getters
  double get lastImportDuration => _lastImportDuration;
  double get lastExportDuration => _lastExportDuration;
  double get lastOcrDuration => _lastOcrDuration;
  double get lastSearchDuration => _lastSearchDuration;

  int get usedStorage => _usedStorage;
  int get availableStorage => _availableStorage;
  int get totalCacheSize => _totalCacheSize;
  int get totalDocumentsSize => _totalDocumentsSize;

  int get totalImports => _totalImports;
  int get totalExports => _totalExports;
  int get totalOcrOperations => _totalOcrOperations;
  int get totalSearches => _totalSearches;
  int get totalDocumentsProcessed => _totalDocumentsProcessed;

  List<String> get recentErrors => List.unmodifiable(_recentErrors);

  double get storageUsagePercentage {
    if (_usedStorage + _availableStorage == 0) return 0.0;
    return _usedStorage / (_usedStorage + _availableStorage);
  }

  // Average metrics
  double get averageImportDuration =>
      _totalImports > 0 ? _lastImportDuration : 0.0;
  double get averageExportDuration =>
      _totalExports > 0 ? _lastExportDuration : 0.0;
  double get averageOcrDuration =>
      _totalOcrOperations > 0 ? _lastOcrDuration : 0.0;
  double get averageSearchDuration =>
      _totalSearches > 0 ? _lastSearchDuration : 0.0;

  // ===== Performance Tracking =====

  /// Track import operation duration
  void recordImportDuration(double durationMs) {
    _lastImportDuration = durationMs;
    _totalImports++;
    notifyListeners();
    debugPrint('Import tracked: ${durationMs}ms');
  }

  /// Track export operation duration
  void recordExportDuration(double durationMs) {
    _lastExportDuration = durationMs;
    _totalExports++;
    notifyListeners();
    debugPrint('Export tracked: ${durationMs}ms');
  }

  /// Track OCR operation duration
  void recordOcrDuration(double durationMs) {
    _lastOcrDuration = durationMs;
    _totalOcrOperations++;
    notifyListeners();
    debugPrint('OCR tracked: ${durationMs}ms');
  }

  /// Track search operation duration
  void recordSearchDuration(double durationMs) {
    _lastSearchDuration = durationMs;
    _totalSearches++;
    notifyListeners();
    debugPrint('Search tracked: ${durationMs}ms');
  }

  /// Increment document counter
  void incrementDocumentsProcessed(int count) {
    _totalDocumentsProcessed += count;
    notifyListeners();
  }

  // ===== Storage Monitoring =====

  /// Calculate and update storage statistics
  Future<void> updateStorageStats() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = await getApplicationCacheDirectory();

      // Calculate used storage
      _usedStorage = await _getDirectorySize(appDir);
      _totalCacheSize = await _getDirectorySize(cacheDir);

      // Get available storage (requires platform-specific code)
      // For now, using estimated values
      _availableStorage = await _getAvailableStorage();

      _totalDocumentsSize = _usedStorage - _totalCacheSize;

      notifyListeners();
      debugPrint(
        'Storage updated: ${(_usedStorage / (1024 * 1024)).toStringAsFixed(2)} MB used',
      );
    } catch (e) {
      debugPrint('Error updating storage stats: $e');
      recordError('Storage monitoring error: $e');
    }
  }

  /// Get total size of a directory recursively
  Future<int> _getDirectorySize(Directory dir) async {
    int size = 0;
    try {
      if (!dir.existsSync()) return 0;

      final entities = dir.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        if (entity is File) {
          size += entity.lengthSync();
        }
      }
    } catch (e) {
      debugPrint('Error calculating directory size: $e');
    }
    return size;
  }

  /// Get available storage on device
  Future<int> _getAvailableStorage() async {
    try {
      // This is a placeholder - actual implementation would require platform channels
      // For now, return a reasonable estimate (5GB)
      return 5 * 1024 * 1024 * 1024;
    } catch (e) {
      return 5 * 1024 * 1024 * 1024;
    }
  }

  /// Get human-readable storage size
  String getFormattedStorageSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get storage usage percentage string
  String getStorageUsageString() {
    final percentage = (storageUsagePercentage * 100).toStringAsFixed(1);
    return '$percentage% used';
  }

  // ===== Error Tracking =====

  /// Record an error for debugging
  void recordError(String error) {
    _recentErrors.insert(0, '[${DateTime.now()}] $error');
    if (_recentErrors.length > _maxErrorsToKeep) {
      _recentErrors.removeAt(_recentErrors.length - 1);
    }
    notifyListeners();
    debugPrint('Error recorded: $error');
  }

  /// Clear error log
  void clearErrors() {
    _recentErrors.clear();
    notifyListeners();
  }

  // ===== Statistics Summary =====

  /// Get all metrics as a formatted string for sharing/logging
  String getMetricsSummary() {
    return '''
=== ScanApp Performance Metrics ===
Import Operations: $_totalImports (last: ${_lastImportDuration.toStringAsFixed(0)}ms)
Export Operations: $_totalExports (last: ${_lastExportDuration.toStringAsFixed(0)}ms)
OCR Operations: $_totalOcrOperations (last: ${_lastOcrDuration.toStringAsFixed(0)}ms)
Search Operations: $_totalSearches (last: ${_lastSearchDuration.toStringAsFixed(0)}ms)
Documents Processed: $_totalDocumentsProcessed

Storage Usage: ${getFormattedStorageSize(_usedStorage)}
Storage Available: ${getFormattedStorageSize(_availableStorage)}
Cache Size: ${getFormattedStorageSize(_totalCacheSize)}
Storage Percentage: ${getStorageUsageString()}

Recent Errors: ${_recentErrors.length}
=================================
    ''';
  }

  /// Reset all metrics
  void resetMetrics() {
    _lastImportDuration = 0.0;
    _lastExportDuration = 0.0;
    _lastOcrDuration = 0.0;
    _lastSearchDuration = 0.0;
    _totalImports = 0;
    _totalExports = 0;
    _totalOcrOperations = 0;
    _totalSearches = 0;
    _totalDocumentsProcessed = 0;
    notifyListeners();
    debugPrint('Metrics reset');
  }
}
