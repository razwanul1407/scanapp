import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';

  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;

  String get currentLanguageName {
    switch (_currentLocale.languageCode) {
      case 'en':
        return 'English';
      case 'bn':
        return 'বাংলা (Bangla)';
      case 'hi':
        return 'हिंदी (Hindi)';
      case 'ar':
        return 'العربية (Arabic)';
      default:
        return 'English';
    }
  }

  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(
      locale: Locale('en'),
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
    ),
    LanguageOption(
      locale: Locale('bn'),
      name: 'Bangla',
      nativeName: 'বাংলা',
      flag: '🇧🇩',
    ),
    LanguageOption(
      locale: Locale('hi'),
      name: 'Hindi',
      nativeName: 'हिंदी',
      flag: '🇮🇳',
    ),
    LanguageOption(
      locale: Locale('ar'),
      name: 'Arabic',
      nativeName: 'العربية',
      flag: '🇸🇦',
    ),
  ];

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString(_languageKey) ?? 'en';
    _currentLocale = Locale(savedLanguageCode);
    notifyListeners();
  }

  Future<void> setLanguage(Locale locale) async {
    if (_currentLocale == locale) return;

    _currentLocale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);
  }
}

class LanguageOption {
  final Locale locale;
  final String name;
  final String nativeName;
  final String flag;

  const LanguageOption({
    required this.locale,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}
