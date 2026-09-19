import 'package:flutter/material.dart';

import 'constants/app_enums.dart';
import 'screens/collector_login_screen.dart';
import 'screens/language_selection_screen.dart';
import 'screens/main_dashboard_container.dart';
import 'services/database_helper.dart';
import 'services/storage_service.dart';
import 'themes/app_colors.dart';
import 'themes/app_theme.dart';
import 'services/sync_worker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await ReNovaStorage.create();
  // Seeds prices from benchmark.json into SQLite if table is empty
  await DatabaseHelper.instance.seedInitialPricesIfNeeded();
  runApp(ReNovaApp(storage: storage));
}

// ============================================================
// APP ROOT
// ============================================================

class ReNovaApp extends StatefulWidget {
  final ReNovaStorage storage;

  const ReNovaApp({super.key, required this.storage});

  @override
  State<ReNovaApp> createState() => ReNovaAppState();
}

class ReNovaAppState extends State<ReNovaApp> {
  late ReNovaThemeMode themeMode;
  AppLanguage language = AppLanguage.english;

  @override
  void initState() {
    SyncWorker.initialize(widget.storage);
    super.initState();

    final savedTheme = widget.storage.theme;
    themeMode = savedTheme == 'light'
        ? ReNovaThemeMode.light
        : ReNovaThemeMode.dark;

    final savedLanguage = widget.storage.language;
    language = savedLanguage == 'hindi'
        ? AppLanguage.hindi
        : savedLanguage == 'marathi'
        ? AppLanguage.marathi
        : AppLanguage.english;
  }

  Future<void> changeTheme(ReNovaThemeMode mode) async {
    setState(() {
      themeMode = mode;
    });
    await widget.storage.saveTheme(mode);
  }

  Future<void> changeLanguage(AppLanguage newLanguage) async {
    setState(() {
      language = newLanguage;
    });
    await widget.storage.prefs.setString('language', newLanguage.name);
  }

  Widget _getInitialHome() {
    // 1. Logged in -> Straight to Dashboard
    // 1. Logged in -> Straight to Dashboard
    if (widget.storage.isLoggedIn) {
      return MainDashboardContainer(
        collectorName: widget.storage.collectorName ?? 'Collector',
        location: widget.storage.location ?? 'Bhubaneswar',
        language: language,
        themeMode: themeMode,
        onThemeChanged: changeTheme,
        storage: widget.storage,
      );
    }

    // 2. Language chosen but not logged in -> Login Screen
    if (widget.storage.language != null) {
      return CollectorLoginScreen(
        language: language,
        storage: widget.storage,
        themeMode: themeMode,
        onThemeChanged: changeTheme,
      );
    }

    // 3. First time app install -> Choose Language
    return LanguageSelectionScreen(
      themeMode: themeMode,
      onThemeChanged: changeTheme,
      language: language,
      onLanguageChanged: changeLanguage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ReNova',
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.lightBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.featherGreen,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.lightBackground,
          foregroundColor: AppColors.lightText,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.lightCard,
          indicatorColor: AppColors.featherGreen.withValues(alpha: 0.22),
          labelTextStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.darkBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGold,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkBackground,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.cardBg,
          indicatorColor: AppColors.primaryGold.withValues(alpha: 0.25),
          labelTextStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          ),
        ),
      ),
      themeMode: themeMode == ReNovaThemeMode.light
          ? ThemeMode.light
          : ThemeMode.dark,
      home: _getInitialHome(),
    );
  }
}
