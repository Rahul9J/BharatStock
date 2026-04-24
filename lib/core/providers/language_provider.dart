import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static final LanguageProvider instance = LanguageProvider._();

  LanguageProvider._();

  static const String _kLanguageKey = 'selected_language';
  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString(_kLanguageKey);
    if (languageCode != null && languageCode.isNotEmpty) {
      _currentLocale = Locale(languageCode);
    } else {
      _currentLocale = const Locale('en');
    }
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    if (_currentLocale.languageCode == languageCode) return;

    _currentLocale = Locale(languageCode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageKey, languageCode);

    notifyListeners();
  }
}
