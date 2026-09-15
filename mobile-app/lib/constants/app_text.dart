enum AppLanguage {
  english,
  hindi,
  marathi,
}

AppLanguage selectedLanguage = AppLanguage.english;

class AppText {
  static final Map<String, Map<AppLanguage, String>> translations = {
    'welcome': {
      AppLanguage.english: 'WELCOME TO ReNova',
      AppLanguage.hindi: 'ReNova में आपका स्वागत है',
      AppLanguage.marathi: 'ReNova मध्ये आपले स्वागत आहे',
    },
    'enter_name': {
      AppLanguage.english: 'Enter your name',
      AppLanguage.hindi: 'अपना नाम दर्ज करें',
      AppLanguage.marathi: 'तुमचे नाव लिहा',
    },
    'continue': {
      AppLanguage.english: 'Continue',
      AppLanguage.hindi: 'आगे बढ़ें',
      AppLanguage.marathi: 'पुढे चला',
    },
    'dashboard': {
      AppLanguage.english: 'Dashboard',
      AppLanguage.hindi: 'डैशबोर्ड',
      AppLanguage.marathi: 'डॅशबोर्ड',
    },
    'earnings': {
      AppLanguage.english: 'Total Earnings',
      AppLanguage.hindi: 'कुल कमाई',
      AppLanguage.marathi: 'एकूण कमाई',
    },
    'kg_collected': {
      AppLanguage.english: 'KG Collected',
      AppLanguage.hindi: 'एकत्रित KG',
      AppLanguage.marathi: 'गोळा केलेले KG',
    },
    'pickups': {
      AppLanguage.english: 'Pickups',
      AppLanguage.hindi: 'पिकअप',
      AppLanguage.marathi: 'पिकअप',
    },
    'recent_activity': {
      AppLanguage.english: 'Recent Activity',
      AppLanguage.hindi: 'हाल की गतिविधि',
      AppLanguage.marathi: 'अलीकडील व्यवहार',
    },
    'my_earnings': {
      AppLanguage.english: 'My Earnings',
      AppLanguage.hindi: 'मेरी कमाई',
      AppLanguage.marathi: 'माझी कमाई',
    },
    'upload': {
      AppLanguage.english: 'Upload',
      AppLanguage.hindi: 'अपलोड',
      AppLanguage.marathi: 'अपलोड',
    },
    'prices': {
      AppLanguage.english: 'Prices',
      AppLanguage.hindi: 'कीमतें',
      AppLanguage.marathi: 'किंमती',
    },
    'profile': {
      AppLanguage.english: 'Profile',
      AppLanguage.hindi: 'प्रोफ़ाइल',
      AppLanguage.marathi: 'प्रोफाइल',
    },
    'choose_language': {
      AppLanguage.english: 'Choose Language',
      AppLanguage.hindi: 'भाषा चुनें',
      AppLanguage.marathi: 'भाषा निवडा',
    },
    'today': {
      AppLanguage.english: 'Today',
      AppLanguage.hindi: 'आज',
      AppLanguage.marathi: 'आज',
    },
    'week': {
      AppLanguage.english: 'Week',
      AppLanguage.hindi: 'सप्ताह',
      AppLanguage.marathi: 'आठवडा',
    },
    'month': {
      AppLanguage.english: 'Month',
      AppLanguage.hindi: 'महीना',
      AppLanguage.marathi: 'महिना',
    },
    'upload_title': {
      AppLanguage.english: 'Upload Material',
      AppLanguage.hindi: 'सामग्री अपलोड करें',
      AppLanguage.marathi: 'साहित्य अपलोड करा',
    },
    'upload_message': {
      AppLanguage.english:
          'Material upload will be available soon.',
      AppLanguage.hindi:
          'सामग्री अपलोड सुविधा जल्द उपलब्ध होगी।',
      AppLanguage.marathi:
          'साहित्य अपलोड करण्याची सुविधा लवकरच उपलब्ध होईल.',
    },
    'material_prices': {
      AppLanguage.english: 'Material Prices',
      AppLanguage.hindi: 'सामग्री की कीमतें',
      AppLanguage.marathi: 'साहित्याच्या किंमती',
    },
  };

  static String get(String key) {
    return translations[key]?[selectedLanguage] ??
        translations[key]?[AppLanguage.english] ??
        key;
  }
}
