import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await ReNovaStorage.create();

  runApp(
    ReNovaApp(storage: storage),
  );
}

// ============================================================
// COLORS
// ============================================================

class AppColors {
  static const Color darkBackground = Color(0xFF00002A);
  static const Color cardBg = Color(0xFF1A3F75);

  static const Color primaryGold = Color(0xFFE99856);
  static const Color accentCoral = Color(0xFFA54055);
  static const Color mintGreen = Color(0xFF86C5DA);

  static const Color lightGreen = Color(0xFF72D6A4);
  static const Color warning = Color(0xFFF2B84B);
  static const Color danger = Color(0xFFE66A6A);

  static const Color lightBackground = Color(0xFFF5F7FB);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF172033);
  static const Color lightMuted = Color(0xFF667085);
  static const Color lightFaint = Color(0xFF8A93A3);
}

// ============================================================
// THEME
// ============================================================

enum ReNovaThemeMode {
  light,
  dark,
}

class AppThemeColors {
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color background(BuildContext context) {
    return isDark(context)
        ? AppColors.darkBackground
        : AppColors.lightBackground;
  }

  static Color card(BuildContext context) {
    return isDark(context)
        ? AppColors.cardBg
        : AppColors.lightCard;
  }

  static Color text(BuildContext context) {
    return isDark(context)
        ? Colors.white
        : AppColors.lightText;
  }

  static Color muted(BuildContext context) {
    return isDark(context)
        ? Colors.white60
        : AppColors.lightMuted;
  }

  static Color faint(BuildContext context) {
    return isDark(context)
        ? Colors.white54
        : AppColors.lightFaint;
  }

  static Color veryFaint(BuildContext context) {
    return isDark(context)
        ? Colors.white38
        : const Color(0xFFA0A8B5);
  }
}

// ============================================================
// LANGUAGE
// ============================================================

enum AppLanguage {
  english,
  hindi,
  marathi,
}

// ============================================================
// LOCAL STORAGE
// ============================================================

class ReNovaStorage {
  final SharedPreferences prefs;
  final Directory documentsDirectory;

  ReNovaStorage._(
    this.prefs,
    this.documentsDirectory,
  );

  static Future<ReNovaStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    final directory =
        await getApplicationDocumentsDirectory();

    return ReNovaStorage._(
      prefs,
      directory,
    );
  }

  String? get collectorName =>
      prefs.getString('collector_name');

  String? get location =>
      prefs.getString('collector_location');

  String? get language =>
      prefs.getString('language');

  String? get theme =>
      prefs.getString('theme');

  String? get profileImagePath =>
      prefs.getString('profile_image_path');

  String? get pickupImagePath =>
      prefs.getString('pickup_image_path');

  String? get paymentPreference =>
      prefs.getString('payment_preference');

  String get collectorId =>
      prefs.getString('collector_id') ??
      'RN-COL-2026-01428';

  Future<void> saveProfile({
    required String name,
    required String location,
    required String language,
    required String paymentPreference,
    String? profileImagePath,
  }) async {
    await prefs.setString(
      'collector_name',
      name,
    );

    await prefs.setString(
      'collector_location',
      location,
    );

    await prefs.setString(
      'language',
      language,
    );

    await prefs.setString(
      'payment_preference',
      paymentPreference,
    );

    if (profileImagePath != null) {
      await prefs.setString(
        'profile_image_path',
        profileImagePath,
      );
    }
  }

  Future<void> saveTheme(
    ReNovaThemeMode mode,
  ) async {
    await prefs.setString(
      'theme',
      mode == ReNovaThemeMode.dark
          ? 'dark'
          : 'light',
    );
  }

  Future<String> saveImagePermanently(
    XFile image,
    String filename,
  ) async {
    final target = File(
      '${documentsDirectory.path}/$filename',
    );

    await File(image.path).copy(
      target.path,
    );

    return target.path;
  }

  Future<void> savePickupImage(
    XFile image,
  ) async {
    final path = await saveImagePermanently(
      image,
      'renova_pickup.jpg',
    );

    await prefs.setString(
      'pickup_image_path',
      path,
    );
  }

  Future<void> saveProfileImage(
    XFile image,
  ) async {
    final path = await saveImagePermanently(
      image,
      'renova_profile.jpg',
    );

    await prefs.setString(
      'profile_image_path',
      path,
    );
  }

  Future<void> removePickupImage() async {
    final path = pickupImagePath;

    if (path != null) {
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
      }
    }

    await prefs.remove(
      'pickup_image_path',
    );
  }
}

// ============================================================
// APP
// ============================================================

class ReNovaApp extends StatefulWidget {
  final ReNovaStorage storage;

  const ReNovaApp({
    super.key,
    required this.storage,
  });

  @override
  State<ReNovaApp> createState() =>
      _ReNovaAppState();
}

