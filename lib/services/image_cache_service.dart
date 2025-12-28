import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:scanapp/services/image_processor.dart';

/// In-memory image cache with LRU eviction
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();

  factory ImageCacheService() {
    return _instance;
  }

  ImageCacheService._internal();

  // LRU Cache: max 50MB in memory
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50MB
  static const int _maxCacheItems = 100; // Max number of cached items

  final Map<String, Uint8List> _memoryCache = {};
  final Map<String, DateTime> _accessTimes = {};
  int _currentCacheSize = 0;

  String? _cacheDirPath;

  /// Initialize cache directory
  Future<void> initialize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      _cacheDirPath = path.join(cacheDir.path, 'scanapp_cache');

      // Create cache directory if it doesn't exist
      final dir = Directory(_cacheDirPath!);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      debugPrint('Image cache initialized at: $_cacheDirPath');
    } catch (e) {
      debugPrint('Error initializing image cache: $e');
    }
  }

  /// Get cached image thumbnail
  Future<Uint8List?> getThumbnail(String imagePath) async {
    final cacheKey = 'thumb_${imagePath.hashCode}';

    // Check memory cache first (fastest)
    if (_memoryCache.containsKey(cacheKey)) {
      _updateAccessTime(cacheKey);
      return _memoryCache[cacheKey];
    }

    // Check disk cache (fast)
    final diskImage = await _getDiskCachedImage(cacheKey);
    if (diskImage != null) {
      _addToMemoryCache(cacheKey, diskImage);
      return diskImage;
    }

    // Generate and cache
    try {
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) return null;

      final thumbnail =
          await ImageProcessor.generateThumbnailFromFile(imageFile);

      // Cache both in memory and on disk
      _addToMemoryCache(cacheKey, thumbnail);
      await _saveToDiskCache(cacheKey, thumbnail);

      return thumbnail;
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }

  /// Get cached processed image
  Future<Uint8List?> getProcessedImage(
      String cacheKey, Future<Uint8List> Function() generator) async {
    // Check memory cache
    if (_memoryCache.containsKey(cacheKey)) {
      _updateAccessTime(cacheKey);
      return _memoryCache[cacheKey];
    }

    // Check disk cache
    final diskImage = await _getDiskCachedImage(cacheKey);
    if (diskImage != null) {
      _addToMemoryCache(cacheKey, diskImage);
      return diskImage;
    }

    // Generate new
    try {
      final processed = await generator();
      _addToMemoryCache(cacheKey, processed);
      await _saveToDiskCache(cacheKey, processed);
      return processed;
    } catch (e) {
      debugPrint('Error generating processed image: $e');
      return null;
    }
  }

  /// Cache image with custom key
  Future<void> cacheImage(String key, Uint8List imageBytes) async {
    _addToMemoryCache(key, imageBytes);
    await _saveToDiskCache(key, imageBytes);
  }

  /// Clear all caches
  Future<void> clearAll() async {
    _memoryCache.clear();
    _accessTimes.clear();
    _currentCacheSize = 0;

    try {
      if (_cacheDirPath != null) {
        final dir = Directory(_cacheDirPath!);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
          await dir.create(recursive: true);
        }
      }
      debugPrint('All caches cleared');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Clear old cache files (older than 7 days)
  Future<void> clearOldCache({int daysOld = 7}) async {
    try {
      if (_cacheDirPath == null) return;

      final dir = Directory(_cacheDirPath!);
      if (!await dir.exists()) return;

      final now = DateTime.now();
      final cutoffDate = now.subtract(Duration(days: daysOld));

      await for (final file in dir.list()) {
        if (file is File) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
          }
        }
      }

      debugPrint('Old cache files cleared (older than $daysOld days)');
    } catch (e) {
      debugPrint('Error clearing old cache: $e');
    }
  }

  // Private methods

  void _addToMemoryCache(String key, Uint8List imageBytes) {
    // Remove old entry if exists
    if (_memoryCache.containsKey(key)) {
      _currentCacheSize -= _memoryCache[key]!.length;
    }

    _memoryCache[key] = imageBytes;
    _currentCacheSize += imageBytes.length;
    _updateAccessTime(key);

    // Evict least recently used items if cache is full
    if (_currentCacheSize > _maxCacheSize ||
        _memoryCache.length > _maxCacheItems) {
      _evictLRU();
    }
  }

  void _evictLRU() {
    if (_memoryCache.isEmpty) return;

    // Find least recently used key
    String? lruKey;
    DateTime? oldestTime;

    for (final entry in _accessTimes.entries) {
      if (oldestTime == null || entry.value.isBefore(oldestTime)) {
        oldestTime = entry.value;
        lruKey = entry.key;
      }
    }

    if (lruKey != null) {
      _currentCacheSize -= _memoryCache[lruKey]?.length ?? 0;
      _memoryCache.remove(lruKey);
      _accessTimes.remove(lruKey);
    }
  }

  void _updateAccessTime(String key) {
    _accessTimes[key] = DateTime.now();
  }

  Future<void> _saveToDiskCache(String key, Uint8List imageBytes) async {
    try {
      if (_cacheDirPath == null) return;

      final file = File(path.join(_cacheDirPath!, '$key.cache'));
      await file.writeAsBytes(imageBytes);
    } catch (e) {
      debugPrint('Error saving to disk cache: $e');
    }
  }

  Future<Uint8List?> _getDiskCachedImage(String key) async {
    try {
      if (_cacheDirPath == null) return null;

      final file = File(path.join(_cacheDirPath!, '$key.cache'));
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      debugPrint('Error reading from disk cache: $e');
    }
    return null;
  }

  /// Get cache stats for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'memoryCacheSize': _currentCacheSize,
      'maxCacheSize': _maxCacheSize,
      'cacheItemCount': _memoryCache.length,
      'diskCachePath': _cacheDirPath,
      'utilizationPercent':
          (_currentCacheSize / _maxCacheSize * 100).toStringAsFixed(2),
    };
  }
}
