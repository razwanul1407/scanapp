import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Filter preset configuration
class FilterPreset {
  final String name;
  final double brightness;
  final double contrast;
  final double saturation;
  final String? filterType; // DocumentFilter name

  FilterPreset({
    required this.name,
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.saturation = 0.0,
    this.filterType,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'brightness': brightness,
      'contrast': contrast,
      'saturation': saturation,
      'filterType': filterType,
    };
  }

  /// Create from JSON
  factory FilterPreset.fromJson(Map<String, dynamic> json) {
    return FilterPreset(
      name: json['name'] as String,
      brightness: (json['brightness'] as num?)?.toDouble() ?? 0.0,
      contrast: (json['contrast'] as num?)?.toDouble() ?? 0.0,
      saturation: (json['saturation'] as num?)?.toDouble() ?? 0.0,
      filterType: json['filterType'] as String?,
    );
  }

  /// Create a copy with modifications
  FilterPreset copyWith({
    String? name,
    double? brightness,
    double? contrast,
    double? saturation,
    String? filterType,
  }) {
    return FilterPreset(
      name: name ?? this.name,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      filterType: filterType ?? this.filterType,
    );
  }

  @override
  String toString() => 'FilterPreset(name: $name, brightness: $brightness)';
}

/// Filter Preset Manager Service (Phase 3)
/// Manages custom filter presets and user preferences
class FilterPresetService extends ChangeNotifier {
  static final FilterPresetService _instance = FilterPresetService._internal();

  factory FilterPresetService() {
    return _instance;
  }

  FilterPresetService._internal();

  static const String _presetsKey = 'filter_presets';
  static const String _recentPresetKey = 'recent_filter_preset';

  late SharedPreferences _prefs;
  List<FilterPreset> _presets = [];
  String? _recentPreset;

  List<FilterPreset> get presets => List.unmodifiable(_presets);
  String? get recentPreset => _recentPreset;

  /// Built-in presets
  static final Map<String, FilterPreset> builtInPresets = {
    'Document': FilterPreset(
      name: 'Document',
      brightness: 0.0,
      contrast: 0.3,
      saturation: 0.0,
      filterType: 'highContrast',
    ),
    'Magazine': FilterPreset(
      name: 'Magazine',
      brightness: 0.1,
      contrast: 0.2,
      saturation: 0.15,
      filterType: 'magicColor',
    ),
    'Photo': FilterPreset(
      name: 'Photo',
      brightness: 0.05,
      contrast: 0.1,
      saturation: 0.1,
      filterType: 'original',
    ),
    'Vivid': FilterPreset(
      name: 'Vivid',
      brightness: 0.0,
      contrast: 0.4,
      saturation: 0.3,
      filterType: 'magicColor',
    ),
    'Vintage': FilterPreset(
      name: 'Vintage',
      brightness: 0.05,
      contrast: -0.1,
      saturation: -0.2,
      filterType: 'sepia',
    ),
  };

  /// Initialize service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPresets();
    debugPrint(
        'FilterPresetService initialized with ${_presets.length} presets');
  }

  /// Load presets from storage
  Future<void> _loadPresets() async {
    try {
      final presetsJson = _prefs.getStringList(_presetsKey) ?? [];
      _presets = presetsJson
          .map((json) =>
              FilterPreset.fromJson(jsonDecode(json) as Map<String, dynamic>))
          .toList();

      _recentPreset = _prefs.getString(_recentPresetKey);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading presets: $e');
    }
  }

  /// Save all presets to storage
  Future<void> _savePresets() async {
    try {
      final presetsJson = _presets.map((p) => jsonEncode(p.toJson())).toList();
      await _prefs.setStringList(_presetsKey, presetsJson);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving presets: $e');
    }
  }

  /// Add a new preset
  Future<void> addPreset(FilterPreset preset) async {
    _presets.add(preset);
    await _savePresets();
    debugPrint('Preset added: ${preset.name}');
  }

  /// Update an existing preset
  Future<void> updatePreset(String oldName, FilterPreset newPreset) async {
    final index = _presets.indexWhere((p) => p.name == oldName);
    if (index >= 0) {
      _presets[index] = newPreset;
      await _savePresets();
      debugPrint('Preset updated: ${newPreset.name}');
    }
  }

  /// Delete a preset
  Future<void> deletePreset(String name) async {
    _presets.removeWhere((p) => p.name == name);
    if (_recentPreset == name) {
      _recentPreset = null;
      await _prefs.remove(_recentPresetKey);
    }
    await _savePresets();
    debugPrint('Preset deleted: $name');
  }

  /// Get preset by name
  FilterPreset? getPreset(String name) {
    try {
      return _presets.firstWhere((p) => p.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Get built-in preset
  FilterPreset? getBuiltInPreset(String name) {
    return builtInPresets[name];
  }

  /// Set recent preset
  Future<void> setRecentPreset(String name) async {
    _recentPreset = name;
    await _prefs.setString(_recentPresetKey, name);
    notifyListeners();
  }

  /// Get recent preset
  FilterPreset? getRecentPreset() {
    if (_recentPreset != null) {
      return getPreset(_recentPreset!) ?? getBuiltInPreset(_recentPreset!);
    }
    return null;
  }

  /// Clear all custom presets (keeps built-in ones)
  Future<void> clearCustomPresets() async {
    _presets.clear();
    _recentPreset = null;
    await _savePresets();
    await _prefs.remove(_recentPresetKey);
    debugPrint('Custom presets cleared');
  }

  /// Export presets as JSON string
  String exportPresetsAsJson() {
    final presetsData = _presets.map((p) => p.toJson()).toList();
    return jsonEncode(presetsData);
  }

  /// Import presets from JSON string
  Future<void> importPresetsFromJson(String jsonString) async {
    try {
      final presetsData = jsonDecode(jsonString) as List;
      for (final presetJson in presetsData) {
        final preset =
            FilterPreset.fromJson(presetJson as Map<String, dynamic>);
        addPreset(preset);
      }
      debugPrint('${presetsData.length} presets imported');
    } catch (e) {
      debugPrint('Error importing presets: $e');
    }
  }

  /// Get all presets (custom + built-in)
  List<FilterPreset> getAllPresetsIncludingBuiltIn() {
    return [
      ..._presets,
      ...builtInPresets.values.where(
        (builtin) => !_presets.any((custom) => custom.name == builtin.name),
      ),
    ];
  }

  /// Check if preset is built-in
  bool isBuiltInPreset(String name) {
    return builtInPresets.containsKey(name);
  }

  /// Check if preset is custom
  bool isCustomPreset(String name) {
    return _presets.any((p) => p.name == name);
  }
}
