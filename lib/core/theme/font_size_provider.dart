import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontSizeProvider extends ChangeNotifier {
  // Singleton
  static final FontSizeProvider instance =
      FontSizeProvider._privateConstructor();
  FontSizeProvider._privateConstructor();

  double _scaleFactor = 1.0;
  double get scaleFactor => _scaleFactor;

  static const String _key = 'font_scale';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_key);
    if (saved != null) {
      _scaleFactor = saved.clamp(0.8, 1.4); // Safety clamp
      notifyListeners();
    }
  }

  Future<void> update(double newValue) async {
    // Clamp between 0.8 and 1.4
    final clamped = newValue.clamp(0.8, 1.4);
    _scaleFactor = clamped;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, clamped);
    notifyListeners();
  }
}