class _ReNovaAppState
    extends State<ReNovaApp> {
  late ReNovaThemeMode themeMode;

  AppLanguage language = AppLanguage.english;

  String collectorName = '';
  String location = '';

  String paymentPreference = 'Cash';

  String? profileImagePath;

  @override
  void initState() {
    super.initState();

    final savedTheme =
        widget.storage.theme;

    themeMode =
        savedTheme == 'light'
            ? ReNovaThemeMode.light
            : ReNovaThemeMode.dark;

    final savedLanguage =
        widget.storage.language;

    language =
        savedLanguage == 'hindi'
            ? AppLanguage.hindi
            : savedLanguage == 'marathi'
                ? AppLanguage.marathi
                : AppLanguage.english;

    collectorName =
        widget.storage.collectorName ?? '';

    location =
        widget.storage.location ?? '';

    paymentPreference =
        widget.storage.paymentPreference ??
            'Cash';

    profileImagePath =
        widget.storage.profileImagePath;
  }

  Future<void> changeTheme(
    ReNovaThemeMode mode,
  ) async {
    setState(() {
      themeMode = mode;
    });

    await widget.storage.saveTheme(mode);
  }

  Future<void> changeLanguage(
    AppLanguage newLanguage,
  ) async {
    setState(() {
      language = newLanguage;
    });

    await widget.storage.prefs.setString(
      'language',
      newLanguage.name,
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
        scaffoldBackgroundColor:
            AppColors.lightBackground,
        colorScheme:
            ColorScheme.fromSeed(
          seedColor:
              AppColors.primaryGold,
          brightness: Brightness.light,
        ),
        appBarTheme:
            const AppBarTheme(
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
              AppColors.primaryGold
                  .withValues(alpha: 0.22),
          labelTextStyle:
              const WidgetStatePropertyAll(
            TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor:
            AppColors.darkBackground,
        colorScheme:
            ColorScheme.fromSeed(
          seedColor:
              AppColors.primaryGold,
          brightness: Brightness.dark,
        ),
        appBarTheme:
            const AppBarTheme(
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
        ),
      ),

      themeMode:
          themeMode == ReNovaThemeMode.light
              ? ThemeMode.light
              : ThemeMode.dark,

      home:
          LanguageSelectionScreen(
        themeMode: themeMode,
        onThemeChanged: changeTheme,
        language: language,
        onLanguageChanged:
            changeLanguage,
      ),
    );
  }
}

// ============================================================
// COMMON THEME BUTTON
// ============================================================

Widget themeSwitchButton(
  BuildContext context,
  ReNovaThemeMode mode,
  ValueChanged<ReNovaThemeMode> onChanged,
) {
  final isDark =
      mode == ReNovaThemeMode.dark;

  return IconButton(
    tooltip: isDark
        ? 'Switch to light mode'
        : 'Switch to dark mode',
    icon: Icon(
      isDark
          ? Icons.light_mode
          : Icons.dark_mode,
      color: AppColors.primaryGold,
    ),
    onPressed: () {
      onChanged(
        isDark
            ? ReNovaThemeMode.light
            : ReNovaThemeMode.dark,
      );
    },
  );
}

// ============================================================
// SCREEN 1 - LANGUAGE
// ============================================================

class LanguageSelectionScreen
    extends StatefulWidget {
  final ReNovaThemeMode themeMode;
  final ValueChanged<ReNovaThemeMode>
      onThemeChanged;

  final AppLanguage language;
  final ValueChanged<AppLanguage>
      onLanguageChanged;

  const LanguageSelectionScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.language,
    required this.onLanguageChanged,
  });

  @override
  State<LanguageSelectionScreen>
      createState() =>
          _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends State<LanguageSelectionScreen> {
  late AppLanguage selectedLanguage;

  @override
  void initState() {
    super.initState();
    selectedLanguage = widget.language;
  }

  String get title {
    switch (selectedLanguage) {
      case AppLanguage.english:
        return 'Choose your language';
      case AppLanguage.hindi:
        return 'अपनी भाषा चुनें';
      case AppLanguage.marathi:
        return 'तुमची भाषा निवडा';
    }
  }

  String get continueText {
    switch (selectedLanguage) {
      case AppLanguage.english:
        return 'Continue';
      case AppLanguage.hindi:
        return 'आगे बढ़ें';
      case AppLanguage.marathi:
        return 'पुढे जा';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment:
                    Alignment.topRight,
                child:
                    themeSwitchButton(
                  context,
                  widget.themeMode,
                  widget.onThemeChanged,
                ),
              ),

              const SizedBox(height: 35),

              Container(
                height: 95,
                width: 95,
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.primaryGold,
                  borderRadius:
                      BorderRadius.circular(
                    28,
                  ),
                ),
                child: const Icon(
                  Icons.recycling,
                  size: 58,
                  color:
                      AppColors.darkBackground,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'ReNova',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      AppColors.primaryGold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Formal Recycling & Fair Price Bridge',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color:
                      AppThemeColors.muted(
                    context,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Text(
                title,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      AppThemeColors.text(
                    context,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              _languageButton(
                'English',
                AppLanguage.english,
              ),

              _languageButton(
                'हिंदी',
                AppLanguage.hindi,
              ),

              _languageButton(
                'मराठी',
                AppLanguage.marathi,
              ),

              const SizedBox(height: 20),

              SizedBox(
                width:
                    double.infinity,
                height: 54,
                child:
                    ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primaryGold,
                    foregroundColor:
                        AppColors.darkBackground,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                  onPressed: () {
                    widget
                        .onLanguageChanged(
                      selectedLanguage,
                    );

                    final storage = _getStorage(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CollectorProfileScreen(
                          language:
                              selectedLanguage,
                          themeMode:
                              widget.themeMode,
                          onThemeChanged:
                              widget
                                  .onThemeChanged,
                          storage: storage,
                          initialName: storage.collectorName ?? '',
                          initialLocation: storage.location ?? '',
                        ),
                      ),
                    );
                  },
                  child: Text(
                    continueText,
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _languageButton(
    String text,
    AppLanguage language,
  ) {
    final selected =
        selectedLanguage == language;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLanguage =
              language;
        });
      },
      child: Container(
        width: double.infinity,
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
            const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 18,
        ),
        decoration:
            BoxDecoration(
          color: selected
              ? AppColors.primaryGold
                  .withValues(
                  alpha: 0.18,
                )
              : AppThemeColors.card(
                  context,
                ),
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primaryGold
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected
                  ? AppColors.primaryGold
                  : AppThemeColors.faint(
                      context,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      AppThemeColors.text(
                    context,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STORAGE ACCESS
// ============================================================

ReNovaStorage _getStorage(
  BuildContext context,
) {
  final state =
      context.findAncestorStateOfType<
          _ReNovaAppState>();

  if (state == null) {
    throw Exception(
      'ReNova storage is unavailable.',
    );
  }

  return state.widget.storage;
}

// ============================================================
// SCREEN 2 - COLLECTOR PROFILE (LOGIN / SIGNUP)
// ============================================================

class CollectorProfileScreen
    extends StatefulWidget {
  final AppLanguage language;

  final ReNovaThemeMode themeMode;
  final ValueChanged<ReNovaThemeMode>
      onThemeChanged;

  final ReNovaStorage storage;

  final String initialName;
  final String initialLocation;

  const CollectorProfileScreen({
    super.key,
    required this.language,
    required this.themeMode,
    required this.onThemeChanged,
    required this.storage,
    required this.initialName,
    required this.initialLocation,
  });

  @override
  State<CollectorProfileScreen>
      createState() =>
          _CollectorProfileScreenState();
}

class _CollectorProfileScreenState
    extends State<CollectorProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController locationController;

  final ImagePicker picker = ImagePicker();
  String? profileImagePath;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.initialName,
    );

    locationController = TextEditingController(
      text: widget.initialLocation,
    );

    profileImagePath = widget.storage.profileImagePath;
  }

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (image == null) return;

    final savedPath = await widget.storage.saveImagePermanently(
      image,
      'renova_profile.jpg',
    );

    setState(() {
      profileImagePath = savedPath;
    });
  }

  String get title {
    switch (widget.language) {
      case AppLanguage.english:
        return 'Welcome to ReNova';
      case AppLanguage.hindi:
        return 'ReNova में आपका स्वागत है';
      case AppLanguage.marathi:
        return 'ReNova मध्ये आपले स्वागत आहे';
    }
  }

  String get nameLabel {
    switch (widget.language) {
      case AppLanguage.english:
        return 'Your Name';
      case AppLanguage.hindi:
        return 'आपका नाम';
      case AppLanguage.marathi:
        return 'तुमचे नाव';
    }
  }

  String get locationLabel {
    switch (widget.language) {
      case AppLanguage.english:
        return 'Your Location';
      case AppLanguage.hindi:
        return 'आपका स्थान';
      case AppLanguage.marathi:
        return 'तुमचे स्थान';
    }
  }

  String get continueText {
    switch (widget.language) {
      case AppLanguage.english:
        return 'Enter ReNova';
      case AppLanguage.hindi:
        return 'ReNova में जाएं';
      case AppLanguage.marathi:
        return 'ReNova मध्ये जा';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValidImage = profileImagePath != null && File(profileImagePath!).existsSync();

    return Scaffold(
      appBar: AppBar(
        actions: [
          themeSwitchButton(
            context,
            widget.themeMode,
            widget.onThemeChanged,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primaryGold,
                    backgroundImage: hasValidImage ? FileImage(File(profileImagePath!)) : null,
                    child: !hasValidImage
                        ? const Icon(
                            Icons.person,
                            size: 52,
                            color: AppColors.darkBackground,
                          )
                        : null,
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.accentCoral,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      onPressed: _pickProfileImage,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: AppThemeColors.text(context),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Create or log into your digital collector profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppThemeColors.muted(context),
                ),
              ),

              const SizedBox(height: 35),

              _label(nameLabel),

              const SizedBox(height: 8),

              _field(
                controller: nameController,
                hint: 'e.g. Rahul Sharma',
                icon: Icons.person,
              ),

              const SizedBox(height: 18),

              _label(locationLabel),

              const SizedBox(height: 8),

              _field(
                controller: locationController,
                hint: 'e.g. Bhubaneswar',
                icon: Icons.location_on,
              ),

              const SizedBox(height: 25),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.mintGreen.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.privacy_tip,
                      color: AppColors.mintGreen,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Only essential collector information is used. ReNova does not require unnecessary personal details.',
                        style: TextStyle(
                          color: AppThemeColors.text(context),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: AppColors.darkBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _enterApp,
                  child: Text(
                    continueText,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppThemeColors.text(context),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: AppThemeColors.card(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Future<void> _enterApp() async {
    final name = nameController.text.trim();
    final location = locationController.text.trim();

    if (name.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name and location.'),
        ),
      );
      return;
    }

    await widget.storage.saveProfile(
      name: name,
      location: location,
      language: widget.language.name,
      paymentPreference: widget.storage.paymentPreference ?? 'Cash',
      profileImagePath: profileImagePath,
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainDashboardContainer(
          collectorName: name,
          location: location,
          language: widget.language,
          themeMode: widget.themeMode,
          onThemeChanged: widget.onThemeChanged,
          storage: widget.storage,
        ),
      ),
    );
  }
}

// ============================================================
// MAIN DASHBOARD
// ============================================================

class MainDashboardContainer extends StatefulWidget {
  final String collectorName;
  final String location;
  final AppLanguage language;

  final ReNovaThemeMode themeMode;
  final ValueChanged<ReNovaThemeMode> onThemeChanged;

  final ReNovaStorage storage;

  const MainDashboardContainer({
    super.key,
    required this.collectorName,
    required this.location,
    required this.language,
    required this.themeMode,
    required this.onThemeChanged,
    required this.storage,
  });

  @override
  State<MainDashboardContainer> createState() => _MainDashboardContainerState();
}

class _MainDashboardContainerState extends State<MainDashboardContainer> {
  late AppLanguage currentLanguage;
  late String collectorName;
  late String location;

  int currentIndex = 4;

  String paymentPreference = 'Cash';
  String? profileImagePath;
  String? uploadedPickupPath;

  @override
  void initState() {
    super.initState();

    currentLanguage = widget.language;
    collectorName = widget.collectorName;
    location = widget.location;

    paymentPreference = widget.storage.paymentPreference ?? 'Cash';
    profileImagePath = widget.storage.profileImagePath;
    uploadedPickupPath = widget.storage.pickupImagePath;
  }

  String get historyText {
    switch (currentLanguage) {
      case AppLanguage.english:
        return 'History';
      case AppLanguage.hindi:
        return 'इतिहास';
      case AppLanguage.marathi:
        return 'इतिहास';
    }
  }

  String get earningsText {
    switch (currentLanguage) {
      case AppLanguage.english:
        return 'Earnings';
      case AppLanguage.hindi:
        return 'कमाई';
      case AppLanguage.marathi:
        return 'कमाई';
    }
  }

  String get paymentText {
    switch (currentLanguage) {
      case AppLanguage.english:
        return 'Payment';
      case AppLanguage.hindi:
        return 'भुगतान';
      case AppLanguage.marathi:
        return 'पेमेंट';
    }
  }

  String get pickupText {
    switch (currentLanguage) {
      case AppLanguage.english:
        return 'Pickup';
      case AppLanguage.hindi:
        return 'पिकअप';
      case AppLanguage.marathi:
        return 'पिकअप';
    }
  }

  String get settingsText {
    switch (currentLanguage) {
      case AppLanguage.english:
        return 'Settings';
      case AppLanguage.hindi:
        return 'सेटिंग्स';
      case AppLanguage.marathi:
        return 'सेटिंग्ज';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HistoryTab(
        language: currentLanguage,
      ),

      const EarningsTab(),

      PaymentTab(
        language: currentLanguage,
        paymentPreference: paymentPreference,
        onPaymentPreferenceChanged: _changePayment,
      ),

      PickupUploadTab(
        savedPhotoPath: uploadedPickupPath,
        storage: widget.storage,
        onPhotoUploaded: (path) {
          setState(() {
            uploadedPickupPath = path;
          });
        },
      ),

      SettingsTab(
        collectorName: collectorName,
        location: location,
        language: currentLanguage,
        profileImagePath: profileImagePath,
        paymentPreference: paymentPreference,
        themeMode: widget.themeMode,
        onThemeChanged: widget.onThemeChanged,
        onLanguageChanged: (language) async {
          setState(() {
            currentLanguage = language;
          });

          await widget.storage.prefs.setString(
            'language',
            language.name,
          );
        },
        onProfileUpdated: (
          newName,
          newLocation,
          newPayment,
          newImage,
        ) async {
          await _saveProfile(
            newName,
            newLocation,
            newPayment,
            newImage,
          );
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(
              Icons.recycling,
              color: AppColors.primaryGold,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'ReNova',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
            ),
            onPressed: _showNotifications,
          ),

          themeSwitchButton(
            context,
            widget.themeMode,
            widget.onThemeChanged,
          ),

          Container(
            margin: const EdgeInsets.only(
              right: 8,
              top: 11,
              bottom: 11,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.mintGreen.withValues(
                alpha: 0.15,
              ),
              borderRadius: BorderRadius.circular(
                20,
              ),
              border: Border.all(
                color: AppColors.mintGreen,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_off,
                  size: 13,
                  color: AppColors.mintGreen,
                ),
                SizedBox(width: 3),
                Text(
                  'Offline',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.mintGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      body: IndexedStack(
        index: currentIndex,
        children: tabs,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(
              Icons.history,
            ),
            selectedIcon: const Icon(
              Icons.history,
              color: AppColors.primaryGold,
            ),
            label: historyText,
          ),
          NavigationDestination(
            icon: const Icon(
              Icons.currency_rupee,
            ),
            selectedIcon: const Icon(
              Icons.currency_rupee,
              color: AppColors.primaryGold,
            ),
            label: earningsText,
          ),
          NavigationDestination(
            icon: const Icon(
              Icons.account_balance_wallet,
            ),
            selectedIcon: const Icon(
              Icons.account_balance_wallet,
              color: AppColors.primaryGold,
            ),
            label: paymentText,
          ),
          NavigationDestination(
            icon: const Icon(
              Icons.local_shipping,
            ),
            selectedIcon: const Icon(
              Icons.local_shipping,
              color: AppColors.primaryGold,
            ),
            label: pickupText,
          ),
          NavigationDestination(
            icon: const Icon(
              Icons.settings,
            ),
            selectedIcon: const Icon(
              Icons.settings,
              color: AppColors.primaryGold,
            ),
            label: settingsText,
          ),
        ],
      ),
    );
  }

  Future<void> _changePayment(
    String value,
  ) async {
    setState(() {
      paymentPreference = value;
    });

    await widget.storage.prefs.setString(
      'payment_preference',
      value,
    );
  }

  Future<void> _saveProfile(
    String name,
    String newLocation,
    String newPayment,
    XFile? image,
  ) async {
    String? imagePath = profileImagePath;

    if (image != null) {
      imagePath = await widget.storage.saveImagePermanently(
        image,
        'renova_profile.jpg',
      );
    }

    setState(() {
      collectorName = name;
      location = newLocation;
      paymentPreference = newPayment;
      profileImagePath = imagePath;
    });

    await widget.storage.saveProfile(
      name: name,
      location: newLocation,
      language: currentLanguage.name,
      paymentPreference: newPayment,
      profileImagePath: imagePath,
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemeColors.card(
        context,
      ),
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGold,
                  ),
                ),
                const SizedBox(height: 20),
                _notificationTile(
                  Icons.local_shipping,
                  'Pickup matched',
                  'EcoRecycle Ltd is 0.8 km away.',
                ),
                _notificationTile(
                  Icons.currency_rupee,
                  'Payment received',
                  '₹1,750 added to your wallet.',
                ),
                _notificationTile(
                  Icons.auto_awesome,
                  'AI classification',
                  'Upload a photo to identify scrap.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _notificationTile(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryGold.withValues(
          alpha: 0.15,
        ),
        child: Icon(
          icon,
          color: AppColors.primaryGold,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppThemeColors.muted(
            context,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TAB 1 - HISTORY
// ============================================================

class HistoryTab extends StatefulWidget {
  final AppLanguage language;

  const HistoryTab({
    super.key,
    required this.language,
  });

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  String selectedPeriod = 'Week';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppThemeColors.text(
                      context,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(
                  maxWidth: 125,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: AppThemeColors.card(
                    context,
                  ),
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedPeriod,
                    isDense: true,
                    dropdownColor: AppThemeColors.card(
                      context,
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.primaryGold,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Week',
                        child: Text('Week'),
                      ),
                      DropdownMenuItem(
                        value: 'Month',
                        child: Text('Month'),
                      ),
                      DropdownMenuItem(
                        value: 'Year',
                        child: Text('Year'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        selectedPeriod = value;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'Showing transactions for $selectedPeriod',
            style: TextStyle(
              color: AppThemeColors.faint(
                context,
              ),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 18),

          _historyCard(
            'PCB / Circuit Boards',
            '12 Sep 2026',
            '8.5 kg',
            '₹2,975',
            Icons.memory,
          ),

          _historyCard(
            'Copper Cables',
            '08 Sep 2026',
            '12 kg',
            '₹3,000',
            Icons.cable,
          ),

          _historyCard(
            'Lead-Acid Batteries',
            '04 Sep 2026',
            '20 kg',
            '₹1,800',
            Icons.battery_full,
          ),

          _historyCard(
            'CRT Glass',
            '29 Aug 2026',
            '25 kg',
            '₹750',
            Icons.tv,
          ),
        ],
      ),
    );
  }

  Widget _historyCard(
    String title,
    String date,
    String weight,
    String amount,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemeColors.card(
          context,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.primaryGold.withValues(
              alpha: 0.16,
            ),
            child: Icon(
              icon,
              color: AppColors.primaryGold,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$date • $weight',
                  style: TextStyle(
                    color: AppThemeColors.muted(
                      context,
                    ),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: const TextStyle(
              color: AppColors.primaryGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TAB 2 - EARNINGS
// ============================================================

class EarningsTab extends StatelessWidget {
  const EarningsTab({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Earnings',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.text(
                context,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppThemeColors.card(
                context,
              ),
              borderRadius: BorderRadius.circular(
                20,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This Month',
                  style: TextStyle(
                    color: AppThemeColors.muted(
                      context,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '₹18,450',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGold,
                  ),
                ),
                const SizedBox(height: 8),
                const Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: AppColors.mintGreen,
                    ),
                    SizedBox(width: 5),
                    Text(
                      '+18.5% from last month',
                      style: TextStyle(
                        color: AppColors.mintGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Material-wise Earnings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.text(
                context,
              ),
            ),
          ),

          const SizedBox(height: 12),

          _earningRow(
            context,
            'Copper',
            '₹7,200',
            Icons.cable,
          ),

          _earningRow(
            context,
            'PCB',
            '₹5,800',
            Icons.memory,
          ),

          _earningRow(
            context,
            'Batteries',
            '₹3,950',
            Icons.battery_full,
          ),

          _earningRow(
            context,
            'CRT',
            '₹1,500',
            Icons.tv,
          ),
        ],
      ),
    );
  }

  Widget _earningRow(
    BuildContext context,
    String title,
    String amount,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppThemeColors.card(
          context,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primaryGold,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              color: AppColors.primaryGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PRICE BOARD
// ============================================================

class PriceBoardTab extends StatefulWidget {
  const PriceBoardTab({
    super.key,
  });

  @override
  State<PriceBoardTab> createState() => _PriceBoardTabState();
}

class _PriceBoardTabState extends State<PriceBoardTab> {
  final FlutterTts tts = FlutterTts();

  String selectedLocation = 'Bhubaneswar';

  final locations = [
    'Bhubaneswar',
    'Cuttack',
    'Mumbai',
    'Delhi',
    'Pune',
  ];

  final List<Map<String, dynamic>> prices = [
    {
      'material': 'Copper',
      'rate': '₹620/kg',
      'trend': '+4.2%',
      'up': true,
      'icon': Icons.cable,
    },
    {
      'material': 'PCB',
      'rate': '₹480/kg',
      'trend': '+6.1%',
      'up': true,
      'icon': Icons.memory,
    },
    {
      'material': 'Aluminium',
      'rate': '₹165/kg',
      'trend': '+1.8%',
      'up': true,
      'icon': Icons.settings,
    },
    {
      'material': 'Lead Battery',
      'rate': '₹95/kg',
      'trend': '-1.4%',
      'up': false,
      'icon': Icons.battery_full,
    },
    {
      'material': 'CRT Glass',
      'rate': '₹30/kg',
      'trend': '+0.8%',
      'up': true,
      'icon': Icons.tv,
    },
    {
      'material': 'Mixed E-Waste',
      'rate': '₹110/kg',
      'trend': '+2.7%',
      'up': true,
      'icon': Icons.devices_other,
    },
  ];

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  Future<void> _speak(
    String text,
  ) async {
    await tts.setLanguage('en-IN');
    await tts.setSpeechRate(0.42);
    await tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Buying Rates',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.text(
                context,
              ),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Indicative local rates • verify before transaction',
            style: TextStyle(
              color: AppThemeColors.muted(
                context,
              ),
            ),
          ),

          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            decoration: BoxDecoration(
              color: AppThemeColors.card(
                context,
              ),
              borderRadius: BorderRadius.circular(
                14,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedLocation,
                isExpanded: true,
                dropdownColor: AppThemeColors.card(
                  context,
                ),
                icon: const Icon(
                  Icons.location_on,
                  color: AppColors.primaryGold,
                ),
                items: locations.map(
                  (location) {
                    return DropdownMenuItem(
                      value: location,
                      child: Text(location),
                    );
                  },
                ).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    selectedLocation = value;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 15),

          ...prices.map(
            (price) => _priceCard(
              context,
              price,
            ),
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(
                14,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.primaryGold,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Prices shown are sample prototype data. In the production version they can be synchronized with recycler and market feeds.',
                    style: TextStyle(
                      color: AppThemeColors.text(
                        context,
                      ),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceCard(
    BuildContext context,
    Map<String, dynamic> price,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppThemeColors.card(
          context,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryGold.withValues(
              alpha: 0.15,
            ),
            child: Icon(
              price['icon'] as IconData,
              color: AppColors.primaryGold,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price['material'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  price['rate'] as String,
                  style: const TextStyle(
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),

          Column(
            children: [
              Icon(
                price['up'] as bool
                    ? Icons.trending_up
                    : Icons.trending_down,
                color: price['up'] as bool
                    ? AppColors.lightGreen
                    : AppColors.danger,
              ),
              Text(
                price['trend'] as String,
                style: TextStyle(
                  color: price['up'] as bool
                      ? AppColors.lightGreen
                      : AppColors.danger,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),

          IconButton(
            tooltip: 'Speak price',
            onPressed: () {
              _speak(
                '${price['material']} in $selectedLocation is ${price['rate']}. Trend ${price['trend']}',
              );
            },
            icon: const Icon(
              Icons.volume_up,
              color: AppColors.mintGreen,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SAFETY GUIDANCE
// ============================================================

class SafetyTab extends StatefulWidget {
  const SafetyTab({
    super.key,
  });

  @override
  State<SafetyTab> createState() => _SafetyTabState();
}

class _SafetyTabState extends State<SafetyTab> {
  final FlutterTts tts = FlutterTts();

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  Future<void> _speak(
    String text,
  ) async {
    await tts.setLanguage('en-IN');
    await tts.setSpeechRate(0.42);
    await tts.speak(text);
  }

  final guidance = const [
    {
      'title': 'Do not burn e-waste',
      'description':
          'Burning wires, plastic or electronic parts can release toxic fumes. Use authorized recycling channels instead.',
      'icon': Icons.local_fire_department,
      'danger': true,
      'audio':
          'Do not burn electronic waste, wires, batteries or plastic. Burning can release toxic fumes.',
    },
    {
      'title': 'Do not open batteries',
      'description':
          'Do not cut, puncture or dismantle batteries. Keep damaged batteries isolated and contact an authorized recycler.',
      'icon': Icons.battery_alert,
      'danger': true,
      'audio':
          'Do not open, cut or puncture batteries. Keep damaged batteries isolated and contact an authorized recycler.',
    },
    {
      'title': 'Handle CRTs carefully',
      'description':
          'CRT televisions and monitors can contain hazardous materials. Avoid breaking the glass and do not smash or burn CRTs.',
      'icon': Icons.tv,
      'danger': true,
      'audio':
          'Handle CRT televisions and monitors carefully. Do not smash, break or burn CRT glass.',
    },
    {
      'title': 'Keep electronics dry',
      'description':
          'Store circuit boards and electronics in a dry, covered place before collection.',
      'icon': Icons.water_drop,
      'danger': false,
      'audio':
          'Keep circuit boards and electronic components dry and covered before collection.',
    },
    {
      'title': 'Use basic protection',
      'description':
          'Use gloves, closed footwear and eye protection when handling sharp or damaged electronic parts.',
      'icon': Icons.health_and_safety,
      'danger': false,
      'audio':
          'Use gloves, closed footwear and eye protection when handling sharp or damaged electronic parts.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Safety Guidance',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.text(
                context,
              ),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Simple picture-based and audio guidance for safer e-waste handling.',
            style: TextStyle(
              color: AppThemeColors.muted(
                context,
              ),
            ),
          ),

          const SizedBox(height: 18),

          ...guidance.map(
            (item) => _safetyCard(
              context,
              item,
            ),
          ),
        ],
      ),
    );
  }

  Widget _safetyCard(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final danger = item['danger'] as bool;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemeColors.card(
          context,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: danger
              ? AppColors.danger.withValues(
                  alpha: 0.45,
                )
              : AppColors.lightGreen.withValues(
                  alpha: 0.35,
                ),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: danger
                      ? AppColors.danger.withValues(
                          alpha: 0.13,
                        )
                      : AppColors.lightGreen.withValues(
                          alpha: 0.13,
                        ),
                  borderRadius: BorderRadius.circular(
                    16,
                  ),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  size: 30,
                  color: danger
                      ? AppColors.danger
                      : AppColors.lightGreen,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['description'] as String,
                      style: TextStyle(
                        color: AppThemeColors.muted(
                          context,
                        ),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _speak(
                  item['audio'] as String,
                );
              },
              icon: const Icon(
                Icons.volume_up,
                color: AppColors.mintGreen,
              ),
              label: const Text(
                'Listen to guidance',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TAB 3 - PAYMENT
// ============================================================

class PaymentTab extends StatelessWidget {
  final AppLanguage language;
  final String paymentPreference;

  final ValueChanged<String> onPaymentPreferenceChanged;

  const PaymentTab({
    super.key,
    required this.language,
    required this.paymentPreference,
    required this.onPaymentPreferenceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      ['Cash', Icons.money],
      [
        'UPI / Digital Wallet',
        Icons.qr_code,
      ],
      [
        'Bank Transfer',
        Icons.account_balance,
      ],
      [
        'Direct Recycler Settlement',
        Icons.factory,
      ],
      [
        'Cheque',
        Icons.receipt_long,
      ],
      [
        'Post-Paid Digital Wallet',
        Icons.wallet,
      ],
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Preference',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.text(
                context,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Cash remains available. Digital payment is optional.',
            style: TextStyle(
              color: AppThemeColors.muted(
                context,
              ),
            ),
          ),

          const SizedBox(height: 20),

          ...options.map(
            (item) => _paymentOptionTile(
              context,
              item[0] as String,
              item[1] as IconData,
            ),
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.mintGreen.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(
                16,
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.verified_user,
                  color: AppColors.mintGreen,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ReNova prioritizes transparent and documented payments without forcing users to adopt digital payments.',
                    style: TextStyle(
                      color: AppColors.mintGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentOptionTile(
    BuildContext context,
    String option,
    IconData icon,
  ) {
    final selected = paymentPreference == option;

    return GestureDetector(
      onTap: () => onPaymentPreferenceChanged(
        option,
      ),
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 12,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryGold.withValues(
                  alpha: 0.18,
                )
              : AppThemeColors.card(
                  context,
                ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryGold : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.primaryGold,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                option,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected
                  ? AppColors.primaryGold
                  : AppThemeColors.veryFaint(
                      context,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TAB 4 - PICKUP + AI
// ============================================================

class PickupUploadTab extends StatefulWidget {
  final String? savedPhotoPath;
  final ReNovaStorage storage;

  final ValueChanged<String?> onPhotoUploaded;

  const PickupUploadTab({
    super.key,
    required this.savedPhotoPath,
    required this.storage,
    required this.onPhotoUploaded,
  });

  @override
  State<PickupUploadTab> createState() => _PickupUploadTabState();
}

class _PickupUploadTabState extends State<PickupUploadTab> {
  final ImagePicker picker = ImagePicker();

  bool isAnalysing = false;

  String detectedMaterial = 'E-Waste / Mixed Electronics';
  String confidence = '92%';
  String estimatedWeight = 'Approx. 8–10 kg';
  String estimatedValue = '₹2,400 – ₹3,100';
  String materialCategory = 'Recoverable Electronic Waste';
  bool isHazardous = false;
  String recommendation =
      'Separate circuit boards, cables and batteries before handing over.';
  String recyclerRecommendation = 'Authorized E-Waste Recycler';

  Future<void> _pickImage(
    ImageSource source,
  ) async {
    try {
      final image = await picker.pickImage(
        source: source,
        imageQuality: 75,
      );

      if (image == null) return;

      final permanentPath = await widget.storage.saveImagePermanently(
        image,
        'renova_pickup.jpg',
      );

      await widget.storage.prefs.setString(
        'pickup_image_path',
        permanentPath,
      );

      widget.onPhotoUploaded(
        permanentPath,
      );

      await _runAiClassification(
        image,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to access image: $e',
          ),
        ),
      );
    }
  }

  Future<void> _runAiClassification(
    XFile image,
  ) async {
    setState(() {
      isAnalysing = true;
    });

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    final filename = image.name.toLowerCase();

    if (filename.contains('battery')) {
      detectedMaterial = 'Lead-Acid / Lithium Battery';
      confidence = '94%';
      estimatedWeight = 'Approx. 10–15 kg';
      estimatedValue = '₹1,500 – ₹2,500';
      materialCategory = 'Potentially Hazardous E-Waste';
      isHazardous = true;
      recommendation =
          'Do not dismantle. Hand over to an authorized battery recycler.';
      recyclerRecommendation = 'Authorized Battery Recycler';
    } else if (filename.contains('cable') || filename.contains('copper')) {
      detectedMaterial = 'Copper Cable / Wire';
      confidence = '96%';
      estimatedWeight = 'Approx. 8–12 kg';
      estimatedValue = '₹2,500 – ₹4,000';
      materialCategory = 'High-Value Recoverable Material';
      isHazardous = false;
      recommendation =
          'Separate copper cables from plastic insulation for better recovery.';
      recyclerRecommendation = 'Metal Recovery Recycler';
    } else if (filename.contains('pcb') || filename.contains('circuit')) {
      detectedMaterial = 'PCB / Circuit Boards';
      confidence = '95%';
      estimatedWeight = 'Approx. 5–8 kg';
      estimatedValue = '₹2,000 – ₹3,500';
      materialCategory = 'High-Value Electronic Waste';
      isHazardous = false;
      recommendation =
          'Keep circuit boards dry and avoid unsafe backyard processing.';
      recyclerRecommendation = 'Authorized E-Waste Recycler';
    } else {
      detectedMaterial = 'E-Waste / Mixed Electronics';
      confidence = '92%';
      estimatedWeight = 'Approx. 8–10 kg';
      estimatedValue = '₹2,400 – ₹3,100';
      materialCategory = 'Recoverable Electronic Waste';
      isHazardous = false;
      recommendation =
          'Separate batteries and hazardous components before handover.';
      recyclerRecommendation = 'Authorized E-Waste Recycler';
    }

    setState(() {
      isAnalysing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.savedPhotoPath;
    final hasPhoto = path != null && File(path).existsSync();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scrap Pickup & AI Verification',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.text(
                context,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Upload a photo and ReNova can analyse the material, estimate value and recommend a recycling channel.',
            style: TextStyle(
              color: AppThemeColors.muted(
                context,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              color: AppThemeColors.card(
                context,
              ),
              borderRadius: BorderRadius.circular(
                16,
              ),
              border: Border.all(
                color: AppColors.primaryGold,
              ),
            ),
            child: hasPhoto
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(
                      16,
                    ),
                    child: Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_a_photo,
                        size: 60,
                        color: AppColors.primaryGold,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No photo uploaded yet',
                        style: TextStyle(
                          color: AppThemeColors.faint(
                            context,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: AppColors.darkBackground,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                  onPressed: () => _pickImage(
                    ImageSource.camera,
                  ),
                  icon: const Icon(
                    Icons.camera_alt,
                  ),
                  label: const Text(
                    'Camera',
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGold,
                    side: const BorderSide(
                      color: AppColors.primaryGold,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                  onPressed: () => _pickImage(
                    ImageSource.gallery,
                  ),
                  icon: const Icon(
                    Icons.photo_library,
                  ),
                  label: const Text(
                    'Gallery',
                  ),
                ),
              ),
            ],
          ),

          if (hasPhoto) ...[
            const SizedBox(height: 24),

            if (isAnalysing)
              _buildAnalysingCard()
            else
              _buildAiResultCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppThemeColors.card(
          context,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.mintGreen,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(
            height: 35,
            width: 35,
            child: CircularProgressIndicator(),
          ),
          const SizedBox(height: 16),
          const Text(
            'AI is analysing your scrap...',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Identifying material, category and estimated value',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppThemeColors.muted(
                context,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppThemeColors.card(
          context,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.mintGreen,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(
                  10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mintGreen.withValues(
                    alpha: 0.15,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.mintGreen,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Classification',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Analysis complete',
                      style: TextStyle(
                        color: AppColors.mintGreen,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mintGreen.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  confidence,
                  style: const TextStyle(
                    color: AppColors.mintGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _aiInfoRow(
            Icons.category,
            'Detected Material',
            detectedMaterial,
          ),

          _aiInfoRow(
            Icons.inventory_2,
            'Category',
            materialCategory,
          ),

          _aiInfoRow(
            Icons.scale,
            'Estimated Weight',
            estimatedWeight,
          ),

          _aiInfoRow(
            Icons.currency_rupee,
            'Estimated Value',
            estimatedValue,
          ),

          _aiInfoRow(
            Icons.factory,
            'Recommended Recycler',
            recyclerRecommendation,
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isHazardous
                  ? AppColors.danger.withValues(
                      alpha: 0.12,
                    )
                  : AppColors.lightGreen.withValues(
                      alpha: 0.12,
                    ),
              borderRadius: BorderRadius.circular(
                14,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isHazardous ? Icons.warning_amber : Icons.verified,
                  color: isHazardous ? AppColors.danger : AppColors.lightGreen,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHazardous
                            ? 'Potentially Hazardous'
                            : 'Handling Status: Safe to Sort',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isHazardous ? AppColors.danger : AppColors.lightGreen,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        recommendation,
                        style: TextStyle(
                          color: AppThemeColors.muted(
                            context,
                          ),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (widget.savedPhotoPath != null) {
                      _runAiClassification(
                        XFile(
                          widget.savedPhotoPath!,
                        ),
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.refresh,
                  ),
                  label: const Text(
                    'Re-analyse',
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mintGreen,
                    foregroundColor: AppColors.darkBackground,
                  ),
                  onPressed: _removePhoto,
                  icon: const Icon(
                    Icons.delete,
                  ),
                  label: const Text(
                    'Remove',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _removePhoto() async {
    await widget.storage.removePickupImage();
    widget.onPhotoUploaded(null);

    if (!mounted) return;
    setState(() {});
  }

  Widget _aiInfoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primaryGold,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppThemeColors.faint(
                      context,
                    ),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SETTINGS
// ============================================================

class SettingsTab extends StatefulWidget {
  final String collectorName;
  final String location;
  final AppLanguage language;

  final String? profileImagePath;
  final String paymentPreference;

  final ReNovaThemeMode themeMode;
  final ValueChanged<ReNovaThemeMode> onThemeChanged;
  final ValueChanged<AppLanguage> onLanguageChanged;

  final Function(
    String,
    String,
    String,
    XFile?,
  ) onProfileUpdated;

  const SettingsTab({
    super.key,
    required this.collectorName,
    required this.location,
    required this.language,
    required this.profileImagePath,
    required this.paymentPreference,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.onProfileUpdated,
  });

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final ImagePicker picker = ImagePicker();
  String? tempImagePath;

  @override
  void initState() {
    super.initState();
    tempImagePath = widget.profileImagePath;
  }

  @override
  void didUpdateWidget(covariant SettingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profileImagePath != oldWidget.profileImagePath) {
      tempImagePath = widget.profileImagePath;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValidImage = tempImagePath != null && File(tempImagePath!).existsSync();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.primaryGold,
                  backgroundImage: hasValidImage ? FileImage(File(tempImagePath!)) : null,
                  child: !hasValidImage
                      ? const Icon(
                          Icons.person,
                          size: 62,
                          color: AppColors.darkBackground,
                        )
                      : null,
                ),

                const SizedBox(height: 12),

                Text(
                  widget.collectorName,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  widget.location,
                  style: TextStyle(
                    color: AppThemeColors.muted(context),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          _settingsTile(
            context,
            Icons.person_outline,
            'Edit Profile',
            'Update your minimal collector profile',
            () {
              _openEditProfile(context);
            },
          ),

          const SizedBox(height: 24),

          _sectionTitle('Language Options'),

          _langTile(context, 'English', AppLanguage.english),
          _langTile(context, 'हिंदी', AppLanguage.hindi),
          _langTile(context, 'मराठी', AppLanguage.marathi),

          const SizedBox(height: 24),

          _sectionTitle('Appearance'),

          _themeTile(
            context,
            ReNovaThemeMode.light,
            'Light Mode',
            Icons.light_mode,
          ),

          _themeTile(
            context,
            ReNovaThemeMode.dark,
            'Dark Mode',
            Icons.dark_mode,
          ),

          const SizedBox(height: 24),

          _sectionTitle('Collector Tools'),

          _settingsTile(
            context,
            Icons.currency_rupee,
            'Price Board',
            'Current buying rates and price trends',
            () {
              _openPriceBoard(context);
            },
          ),

          const SizedBox(height: 10),

          _settingsTile(
            context,
            Icons.health_and_safety,
            'Safety Guidance',
            'Picture and audio safety instructions',
            () {
              _openSafety(context);
            },
          ),

          const SizedBox(height: 24),

          _sectionTitle('Account Settings'),

          _settingsTile(
            context,
            Icons.lock,
            'Security & Passcode',
            'Manage account security',
            () {
              _showComingSoon(
                context,
                'Security & Passcode',
              );
            },
          ),

          const SizedBox(height: 10),

          _settingsTile(
            context,
            Icons.notifications,
            'Notifications',
            'Pickup, payment and AI alerts',
            () {
              _showComingSoon(
                context,
                'Notification Settings',
              );
            },
          ),

          const SizedBox(height: 10),

          _settingsTile(
            context,
            Icons.help_outline,
            'Help & Support',
            'Get help with ReNova',
            () {
              _showComingSoon(
                context,
                'Help & Support',
              );
            },
          ),

          const SizedBox(height: 10),

          _settingsTile(
            context,
            Icons.info_outline,
            'About ReNova',
            'Version 1.0 • SIH Prototype',
            () {
              _showAbout(context);
            },
          ),

          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _themeTile(
    BuildContext context,
    ReNovaThemeMode mode,
    String title,
    IconData icon,
  ) {
    final selected = widget.themeMode == mode;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: AppThemeColors.card(
          context,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.primaryGold : Colors.transparent,
        ),
      ),
      child: RadioListTile<ReNovaThemeMode>(
        value: mode,
        groupValue: widget.themeMode,
        onChanged: (value) {
          if (value != null) {
            widget.onThemeChanged(value);
          }
        },
        title: Text(title),
        secondary: Icon(
          icon,
          color: AppColors.primaryGold,
        ),
        activeColor: AppColors.primaryGold,
      ),
    );
  }

  Widget _settingsTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 5,
      ),
      tileColor: AppThemeColors.card(
        context,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryGold.withValues(
          alpha: 0.15,
        ),
        child: Icon(
          icon,
          color: AppColors.primaryGold,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppThemeColors.faint(
            context,
          ),
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  Widget _langTile(
    BuildContext context,
    String label,
    AppLanguage lang,
  ) {
    final selected = widget.language == lang;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      child: ListTile(
        tileColor: AppThemeColors.card(
          context,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? AppColors.primaryGold : Colors.transparent,
          ),
        ),
        title: Text(label),
        trailing: selected
            ? const Icon(
                Icons.check,
                color: AppColors.primaryGold,
              )
            : null,
        onTap: () => widget.onLanguageChanged(lang),
      ),
    );
  }

  Future<void> _openEditProfile(
    BuildContext context,
  ) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          collectorName: widget.collectorName,
          location: widget.location,
          profileImagePath: tempImagePath,
          paymentPreference: widget.paymentPreference,
          themeMode: widget.themeMode,
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
    );

    if (result != null) {
      widget.onProfileUpdated(
        result['name'] as String,
        result['location'] as String,
        result['payment'] as String,
        result['image'] as XFile?,
      );
    }
  }

  void _openPriceBoard(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PriceBoardTab(),
      ),
    );
  }

  void _openSafety(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SafetyTab(),
      ),
    );
  }

  void _showComingSoon(
    BuildContext context,
    String title,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppThemeColors.card(
          context,
        ),
        title: Text(title),
        content: const Text(
          'This feature will be connected to the ReNova backend in the next version.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
              context,
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                color: AppColors.primaryGold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAbout(
    BuildContext context,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppThemeColors.card(
          context,
        ),
        title: const Text(
          'ReNova',
          style: TextStyle(
            color: AppColors.primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'A digital bridge connecting informal e-waste collectors with fair pricing, AI-assisted classification, safety guidance and authorized recycling channels.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
              context,
            ),
            child: const Text(
              'Close',
              style: TextStyle(
                color: AppColors.primaryGold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EDIT PROFILE
// ============================================================

class EditProfileScreen extends StatefulWidget {
  final String collectorName;
  final String location;
  final String? profileImagePath;
  final String paymentPreference;

  final ReNovaThemeMode themeMode;
  final ValueChanged<ReNovaThemeMode> onThemeChanged;

  const EditProfileScreen({
    super.key,
    required this.collectorName,
    required this.location,
    required this.profileImagePath,
    required this.paymentPreference,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController locationController;

  final ImagePicker picker = ImagePicker();
  String? profileImagePath;
  String paymentPreference = 'Cash';
  late ReNovaThemeMode selectedTheme;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.collectorName,
    );

    locationController = TextEditingController(
      text: widget.location,
    );

    profileImagePath = widget.profileImagePath;
    paymentPreference = widget.paymentPreference;
    selectedTheme = widget.themeMode;
  }

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> _changeImage() async {
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (image == null) return;

    final storage = _getStorage(context);

    final savedPath = await storage.saveImagePermanently(
      image,
      'renova_profile.jpg',
    );

    setState(() {
      profileImagePath = savedPath;
    });
  }

  void _save() {
    final name = nameController.text.trim();
    final location = locationController.text.trim();

    if (name.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name and location cannot be empty.'),
        ),
      );
      return;
    }

    final storage = _getStorage(context);

    storage.saveProfile(
      name: name,
      location: location,
      language: storage.language ?? 'english',
      paymentPreference: paymentPreference,
      profileImagePath: profileImagePath,
    );

    Navigator.pop(
      context,
      {
        'name': name,
        'location': location,
        'payment': paymentPreference,
        'image': profileImagePath != null ? XFile(profileImagePath!) : null,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasValidImage = profileImagePath != null && File(profileImagePath!).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'SAVE',
              style: TextStyle(
                color: AppColors.primaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 58,
                    backgroundColor: AppColors.primaryGold,
                    backgroundImage: hasValidImage ? FileImage(File(profileImagePath!)) : null,
                    child: !hasValidImage
                        ? const Icon(
                            Icons.person,
                            size: 65,
                            color: AppColors.darkBackground,
                          )
                        : null,
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.accentCoral,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: _changeImage,
                      icon: const Icon(
                        Icons.camera_alt,
                        size: 19,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            _sectionTitle('Personal Details'),

            _field(
              'Full Name',
              nameController,
              Icons.person,
            ),

            _field(
              'General Location',
              locationController,
              Icons.location_on,
            ),

            const SizedBox(height: 18),

            _sectionTitle('Collector Dataset'),

            _infoCard(
              Icons.badge,
              'Collector ID',
              'RN-COL-2026-01428',
            ),

            _infoCard(
              Icons.translate,
              'Preferred Language',
              'Selected in the ReNova language setup',
            ),

            _infoCard(
              Icons.history,
              'Transaction History',
              '87 recorded transactions',
            ),

            _infoCard(
              Icons.currency_rupee,
              'Earnings History',
              '₹1,84,750 total earnings',
            ),

            const SizedBox(height: 18),

            _sectionTitle('Pickup Preferences'),

            _paymentDropdown(),

            const SizedBox(height: 22),

            _sectionTitle('Appearance'),

            _themeTile(
              ReNovaThemeMode.light,
              'Light Mode',
              Icons.light_mode,
            ),

            _themeTile(
              ReNovaThemeMode.dark,
              'Dark Mode',
              Icons.dark_mode,
            ),

            const SizedBox(height: 22),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.mintGreen.withValues(
                  alpha: 0.10,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.mintGreen.withValues(
                    alpha: 0.35,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.shield,
                    color: AppColors.mintGreen,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ReNova keeps the collector profile minimal and focuses on information needed for recycling transactions.',
                      style: TextStyle(
                        color: AppThemeColors.muted(
                          context,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.darkBackground,
                ),
                onPressed: _save,
                icon: const Icon(
                  Icons.save,
                ),
                label: const Text(
                  'Save Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: AppColors.primaryGold,
          ),
          filled: true,
          fillColor: AppThemeColors.card(
            context,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppThemeColors.card(
          context,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryGold.withValues(
              alpha: 0.15,
            ),
            child: Icon(
              icon,
              color: AppColors.primaryGold,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppThemeColors.faint(
                      context,
                    ),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentDropdown() {
    final methods = [
      'Cash',
      'UPI / Digital Wallet',
      'Bank Transfer',
      'Direct Recycler Settlement',
      'Cheque',
      'Post-Paid Digital Wallet',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
      ),
      decoration: BoxDecoration(
        color: AppThemeColors.card(
          context,
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: paymentPreference,
          isExpanded: true,
          dropdownColor: AppThemeColors.card(
            context,
          ),
          items: methods
              .map(
                (method) => DropdownMenuItem(
                  value: method,
                  child: Text(method),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              paymentPreference = value;
            });
          },
        ),
      ),
    );
  }

  Widget _themeTile(
    ReNovaThemeMode mode,
    String title,
    IconData icon,
  ) {
    final selected = selectedTheme == mode;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: AppThemeColors.card(
          context,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.primaryGold : Colors.transparent,
        ),
      ),
      child: RadioListTile<ReNovaThemeMode>(
        value: mode,
        groupValue: selectedTheme,
        activeColor: AppColors.primaryGold,
        secondary: Icon(
          icon,
          color: AppColors.primaryGold,
        ),
        title: Text(title),
        onChanged: (value) {
          if (value == null) {
            return;
          }

          setState(() {
            selectedTheme = value;
          });

          widget.onThemeChanged(
            value,
          );
        },
      ),
    );
  }
}