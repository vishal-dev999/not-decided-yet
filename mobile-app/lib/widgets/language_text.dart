import '../constants/app_enums.dart';

class LanguageText {
  static String t(AppLanguage language, String en, String hi, String mr) {
    switch (language) {
      case AppLanguage.hindi:
        return hi;
      case AppLanguage.marathi:
        return mr;
      case AppLanguage.english:
      default:
        return en;
    }
  }
}
