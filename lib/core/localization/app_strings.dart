import 'languages.dart';

class AppStrings {
  static String currentLanguage = 'en';

  static String get(String key) {
    return appLanguages[currentLanguage]?[key] ?? key;
  }

  static void changeLanguage(String languageCode) {
    currentLanguage = languageCode;
  }
}
