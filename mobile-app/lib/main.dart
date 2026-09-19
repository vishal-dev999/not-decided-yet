import 'package:flutter/material.dart';

import 'constants/app_enums.dart';
import 'screens/collector_login_screen.dart';
import 'screens/language_selection_screen.dart';
import 'screens/main_dashboard_container.dart';
import 'screens/role_selection_screen.dart';
import 'services/database_helper.dart';
import 'services/storage_service.dart';
import 'themes/app_colors.dart';
import 'themes/app_theme.dart';
import 'services/sync_worker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await ReNovaStorage.create();

  // Seeds prices from benchmark.json into SQLite if table is empty.
  await DatabaseHelper.instance.seedInitialPricesIfNeeded();

  runApp(
    ReNovaApp(
      storage: storage,
    ),
  );
}

// ============================================================
// APP ROOT
// ============================================================

class ReNovaApp extends StatefulWidget {
  final ReNovaStorage storage;

  const ReNovaApp({
    super.key,
    required this.storage,
  });

  @override
  State<ReNovaApp> createState() => ReNovaAppState();
}

class ReNovaAppState extends State<ReNovaApp> {
  late ReNovaThemeMode themeMode;

  AppLanguage language = AppLanguage.english;

  @override
  void initState() {
    super.initState();

    // Start background sync worker.
    SyncWorker.initialize(widget.storage);

    // ==========================================================
    // LOAD SAVED THEME
    // ==========================================================

    final savedTheme = widget.storage.theme;

    themeMode = savedTheme == 'light'
        ? ReNovaThemeMode.light
        : ReNovaThemeMode.dark;

    // ==========================================================
    // LOAD SAVED LANGUAGE
    // ==========================================================

    final savedLanguage = widget.storage.language;

    language = savedLanguage == 'hindi'
        ? AppLanguage.hindi
        : savedLanguage == 'marathi'
            ? AppLanguage.marathi
            : AppLanguage.english;
  }

  // ============================================================
  // THEME
  // ============================================================

  Future<void> changeTheme(ReNovaThemeMode mode) async {
    setState(() {
      themeMode = mode;
    });

    await widget.storage.saveTheme(mode);
  }

  // ============================================================
  // LANGUAGE
  // ============================================================

  Future<void> changeLanguage(AppLanguage newLanguage) async {
    setState(() {
      language = newLanguage;
    });

    await widget.storage.prefs.setString(
      'language',
      newLanguage.name,
    );
  }

  // ============================================================
  // INITIAL HOME
  // ============================================================

  Widget _getInitialHome() {
    // ==========================================================
    // ALWAYS SHOW ROLE SELECTION FIRST
    // ==========================================================
    //
    // Every time the app starts:
    //
    // RecyLink
    // Select Role
    //
    // Then:
    //
    // ScrapCollector
    //     |
    //     |-- Already logged in --> Dashboard
    //     |
    //     |-- Not logged in -----> Collector Login
    //
    // Rider
    //     |
    //     --> Rider module placeholder
    //
    // ==========================================================

    return RoleSelectionScreen(
      language: language,
      onLanguageChanged: changeLanguage,

      themeMode: themeMode,
      onThemeChanged: changeTheme,

      // ========================================================
      // SCRAP COLLECTOR SELECTED
      // ========================================================
      //
      // IMPORTANT:
      // The BuildContext comes from RoleSelectionScreen.
      // This allows Navigator.of(context) to correctly find
      // the MaterialApp Navigator.
      //

      onScrapCollectorSelected: (context) {
        // ======================================================
        // ALREADY LOGGED IN
        // ======================================================

        if (widget.storage.isLoggedIn) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => MainDashboardContainer(
                collectorName:
                    widget.storage.collectorName ?? 'Collector',

                location:
                    widget.storage.location ?? 'Bhubaneswar',

                language: language,

                themeMode: themeMode,

                onThemeChanged: changeTheme,

                storage: widget.storage,
              ),
            ),
          );

          return;
        }

        // ======================================================
        // NOT LOGGED IN
        // ======================================================

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CollectorLoginScreen(
              language: language,

              storage: widget.storage,

              themeMode: themeMode,

              onThemeChanged: changeTheme,
            ),
          ),
        );
      },

      // ========================================================
      // RIDER SELECTED
      // ========================================================

      onRiderSelected: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              language == AppLanguage.hindi
                  ? 'Rider मॉड्यूल जल्द उपलब्ध होगा'
                  : language == AppLanguage.marathi
                      ? 'Rider मॉड्यूल लवकरच उपलब्ध होईल'
                      : 'Rider module will be available soon',
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'ReNova',

      // ========================================================
      // LIGHT THEME
      // ========================================================

      theme: ThemeData(
        brightness: Brightness.light,

        useMaterial3: true,

        scaffoldBackgroundColor:
            AppColors.lightBackground,

        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.featherGreen,
          brightness: Brightness.light,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor:
              AppColors.lightBackground,

          foregroundColor:
              AppColors.lightText,

          elevation: 0,
        ),

        navigationBarTheme:
            NavigationBarThemeData(
          backgroundColor:
              AppColors.lightCard,

          indicatorColor:
              AppColors.featherGreen
                  .withValues(alpha: 0.22),

          labelTextStyle:
              const WidgetStatePropertyAll(
            TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),

      // ========================================================
      // DARK THEME
      // ========================================================

      darkTheme: ThemeData(
        brightness: Brightness.dark,

        useMaterial3: true,

        scaffoldBackgroundColor:
            AppColors.darkBackground,

        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGold,
          brightness: Brightness.dark,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor:
              AppColors.darkBackground,

          foregroundColor:
              Colors.white,

          elevation: 0,
        ),

        navigationBarTheme:
            NavigationBarThemeData(
          backgroundColor:
              AppColors.cardBg,

          indicatorColor:
              AppColors.primaryGold
                  .withValues(alpha: 0.25),

          labelTextStyle:
              const WidgetStatePropertyAll(
            TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),

      // ========================================================
      // THEME MODE
      // ========================================================

      themeMode:
          themeMode == ReNovaThemeMode.light
              ? ThemeMode.light
              : ThemeMode.dark,

      // ========================================================
      // INITIAL SCREEN
      // ========================================================

      home: _getInitialHome(),
    );
  }
}

