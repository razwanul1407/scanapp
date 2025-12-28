import 'package:flutter/material.dart';

/// Service to save and restore scroll positions
class ScrollPositionService {
  static final ScrollPositionService _instance =
      ScrollPositionService._internal();

  factory ScrollPositionService() {
    return _instance;
  }

  ScrollPositionService._internal();

  final Map<String, double> _scrollPositions = {};

  /// Save scroll position for a screen
  void saveScrollPosition(String screenKey, double position) {
    _scrollPositions[screenKey] = position;
    debugPrint('Saved scroll position for $screenKey: $position');
  }

  /// Get saved scroll position
  double? getScrollPosition(String screenKey) {
    return _scrollPositions[screenKey];
  }

  /// Clear scroll position
  void clearScrollPosition(String screenKey) {
    _scrollPositions.remove(screenKey);
  }

  /// Clear all scroll positions
  void clearAll() {
    _scrollPositions.clear();
  }
}
