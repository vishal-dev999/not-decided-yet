import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
  // Dark Mode Palette
  static const Color darkBackground = Color(0xFF0D1B1E); // Deep dark forest green
  static const Color cardBg = Color(0xFF1B3B36); // Rich dark emerald green

  static const Color primaryGold = Color(0xFF70A9A1); // Mint green accent
  static const Color accentCoral = Color(0xFF5A9E87); // Deep sage green
  static const Color mintGreen = Color(0xFF90E0EF);

  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color ColorGold = Color(0xFFF2B84B);
  static const Color warning = Color(0xFFF2B84B);
  static const Color danger = Color(0xFFE66A6A);

  // Light Mode Palette (Feather Green & Off-White)
  static const Color lightBackground = Color(0xFFFAFAF7); // Soft off-white background
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color featherGreen = Color(0xFF7FA998); // Soft feather green accent
  static const Color lightText = Color(0xFF1E2D2B);
  static const Color lightMuted = Color(0xFF5B7065);
  static const Color lightFaint = Color(0xFF8FA89B);
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
// LANGUAGE & USER TYPE
// ============================================================

enum AppLanguage {
  english,
  hindi,
  marathi,
}

enum UserType {
  scrapCollector,
  recycler,
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
    final directory = await getApplicationDocumentsDirectory();

    return ReNovaStorage._(
      prefs,
      directory,
    );
  }

  String? get collectorName => prefs.getString('collector_name');
  String? get location => prefs.getString('collector_location');
  String? get age => prefs.getString('collector_age');
  String? get otherDetails => prefs.getString('collector_other_details');
  String? get language => prefs.getString('language');
  String? get theme => prefs.getString('theme');
  String? get profileImagePath => prefs.getString('profile_image_path');
  String? get pickupImagePath => prefs.getString('pickup_image_path');
  String? get paymentPreference => prefs.getString('payment_preference');
  String? get userType => prefs.getString('user_type');
  String? get savedUpiId => prefs.getString('saved_upi_id');

  String get collectorId =>
      prefs.getString('collector_id') ?? 'RN-COL-2026-01428';

  Map<String, dynamic>? get recyclerData {
    final raw = prefs.getString('recycler_data');
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveRecyclerData(Map<String, dynamic> data) async {
    await prefs.setString('recycler_data', jsonEncode(data));
    await prefs.setString('user_type', 'recycler');
  }

  Future<void> saveProfile({
    required String name,
    required String location,
    String? age,
    String? otherDetails,
    required String language,
    required String paymentPreference,
    String? profileImagePath,
    String? userType,
  }) async {
    await prefs.setString('collector_name', name);
    await prefs.setString('collector_location', location);
    if (age != null) await prefs.setString('collector_age', age);
    if (otherDetails != null) await prefs.setString('collector_other_details', otherDetails);
    await prefs.setString('language', language);
    await prefs.setString('payment_preference', paymentPreference);
    if (userType != null) {
      await prefs.setString('user_type', userType);
    }

    if (profileImagePath != null) {
      await prefs.setString('profile_image_path', profileImagePath);
    }
  }

  Future<void> saveUpiId(String upiId) async {
    await prefs.setString('saved_upi_id', upiId);
  }

  Future<void> saveTheme(ReNovaThemeMode mode) async {
    await prefs.setString('theme', mode == ReNovaThemeMode.dark ? 'dark' : 'light');
  }

  Future<String> saveImagePermanently(XFile image, String filename) async {
    final target = File('${documentsDirectory.path}/$filename');
    await File(image.path).copy(target.path);
    return target.path;
  }

  Future<void> savePickupImage(XFile image) async {
    final path = await saveImagePermanently(image, 'renova_pickup.jpg');
    await prefs.setString('pickup_image_path', path);
  }

  Future<void> saveProfileImage(XFile image) async {
    final path = await saveImagePermanently(image, 'renova_profile.jpg');
    await prefs.setString('profile_image_path', path);
  }

  Future<void> removePickupImage() async {
    final path = pickupImagePath;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await prefs.remove('pickup_image_path');
  }

  List<Map<String, dynamic>> get classificationHistory {
    final raw = prefs.getStringList('classification_history') ?? [];
    return raw.map((item) {
      try {
        return Map<String, dynamic>.from(jsonDecode(item) as Map);
      } catch (_) {
        return <String, dynamic>{};
      }
    }).where((item) => item.isNotEmpty).toList();
  }

  Future<void> saveClassification(Map<String, dynamic> item) async {
    final items = prefs.getStringList('classification_history') ?? [];
    items.insert(0, jsonEncode(item));
    if (items.length > 100) {
      items.removeRange(100, items.length);
    }
    await prefs.setStringList('classification_history', items);
  }

  List<Map<String, dynamic>> get paymentHistory {
    final raw = prefs.getStringList('payment_history') ?? [];
    return raw.map((item) {
      try {
        return Map<String, dynamic>.from(jsonDecode(item) as Map);
      } catch (_) {
        return <String, dynamic>{};
      }
    }).where((item) => item.isNotEmpty).toList();
  }

  Future<void> savePayment(Map<String, dynamic> item) async {
    final items = prefs.getStringList('payment_history') ?? [];
    items.insert(0, jsonEncode(item));
    if (items.length > 100) {
      items.removeRange(100, items.length);
    }
    await prefs.setStringList('payment_history', items);
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
  State<ReNovaApp> createState() => _ReNovaAppState();
}

class _ReNovaAppState extends State<ReNovaApp> {
  late ReNovaThemeMode themeMode;
  AppLanguage language = AppLanguage.english;
  String collectorName = '';
  String location = '';
  String paymentPreference = 'Cash';
  String? profileImagePath;

  @override
  void initState() {
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

    collectorName = widget.storage.collectorName ?? '';
    location = widget.storage.location ?? '';
    paymentPreference = widget.storage.paymentPreference ?? 'Cash';
    profileImagePath = widget.storage.profileImagePath;
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
      home: LanguageSelectionScreen(
        themeMode: themeMode,
        onThemeChanged: changeTheme,
        language: language,
        onLanguageChanged: changeLanguage,
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
  final state = context.findAncestorStateOfType<_ReNovaAppState>();
  final currentMode = state?.themeMode ?? mode;
  final isDark = currentMode == ReNovaThemeMode.dark;

  return IconButton(
    tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
    icon: Icon(
      isDark ? Icons.light_mode : Icons.dark_mode,
      color: isDark ? AppColors.primaryGold : AppColors.featherGreen,
    ),
    onPressed: () {
      final newMode = isDark ? ReNovaThemeMode.light : ReNovaThemeMode.dark;
      if (state != null) {
        state.changeTheme(newMode);
      } else {
        onChanged(newMode);
      }
    },
  );
}

// ============================================================
// ANIMATED BELL ICON BUTTON
// ============================================================

class AnimatedBellIconButton extends StatefulWidget {
  final VoidCallback onPressed;

  const AnimatedBellIconButton({super.key, required this.onPressed});

  @override
  State<AnimatedBellIconButton> createState() => _AnimatedBellIconButtonState();
}

class _AnimatedBellIconButtonState extends State<AnimatedBellIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerShake() {
    _controller.forward(from: 0.0);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double rotate =
            math.sin(_controller.value * math.pi * 4) * 0.25;
        return Transform.rotate(
          angle: rotate,
          child: child,
        );
      },
      child: IconButton(
        icon: const Icon(Icons.notifications_none),
        onPressed: _triggerShake,
      ),
    );
  }
}

// ============================================================
// SCREEN 1 - LANGUAGE
// ============================================================

class LanguageSelectionScreen extends StatefulWidget {
  final ReNovaThemeMode themeMode;
  final ValueChanged<ReNovaThemeMode> onThemeChanged;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  const LanguageSelectionScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.language,
    required this.onLanguageChanged,
  });

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
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

  String get subtitle {
    switch (selectedLanguage) {
      case AppLanguage.english:
        return 'Formal Recycling & Fair Price Bridge';
      case AppLanguage.hindi:
        return 'औपचारिक रीसाइक्लिंग और उचित मूल्य पुल';
      case AppLanguage.marathi:
        return 'अधिकृत पुनर्वापर आणि योग्य मूल्य मंच';
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
    final activeAccent = AppThemeColors.isDark(context) ? AppColors.primaryGold : AppColors.featherGreen;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: themeSwitchButton(
                  context,
                  widget.themeMode,
                  widget.onThemeChanged,
                ),
              ),
              const SizedBox(height: 35),
              // Front Logo Updated
              Container(
                height: 95,
                width: 95,
                decoration: BoxDecoration(
                  color: activeAccent,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Center(
                  child: Icon(
                    Icons.eco,
                    size: 58,
                    color: AppColors.darkBackground,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'ReNova',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: activeAccent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppThemeColors.muted(context),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                title,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: AppThemeColors.text(context),
                ),
              ),
              const SizedBox(height: 20),
              _languageButton('English', AppLanguage.english),
              _languageButton('हिंदी', AppLanguage.hindi),
              _languageButton('मराठी', AppLanguage.marathi),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeAccent,
                    foregroundColor: AppColors.darkBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    widget.onLanguageChanged(selectedLanguage);
                    final storage = _getStorage(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CollectorProfileScreen(
                          language: selectedLanguage,
                          themeMode: widget.themeMode,
                          onThemeChanged: widget.onThemeChanged,
                          storage: storage,
                          initialName: storage.collectorName ?? '',
                          initialLocation: storage.location ?? '',
                        ),
                      ),
                    );
                  },
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

  Widget _languageButton(String text, AppLanguage language) {
    final selected = selectedLanguage == language;
    final activeAccent = AppThemeColors.isDark(context) ? AppColors.primaryGold : AppColors.featherGreen;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() {
          selectedLanguage = language;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        decoration: BoxDecoration(
          color: selected
              ? activeAccent.withValues(alpha: 0.18)
              : AppThemeColors.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? activeAccent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected
                  ? activeAccent
                  : AppThemeColors.faint(context),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppThemeColors.text(context),
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

ReNovaStorage _getStorage(BuildContext context) {
  final state = context.findAncestorStateOfType<_ReNovaAppState>();
  if (state == null) {
    throw Exception('ReNova storage is unavailable.');
  }
  return state.widget.storage;
}

// ============================================================
// SCREEN 2 - COLLECTOR PROFILE (LOGIN / SIGNUP)
// ============================================================

class CollectorProfileScreen extends StatefulWidget {
  final AppLanguage language;
  final ReNovaThemeMode themeMode;
  final ValueChanged<ReNovaThemeMode> onThemeChanged;
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
  State<CollectorProfileScreen> createState() => _CollectorProfileScreenState();
}

class _CollectorProfileScreenState extends State<CollectorProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController locationController;

  final ImagePicker picker = ImagePicker();
  String? profileImagePath;
  UserType selectedUserType = UserType.scrapCollector;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialName);
    locationController = TextEditingController(text: widget.initialLocation);
    profileImagePath = widget.storage.profileImagePath;

    final savedUserType = widget.storage.userType;
    if (savedUserType == 'recycler') {
      selectedUserType = UserType.recycler;
    }
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

  String get subtitle {
    switch (widget.language) {
      case AppLanguage.english:
        return 'Create or log into your digital collector profile';
      case AppLanguage.hindi:
        return 'अपना डिजिटल स्क्रैप प्रोफ़ाइल बनाएं या लॉग इन करें';
      case AppLanguage.marathi:
        return 'तुमचे डिजिटल प्रोफाइल तयार करा किंवा लॉगिन करा';
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

  String get userTypeLabel {
    switch (widget.language) {
      case AppLanguage.english:
        return 'Select Role';
      case AppLanguage.hindi:
        return 'अपनी भूमिका चुनें';
      case AppLanguage.marathi:
        return 'तुमची भूमिका निवडा';
    }
  }

  String get collectorRoleText {
    switch (widget.language) {
      case AppLanguage.english:
        return 'Scrap Collector';
      case AppLanguage.hindi:
        return 'कबाड़ संग्रहकर्ता (Scrap Collector)';
      case AppLanguage.marathi:
        return 'भंगार विक्रेता (Scrap Collector)';
    }
  }

  String get recyclerRoleText {
    switch (widget.language) {
      case AppLanguage.english:
        return 'Recycler';
      case AppLanguage.hindi:
        return 'पुनर्चक्रणकर्ता (Recycler)';
      case AppLanguage.marathi:
        return 'पुनर्वापरकर्ता (Recycler)';
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

  String get privacyText {
    switch (widget.language) {
      case AppLanguage.english:
        return 'Only essential collector information is used. ReNova does not require unnecessary personal details.';
      case AppLanguage.hindi:
        return 'केवल आवश्यक संग्रहकर्ता जानकारी का उपयोग किया जाता है। ReNova को अनावश्यक व्यक्तिगत विवरणों की आवश्यकता नहीं है।';
      case AppLanguage.marathi:
        return 'फक्त आवश्यक माहिती वापरली जाते. ReNova ला अनावश्यक वैयक्तिक माहितीची गरज नाही.';
    }
  }

  void _showRoleSelectorBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppThemeColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppThemeColors.faint(context),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userTypeLabel,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppThemeColors.text(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: Column(
                          children: [
                            _roleOptionTile(
                              title: collectorRoleText,
                              icon: Icons.unarchive_outlined,
                              type: UserType.scrapCollector,
                              onTap: () {
                                setModalState(() {
                                  selectedUserType = UserType.scrapCollector;
                                });
                                setState(() {});
                                Navigator.pop(context);
                              },
                            ),
                            const SizedBox(height: 12),
                            _roleOptionTile(
                              title: recyclerRoleText,
                              icon: Icons.autorenew,
                              type: UserType.recycler,
                              onTap: () {
                                setModalState(() {
                                  selectedUserType = UserType.recycler;
                                });
                                setState(() {});
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _roleOptionTile({
    required String title,
    required IconData icon,
    required UserType type,
    required VoidCallback onTap,
  }) {
    final selected = selectedUserType == type;
    final activeAccent = AppThemeColors.isDark(context) ? AppColors.primaryGold : AppColors.featherGreen;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? activeAccent.withValues(alpha: 0.18)
              : AppThemeColors.background(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? activeAccent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: activeAccent,
              size: 28,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppThemeColors.text(context),
                ),
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected
                  ? activeAccent
                  : AppThemeColors.faint(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasValidImage = profileImagePath != null && File(profileImagePath!).existsSync();
    final activeAccent = AppThemeColors.isDark(context) ? AppColors.primaryGold : AppColors.featherGreen;

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
                    backgroundColor: activeAccent,
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
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, val, child) {
                  return Opacity(
                    opacity: val,
                    child: Transform.translate(
                      offset: Offset(0, -15 * (1 - val)),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: AppThemeColors.text(context),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppThemeColors.muted(context),
                ),
              ),
              const SizedBox(height: 30),
              _label(userTypeLabel),
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _showRoleSelectorBottomSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppThemeColors.card(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: activeAccent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedUserType == UserType.scrapCollector
                            ? Icons.unarchive_outlined
                            : Icons.autorenew,
                        color: activeAccent,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          selectedUserType == UserType.scrapCollector
                              ? collectorRoleText
                              : recyclerRoleText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppThemeColors.text(context),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_up,
                        color: activeAccent,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
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
                        privacyText,
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
                    backgroundColor: activeAccent,
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

    if (selectedUserType == UserType.recycler) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RecyclerAccessScreen(
            storage: widget.storage,
            language: widget.language,
            themeMode: widget.themeMode,
            onThemeChanged: widget.onThemeChanged,
          ),
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
      userType: selectedUserType.name,
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

  int currentIndex = 0;

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

  String get dashboardText {
    switch (currentLanguage) {
      case AppLanguage.english:
        return 'Dashboard';
      case AppLanguage.hindi:
        return 'डैशबोर्ड';
      case AppLanguage.marathi:
        return 'डॅशबोर्ड';
    }
  }

  String get historyText {
    switch (currentLanguage) {
      case AppLanguage.english:
        return 'Deals';
      case AppLanguage.hindi:
        return 'सौदे';
      case AppLanguage.marathi:
        return 'सोदे';
    }
  }

  String get pickupText {
    switch (currentLanguage) {
      case AppLanguage.english:
        return 'Pick-Up';
      case AppLanguage.hindi:
        return 'पिक-अप';
      case AppLanguage.marathi:
        return 'पिक-अप';
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

  String get classifyText {
    switch (currentLanguage) {
      case AppLanguage.english:
        return 'Classify';
      case AppLanguage.hindi:
        return 'वर्गीकरण';
      case AppLanguage.marathi:
        return 'वर्गीकरण';
    }
  }

  String get classifyScrapText {
    switch (currentLanguage) {
      case AppLanguage.english:
        return 'Classify Scrap';
      case AppLanguage.hindi:
        return 'कबाड़ का वर्गीकरण';
      case AppLanguage.marathi:
        return 'भंगाराचे वर्गीकरण';
    }
  }

  String get classifyBulkText {
    switch (currentLanguage) {
      case AppLanguage.english:
        return 'Classify Bulk';
      case AppLanguage.hindi:
        return 'बल्क वर्गीकरण';
      case AppLanguage.marathi:
        return 'बल्क वर्गीकरण';
    }
  }

  String get recentText {
    switch (currentLanguage) {
      case AppLanguage.english:
        return 'Recent';
      case AppLanguage.hindi:
        return 'हालिया';
      case AppLanguage.marathi:
        return 'अलीकडील';
    }
  }

  String get notificationsTitle {
    switch (currentLanguage) {
      case AppLanguage.english:
        return 'Notifications';
      case AppLanguage.hindi:
        return 'सूचनाएं';
      case AppLanguage.marathi:
        return 'सूचना';
    }
  }

  void _showClassifyOptionsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemeColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.center_focus_strong, color: AppColors.primaryGold),
                title: Text(classifyScrapText),
                subtitle: const Text('Single item analysis via Camera or Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    currentIndex = 5;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.apps, color: AppColors.primaryGold),
                title: Text(classifyBulkText),
                subtitle: const Text('Analyze bulk scrap for weight & price'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClassifyBulkScreen(storage: widget.storage, language: currentLanguage),
                    ),
                  ).then((_) {
                    if (mounted) {
                      setState(() {
                        currentIndex = 0;
                      });
                    }
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: AppColors.primaryGold),
                title: Text(recentText),
                subtitle: const Text('View history categorized by Week, Month, Year'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecentUploadsScreen(language: currentLanguage, storage: widget.storage),
                    ),
                  ).then((_) {
                    if (mounted) {
                      setState(() {
                        currentIndex = 0;
                      });
                    }
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeAccent = AppThemeColors.isDark(context) ? AppColors.primaryGold : AppColors.featherGreen;

    final tabs = [
      OverviewDashboardTab(
        collectorName: collectorName,
        location: location,
        language: currentLanguage,
        profileImagePath: profileImagePath,
        onNavigateTab: (index) {
          if (index == 5) {
            _showClassifyOptionsModal(context);
          } else {
            setState(() {
              currentIndex = index;
            });
          }
        },
      ),
      PickupTab(language: currentLanguage),
      HistoryTab(
        language: currentLanguage,
      ),
      EarningsTab(
        language: currentLanguage,
      ),
      PaymentTab(
        language: currentLanguage,
        paymentPreference: paymentPreference,
        onPaymentPreferenceChanged: _changePayment,
      ),
      PickupUploadTab(
        savedPhotoPath: uploadedPickupPath,
        storage: widget.storage,
        language: currentLanguage,
        onPhotoUploaded: (path) {
          setState(() {
            uploadedPickupPath = path;
          });
        },
      ),
    ];

    return PopScope(
      canPop: currentIndex == 0,
      onPopInvoked: (didPop) {
        if (!didPop && currentIndex != 0) {
          setState(() {
            currentIndex = 0;
          });
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.recycling,
                color: activeAccent,
              ),
              const SizedBox(width: 8),
              Text(
                'ReNova',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: activeAccent,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Safety Guidance',
            icon: Icon(
              Icons.health_and_safety_outlined,
              color: activeAccent,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SafetyTab(language: currentLanguage),
                ),
              ).then((_) {
                if (mounted) {
                  setState(() {
                    currentIndex = 0;
                  });
                }
              });
            },
          ),
          IconButton(
            tooltip: 'Settings',
            icon: Icon(
              Icons.settings,
              color: activeAccent,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsTab(
                    collectorName: collectorName,
                    location: location,
                    language: currentLanguage,
                    profileImagePath: profileImagePath,
                    paymentPreference: paymentPreference,
                    themeMode: widget.themeMode,
                    onThemeChanged: widget.onThemeChanged,
                    storage: widget.storage,
                    onLanguageChanged: (lang) async {
                      setState(() {
                        currentLanguage = lang;
                      });
                      await widget.storage.prefs.setString('language', lang.name);
                      final appState = context.findAncestorStateOfType<_ReNovaAppState>();
                      if (appState != null) {
                        await appState.changeLanguage(lang);
                      }
                    },
                    onProfileUpdated: (newName, newLoc, newPay, newImg, newAge, newOther) async {
                      await _saveProfile(newName, newLoc, newPay, newImg, newAge, newOther);
                    },
                  ),
                ),
              ).then((_) {
                if (mounted) {
                  setState(() {
                    currentIndex = 0;
                  });
                }
              });
            },
          ),
          AnimatedBellIconButton(
            onPressed: _showNotifications,
          ),
          themeSwitchButton(
            context,
            widget.themeMode,
            widget.onThemeChanged,
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: tabs[currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (index == 5) {
            _showClassifyOptionsModal(context);
          } else {
            setState(() {
              currentIndex = index;
            });
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(
              Icons.dashboard,
              color: activeAccent,
            ),
            label: dashboardText,
          ),
          NavigationDestination(
            icon: const Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(
              Icons.local_shipping,
              color: activeAccent,
            ),
            label: pickupText,
          ),
          NavigationDestination(
            icon: const Icon(
              Icons.history,
            ),
            selectedIcon: Icon(
              Icons.history,
              color: activeAccent,
            ),
            label: historyText,
          ),
          NavigationDestination(
            icon: const Icon(
              Icons.currency_rupee,
            ),
            selectedIcon: Icon(
              Icons.currency_rupee,
              color: activeAccent,
            ),
            label: earningsText,
          ),
          NavigationDestination(
            icon: const Icon(
              Icons.account_balance_wallet,
            ),
            selectedIcon: Icon(
              Icons.account_balance_wallet,
              color: activeAccent,
            ),
            label: paymentText,
          ),
          NavigationDestination(
            icon: const Icon(
              Icons.auto_awesome,
            ),
            selectedIcon: Icon(
              Icons.auto_awesome,
              color: activeAccent,
            ),
            label: classifyText,
          ),
        ],
      ),
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
    XFile? image, [
    String? age,
    String? otherDetails,
  ]) async {
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
      age: age,
      otherDetails: otherDetails,
      language: currentLanguage.name,
      paymentPreference: newPayment,
      profileImagePath: imagePath,
    );
  }

  void _showNotifications() {
    final activeAccent = AppThemeColors.isDark(context) ? AppColors.primaryGold : AppColors.featherGreen;

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
                Text(
                  notificationsTitle,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: activeAccent,
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
    final activeAccent = AppThemeColors.isDark(context) ? AppColors.primaryGold : AppColors.featherGreen;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: activeAccent.withValues(
          alpha: 0.15,
        ),
        child: Icon(
          icon,
          color: activeAccent,
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
// SETTINGS TAB WITH PROFILE, LANGUAGE OPTIONS, AND ABOUT
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
  final Function(String name, String location, String payment, XFile? image, String age, String otherDetails) onProfileUpdated;
  final ReNovaStorage? storage;

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
    this.storage,
  });

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late AppLanguage selectedLanguage;

  @override
  void initState() {
    super.initState();
    selectedLanguage = widget.language;
  }

  String _t(String en, String hi, String mr) {
    switch (selectedLanguage) {
      case AppLanguage.hindi:
        return hi;
      case AppLanguage.marathi:
        return mr;
      case AppLanguage.english:
      default:
        return en;
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: widget.collectorName);
    final locationController = TextEditingController(text: widget.location);
    final ageController = TextEditingController(text: widget.storage?.age ?? '');
    final otherController = TextEditingController(text: widget.storage?.otherDetails ?? '');
    String currentPayment = widget.paymentPreference;
    XFile? pickedFile;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final activeAccent = AppThemeColors.isDark(context)
                ? AppColors.primaryGold
                : AppColors.featherGreen;

            return AlertDialog(
              backgroundColor: AppThemeColors.card(context),
              title: Text(
                _t('Edit Profile', 'प्रोफ़ाइल संपादित करें', 'प्रोफाइल संपादित करा'),
                style: TextStyle(color: AppThemeColors.text(context)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: _t('Name', 'नाम', 'नाव'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _t('Age', 'आयु', 'वय'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: _t('Location', 'स्थान', 'स्थान'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: currentPayment,
                      items: ['Cash', 'UPI / Digital Wallet']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => currentPayment = val);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: _t('Payment Preference', 'भुगतान पसंद', 'पेमेंट पसंती'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: otherController,
                      decoration: InputDecoration(
                        labelText: _t('Other Details', 'अन्य विवरण', 'इतर तपशील'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: activeAccent),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final img = await picker.pickImage(source: ImageSource.gallery);
                        if (img != null) {
                          setDialogState(() => pickedFile = img);
                        }
                      },
                      icon: const Icon(Icons.photo_library, color: AppColors.darkBackground),
                      label: Text(
                        pickedFile == null
                            ? _t('Change Profile Picture', 'प्रोफ़ाइल चित्र बदलें', 'प्रोफाइल फोटो बदला')
                            : _t('Image Selected', 'चित्र चुना गया', 'फोटो निवडला'),
                        style: const TextStyle(color: AppColors.darkBackground),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(_t('Cancel', 'रद्द करें', 'रद्द करा')),
                ),
                ElevatedButton(
                  onPressed: () {
                    widget.onProfileUpdated(
                      nameController.text.trim(),
                      locationController.text.trim(),
                      currentPayment,
                      pickedFile,
                      ageController.text.trim(),
                      otherController.text.trim(),
                    );
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                  child: Text(_t('Save', 'सहेजें', 'जतन करा')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showProfileDetails() {
    final hasValidImage = widget.profileImagePath != null &&
        File(widget.profileImagePath!).existsSync();
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppThemeColors.card(context),
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: activeAccent,
                  backgroundImage: hasValidImage
                      ? FileImage(File(widget.profileImagePath!))
                      : null,
                  child: !hasValidImage
                      ? const Icon(Icons.person, size: 50, color: AppColors.darkBackground)
                      : null,
                ),
                const SizedBox(height: 14),
                Text(
                  widget.collectorName.isEmpty ? _t('User', 'उपयोगकर्ता', 'वापरकर्ता') : widget.collectorName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppThemeColors.text(context),
                  ),
                ),
                const SizedBox(height: 16),
                _detailRow(Icons.badge, _t('Collector ID', 'कलेक्टर आईडी', 'कलेक्टर आयडी'),
                    widget.storage?.collectorId ?? 'RN-COL-2026-01428'),
                _detailRow(Icons.location_on, _t('Location', 'स्थान', 'स्थान'),
                    widget.location.isEmpty ? _t('Not specified', 'निर्दिष्ट नहीं', 'नमूद नाही') : widget.location),
                _detailRow(Icons.cake, _t('Age', 'आयु', 'वय'),
                    widget.storage?.age?.isNotEmpty == true ? widget.storage!.age! : _t('Not specified', 'निर्दिष्ट नहीं', 'नमूद नाही')),
                _detailRow(Icons.payments, _t('Payment', 'भुगतान', 'पेमेंट'),
                    widget.paymentPreference),
                if (widget.storage?.otherDetails?.isNotEmpty == true)
                  _detailRow(Icons.notes, _t('Other Details', 'अन्य विवरण', 'इतर तपशील'),
                      widget.storage!.otherDetails!),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showEditProfileDialog();
                    },
                    icon: Icon(Icons.edit, color: activeAccent),
                    label: Text(
                      _t('Edit Profile', 'प्रोफ़ाइल संपादित करें', 'प्रोफाइल संपादित करा'),
                      style: TextStyle(color: activeAccent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;
    return ListTile(
      leading: Icon(icon, color: activeAccent),
      title: Text(label, style: TextStyle(color: AppThemeColors.muted(context), fontSize: 12)),
      subtitle: Text(value, style: TextStyle(color: AppThemeColors.text(context), fontSize: 15)),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemeColors.card(context),
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              trailing: selectedLanguage == AppLanguage.english
                  ? const Icon(Icons.check_circle)
                  : null,
              onTap: () => _selectLanguage(AppLanguage.english, ctx),
            ),
            ListTile(
              leading: const Text('🇮🇳', style: TextStyle(fontSize: 24)),
              title: const Text('हिंदी'),
              trailing: selectedLanguage == AppLanguage.hindi
                  ? const Icon(Icons.check_circle)
                  : null,
              onTap: () => _selectLanguage(AppLanguage.hindi, ctx),
            ),
            ListTile(
              leading: const Text('🇮🇳', style: TextStyle(fontSize: 24)),
              title: const Text('मराठी'),
              trailing: selectedLanguage == AppLanguage.marathi
                  ? const Icon(Icons.check_circle)
                  : null,
              onTap: () => _selectLanguage(AppLanguage.marathi, ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _selectLanguage(AppLanguage lang, BuildContext sheetContext) {
    setState(() => selectedLanguage = lang);
    widget.onLanguageChanged(lang);
    Navigator.pop(sheetContext);
  }

  void _showCollectorTools() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CollectorToolsScreen(
          language: selectedLanguage,
        ),
      ),
    );
  }

  void _showSimpleInfo(String title, String body, {IconData icon = Icons.info_outline}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppThemeColors.card(context),
        title: Row(
          children: [
            Icon(icon, color: AppColors.featherGreen),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('Close', 'बंद करें', 'बंद करा')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    final items = <Widget>[
      _settingsButton(
        Icons.person_outline,
        _t('Profile', 'प्रोफ़ाइल', 'प्रोफाइल'),
        _t('View account details and edit your profile', 'खाते का विवरण देखें और प्रोफ़ाइल संपादित करें', 'खाते तपशील पहा आणि प्रोफाइल संपादित करा'),
        _showProfileDetails,
      ),
      _settingsButton(
        Icons.language,
        _t('App Language', 'ऐप की भाषा', 'अ‍ॅपची भाषा'),
        _t('Change app text and safety audio language', 'ऐप का टेक्स्ट और सुरक्षा ऑडियो भाषा बदलें', 'अ‍ॅपचा मजकूर आणि सुरक्षा ऑडिओ भाषा बदला'),
        _showLanguagePicker,
      ),
      _settingsButton(
        Icons.build_circle_outlined,
        _t('Collector Tools', 'कलेक्टर टूल्स', 'कलेक्टर टूल्स'),
        _t('Weekly price board and recyclers nearby', 'साप्ताहिक मूल्य बोर्ड और पास के रीसायकलर', 'साप्ताहिक किंमत बोर्ड आणि जवळचे रीसायकलर'),
        _showCollectorTools,
      ),
      _settingsButton(
        Icons.security,
        _t('Security', 'सुरक्षा', 'सुरक्षा'),
        _t('Review account and app security information', 'खाते और ऐप सुरक्षा जानकारी देखें', 'खाते आणि अ‍ॅप सुरक्षा माहिती पहा'),
        () => _showSimpleInfo(
          _t('Security', 'सुरक्षा', 'सुरक्षा'),
          _t(
            'Your ReNova profile is stored locally on this device. Avoid sharing OTPs, passcodes or payment credentials.',
            'आपकी ReNova प्रोफ़ाइल इस डिवाइस पर स्थानीय रूप से संग्रहीत है। OTP, पासकोड या भुगतान जानकारी साझा न करें।',
            'तुमची ReNova प्रोफाइल या डिव्हाइसवर स्थानिकरित्या साठवली जाते. OTP, पासकोड किंवा पेमेंट माहिती शेअर करू नका.',
          ),
          icon: Icons.security,
        ),
      ),
      _settingsButton(
        Icons.lock_outline,
        _t('Passcode', 'पासकोड', 'पासकोड'),
        _t('Set or manage your app passcode', 'ऐप पासकोड सेट या प्रबंधित करें', 'अ‍ॅप पासकोड सेट किंवा व्यवस्थापित करा'),
        () => _showSimpleInfo(
          _t('Passcode', 'पासकोड', 'पासकोड'),
          _t(
            'Passcode management can be connected to device authentication in the production version.',
            'उत्पादन संस्करण में पासकोड प्रबंधन को डिवाइस प्रमाणीकरण से जोड़ा जा सकता है।',
            'उत्पादन आवृत्तीत पासकोड व्यवस्थापन डिव्हाइस प्रमाणीकरणाशी जोडता येईल.',
          ),
          icon: Icons.lock_outline,
        ),
      ),
      _settingsButton(
        Icons.notifications_outlined,
        _t('Notifications', 'सूचनाएं', 'सूचना'),
        _t('Manage notification preferences', 'सूचना प्राथमिकताएं प्रबंधित करें', 'सूचना प्राधान्ये व्यवस्थापित करा'),
        () => _showSimpleInfo(
          _t('Notifications', 'सूचनाएं', 'सूचना'),
          _t(
            'Notifications can include pickup matches, payment updates and classification reminders.',
            'सूचनाओं में पिकअप मैच, भुगतान अपडेट और वर्गीकरण रिमाइंडर शामिल हो सकते हैं।',
            'सूचनांमध्ये पिकअप मॅच, पेमेंट अपडेट आणि वर्गीकरण स्मरणपत्रे असू शकतात.',
          ),
          icon: Icons.notifications_outlined,
        ),
      ),
      _settingsButton(
        Icons.info_outline,
        _t('About ReNova', 'ReNova के बारे में', 'ReNova बद्दल'),
        _t('Prototype and team information', 'प्रोटोटाइप और टीम की जानकारी', 'प्रोटोटाइप आणि टीमची माहिती'),
        () => _showSimpleInfo(
          _t('About ReNova', 'ReNova के बारे में', 'ReNova बद्दल'),
          _t(
            'This app is an experimental prototype version 1.0.0 made by Team ReNova, a team of 6 members for SIH 2026.',
            'यह ऐप SIH 2026 के लिए 6 सदस्यों की Team ReNova द्वारा बनाया गया प्रायोगिक प्रोटोटाइप संस्करण 1.0.0 है।',
            'हे अ‍ॅप SIH 2026 साठी Team ReNova च्या 6 सदस्यांनी तयार केलेले प्रायोगिक प्रोटोटाइप आवृत्ती 1.0.0 आहे.',
          ),
          icon: Icons.info_outline,
        ),
      ),
      _settingsButton(
        Icons.help_outline,
        _t('Help and Security', 'मदद और सुरक्षा', 'मदत आणि सुरक्षा'),
        _t('Safety, privacy and app help', 'सुरक्षा, गोपनीयता और ऐप सहायता', 'सुरक्षा, गोपनीयता आणि अ‍ॅप मदत'),
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SafetyTab(language: selectedLanguage),
          ),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t('Settings', 'सेटिंग्स', 'सेटिंग्ज'),
          style: TextStyle(color: AppThemeColors.text(context)),
        ),
        actions: [
          themeSwitchButton(context, widget.themeMode, widget.onThemeChanged),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _profileQuickBar(),
          const SizedBox(height: 16),
          Text(
            _t('Account & Preferences', 'खाता और प्राथमिकताएं', 'खाते आणि प्राधान्ये'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.text(context),
            ),
          ),
          const SizedBox(height: 12),
          ...items,
          const SizedBox(height: 8),
          Text(
            _t(
              'Current language: ${selectedLanguage == AppLanguage.english ? 'English' : selectedLanguage == AppLanguage.hindi ? 'Hindi' : 'Marathi'}',
              'वर्तमान भाषा: ${selectedLanguage == AppLanguage.english ? 'अंग्रेज़ी' : selectedLanguage == AppLanguage.hindi ? 'हिंदी' : 'मराठी'}',
              'सध्याची भाषा: ${selectedLanguage == AppLanguage.english ? 'इंग्रजी' : selectedLanguage == AppLanguage.hindi ? 'हिंदी' : 'मराठी'}',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppThemeColors.faint(context), fontSize: 12),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _profileQuickBar() {
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    final hasValidImage = widget.profileImagePath != null &&
        File(widget.profileImagePath!).existsSync();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppThemeColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: activeAccent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: activeAccent,
            backgroundImage: hasValidImage
                ? FileImage(File(widget.profileImagePath!))
                : null,
            child: !hasValidImage
                ? const Icon(Icons.person, color: AppColors.darkBackground)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.collectorName.isEmpty
                      ? _t('User', 'उपयोगकर्ता', 'वापरकर्ता')
                      : widget.collectorName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppThemeColors.text(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.location.isEmpty
                      ? _t('Not specified', 'निर्दिष्ट नहीं', 'नमूद नाही')
                      : widget.location,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppThemeColors.muted(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: _t('Edit Profile', 'प्रोफ़ाइल संपादित करें', 'प्रोफाइल संपादित करा'),
            icon: Icon(Icons.edit, color: activeAccent),
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
    );
  }

  Widget _settingsButton(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppThemeColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: activeAccent.withValues(alpha: 0.18)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: activeAccent.withValues(alpha: 0.14),
          child: Icon(icon, color: activeAccent),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppThemeColors.text(context),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppThemeColors.muted(context), fontSize: 12),
        ),
        trailing: Icon(Icons.chevron_right, color: AppThemeColors.faint(context)),
        onTap: onTap,
      ),
    );
  }
}

// ============================================================
// COLLECTOR TOOLS
// ============================================================

class CollectorToolsScreen extends StatelessWidget {
  final AppLanguage language;

  const CollectorToolsScreen({
    super.key,
    required this.language,
  });

  String _t(String en, String hi, String mr) {
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

  @override
  Widget build(BuildContext context) {
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Collector Tools', 'कलेक्टर टूल्स', 'कलेक्टर टूल्स')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _toolCard(
            context,
            Icons.location_on,
            _t('Recyclers Nearby', 'पास के रीसायकलर', 'जवळचे रीसायकलर'),
            _t('View nearby recycler options for the prototype.',
                'प्रोटोटाइप में पास के रीसायकलर विकल्प देखें।',
                'प्रोटोटाइपमधील जवळचे रीसायकलर पर्याय पहा.'),
            () => _showNearbyRecyclers(context, activeAccent),
          ),
        ],
      ),
    );
  }

  Widget _toolCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppThemeColors.card(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 27,
          backgroundColor: activeAccent.withValues(alpha: 0.15),
          child: Icon(icon, color: activeAccent),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showNearbyRecyclers(BuildContext context, Color accent) {
    final recyclers = [
      ['EcoRecycle Ltd', '1.2 km', 'E-Waste • PCB • Batteries'],
      ['GreenLoop Recycling', '2.4 km', 'E-Waste • Metals • Plastics'],
      ['ReCircle Hub', '3.1 km', 'Electronics • Mixed Scrap'],
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemeColors.card(context),
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              _t('Recyclers Nearby', 'पास के रीसायकलर', 'जवळचे रीसायकलर'),
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: accent),
            ),
            const SizedBox(height: 12),
            ...recyclers.map(
              (r) => Card(
                child: ListTile(
                  leading: Icon(Icons.recycling, color: accent),
                  title: Text(r[0]),
                  subtitle: Text('${r[1]} • ${r[2]}'),
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
// RECY AI CHATBOT DIALOG / BOT
// ============================================================

class ChatMessage {
  final String text;
  final bool isUser;
  final String? audioText;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.audioText,
  });
}

class RecyChatbotSheet extends StatefulWidget {
  final AppLanguage language;

  const RecyChatbotSheet({super.key, required this.language});

  @override
  State<RecyChatbotSheet> createState() => _RecyChatbotSheetState();
}

class _RecyChatbotSheetState extends State<RecyChatbotSheet> {
  final FlutterTts tts = FlutterTts();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      text: welcomeMsg,
      isUser: false,
      audioText: welcomeMsg,
    ));
  }

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  String get welcomeMsg {
    switch (widget.language) {
      case AppLanguage.hindi:
        return 'नमस्ते! मैं Recy हूँ, आपका रीसाइक्लिंग AI सहायक! 🤖✨ आज मैं आपकी क्या मदद कर सकता हूँ? नीचे दिए गए प्रश्नों में से चुनें!';
      case AppLanguage.marathi:
        return 'नमस्कार! मी Recy आहे, तुमचा रीसायकलिंग AI मित्र! 🤖✨ आज मी तुम्हाला कशी मदत करू शकतो? खालील प्रश्नांमधून निवडा!';
      case AppLanguage.english:
      default:
        return 'Hello! I am Recy, your friendly recycling AI buddy! 🤖✨ How can I help you today? Pick a question below!';
    }
  }

  List<Map<String, String>> get questionsAndAnswers {
    switch (widget.language) {
      case AppLanguage.hindi:
        return [
          {
            'q': 'कबाड़ का सही मूल्य कैसे प्राप्त करें?',
            'a': 'अपने कबाड़ को धातु, प्लास्टिक और ई-कचरे में अलग करें। वर्गीकृत सामग्री पर अधिक मूल्य मिलता है!'
          },
          {
            'q': 'ई-कचरा (E-Waste) कैसे बेचें?',
            'a': 'ऐप में \'Classify\' विकल्प पर जाएं, ई-कचरे की फोटो लें और आपको तुरंत अनुमानित मूल्य और रीसाइक्लिंग सुझाव मिल जाएंगे।'
          },
          {
            'q': 'पिकअप कैसे शेड्यूल करें?',
            'a': 'Pick-Up टैब पर जाएं और अपने नजदीकी संग्रहण स्थल की जांच करके पिकअप स्वीकार करें।'
          },
          {
            'q': 'प्लास्टिक कचरे का क्या करें?',
            'a': 'प्लास्टिक को बोतल, हार्ड प्लास्टिक और थैलियों में छांट लें। साफ और सूखी प्लास्टिक का बेहतर दाम मिलता है।'
          },
          {
            'q': 'पुराने इलेक्ट्रॉनिक्स की जांच कैसे करें?',
            'a': 'मशीनों से बैटरी निकालें और सर्किट्स को अलग रखें। बैटरी का सुरक्षित निपटान जरूरी है।'
          },
          {
            'q': 'तांबा और पीतल की कीमत ज्यादा क्यों है?',
            'a': 'ये कीमती धातुएं हैं जिनका पुनर्चक्रण आसान है और उद्योग में इनकी बहुत मांग है।'
          },
          {
            'q': 'डिजिटल भुगतान कैसे प्राप्त करें?',
            'a': 'Payment टैब में जाकर अपना UPI या बैंक विवरण अपडेट करें। भुगतान सीधा आपके खाते में आएगा।'
          },
          {
            'q': 'कबाड़ का वजन कैसे मापा जाता है?',
            'a': 'हमारे सत्यापित रीसायकलर डिजिटल कांटे का उपयोग करते हैं जिससे सटीक वजन मिलता है।'
          },
          {
            'q': 'सुरक्षा के लिए क्या उपाय करें?',
            'a': 'कबाड़ उठाते समय दस्ताने और मजबूत जूते पहनें। खतरनाक रसायनों और कांच से बचें।'
          },
          {
            'q': 'क्या घर बैठे पिकअप हो सकता है?',
            'a': 'हाँ, ऐप में Pick-Up विकल्प का उपयोग करके आप निकटतम पिकअप अनुरोध चुन सकते हैं।'
          },
          {
            'q': 'रीसाइक्लिंग से पर्यावरण को क्या फायदा है?',
            'a': 'इससे प्राकृतिक संसाधनों की बचत होती है और प्रदूषण कम होता है।'
          },
          {
            'q': 'नया रीसायकलर कैसे खोजें?',
            'a': 'डैशबोर्ड और Pick-Up टैब में आपके पास के सभी प्रमाणित रीसायकलर्स की सूची दिखती है।'
          },
          {
            'q': 'लोहे का कबाड़ कैसे बेचें?',
            'a': 'लोहे को जंग और गंदगी से साफ रखें। भारी लोहे की कीमत सामान्य कबाड़ से बेहतर मिलती है।'
          },
          {
            'q': 'ऐप में भाषा कैसे बदलें?',
            'a': 'सेटिंग्स विकल्प में जाकर आप हिंदी, अंग्रेजी या मराठी चुन सकते हैं।'
          },
        ];
      case AppLanguage.marathi:
        return [
          {
            'q': 'भंगाराचा योग्य दर कसा मिळवावा?',
            'a': 'तुमचे भंगार प्लास्टिक, धातू आणि ई-कचऱ्यामध्ये वेगळे करा. वर्गीकरण केलेल्या भंगाराला जास्त दर मिळतो!'
          },
          {
            'q': 'ई-कचरा कसा विकावा?',
            'a': '\'Classify\' पर्यायावर जा, फोटो काढा आणि तुम्हाला लगेचच अंदाजित किंमत आणि रीसायकलिंग पर्याय मिळतील.'
          },
          {
            'q': 'पिकअप कसा बुक करावा?',
            'a': 'Pick-Up टॅबवर जा आणि तुमच्या जवळच्या ठिकाणी पिकअप शेड्युल करा.'
          },
          {
            'q': 'प्लास्टिक कचऱ्याचे काय करावे?',
            'a': 'प्लास्टिकच्या बाटल्या आणि इतर प्लास्टिक वेगळे करा. स्वच्छ प्लास्टिकला चांगला भाव मिळतो.'
          },
          {
            'q': 'जुने इलेक्ट्रॉनिक्स कसे तपासावे?',
            'a': 'इलेक्ट्रॉनिक वस्तूंमधून बॅटरी वेगळी करा. सर्किट बोर्ड कोरडे ठेवा.'
          },
          {
            'q': 'तांबे आणि पितळाला जास्त दर का मिळतो?',
            'a': 'ह्या मौल्यवान धातू आहेत आणि उद्योगांमध्ये यांची मागणी जास्त असते.'
          },
          {
            'q': 'डिजिटल पेमेंट कसे मिळवावे?',
            'a': 'Payment टॅबवर जाऊन तुमची UPI माहिती सेट करा. पैसे थेट खात्यात जमा होतील.'
          },
          {
            'q': 'भंगाराचे वजन कसे केले जाते?',
            'a': 'डिजिटल काट्याचा वापर करून अचूक वजन केले जाते.'
          },
          {
            'q': 'सुरक्षतेसाठी काय काळजी घ्यावी?',
            'a': 'काम करताना हातमोजे आणि योग्य शूज वापरा. काच व रसायनांपासून सावध राहा.'
          },
          {
            'q': 'घरपोच पिकअप सुविधा उपलब्ध आहे का?',
            'a': 'होय, Pick-Up पर्यायातून तुम्ही जवळची पिकअप मागणी स्वीकारू शकता.'
          },
          {
            'q': 'पुनर्वापराचा पर्यावरणाला काय फायदा होतो?',
            'a': 'यामुळे प्रदूषण कमी होते आणि नैसर्गिक संसाधनांची बचत होते.'
          },
          {
            'q': 'नवीन रीसायकलर कसा शोधावा?',
            'a': 'डॅशबोर्डवर तुम्हाला परिसरातील नोंदणीकृत रीसायकलर दिसतील.'
          },
          {
            'q': 'खंडी लोखंड कसे विकावे?',
            'a': 'लोखंड स्वच्छ आणि कोरडे ठेवा. जाड लोखंडाला चांगला दर मिळतो.'
          },
          {
            'q': 'अ‍ॅपची भाषा कशी बदलावी?',
            'a': 'सेटिंग्ज मध्ये जाऊन तुम्ही तुमची आवडती भाषा निवडू शकता.'
          },
        ];
      case AppLanguage.english:
      default:
        return [
          {
            'q': 'How do I get the best scrap prices?',
            'a': 'Separate your scrap into copper, PCB, and plastics beforehand. Clean and sorted scrap earns a higher value!'
          },
          {
            'q': 'How to classify and sell E-Waste?',
            'a': 'Go to the Classify tab, take a photo of your electronic item, and Recy AI will estimate its weight and fair price.'
          },
          {
            'q': 'How do I check pickup schedules?',
            'a': 'Check the Pick-Up tab from the bottom navigation bar to view all designated pickup locations and details.'
          },
          {
            'q': 'What is the best way to handle plastic scrap?',
            'a': 'Segregate PET bottles, hard plastics, and flexible films. Clean and dry plastics get better market rates.'
          },
          {
            'q': 'How to process old circuit boards (PCBs)?',
            'a': 'Remove batteries and bulky casings. Keep PCBs dry to maintain highest recovery grade value.'
          },
          {
            'q': 'Why do copper and brass have higher rates?',
            'a': 'They are high-demand non-ferrous metals that can be recycled infinitely without quality loss.'
          },
          {
            'q': 'How do I receive digital payments?',
            'a': 'Go to the Payment tab and choose UPI/Digital Wallet as your preference for instant settlements.'
          },
          {
            'q': 'How is scrap weight verified?',
            'a': 'Partnered recyclers use certified digital weighing scales to ensure accurate and transparent measurement.'
          },
          {
            'q': 'What safety gear should scrap collectors use?',
            'a': 'Always wear heavy-duty gloves, safety shoes, and protective goggles when handling broken glass or sharp metals.'
          },
          {
            'q': 'Can I schedule doorstep scrap collection?',
            'a': 'Yes, use the Pick-Up tab to view nearby collection requests and schedule a convenient pickup time.'
          },
          {
            'q': 'What are the environmental benefits of recycling?',
            'a': 'Recycling reduces landfill waste, conserves raw natural resources, and lowers industrial carbon emissions.'
          },
          {
            'q': 'How to find verified recyclers nearby?',
            'a': 'The Dashboard map and Pick-Up list highlight verified regional recycling units close to your location.'
          },
          {
            'q': 'How to maximize earnings from iron scrap?',
            'a': 'Remove heavy rust, soil, and non-metal attachments. Heavy structural iron commands higher pricing.'
          },
          {
            'q': 'How do I change the app language?',
            'a': 'Open Settings from the top bar to switch seamlessly between English, Hindi, and Marathi.'
          },
        ];
    }
  }

  Future<void> _speak(String text) async {
    await tts.stop();
    switch (widget.language) {
      case AppLanguage.hindi:
        await tts.setLanguage('hi-IN');
        break;
      case AppLanguage.marathi:
        await tts.setLanguage('mr-IN');
        break;
      case AppLanguage.english:
      default:
        await tts.setLanguage('en-IN');
        break;
    }
    await tts.setSpeechRate(0.42);
    await tts.speak(text);
  }

  void _onQuestionSelected(String question, String answer) {
    setState(() {
      _messages.add(ChatMessage(
        text: question,
        isUser: true,
      ));
      _messages.add(ChatMessage(
        text: answer,
        isUser: false,
        audioText: answer,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeAccent = AppThemeColors.isDark(context) ? AppColors.primaryGold : AppColors.featherGreen;

    return Container(
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: AppThemeColors.card(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppThemeColors.faint(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: activeAccent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy, size: 36, color: AppColors.mintGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recy AI Assistant',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppThemeColors.text(context),
                        ),
                      ),
                      Text(
                        'Your Recycling Guide',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppThemeColors.muted(context),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),
            // Chat message area
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Align(
                    alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: msg.isUser
                            ? activeAccent
                            : activeAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(14),
                          topRight: const Radius.circular(14),
                          bottomLeft: Radius.circular(msg.isUser ? 14 : 2),
                          bottomRight: Radius.circular(msg.isUser ? 2 : 14),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              msg.text,
                              style: TextStyle(
                                fontSize: 13,
                                color: msg.isUser
                                    ? AppColors.darkBackground
                                    : AppThemeColors.text(context),
                                fontWeight: msg.isUser ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (!msg.isUser && msg.audioText != null) ...[
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => _speak(msg.audioText!),
                              child: const Icon(
                                Icons.volume_up,
                                size: 18,
                                color: AppColors.mintGreen,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 16),
            Text(
              'Select a question:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppThemeColors.text(context),
              ),
            ),
            const SizedBox(height: 8),
            // Options list
            SizedBox(
              height: 140,
              child: ListView.builder(
                itemCount: questionsAndAnswers.length,
                itemBuilder: (context, index) {
                  final item = questionsAndAnswers[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _onQuestionSelected(item['q']!, item['a']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppThemeColors.background(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: activeAccent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.help_outline, size: 16, color: activeAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item['q']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppThemeColors.text(context),
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 12, color: AppThemeColors.faint(context)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PICK-UP TAB (NEWLY ADDED)
// ============================================================

class PickupTab extends StatelessWidget {
  final AppLanguage language;

  const PickupTab({super.key, this.language = AppLanguage.english});

  String get pickupTitle {
    switch (language) {
      case AppLanguage.hindi:
        return 'पिक-अप लॉट विवरण';
      case AppLanguage.marathi:
        return 'पिक-अप लॉट तपशील';
      case AppLanguage.english:
      default:
        return 'Pick-Up Lot Details';
    }
  }

  String get pickupSubtitle {
    switch (language) {
      case AppLanguage.hindi:
        return 'वर्तमान निर्धारित पिकअप स्थान और सामग्री विवरण';
      case AppLanguage.marathi:
        return 'सध्याचे नियोजित पिकअप ठिकाणे आणि साहित्याचा तपशील';
      case AppLanguage.english:
      default:
        return 'Current scheduled pickup locations and item breakdown';
    }
  }

  List<Map<String, String>> get lotDetails {
    switch (language) {
      case AppLanguage.hindi:
        return [
          {
            'location': '1. क्षेत्र A - उत्तर यार्ड',
            'details': '150 किग्रा मिश्रित पीसीबी और तांबे के तार • प्राथमिकता: उच्च',
          },
          {
            'location': '2. क्षेत्र B - केंद्रीय हब',
            'details': '85 किग्रा लेड-एसिड बैटरियां • प्राथमिकता: मध्यम',
          },
          {
            'location': '3. क्षेत्र C - दक्षिण भंडारण',
            'details': '210 किग्रा सीआरटी कांच और प्लास्टिक कवर • प्राथमिकता: कम',
          },
        ];
      case AppLanguage.marathi:
        return [
          {
            'location': '1. विभाग A - उत्तर यार्ड',
            'details': '150 किलोग्रॅम मिश्रित पीसीबी आणि तांब्याच्या तारा • प्राधान्य: उच्च',
          },
          {
            'location': '2. विभाग B - मध्यवर्ती हब',
            'details': '85 किलोग्रॅम लेड-ॲसिड बॅटऱ्या • प्राधान्य: मध्यम',
          },
          {
            'location': '3. विभाग C - दक्षिण साठा',
            'details': '210 किलोग्रॅम सीआरटी काच आणि प्लास्टिक कव्हर • प्राधान्य: कमी',
          },
        ];
      case AppLanguage.english:
      default:
        return [
          {
            'location': '1. Zone A - North Yard',
            'details': '150 kg Mixed PCB & Copper Wires • Priority: High',
          },
          {
            'location': '2. Zone B - Central Hub',
            'details': '85 kg Lead-Acid Batteries • Priority: Medium',
          },
          {
            'location': '3. Zone C - South Storage',
            'details': '210 kg CRT Glasses & Plastic Shells • Priority: Low',
          },
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeAccent = AppThemeColors.isDark(context) ? AppColors.primaryGold : AppColors.featherGreen;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pickupTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.text(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pickupSubtitle,
            style: TextStyle(
              color: AppThemeColors.muted(context),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecyclerNearbyMapScreen(language: language),
                  ),
                );
              },
              icon: Icon(Icons.map_outlined, color: activeAccent),
              label: Text(
                _LanguageText.t(language, 'Recycler Nearby', 'पास के रीसायकलर', 'जवळचे रीसायकलर'),
                style: TextStyle(color: activeAccent, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: activeAccent),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...lotDetails.map(
            (lot) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppThemeColors.card(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: activeAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: activeAccent.withValues(alpha: 0.15),
                    child: Icon(
                      Icons.location_on,
                      color: activeAccent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lot['location']!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppThemeColors.text(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lot['details']!,
                          style: TextStyle(
                            color: AppThemeColors.muted(context),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================

// ============================================================
// RECYCLER FLOW - LOGIN / ACCOUNT / DASHBOARD
// This section is isolated from the Scrap Collector dashboard.
// ============================================================

class RecyclerAccessScreen extends StatelessWidget {
  final ReNovaStorage storage;
  final AppLanguage language;
  final ReNovaThemeMode themeMode;
  final ValueChanged<ReNovaThemeMode> onThemeChanged;

  const RecyclerAccessScreen({
    super.key,
    required this.storage,
    required this.language,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    return Scaffold(
      appBar: AppBar(
        actions: [themeSwitchButton(context, themeMode, onThemeChanged)],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.recycling, size: 72, color: accent),
                  const SizedBox(height: 18),
                  Text(
                    'Recycler',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppThemeColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Access your ReNova recycler account',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppThemeColors.muted(context)),
                  ),
                  const SizedBox(height: 30),
                  _action(
                    context,
                    'Sign in',
                    Icons.login,
                    () => _openDashboard(context),
                  ),
                  const SizedBox(height: 14),
                  _action(
                    context,
                    'Continue as Guest',
                    Icons.person_outline,
                    () => _openDashboard(context),
                  ),
                  const SizedBox(height: 14),
                  _action(
                    context,
                    'Create a new account',
                    Icons.add_business_outlined,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecyclerRegistrationScreen(
                            storage: storage,
                            language: language,
                            themeMode: themeMode,
                            onThemeChanged: onThemeChanged,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _action(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onTap,
  ) {
    final accent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: AppColors.darkBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _openDashboard(BuildContext context) {
    if (storage.recyclerData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create your recycler account first.'),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RecyclerMainDashboard(
          storage: storage,
          language: language,
          themeMode: themeMode,
          onThemeChanged: onThemeChanged,
        ),
      ),
    );
  }
}

class RecyclerRegistrationScreen extends StatefulWidget {
  final ReNovaStorage storage;
  final AppLanguage language;
  final ReNovaThemeMode themeMode;
  final ValueChanged<ReNovaThemeMode> onThemeChanged;

  const RecyclerRegistrationScreen({
    super.key,
    required this.storage,
    required this.language,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<RecyclerRegistrationScreen> createState() =>
      _RecyclerRegistrationScreenState();
}

class _RecyclerRegistrationScreenState
    extends State<RecyclerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> c = {};

  bool pickupAvailable = true;
  bool dropOffAvailable = true;
  String? logoPath;
  String? authCertPath;
  String? gstCertPath;
  String? companyCertPath;
  String preferredLanguage = 'English';

  final Set<String> requiredFields = {
    'Company / Recycler Name',
    'Company Type',
    'Authorized Representative Name',
    'Designation / Role',
    'Mobile Number',
    'Email Address',
    'Password',
    'Confirm Password',
    'Recycler Authorization / Registration Number',
    'Facility / Plant Name',
    'Facility Address',
    'City',
    'State',
    'PIN Code',
    'Materials Accepted',
  };

  static const List<String> fields = [
    'Company / Recycler Name',
    'Company Type',
    'Company Logo',
    'Year Established',
    'Company Description',
    'Website',
    'Authorized Representative Name',
    'Designation / Role',
    'Mobile Number',
    'Email Address',
    'Password',
    'Confirm Password',
    'Preferred Language',
    'Business Registration Number',
    'GSTIN',
    'PAN',
    'CIN / LLPIN',
    'Udyam Registration Number',
    'Recycler Authorization / Registration Number',
    'State Pollution Control Board / PCC',
    'Authorization Certificate Upload',
    'GST Certificate Upload',
    'Company Registration Certificate Upload',
    'Facility / Plant Name',
    'Facility Address',
    'City',
    'District',
    'State',
    'PIN Code',
    'Facility Location / Map Location',
    'Facility Contact Number',
    'Processing / Recycling Capacity',
    'Operating Days',
    'Operating Hours',
    'Materials Accepted',
    'Minimum Quantity Accepted',
    'Pickup Available?',
    'Pickup Radius',
    'Drop-off Available?',
  ];

  @override
  void initState() {
    super.initState();
    final old = widget.storage.recyclerData ?? <String, dynamic>{};

    for (final field in fields) {
      if (field == 'Preferred Language' ||
          field.contains('Upload') ||
          field == 'Pickup Available?' ||
          field == 'Drop-off Available?' ||
          field == 'Company Logo') {
        continue;
      }
      c[field] = TextEditingController(text: '${old[field] ?? ''}');
    }

    preferredLanguage = '${old['Preferred Language'] ?? 'English'}';
    pickupAvailable = old['Pickup Available?'] != false;
    dropOffAvailable = old['Drop-off Available?'] != false;
    logoPath = old['Company Logo']?.toString();
    authCertPath = old['Authorization Certificate Upload']?.toString();
    gstCertPath = old['GST Certificate Upload']?.toString();
    companyCertPath =
        old['Company Registration Certificate Upload']?.toString();
  }

  @override
  void dispose() {
    for (final controller in c.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _value(String key) => c[key]?.text.trim() ?? '';

  Future<void> _pick(String key) async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null || !mounted) return;

    final path = await widget.storage.saveImagePermanently(
      image,
      'recycler_${key.hashCode}.jpg',
    );

    if (!mounted) return;
    setState(() {
      if (key == 'Company Logo') {
        logoPath = path;
      } else if (key == 'Authorization Certificate Upload') {
        authCertPath = path;
      } else if (key == 'GST Certificate Upload') {
        gstCertPath = path;
      } else {
        companyCertPath = path;
      }
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (authCertPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authorization Certificate Upload is required.'),
        ),
      );
      return;
    }

    if (_value('Password') != _value('Confirm Password')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    final data = <String, dynamic>{};
    for (final field in fields) {
      if (field == 'Preferred Language') {
        data[field] = preferredLanguage;
      } else if (field == 'Pickup Available?') {
        data[field] = pickupAvailable;
      } else if (field == 'Drop-off Available?') {
        data[field] = dropOffAvailable;
      } else if (field == 'Company Logo') {
        data[field] = logoPath;
      } else if (field == 'Authorization Certificate Upload') {
        data[field] = authCertPath;
      } else if (field == 'GST Certificate Upload') {
        data[field] = gstCertPath;
      } else if (field == 'Company Registration Certificate Upload') {
        data[field] = companyCertPath;
      } else {
        data[field] = _value(field);
      }
    }

    await widget.storage.saveRecyclerData(data);
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('🎉 SUCCESS'),
          content: const Text(
            'YAY ACCOUNT CREATED SUCESSFULLY 🎉Your Recycler Account Is Ready — Let’s Build a Cleaner Future',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RecyclerMainDashboard(
          storage: widget.storage,
          language: widget.language,
          themeMode: widget.themeMode,
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    final generalFields = fields.where(
      (field) =>
          !{
            'Preferred Language',
            'Company Logo',
            'Authorization Certificate Upload',
            'GST Certificate Upload',
            'Company Registration Certificate Upload',
            'Pickup Available?',
            'Drop-off Available?',
          }.contains(field) &&
          !field.startsWith('Facility '),
    );

    final facilityFields = fields.where(
      (field) =>
          field == 'Facility / Plant Name' ||
          field == 'Facility Address' ||
          field == 'City' ||
          field == 'District' ||
          field == 'State' ||
          field == 'PIN Code' ||
          field == 'Facility Location / Map Location' ||
          field == 'Facility Contact Number' ||
          field == 'Processing / Recycling Capacity' ||
          field == 'Operating Days' ||
          field == 'Operating Hours' ||
          field == 'Materials Accepted' ||
          field == 'Minimum Quantity Accepted',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Recycler Account'),
        actions: [
          themeSwitchButton(
            context,
            widget.themeMode,
            widget.onThemeChanged,
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              Text(
                'Company & Representative',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
              const SizedBox(height: 10),
              ...generalFields.map(_textField),
              _pickerTile('Company Logo', logoPath, false),
              _dropdown(),
              const SizedBox(height: 8),
              Text(
                'Compliance & Certificates',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
              _pickerTile(
                'Authorization Certificate Upload',
                authCertPath,
                true,
              ),
              _pickerTile('GST Certificate Upload', gstCertPath, false),
              _pickerTile(
                'Company Registration Certificate Upload',
                companyCertPath,
                false,
              ),
              ...facilityFields.map(_textField),
              _switchTile(
                'Pickup Available?',
                pickupAvailable,
                (value) => setState(() => pickupAvailable = value),
              ),
              _textFieldByKey('Pickup Radius'),
              _switchTile(
                'Drop-off Available?',
                dropOffAvailable,
                (value) => setState(() => dropOffAvailable = value),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Save and Continue',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: AppColors.darkBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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

  Widget _textField(String key) => _textFieldByKey(key);

  Widget _textFieldByKey(String key) {
    final isPassword = key == 'Password' || key == 'Confirm Password';
    final required = requiredFields.contains(key);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c[key],
        obscureText: isPassword,
        keyboardType: key.contains('Number') || key == 'PIN Code'
            ? TextInputType.phone
            : TextInputType.text,
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return 'Required field';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: required ? '$key *' : key,
          filled: true,
          fillColor: AppThemeColors.card(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          prefixIcon: Icon(_icon(key)),
        ),
      ),
    );
  }

  Widget _dropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: preferredLanguage,
        items: const ['English', 'Hindi', 'Marathi']
            .map(
              (value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              ),
            )
            .toList(),
        onChanged: (value) {
          setState(() => preferredLanguage = value ?? 'English');
        },
        decoration: InputDecoration(
          labelText: 'Preferred Language',
          filled: true,
          fillColor: AppThemeColors.card(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _pickerTile(String title, String? path, bool required) {
    final accent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    return Card(
      color: AppThemeColors.card(context),
      child: ListTile(
        leading: Icon(Icons.upload_file, color: accent),
        title: Text(required ? '$title *' : title),
        subtitle: Text(path == null ? 'Not uploaded' : 'Uploaded'),
        trailing: IconButton(
          icon: const Icon(Icons.attach_file),
          onPressed: () => _pick(title),
        ),
      ),
    );
  }

  Widget _switchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  IconData _icon(String key) {
    if (key.contains('Name')) return Icons.business;
    if (key.contains('Address') ||
        key == 'City' ||
        key == 'District' ||
        key == 'State') {
      return Icons.location_on_outlined;
    }
    if (key.contains('Email')) return Icons.email_outlined;
    if (key.contains('Phone') || key.contains('Mobile')) {
      return Icons.phone_outlined;
    }
    if (key.contains('Password')) return Icons.lock_outline;
    if (key.contains('Website')) return Icons.language;
    if (key.contains('GST') ||
        key.contains('PAN') ||
        key.contains('CIN') ||
        key.contains('Registration')) {
      return Icons.badge_outlined;
    }
    if (key.contains('Capacity') ||
        key.contains('Quantity') ||
        key.contains('Radius') ||
        key == 'PIN Code') {
      return Icons.numbers;
    }
    return Icons.edit_outlined;
  }
}

class RecyclerMainDashboard extends StatefulWidget {
  final ReNovaStorage storage;
  final AppLanguage language;
  final ReNovaThemeMode themeMode;
  final ValueChanged<ReNovaThemeMode> onThemeChanged;

  const RecyclerMainDashboard({
    super.key,
    required this.storage,
    required this.language,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<RecyclerMainDashboard> createState() => _RecyclerMainDashboardState();
}

class _RecyclerMainDashboardState extends State<RecyclerMainDashboard> {
  int index = 0;
  late Map<String, dynamic> data;
  bool bankSaved = false;

  static const List<String> titles = [
    'Dashboard',
    'Pickup Management',
    'Rider Management',
    'Area / Route Management',
    'Kabadiwala Payments',
    'Collection Records',
    'Inventory',
    'Processing Management',
    'Recovery / Material Output',
    'Compliance Records',
    'Documents',
    'Reports & Analytics',
    'Transactions',
    'Notifications',
    'Company Profile',
  ];

  @override
  void initState() {
    super.initState();
    data = widget.storage.recyclerData ?? <String, dynamic>{};
    bankSaved = widget.storage.prefs.getBool('recycler_bank_saved') ?? false;
  }

  String get company {
    final value = data['Company / Recycler Name']?.toString().trim() ?? '';
    return value.isEmpty ? 'Recycler Company' : value;
  }

  void _refreshData() {
    setState(() {
      data = widget.storage.recyclerData ?? <String, dynamic>{};
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.recycling, color: accent),
              const SizedBox(width: 8),
              Text(
                'HI $company COMPANY',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _settings,
          ),
          themeSwitchButton(
            context,
            widget.themeMode,
            widget.onThemeChanged,
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              DrawerHeader(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.recycling, size: 48, color: accent),
                    const SizedBox(height: 8),
                    Text(
                      company,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ...List.generate(
                titles.length,
                (i) => ListTile(
                  leading: Icon(_menuIcon(i)),
                  title: Text(titles[i]),
                  selected: index == i,
                  onTap: () {
                    setState(() => index = i);
                    Navigator.pop(context);
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add_business),
                title: const Text('Create New Account'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecyclerRegistrationScreen(
                        storage: widget.storage,
                        language: widget.language,
                        themeMode: widget.themeMode,
                        onThemeChanged: widget.onThemeChanged,
                      ),
                    ),
                  ).then((_) => _refreshData());
                },
              ),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _page(index),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index > 4 ? 0 : index,
        onDestinationSelected: (value) {
          setState(() => index = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            label: 'Pickups',
          ),
          NavigationDestination(
            icon: Icon(Icons.two_wheeler_outlined),
            label: 'Riders',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Icon(Icons.precision_manufacturing_outlined),
            label: 'Processing',
          ),
        ],
      ),
    );
  }

  IconData _menuIcon(int i) {
    const icons = [
      Icons.dashboard_outlined,
      Icons.local_shipping_outlined,
      Icons.two_wheeler_outlined,
      Icons.location_on_outlined,
      Icons.payments_outlined,
      Icons.inventory_outlined,
      Icons.bar_chart,
      Icons.settings_applications_outlined,
      Icons.recycling,
      Icons.fact_check_outlined,
      Icons.description_outlined,
      Icons.analytics_outlined,
      Icons.account_balance_wallet_outlined,
      Icons.notifications_outlined,
      Icons.business_outlined,
    ];
    return icons[i];
  }

  Widget _page(int value) {
    switch (value) {
      case 0:
        return _dashboard();
      case 1:
        return _pickups();
      case 2:
        return _riders();
      case 3:
        return _section(
          'Area / Route Management',
          [
            'Service areas',
            'PIN codes covered',
            'Districts covered',
            'Pickup radius',
            'Rider assigned to area',
            'Number of kabadiwalas in area',
            'Pending pickups by area',
            'Daily collection by area',
            'Bhubaneswar Zone 1 • Riders: 3 • Kabadiwalas: 42 • Pending pickups: 8 • Today: 184 kg',
          ],
        );
      case 4:
        return _payments();
      case 5:
        return _section(
          'Collection Records',
          [
            'Unique Collection ID',
            'Kabadiwala',
            'Rider',
            'Pickup location',
            'Date & time',
            'Material category',
            'Weight',
            'Price/kg',
            'Total amount',
            'Payment method',
            'Payment status',
            'Photos',
            'Remarks',
          ],
        );
      case 6:
        return _inventory();
      case 7:
        return _processing();
      case 8:
        return _section(
          'Recovery / Material Output',
          [
            'Copper — XX kg',
            'Aluminium — XX kg',
            'Iron — XX kg',
            'Gold — XX g',
            'Silver — XX g',
            'Plastic — XX kg',
            'Input: 25 kg • Recovered: 23 kg • Residual: 2 kg',
          ],
        );
      case 9:
        return _compliance();
      case 10:
        return _documents();
      case 11:
        return _section(
          'Reports & Analytics',
          [
            'Collection Analytics: Daily / Weekly / Monthly / Yearly',
            'Material Analytics: Mobile phones / Batteries / PCBs / Computers',
            'Processing Analytics: Total received / processed / recovered / residual waste',
            'Financial Analytics: Kabadiwala payments / cash / online / procurement cost',
            'Rider Analytics: Collections per rider / weight per rider / areas covered',
          ],
        );
      case 12:
        return _section(
          'Transactions',
          [
            'Kabadiwala payments',
            'Rider payments / incentives',
            'Recycler purchases',
            'Recovered-material sales',
            'Invoices',
            'Refunds / disputes',
          ],
        );
      case 13:
        return _section(
          'Notifications',
          [
            'New pickup request received.',
            'Ravi Kumar has accepted pickup RN-00183.',
            'Pickup completed.',
            'Payment of ₹1,125 completed.',
            '42 kg of e-waste has arrived at your facility.',
            'Compliance record RN-00183 is ready.',
            'Authorization document expires in 30 days.',
          ],
        );
      case 14:
        return _profile();
      default:
        return _dashboard();
    }
  }

  Widget _dashboard() {
    return ListView(
      key: const ValueKey('recycler-dashboard'),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppThemeColors.text(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Company overview & operations',
          style: TextStyle(color: AppThemeColors.muted(context)),
        ),
        const SizedBox(height: 16),
        _banner(),
        const SizedBox(height: 12),
        _heading('Today'),
        _grid([
          ["Today's collections", '127 kg', Icons.local_shipping],
          ["Today's processing", '89 kg', Icons.precision_manufacturing],
          ["Today's payments", '₹18,450', Icons.currency_rupee],
          ['Pending pickups', '14', Icons.pending_actions],
        ]),
        _heading('This Month'),
        _grid([
          ['Collected quantity', '3,840 kg', Icons.scale],
          ['Processed quantity', '2,960 kg', Icons.recycling],
          ['Pending payments', '₹18,450', Icons.account_balance_wallet],
          ['Active riders', '8 / 10', Icons.two_wheeler],
        ]),
        _heading('Operations'),
        _cardList([
          'Inventory alerts — 3 categories need attention',
          'Compliance status — Documents on file',
          'Recent collection records — RN-00183 • RN-00184 • RN-00185',
        ]),
      ],
    );
  }

  Widget _banner() {
    final accent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;
    final facility =
        data['Facility / Plant Name']?.toString().trim().isNotEmpty == true
            ? data['Facility / Plant Name'].toString()
            : 'Main Facility';
    final city = data['City']?.toString() ?? '';
    final state = data['State']?.toString() ?? '';
    final materials =
        data['Materials Accepted']?.toString() ?? 'Not specified';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: accent,
              child: const Icon(
                Icons.business,
                color: AppColors.darkBackground,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('$facility • $city, $state'),
                  Text('Materials: $materials'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickups() {
    return _pageWithTitle(
      'Pickup Management',
      'Manage the complete pickup lifecycle.',
      [
        _actionButton('New pickup requests', Icons.add_box_outlined),
        ...[
          ['Pending pickups', '14'],
          ['Assigned pickups', '9'],
          ['Pickups in progress', '6'],
          ['Completed pickups', '103'],
          ['Cancelled pickups', '2'],
        ].map(
          (item) => _status(item[0], item[1], Icons.local_shipping_outlined),
        ),
        _heading('Latest Request'),
        _cardList([
          'Collection ID — RN-00183',
          'Kabadiwala name — Ravi Kumar',
          'Kabadiwala phone number — +91 98XXXXXX21',
          'Estimated quantity — 25 kg',
          'E-waste category — Mixed e-waste',
          'Preferred pickup time — Today • 4:00 PM',
          'Assigned rider — Ravi Kumar',
          'Pickup status — Requested → Assigned → Rider En Route → Collected → Payment Completed → Received at Facility',
        ]),
      ],
    );
  }

  Widget _riders() {
    return _pageWithTitle(
      'Rider Management',
      'Rider list, assignments and pickup performance.',
      [
        _actionButton('Add rider', Icons.person_add_alt_1_outlined),
        _rider('Ravi Kumar', 'RN-R017', 'Bhubaneswar North', '7', '5', '2', true),
        _rider('Amit Das', 'RN-R021', 'Bhubaneswar South', '6', '6', '0', true),
        _rider('Sanjay Mishra', 'RN-R024', 'Cuttack', '4', '3', '1', false),
      ],
    );
  }

  Widget _inventory() {
    return _pageWithTitle(
      'Inventory',
      'Track received, processed and pending e-waste.',
      [
        _heading('Category Inventory'),
        ...[
          ['Mobile phones', '184 kg'],
          ['PCBs', '327 kg'],
          ['Batteries', '215 kg'],
          ['Laptops', '142 kg'],
          ['Cables', '96 kg'],
          ['Computers', '208 kg'],
          ['Monitors', '119 kg'],
          ['Mixed e-waste', '401 kg'],
        ].map(
          (item) => _status(item[0], item[1], Icons.recycling),
        ),
      ],
    );
  }

  Widget _processing() {
    return _pageWithTitle(
      'Processing Management',
      'Received → Sorting → Dismantling → Processing → Recovery → Completed',
      [
        ...[
          ['Received', '42 batches'],
          ['Sorting', '11 batches'],
          ['Dismantling', '8 batches'],
          ['Processing', '14 batches'],
          ['Recovery', '7 batches'],
          ['Completed', '103 batches'],
        ].map(
          (item) => _status(
            item[0],
            item[1],
            Icons.precision_manufacturing_outlined,
          ),
        ),
        _heading('Current Batch'),
        _cardList([
          'Processing ID — PROC-00042',
          'Collection ID — RN-00183',
          'Material — Mixed e-waste',
          'Input quantity — 25 kg',
          'Processing date — 19 Sept 2026',
          'Processing status — Processing',
          'Output quantity — 23 kg',
          'Recovery quantity — 21 kg',
          'Residual quantity — 2 kg',
        ]),
      ],
    );
  }

  Widget _compliance() {
    return _pageWithTitle(
      'Compliance Records',
      'Maintain collection, processing and recovery records.',
      [
        ...[
          ['RN-00183', '25 kg', 'Processed'],
          ['RN-00184', '18 kg', 'Processed'],
          ['RN-00185', '42 kg', 'Processing'],
          ['RN-00186', '31 kg', 'Received'],
        ].map(
          (item) => Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(item[0]),
              subtitle: Text(item[1]),
              trailing: Text(item[2]),
            ),
          ),
        ),
        _heading('Example Record'),
        _cardList([
          'Collection ID: RN-00183',
          'Collector: Ravi Kumar',
          'Received: 25 kg',
          'Material: E-waste',
          'Date: 19 Sept 2026',
          'Processed: 23 kg',
          'Recovery: Completed',
          'Recovered Materials: Copper — XX kg • Aluminium — XX kg • Iron — XX kg',
        ]),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.description_outlined),
          label: const Text('Generate Compliance Record'),
        ),
      ],
    );
  }

  Widget _documents() {
    return _pageWithTitle(
      'Documents',
      'Manage registration and compliance documents.',
      [
        ...[
          'Recycler registration • Verified',
          'EPR registration • Verified',
          'Authorization documents • Expiring Soon',
          'GST documents • Verified',
          'Pollution-control documents • Verified',
          'Collection records',
          'Processing records',
          'Invoices',
          'Recovery records',
          'Other compliance documents',
          'Statuses: Verified / Expiring Soon / Expired',
        ].map(_documentCard),
      ],
    );
  }

  Widget _profile() {
    final entries = data.entries
        .where(
          (entry) =>
              entry.key != 'Password' &&
              entry.key != 'Confirm Password' &&
              entry.value != null &&
              entry.value.toString().isNotEmpty,
        )
        .toList();

    return ListView(
      key: const ValueKey('recycler-profile'),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Company Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppThemeColors.text(context),
          ),
        ),
        const SizedBox(height: 12),
        ...entries.map((entry) => _profileCard(entry.key, entry.value.toString())),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecyclerRegistrationScreen(
                  storage: widget.storage,
                  language: widget.language,
                  themeMode: widget.themeMode,
                  onThemeChanged: widget.onThemeChanged,
                ),
              ),
            ).then((_) => _refreshData());
          },
          icon: const Icon(Icons.edit),
          label: const Text('Create New Account / Edit Details'),
        ),
      ],
    );
  }

  Future<void> _settings() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppThemeColors.card(context),
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(18),
            children: [
              const Text(
                'Recycler Settings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('CPCB Certificate Storage & Verification'),
                subtitle: const Text(
                  'Store certificate and track verification status. Uploading a certificate alone does not prove government approval; real CPCB/SPCB verification requires an official service or backend.',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _cpcb();
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit company details'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecyclerRegistrationScreen(
                        storage: widget.storage,
                        language: widget.language,
                        themeMode: widget.themeMode,
                        onThemeChanged: widget.onThemeChanged,
                      ),
                    ),
                  ).then((_) => _refreshData());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cpcb() async {
    final number = TextEditingController(
      text: widget.storage.prefs.getString('recycler_cpcb_certificate_number') ?? '',
    );
    final authority = TextEditingController(
      text: widget.storage.prefs.getString('recycler_cpcb_authority') ??
          'CPCB / relevant authority',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('CPCB Certificate Verification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Store the certificate/reference information here. This app does not independently certify government approval.',
              ),
              TextField(
                controller: number,
                decoration: const InputDecoration(
                  labelText: 'CPCB Certificate / Reference Number',
                ),
              ),
              TextField(
                controller: authority,
                decoration: const InputDecoration(
                  labelText: 'Issuing Authority',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await widget.storage.prefs.setString(
                  'recycler_cpcb_certificate_number',
                  number.text.trim(),
                );
                await widget.storage.prefs.setString(
                  'recycler_cpcb_authority',
                  authority.text.trim(),
                );
                await widget.storage.prefs.setBool(
                  'recycler_cpcb_verification_submitted',
                  number.text.trim().isNotEmpty,
                );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    number.dispose();
    authority.dispose();
  }

  Widget _section(String title, List<String> rows) {
    return _pageWithTitle(
      title,
      'Front-end preview — sample data only.',
      [
        _cardList(rows),
      ],
    );
  }

  Widget _payments() {
    return _pageWithTitle(
      'Kabadiwala Payments',
      'Track payment records and payment status.',
      [
        _actionButton('Record payment', Icons.add_card_outlined),
        _status('Pending payments', '₹18,450', Icons.pending_actions),
        _status('Paid today', '₹12,600', Icons.check_circle_outline),
        _status('This month', '₹84,250', Icons.payments_outlined),
        _heading('Recent Payments'),
        _cardList([
          'Payment ID — PAY-00142',
          'Kabadiwala — Ravi Kumar',
          'Collection ID — RN-00183',
          'Amount — ₹1,125',
          'Method — UPI',
          'Status — Completed',
          'Payment ID — PAY-00143',
          'Kabadiwala — Amit Das',
          'Collection ID — RN-00184',
          'Amount — ₹980',
          'Method — Bank Transfer',
          'Status — Pending',
        ]),
      ],
    );
  }

  Widget _pageWithTitle(
    String title,
    String subtitle,
    List<Widget> children,
  ) {
    return SafeArea(
      child: ListView(
        key: ValueKey(title),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _heading(String text) {
    final accent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _grid(List<List<dynamic>> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (_, i) {
        final accent = AppThemeColors.isDark(context)
            ? AppColors.primaryGold
            : AppColors.featherGreen;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(items[i][2] as IconData, color: accent),
                const SizedBox(height: 8),
                Text(
                  items[i][1] as String,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  items[i][0] as String,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cardList(List<String> rows) {
    final accent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;
    return Card(
      child: Column(
        children: rows
            .map(
              (row) => ListTile(
                dense: true,
                leading: Icon(Icons.chevron_right, color: accent),
                title: Text(row),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _status(String title, String value, IconData icon) {
    final accent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;
    return Card(
      child: ListTile(
        leading: Icon(icon, color: accent),
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(color: accent, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _actionButton(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: Icon(icon),
          label: Text(text),
        ),
      ),
    );
  }

  Widget _rider(
    String name,
    String id,
    String area,
    String today,
    String done,
    String pending,
    bool active,
  ) {
    final accent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: accent.withValues(alpha: 0.15),
                  child: Icon(Icons.person, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(active ? '🟢 Active' : '⚪ Inactive'),
              ],
            ),
            Text('Rider ID: $id'),
            Text('Area: $area'),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Today: $today'),
                Text('Completed: $done'),
                Text('Pending: $pending'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('View Rider Location'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Assign Pickup'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _documentCard(String text) {
    final accent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;
    return Card(
      child: ListTile(
        leading: Icon(Icons.description_outlined, color: accent),
        title: Text(text),
        trailing: const Text('On file'),
      ),
    );
  }

  Widget _profileCard(String title, String value) {
    return Card(
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(value),
      ),
    );
  }
}


// RECYCLER NEARBY MAP (PROTOTYPE, FRONT-END DATA ONLY)
// ============================================================

class RecyclerNearbyMapScreen extends StatelessWidget {
  final AppLanguage language;

  const RecyclerNearbyMapScreen({super.key, required this.language});

  static const double _maxRadiusKm = 8;

  List<Map<String, dynamic>> get _recyclers => [
        {
          'name': 'EcoRecycle Ltd',
          'distance': 1.2,
          'angle': 40.0,
          'tag': _LanguageText.t(language, 'E-Waste • PCB • Batteries', 'ई-कचरा • पीसीबी • बैटरी', 'ई-कचरा • पीसीबी • बॅटरी'),
        },
        {
          'name': 'GreenLoop Recycling',
          'distance': 2.4,
          'angle': 120.0,
          'tag': _LanguageText.t(language, 'E-Waste • Metals • Plastics', 'ई-कचरा • धातु • प्लास्टिक', 'ई-कचरा • धातू • प्लास्टिक'),
        },
        {
          'name': 'ReCircle Hub',
          'distance': 3.1,
          'angle': 200.0,
          'tag': _LanguageText.t(language, 'Electronics • Mixed Scrap', 'इलेक्ट्रॉनिक्स • मिश्रित कबाड़', 'इलेक्ट्रॉनिक्स • मिश्रित भंगार'),
        },
        {
          'name': 'Metro Metal Works',
          'distance': 5.6,
          'angle': 280.0,
          'tag': _LanguageText.t(language, 'Copper • Aluminium', 'तांबा • एल्युमीनियम', 'तांबे • ॲल्युमिनियम'),
        },
        {
          'name': 'UrbanScrap Recyclers',
          'distance': 7.4,
          'angle': 330.0,
          'tag': _LanguageText.t(language, 'Mixed Scrap', 'मिश्रित कबाड़', 'मिश्रित भंगार'),
        },
      ];

  @override
  Widget build(BuildContext context) {
    final activeAccent = AppThemeColors.isDark(context) ? AppColors.primaryGold : AppColors.featherGreen;
    final double mapSize = math.min(300.0, MediaQuery.of(context).size.width - 32);

    return Scaffold(
      appBar: AppBar(
        title: Text(_LanguageText.t(language, 'Recycler Nearby', 'पास के रीसायकलर', 'जवळचे रीसायकलर')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _LanguageText.t(language, 'Recyclers within 8 km', '8 किमी के दायरे में रीसायकलर', '8 किमी परिसरातील रीसायकलर'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppThemeColors.text(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _LanguageText.t(
                language,
                'Prototype map using sample locations. This will use live location and Google Maps in a future version.',
                'यह प्रोटोटाइप नमूना स्थानों का उपयोग करता है। भविष्य के संस्करण में इसमें लाइव लोकेशन और गूगल मैप्स होंगे।',
                'हे प्रोटोटाइप नमुना ठिकाणे वापरते. भविष्यातील आवृत्तीत यात थेट लोकेशन आणि गूगल नकाशे असतील.',
              ),
              style: TextStyle(color: AppThemeColors.muted(context), fontSize: 12),
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: mapSize,
                height: mapSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    for (final ring in [1.0, 0.75, 0.5, 0.25])
                      Container(
                        width: mapSize * ring,
                        height: mapSize * ring,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: activeAccent.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    for (final r in _recyclers)
                      Positioned(
                        left: mapSize / 2 +
                            ((mapSize / 2) * ((r['distance'] as double) / _maxRadiusKm)) *
                                math.cos((r['angle'] as double) * math.pi / 180) -
                            16,
                        top: mapSize / 2 +
                            ((mapSize / 2) * ((r['distance'] as double) / _maxRadiusKm)) *
                                math.sin((r['angle'] as double) * math.pi / 180) -
                            16,
                        child: GestureDetector(
                          onTap: () => _showRecyclerInfo(context, r, activeAccent),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: activeAccent,
                            child: const Icon(Icons.recycling, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.danger,
                      child: const Icon(Icons.person_pin_circle, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _LanguageText.t(language, 'You are at the center', 'आप केंद्र में हैं', 'तुम्ही मध्यभागी आहात'),
                style: TextStyle(color: AppThemeColors.faint(context), fontSize: 11),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _LanguageText.t(language, 'Nearby Recyclers', 'पास के रीसायकलर', 'जवळचे रीसायकलर'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppThemeColors.text(context),
              ),
            ),
            const SizedBox(height: 10),
            ..._recyclers.map(
              (r) => Card(
                child: ListTile(
                  leading: Icon(Icons.recycling, color: activeAccent),
                  title: Text(r['name'] as String),
                  subtitle: Text('${r['distance']} km • ${r['tag']}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecyclerInfo(BuildContext context, Map<String, dynamic> r, Color accent) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppThemeColors.card(context),
        title: Text(r['name'] as String),
        content: Text('${r['distance']} km • ${r['tag']}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_LanguageText.t(language, 'Close', 'बंद करें', 'बंद करा')),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// OVERVIEW DASHBOARD TAB
// ============================================================

class OverviewDashboardTab extends StatelessWidget {
  final String collectorName;
  final String location;
  final AppLanguage language;
  final String? profileImagePath;
  final ValueChanged<int> onNavigateTab;

  const OverviewDashboardTab({
    super.key,
    required this.collectorName,
    required this.location,
    required this.language,
    this.profileImagePath,
    required this.onNavigateTab,
  });

  String get welcomeText {
    switch (language) {
      case AppLanguage.english:
        return 'Welcome back,';
      case AppLanguage.hindi:
        return 'वापसी पर स्वागत है,';
      case AppLanguage.marathi:
        return 'पुन्हा स्वागत आहे,';
    }
  }

  String get quickStatsText {
    switch (language) {
      case AppLanguage.english:
        return 'Dashboard Overview';
      case AppLanguage.hindi:
        return 'डैशबोर्ड अवलोकन';
      case AppLanguage.marathi:
        return 'डॅशबोर्ड विहंगावलोकन';
    }
  }

  String get totalEarningsLabel {
    switch (language) {
      case AppLanguage.english:
        return 'Total Earnings';
      case AppLanguage.hindi:
        return 'कुल कमाई';
      case AppLanguage.marathi:
        return 'एकूण कमाई';
    }
  }

  String get scrapProcessedLabel {
    switch (language) {
      case AppLanguage.english:
        return 'Scrap Processed';
      case AppLanguage.hindi:
        return 'संसाधित कबाड़';
      case AppLanguage.marathi:
        return 'प्रक्रियेत आणलेले भंगार';
    }
  }

  String get pendingPayoutLabel {
    switch (language) {
      case AppLanguage.english:
        return 'Pending Payout';
      case AppLanguage.hindi:
        return 'बकाया भुगतान';
      case AppLanguage.marathi:
        return 'लंबित पेमेंट';
    }
  }

  String get classificationsLabel {
    switch (language) {
      case AppLanguage.english:
        return 'Classifications';
      case AppLanguage.hindi:
        return 'वर्गीकरण';
      case AppLanguage.marathi:
        return 'वर्गीकरण';
    }
  }

  String get quickActionsText {
    switch (language) {
      case AppLanguage.english:
        return 'Quick Actions';
      case AppLanguage.hindi:
        return 'त्वरित क्रियाएं';
      case AppLanguage.marathi:
        return 'जलद कृती';
    }
  }

  String get actionClassifyText {
    switch (language) {
      case AppLanguage.english:
        return 'Classify Scrap';
      case AppLanguage.hindi:
        return 'कबाड़ वर्गीकृत करें';
      case AppLanguage.marathi:
        return 'भंगार वर्गीकरण करा';
    }
  }

  String get actionPaymentText {
    switch (language) {
      case AppLanguage.english:
        return 'Payment Status';
      case AppLanguage.hindi:
        return 'भुगतान स्थिति';
      case AppLanguage.marathi:
        return 'पेमेंट स्थिती';
    }
  }

  String get actionHistoryText {
    switch (language) {
      case AppLanguage.english:
        return 'View Deals';
      case AppLanguage.hindi:
        return 'सौदे देखें';
      case AppLanguage.marathi:
        return 'सोदे पहा';
    }
  }

  String get recyAiText {
    switch (language) {
      case AppLanguage.hindi:
        return 'Recy AI';
      case AppLanguage.marathi:
        return 'Recy AI';
      case AppLanguage.english:
      default:
        return 'Recy AI';
    }
  }

  String get pickupText {
    switch (language) {
      case AppLanguage.hindi:
        return 'पिक-अप';
      case AppLanguage.marathi:
        return 'पिक-अप';
      case AppLanguage.english:
      default:
        return 'Pick-Up';
    }
  }

  String get earningsText {
    switch (language) {
      case AppLanguage.hindi:
        return 'कमाई';
      case AppLanguage.marathi:
        return 'कमाई';
      case AppLanguage.english:
      default:
        return 'Earnings';
    }
  }

  void _openRecyChatbot(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecyChatbotSheet(language: language),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasValidImage = profileImagePath != null && File(profileImagePath!).existsSync();
    final activeAccent = AppThemeColors.isDark(context) ? AppColors.primaryGold : AppColors.featherGreen;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppThemeColors.card(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        welcomeText,
                        style: TextStyle(
                          color: AppThemeColors.muted(context),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        collectorName.isEmpty ? 'Collector' : collectorName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: activeAccent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.mintGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            location.isEmpty ? 'Bhubaneswar' : location,
                            style: const TextStyle(
                              color: AppColors.mintGreen,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 28,
                  backgroundColor: activeAccent,
                  backgroundImage: hasValidImage ? FileImage(File(profileImagePath!)) : null,
                  child: !hasValidImage
                      ? const Icon(
                          Icons.person,
                          size: 32,
                          color: AppColors.darkBackground,
                        )
                      : null,
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            quickStatsText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.text(context),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  context,
                  totalEarningsLabel,
                  '₹18,450',
                  Icons.currency_rupee,
                  activeAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  context,
                  scrapProcessedLabel,
                  '125.5 kg',
                  Icons.scale,
                  AppColors.mintGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  context,
                  pendingPayoutLabel,
                  '₹1,200',
                  Icons.hourglass_top,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  context,
                  classificationsLabel,
                  '28 Done',
                  Icons.auto_awesome,
                  AppColors.lightGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            quickActionsText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.text(context),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _actionButton(
                context,
                Icons.auto_awesome,
                actionClassifyText,
                () => onNavigateTab(5),
              ),
              _actionButton(
                context,
                Icons.account_balance_wallet,
                actionPaymentText,
                () => onNavigateTab(4),
              ),
              _actionButton(
                context,
                Icons.history,
                actionHistoryText,
                () => onNavigateTab(2),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _actionButton(
                context,
                Icons.smart_toy,
                recyAiText,
                () => _openRecyChatbot(context),
              ),
              _actionButton(
                context,
                Icons.local_shipping,
                pickupText,
                () => onNavigateTab(1),
              ),
              _actionButton(
                context,
                Icons.currency_rupee,
                earningsText,
                () => onNavigateTab(3),
              ),
            ],
          ),
          const SizedBox(height: 24),
          PriceBoardTab(language: language),
        ],
      ),
    );
  }

  Widget _statCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemeColors.card(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.text(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppThemeColors.muted(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final activeAccent = AppThemeColors.isDark(context) ? AppColors.primaryGold : AppColors.featherGreen;

    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: activeAccent.withValues(alpha: 0.15),
            child: Icon(icon, color: activeAccent),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppThemeColors.text(context),
            ),
          )
        ],
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

  String get headerTitle {
    switch (widget.language) {
      case AppLanguage.english:
        return 'Recent Deals';
      case AppLanguage.hindi:
        return 'हाल के सौदे';
      case AppLanguage.marathi:
        return 'नुकतेच झालेले सोदे';
    }
  }

  String get periodTranslated {
    switch (widget.language) {
      case AppLanguage.hindi:
        return selectedPeriod == 'Week' ? 'सप्ताह' : (selectedPeriod == 'Month' ? 'महीना' : 'वर्ष');
      case AppLanguage.marathi:
        return selectedPeriod == 'Week' ? 'आठवडा' : (selectedPeriod == 'Month' ? 'महिना' : 'वर्ष');
      case AppLanguage.english:
      default:
        return selectedPeriod;
    }
  }

  String get showingSubtext {
    switch (widget.language) {
      case AppLanguage.english:
        return 'Showing deals for $periodTranslated';
      case AppLanguage.hindi:
        return '$periodTranslated के लिए सौदे दिखाए जा रहे हैं';
      case AppLanguage.marathi:
        return '$periodTranslated साठीचे सोदे दाखवत आहे';
    }
  }

  String get weekText {
    switch (widget.language) {
      case AppLanguage.hindi:
        return 'सप्ताह';
      case AppLanguage.marathi:
        return 'आठवडा';
      case AppLanguage.english:
      default:
        return 'Week';
    }
  }

  String get monthText {
    switch (widget.language) {
      case AppLanguage.hindi:
        return 'महीना';
      case AppLanguage.marathi:
        return 'महिना';
      case AppLanguage.english:
      default:
        return 'Month';
    }
  }

  String get yearText {
    switch (widget.language) {
      case AppLanguage.hindi:
        return 'वर्ष';
      case AppLanguage.marathi:
        return 'वर्ष';
      case AppLanguage.english:
      default:
        return 'Year';
    }
  }

  List<Map<String, dynamic>> get materials {
    switch (widget.language) {
      case AppLanguage.hindi:
        return [
          {
            'title': 'पीसीबी / सर्किट बोर्ड',
            'date': '12 सितम्बर 2026',
            'weight': '8.5 किग्रा',
            'amount': '₹2,975',
            'icon': Icons.memory,
          },
          {
            'title': 'तांबे के तार',
            'date': '08 सितम्बर 2026',
            'weight': '12 किग्रा',
            'amount': '₹3,000',
            'icon': Icons.cable,
          },
          {
            'title': 'लेड-एसिड बैटरियां',
            'date': '04 सितम्बर 2026',
            'weight': '20 किग्रा',
            'amount': '₹1,800',
            'icon': Icons.battery_full,
          },
          {
            'title': 'सीआरटी कांच',
            'date': '29 अगस्त 2026',
            'weight': '25 किग्रा',
            'amount': '₹750',
            'icon': Icons.tv,
          },
        ];
      case AppLanguage.marathi:
        return [
          {
            'title': 'पीसीबी / सर्किट बोर्ड',
            'date': '12 सप्टेंबर 2026',
            'weight': '8.5 किलोग्रॅम',
            'amount': '₹2,975',
            'icon': Icons.memory,
          },
          {
            'title': 'तांब्याच्या तारा',
            'date': '08 सप्टेंबर 2026',
            'weight': '12 किलोग्रॅम',
            'amount': '₹3,000',
            'icon': Icons.cable,
          },
          {
            'title': 'लेड-ॲसिड बॅटऱ्या',
            'date': '04 सप्टेंबर 2026',
            'weight': '20 किलोग्रॅम',
            'amount': '₹1,800',
            'icon': Icons.battery_full,
          },
          {
            'title': 'सीआरटी काच',
            'date': '29 ऑगस्ट 2026',
            'weight': '25 किलोग्रॅम',
            'amount': '₹750',
            'icon': Icons.tv,
          },
        ];
      case AppLanguage.english:
      default:
        return [
          {
            'title': 'PCB / Circuit Boards',
            'date': '12 Sep 2026',
            'weight': '8.5 kg',
            'amount': '₹2,975',
            'icon': Icons.memory,
          },
          {
            'title': 'Copper Cables',
            'date': '08 Sep 2026',
            'weight': '12 kg',
            'amount': '₹3,000',
            'icon': Icons.cable,
          },
          {
            'title': 'Lead-Acid Batteries',
            'date': '04 Sep 2026',
            'weight': '20 kg',
            'amount': '₹1,800',
            'icon': Icons.battery_full,
          },
          {
            'title': 'CRT Glass',
            'date': '29 Aug 2026',
            'weight': '25 kg',
            'amount': '₹750',
            'icon': Icons.tv,
          },
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeAccent = AppThemeColors.isDark(context) ? AppColors.primaryGold : AppColors.featherGreen;

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
                  headerTitle,
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
                  maxWidth: 135,
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
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: activeAccent,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'Week',
                        child: Text(weekText),
                      ),
                      DropdownMenuItem(
                        value: 'Month',
                        child: Text(monthText),
                      ),
                      DropdownMenuItem(
                        value: 'Year',
                        child: Text(yearText),
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
            showingSubtext,
            style: TextStyle(
              color: AppThemeColors.faint(
                context,
              ),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          ...materials.map((m) => _historyCard(
            m['title'] as String,
            m['date'] as String,
            m['weight'] as String,
            m['amount'] as String,
            m['icon'] as IconData,
          )),
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
    final activeAccent = AppThemeColors.isDark(context) ? AppColors.primaryGold : AppColors.featherGreen;

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
            backgroundColor: activeAccent.withValues(
              alpha: 0.16,
            ),
            child: Icon(
              icon,
              color: activeAccent,
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
            style: TextStyle(
              color: activeAccent,
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
  final AppLanguage language;

  const EarningsTab({
    super.key,
    required this.language,
  });

  String get titleText {
    switch (language) {
      case AppLanguage.english:
        return 'Your Earnings';
      case AppLanguage.hindi:
        return 'आपकी कमाई';
      case AppLanguage.marathi:
        return 'तुमची कमाई';
    }
  }

  String get thisMonthText {
    switch (language) {
      case AppLanguage.english:
        return 'This Month';
      case AppLanguage.hindi:
        return 'इस महीने';
      case AppLanguage.marathi:
        return 'या महिन्यात';
    }
  }

  String get materialEarningsText {
    switch (language) {
      case AppLanguage.english:
        return 'Material-wise Earnings';
      case AppLanguage.hindi:
        return 'सामग्री के अनुसार कमाई';
      case AppLanguage.marathi:
        return 'मालगोठ्यानुसार कमाई';
    }
  }

  List<Map<String, dynamic>> get earningItems {
    switch (language) {
      case AppLanguage.hindi:
        return [
          {'title': 'तांबा (Copper)', 'amount': '₹7,200', 'icon': Icons.cable},
          {'title': 'पीसीबी (PCB)', 'amount': '₹5,800', 'icon': Icons.memory},
          {'title': 'बैटरियां (Batteries)', 'amount': '₹3,950', 'icon': Icons.battery_full},
          {'title': 'सीआरटी (CRT)', 'amount': '₹1,500', 'icon': Icons.tv},
        ];
      case AppLanguage.marathi:
        return [
          {'title': 'तांबे (Copper)', 'amount': '₹7,200', 'icon': Icons.cable},
          {'title': 'पीसीबी (PCB)', 'amount': '₹5,800', 'icon': Icons.memory},
          {'title': 'बॅटऱ्या (Batteries)', 'amount': '₹3,950', 'icon': Icons.battery_full},
          {'title': 'सीआरटी (CRT)', 'amount': '₹1,500', 'icon': Icons.tv},
        ];
      case AppLanguage.english:
      default:
        return [
          {'title': 'Copper', 'amount': '₹7,200', 'icon': Icons.cable},
          {'title': 'PCB', 'amount': '₹5,800', 'icon': Icons.memory},
          {'title': 'Batteries', 'amount': '₹3,950', 'icon': Icons.battery_full},
          {'title': 'CRT', 'amount': '₹1,500', 'icon': Icons.tv},
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeAccent = AppThemeColors.isDark(context) ? AppColors.primaryGold : AppColors.featherGreen;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleText,
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
                  thisMonthText,
                  style: TextStyle(
                    color: AppThemeColors.muted(
                      context,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹18,450',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: activeAccent,
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
            materialEarningsText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.text(
                context,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...earningItems.map((item) => _earningRow(
            context,
            item['title'] as String,
            item['amount'] as String,
            item['icon'] as IconData,
          )),
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
    final activeAccent = AppThemeColors.isDark(context) ? AppColors.primaryGold : AppColors.featherGreen;

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
            color: activeAccent,
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
            style: TextStyle(
              color: activeAccent,
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
  final AppLanguage language;

  const PriceBoardTab({
    super.key,
    this.language = AppLanguage.english,
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

  String get headerTitle {
    switch (widget.language) {
      case AppLanguage.hindi:
        return 'वर्तमान खरीद दरें';
      case AppLanguage.marathi:
        return 'सध्याचे खरेदीचे दर';
      case AppLanguage.english:
      default:
        return 'Current Buying Rates';
    }
  }

  String get headerSubtitle {
    switch (widget.language) {
      case AppLanguage.hindi:
        return 'सांकेतिक स्थानीय दरें • लेनदेन से पहले सत्यापित करें';
      case AppLanguage.marathi:
        return 'स्थानिक दर • व्यवहारापूर्वी पडताळणी करा';
      case AppLanguage.english:
      default:
        return 'Indicative local rates • verify before transaction';
    }
  }

  String _t2(String en, String hi, String mr) {
    switch (widget.language) {
      case AppLanguage.hindi:
        return hi;
      case AppLanguage.marathi:
        return mr;
      case AppLanguage.english:
      default:
        return en;
    }
  }

  String get _weekRangeLabel {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${monday.day} ${months[monday.month - 1]} - ${sunday.day} ${months[sunday.month - 1]}, ${sunday.year}';
  }

  final Map<String, double> _locationMultipliers = const {
    'Bhubaneswar': 1.0,
    'Cuttack': 0.95,
    'Mumbai': 1.15,
    'Delhi': 1.10,
    'Pune': 1.05,
  };

  List<Map<String, dynamic>> get _weeklyBoardMaterials => [
        {'material': _t2('Copper', 'तांबा', 'तांबे'), 'base': 620, 'unit': _t2('kg', 'किग्रा', 'किग्रॅ'), 'icon': Icons.cable},
        {'material': 'PCB', 'base': 480, 'unit': _t2('kg', 'किग्रा', 'किग्रॅ'), 'icon': Icons.memory},
        {'material': _t2('Aluminium', 'एल्युमीनियम', 'ॲल्युमिनियम'), 'base': 165, 'unit': _t2('kg', 'किग्रा', 'किग्रॅ'), 'icon': Icons.settings},
        {'material': _t2('Lead Battery', 'लेड बैटरी', 'लेड बॅटरी'), 'base': 95, 'unit': _t2('kg', 'किग्रा', 'किग्रॅ'), 'icon': Icons.battery_full},
        {'material': _t2('CRT Glass', 'सीआरटी कांच', 'सीआरटी काच'), 'base': 30, 'unit': _t2('kg', 'किग्रा', 'किग्रॅ'), 'icon': Icons.tv},
        {'material': _t2('Mixed E-Waste', 'मिश्रित ई-कचरा', 'मिश्रित ई-कचरा'), 'base': 110, 'unit': _t2('kg', 'किग्रा', 'किग्रॅ'), 'icon': Icons.devices_other},
      ];

  Widget _weeklyPriceBoard(BuildContext context, Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppThemeColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _t2('This Week\'s Price Board', 'इस सप्ताह का मूल्य बोर्ड', 'या आठवड्याचा किंमत बोर्ड'),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppThemeColors.text(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _weekRangeLabel,
            style: TextStyle(color: AppThemeColors.muted(context), fontSize: 12),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppThemeColors.background(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedLocation,
                isExpanded: true,
                dropdownColor: AppThemeColors.card(context),
                icon: Icon(Icons.location_on, color: accent),
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
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    _t2('Material', 'सामग्री', 'साहित्य'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppThemeColors.muted(context),
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _t2('Location', 'स्थान', 'स्थान'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppThemeColors.muted(context),
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _t2('Standardized Market Price', 'मानकीकृत बाजार मूल्य', 'मानकीकृत बाजार किंमत'),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppThemeColors.muted(context),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          for (final item in _weeklyBoardMaterials)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppThemeColors.background(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(item['icon'] as IconData, color: accent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text(
                      item['material'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppThemeColors.text(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      selectedLocation,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppThemeColors.muted(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${((item['base'] as int) * (_locationMultipliers[selectedLocation] ?? 1.0)).round()}/${item['unit']}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: accent,
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

  List<Map<String, dynamic>> get prices {
    switch (widget.language) {
      case AppLanguage.hindi:
        return [
          {
            'material': 'तांबा (Copper)',
            'rate': '₹620/किग्रा',
            'trend': '+4.2%',
            'up': true,
            'icon': Icons.cable,
          },
          {
            'material': 'पीसीबी (PCB)',
            'rate': '₹480/किग्रा',
            'trend': '+6.1%',
            'up': true,
            'icon': Icons.memory,
          },
          {
            'material': 'एल्युमीनियम (Aluminium)',
            'rate': '₹165/किग्रा',
            'trend': '+1.8%',
            'up': true,
            'icon': Icons.settings,
          },
          {
            'material': 'लेड बैटरी (Lead Battery)',
            'rate': '₹95/किग्रा',
            'trend': '-1.4%',
            'up': false,
            'icon': Icons.battery_full,
          },
          {
            'material': 'सीआरटी कांच (CRT Glass)',
            'rate': '₹30/किग्रा',
            'trend': '+0.8%',
            'up': true,
            'icon': Icons.tv,
          },
          {
            'material': 'मिश्रित ई-कचरा (Mixed E-Waste)',
            'rate': '₹110/किग्रा',
            'trend': '+2.7%',
            'up': true,
            'icon': Icons.devices_other,
          },
        ];
      case AppLanguage.marathi:
        return [
          {
            'material': 'तांबे (Copper)',
            'rate': '₹620/किग्रॅ',
            'trend': '+4.2%',
            'up': true,
            'icon': Icons.cable,
          },
          {
            'material': 'पीसीबी (PCB)',
            'rate': '₹480/किग्रॅ',
            'trend': '+6.1%',
            'up': true,
            'icon': Icons.memory,
          },
          {
            'material': 'ॲल्युमिनियम (Aluminium)',
            'rate': '₹165/किग्रॅ',
            'trend': '+1.8%',
            'up': true,
            'icon': Icons.settings,
          },
          {
            'material': 'लेड बॅटरी (Lead Battery)',
            'rate': '₹95/किग्रॅ',
            'trend': '-1.4%',
            'up': false,
            'icon': Icons.battery_full,
          },
          {
            'material': 'सीआरटी काच (CRT Glass)',
            'rate': '₹30/किग्रॅ',
            'trend': '+0.8%',
            'up': true,
            'icon': Icons.tv,
          },
          {
            'material': 'मिश्रित ई-कचरा (Mixed E-Waste)',
            'rate': '₹110/किग्रॅ',
            'trend': '+2.7%',
            'up': true,
            'icon': Icons.devices_other,
          },
        ];
      case AppLanguage.english:
      default:
        return [
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
    }
  }

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  Future<void> _speak(
    String text,
  ) async {
    switch (widget.language) {
      case AppLanguage.hindi:
        await tts.setLanguage('hi-IN');
        break;
      case AppLanguage.marathi:
        await tts.setLanguage('mr-IN');
        break;
      case AppLanguage.english:
      default:
        await tts.setLanguage('en-IN');
        break;
    }
    await tts.setSpeechRate(0.42);
    await tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final activeAccent = AppThemeColors.isDark(context) ? AppColors.primaryGold : AppColors.featherGreen;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headerTitle,
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
            headerSubtitle,
            style: TextStyle(
              color: AppThemeColors.muted(
                context,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _weeklyPriceBoard(context, activeAccent),
          const SizedBox(height: 24),
          Text(
            _t2(
              'Select a location for details',
              'विवरण के लिए स्थान चुनें',
              'तपशीलासाठी स्थान निवडा',
            ),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.text(context),
            ),
          ),
          const SizedBox(height: 10),
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
                icon: Icon(
                  Icons.location_on,
                  color: activeAccent,
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
              color: activeAccent.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(
                14,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: activeAccent,
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
    final activeAccent = AppThemeColors.isDark(context) ? AppColors.primaryGold : AppColors.featherGreen;

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
            backgroundColor: activeAccent.withValues(
              alpha: 0.15,
            ),
            child: Icon(
              price['icon'] as IconData,
              color: activeAccent,
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
                  style: TextStyle(
                    color: activeAccent,
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
  final AppLanguage language;

  const SafetyTab({
    super.key,
    this.language = AppLanguage.english,
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
    switch (widget.language) {
      case AppLanguage.hindi:
        await tts.setLanguage('hi-IN');
        break;
      case AppLanguage.marathi:
        await tts.setLanguage('mr-IN');
        break;
      case AppLanguage.english:
      default:
        await tts.setLanguage('en-IN');
        break;
    }
    await tts.setSpeechRate(0.42);
    await tts.speak(text);
  }

  List<Map<String, dynamic>> get guidance {
    switch (widget.language) {
      case AppLanguage.hindi:
        return [
          {
            'title': 'ई-कचरा न जलाएं',
            'description': 'तार, प्लास्टिक या इलेक्ट्रॉनिक भागों को जलाने से जहरीला धुआं निकलता है। इसके बजाय अधिकृत रीसाइक्लिंग चैनलों का उपयोग करें।',
            'icon': Icons.local_fire_department,
            'danger': true,
            'audio': 'इलेक्ट्रॉनिक कचरा, तार, बैटरी या प्लास्टिक न जलाएं। जलाने से जहरीला धुआं निकल सकता है।',
          },
          {
            'title': 'बैटरी न खोलें',
            'description': 'बैटरियों को काटें, छेद न करें या खोलें नहीं। क्षतिग्रस्त बैटरियों को अलग रखें और अधिकृत रीसायकलर से संपर्क करें।',
            'icon': Icons.battery_alert,
            'danger': true,
            'audio': 'बैटरियों को न खोलें, काटें या छेदें। क्षतिग्रस्त बैटरियों को अलग रखें।',
          },
          {
            'title': 'CRT को सावधानी से संभालें',
            'description': 'CRT टीवी और मॉनिटर में खतरनाक सामग्री हो सकती है। कांच को तोड़ने से बचें और जलाएं नहीं।',
            'icon': Icons.tv,
            'danger': true,
            'audio': 'CRT टीवी और मॉनिटर को सावधानी से संभालें। कांच न तोड़ें।',
          },
          {
            'title': 'इलेक्ट्रॉनिक्स को सूखा रखें',
            'description': 'संग्रहण से पहले सर्किट बोर्ड और इलेक्ट्रॉनिक्स को सूखे स्थान पर रखें।',
            'icon': Icons.water_drop,
            'danger': false,
            'audio': 'सर्किट बोर्ड और इलेक्ट्रॉनिक घटकों को सूखा रखें।',
          },
          {
            'title': 'सुरक्षा उपकरणों का प्रयोग करें',
            'description': 'धारदार या क्षतिग्रस्त हिस्सों को संभालते समय दस्ताने और जूते पहनें।',
            'icon': Icons.health_and_safety,
            'danger': false,
            'audio': 'धारदार हिस्सों को संभालते समय दस्ताने और जूते पहनें।',
          },
        ];
      case AppLanguage.marathi:
        return [
          {
            'title': 'ई-कचरा जाळू नका',
            'description': 'इलेक्ट्रॉनिक भाग जाळल्याने विषारी वायू बाहेर पडतात. अधिकृत मार्गांचा वापर करा.',
            'icon': Icons.local_fire_department,
            'danger': true,
            'audio': 'इलेक्ट्रॉनिक कचरा किंवा प्लास्टिक जाळू नका.',
          },
          {
            'title': 'बॅटरी उघडू नका',
            'description': 'बॅटरी कापू किंवा फोडू नका. खराब झालेल्या बॅटरी वेगळ्या ठेवा.',
            'icon': Icons.battery_alert,
            'danger': true,
            'audio': 'बॅटरी उघडू नका किंवा कापू नका.',
          },
          {
            'title': 'CRT काळजीपूर्वक हाताळा',
            'description': 'CRT टीव्हीमधील काच फोडू नका किंवा जाळू नका.',
            'icon': Icons.tv,
            'danger': true,
            'audio': 'CRT टीव्ही आणि मॉनिटर काळजीपूर्वक हाताळा.',
          },
          {
            'title': 'इलेक्ट्रॉनिक्स कोरडे ठेवा',
            'description': 'सर्किट बोर्ड कोरड्या जागी ठेवा.',
            'icon': Icons.water_drop,
            'danger': false,
            'audio': 'इलेक्ट्रॉनिक वस्तू कोरड्या जागी ठेवा.',
          },
          {
            'title': 'सुरक्षिततेची साधने वापरा',
            'description': 'काम करताना हातमोजे आणि योग्य शूज वापरा.',
            'icon': Icons.health_and_safety,
            'danger': false,
            'audio': 'हातमोजे आणि शूज वापरणे गरजेचे आहे.',
          },
        ];
      case AppLanguage.english:
      default:
        return [
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_LanguageText.t(
          widget.language,
          'Safety Guidance',
          'सुरक्षा मार्गदर्शन',
          'सुरक्षा मार्गदर्शन',
        )),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _LanguageText.t(
                widget.language,
                'Safety Guidance',
                'सुरक्षा मार्गदर्शन',
                'सुरक्षा मार्गदर्शन',
              ),
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
              _LanguageText.t(
                widget.language,
                'Simple picture-based and audio guidance for safer e-waste handling.',
                'सुरक्षित ई-कचरा संभालने के लिए सरल चित्र और ऑडियो मार्गदर्शन।',
                'सुरक्षित ई-कचरा हाताळणीसाठी सोपे चित्र आणि ऑडिओ मार्गदर्शन.',
              ),
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
      ),
    );
  }

  Widget _safetyCard(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final danger = item['danger'] as bool;
    final iconBoxSize = MediaQuery.of(context).size.width < 340 ? 46.0 : 58.0;
    final iconSize = MediaQuery.of(context).size.width < 340 ? 24.0 : 30.0;

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
                height: iconBoxSize,
                width: iconBoxSize,
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
                  size: iconSize,
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
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 42,
              height: 42,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: AppColors.mintGreen,
                  foregroundColor: AppColors.darkBackground,
                  shape: const CircleBorder(),
                ),
                onPressed: () {
                  _speak(
                    item['audio'] as String,
                  );
                },
                child: const Icon(
                  Icons.volume_up,
                  color: AppColors.darkBackground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CLASSIFICATION, RECENT UPLOADS, PAYMENTS AND PICKUP UPLOAD
// ============================================================

class _LanguageText {
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

class ClassifyResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  final AppLanguage language;

  const ClassifyResultScreen({
    super.key,
    required this.result,
    required this.language,
  });

  String _t(String en, String hi, String mr) =>
      _LanguageText.t(language, en, hi, mr);

  @override
  Widget build(BuildContext context) {
    final accent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;
    final imagePath = result['imagePath'] as String?;
    final material = result['material'] as String? ?? 'E-Waste';
    final weight = result['weight'] as String? ?? 'Approx. 2.5 kg';
    final price = result['price'] as String? ?? '₹275';
    final confidence = result['confidence'] as String? ?? '89%';
    final date = result['date'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('AI Classification', 'AI वर्गीकरण', 'AI वर्गीकरण')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (imagePath != null && File(imagePath).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                File(imagePath),
                height: 240,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppThemeColors.card(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                _resultRow(context, Icons.category,
                    _t('Material', 'सामग्री', 'साहित्य'), material),
                _resultRow(context, Icons.scale,
                    _t('Approx. Weight', 'अनुमानित वजन', 'अंदाजे वजन'), weight),
                _resultRow(context, Icons.currency_rupee,
                    _t('Estimated Price', 'अनुमानित कीमत', 'अंदाजे किंमत'), price),
                _resultRow(context, Icons.verified,
                    _t('AI Confidence', 'AI विश्वास स्तर', 'AI विश्वास पातळी'), confidence),
                _resultRow(context, Icons.calendar_today,
                    _t('Picture Date', 'चित्र की तारीख', 'फोटोची तारीख'), date),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _t(
                'AI results are estimates for the prototype. Confirm actual material, weight and market price with a verified recycler before completing a transaction.',
                'AI परिणाम प्रोटोटाइप के लिए अनुमान हैं। लेनदेन पूरा करने से पहले सत्यापित रीसायकलर से वास्तविक सामग्री, वजन और बाजार मूल्य की पुष्टि करें।',
                'AI परिणाम प्रोटोटाइपसाठी अंदाज आहेत. व्यवहार पूर्ण करण्यापूर्वी सत्यापित रीसायकलरकडून वास्तविक साहित्य, वजन आणि बाजारभावाची पुष्टी करा.',
              ),
              style: TextStyle(color: AppThemeColors.text(context), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(BuildContext context, IconData icon, String label, String value) {
    final accent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppThemeColors.muted(context)),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppThemeColors.text(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalAiClassifier {
  static Map<String, dynamic> classify(String path, {bool bulk = false}) {
    // Prototype-only local classifier. It intentionally does not claim to be a
    // trained ML model; it provides an AI-style result until a backend/model is connected.
    final name = path.toLowerCase();
    String material;
    String weight;
    String price;
    String confidence;

    if (name.contains('battery')) {
      material = 'Lead Battery';
      weight = bulk ? 'Approx. 8.0 kg' : 'Approx. 2.0 kg';
      price = bulk ? '₹760' : '₹190';
      confidence = '91%';
    } else if (name.contains('cable') || name.contains('wire')) {
      material = 'Copper Cable';
      weight = bulk ? 'Approx. 10.0 kg' : 'Approx. 2.5 kg';
      price = bulk ? '₹2,800' : '₹700';
      confidence = '88%';
    } else if (name.contains('pcb') || name.contains('circuit')) {
      material = 'PCB / Circuit Board';
      weight = bulk ? 'Approx. 7.5 kg' : 'Approx. 1.8 kg';
      price = bulk ? '₹3,600' : '₹864';
      confidence = '93%';
    } else if (name.contains('plastic')) {
      material = 'Hard Plastic';
      weight = bulk ? 'Approx. 12.0 kg' : 'Approx. 3.0 kg';
      price = bulk ? '₹720' : '₹180';
      confidence = '86%';
    } else if (name.contains('aluminium') || name.contains('aluminum')) {
      material = 'Aluminium';
      weight = bulk ? 'Approx. 9.0 kg' : 'Approx. 2.5 kg';
      price = bulk ? '₹1,485' : '₹413';
      confidence = '89%';
    } else {
      material = bulk ? 'Mixed E-Waste' : 'Electronic Scrap';
      weight = bulk ? 'Approx. 6.0 kg' : 'Approx. 2.5 kg';
      price = bulk ? '₹660' : '₹275';
      confidence = bulk ? '84%' : '87%';
    }

    return {
      'material': material,
      'weight': weight,
      'price': price,
      'confidence': confidence,
      'imagePath': path,
      'date': DateTime.now().toIso8601String(),
      'mode': bulk ? 'bulk' : 'scrap',
    };
  }
}

Future<XFile?> _pickClassificationImage(BuildContext context, AppLanguage language) async {
  final picker = ImagePicker();

  return showModalBottomSheet<XFile?>(
    context: context,
    backgroundColor: AppThemeColors.card(context),
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(_LanguageText.t(
                language,
                'Camera',
                'कैमरा',
                'कॅमेरा',
              )),
              onTap: () async {
                final image = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (ctx.mounted) Navigator.pop(ctx, image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(_LanguageText.t(
                language,
                'Gallery',
                'गैलरी',
                'गॅलरी',
              )),
              onTap: () async {
                final image = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (ctx.mounted) Navigator.pop(ctx, image);
              },
            ),
          ],
        ),
      );
    },
  );
}

class PickupUploadTab extends StatefulWidget {
  final String? savedPhotoPath;
  final ReNovaStorage storage;
  final AppLanguage language;
  final ValueChanged<String?> onPhotoUploaded;

  const PickupUploadTab({
    super.key,
    this.savedPhotoPath,
    required this.storage,
    required this.language,
    required this.onPhotoUploaded,
  });

  @override
  State<PickupUploadTab> createState() => _PickupUploadTabState();
}

class _PickupUploadTabState extends State<PickupUploadTab> {
  bool loading = false;

  String _t(String en, String hi, String mr) =>
      _LanguageText.t(widget.language, en, hi, mr);

  Future<void> _classifyScrap() async {
    final image = await _pickClassificationImage(context, widget.language);
    if (image == null) return;

    setState(() => loading = true);
    final path = await widget.storage.saveImagePermanently(
      image,
      'renova_classification_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final result = _LocalAiClassifier.classify(path);
    await widget.storage.saveClassification(result);
    if (!mounted) return;
    setState(() => loading = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClassifyResultScreen(
          result: result,
          language: widget.language,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _t('Classify Scrap', 'कबाड़ का वर्गीकरण', 'भंगाराचे वर्गीकरण'),
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: AppThemeColors.text(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _t(
            'Upload one scrap image through Camera or Gallery and get an estimated material, weight, price and AI confidence.',
            'कैमरा या गैलरी से एक कबाड़ की तस्वीर अपलोड करें और अनुमानित सामग्री, वजन, कीमत और AI विश्वास स्तर प्राप्त करें।',
            'कॅमेरा किंवा गॅलरीमधून भंगाराचा फोटो अपलोड करून अंदाजे साहित्य, वजन, किंमत आणि AI विश्वास पातळी मिळवा.',
          ),
          style: TextStyle(color: AppThemeColors.muted(context)),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppThemeColors.card(context),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(Icons.auto_awesome, size: 58, color: accent),
              const SizedBox(height: 16),
              Text(
                _t('AI Scrap Classifier', 'AI कबाड़ वर्गीकरण', 'AI भंगार वर्गीकरण'),
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppThemeColors.text(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _t(
                  'Take a clear photo of the scrap item.',
                  'कबाड़ की साफ तस्वीर लें।',
                  'भंगाराचा स्पष्ट फोटो काढा.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppThemeColors.muted(context)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : _classifyScrap,
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt),
                  label: Text(
                    loading
                        ? _t('Analyzing...', 'विश्लेषण हो रहा है...', 'विश्लेषण सुरू आहे...')
                        : _t('Upload Image', 'तस्वीर अपलोड करें', 'फोटो अपलोड करा'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ClassifyBulkScreen extends StatefulWidget {
  final ReNovaStorage storage;
  final AppLanguage language;

  const ClassifyBulkScreen({
    super.key,
    required this.storage,
    this.language = AppLanguage.english,
  });

  @override
  State<ClassifyBulkScreen> createState() => _ClassifyBulkScreenState();
}

class _ClassifyBulkScreenState extends State<ClassifyBulkScreen> {
  bool loading = false;

  String _t(String en, String hi, String mr) =>
      _LanguageText.t(widget.language, en, hi, mr);

  Future<void> _classifyBulk() async {
    final image = await _pickClassificationImage(context, widget.language);
    if (image == null) return;

    setState(() => loading = true);
    final path = await widget.storage.saveImagePermanently(
      image,
      'renova_bulk_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final result = _LocalAiClassifier.classify(path, bulk: true);
    await widget.storage.saveClassification(result);
    if (!mounted) return;
    setState(() => loading = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClassifyResultScreen(
          result: result,
          language: widget.language,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Classify Bulk', 'बल्क वर्गीकरण', 'बल्क वर्गीकरण')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _t(
              'Upload a photo of the bulk scrap.',
              'बल्क कबाड़ की तस्वीर अपलोड करें।',
              'बल्क भंगाराचा फोटो अपलोड करा.',
            ),
            style: TextStyle(color: AppThemeColors.muted(context)),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppThemeColors.card(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.apps, size: 60),
                const SizedBox(height: 16),
                Text(
                  _t(
                    'Bulk AI Analysis',
                    'बल्क AI विश्लेषण',
                    'बल्क AI विश्लेषण',
                  ),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  _t(
                    'The prototype estimates total material type, weight, price and confidence from the uploaded image.',
                    'प्रोटोटाइप अपलोड की गई तस्वीर से सामग्री प्रकार, वजन, कीमत और विश्वास स्तर का अनुमान लगाता है।',
                    'प्रोटोटाइप अपलोड केलेल्या फोटोवरून साहित्य प्रकार, वजन, किंमत आणि विश्वास पातळीचा अंदाज लावतो.',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : _classifyBulk,
                    icon: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.photo_camera),
                    label: Text(
                      loading
                          ? _t('Analyzing...', 'विश्लेषण हो रहा है...', 'विश्लेषण सुरू आहे...')
                          : _t('Upload Bulk Image', 'बल्क तस्वीर अपलोड करें', 'बल्क फोटो अपलोड करा'),
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
}

class RecentUploadsScreen extends StatefulWidget {
  final AppLanguage language;
  final ReNovaStorage? storage;

  const RecentUploadsScreen({
    super.key,
    this.language = AppLanguage.english,
    this.storage,
  });

  @override
  State<RecentUploadsScreen> createState() => _RecentUploadsScreenState();
}

class _RecentUploadsScreenState extends State<RecentUploadsScreen> {
  String selectedPeriod = 'Week';

  String _t(String en, String hi, String mr) =>
      _LanguageText.t(widget.language, en, hi, mr);

  List<Map<String, dynamic>> get items =>
      widget.storage?.classificationHistory ?? [];

  List<Map<String, dynamic>> get filteredItems {
    final now = DateTime.now();
    final list = items.where((item) {
      final raw = item['date'] as String?;
      final date = raw == null ? null : DateTime.tryParse(raw);
      if (date == null) return false;

      if (selectedPeriod == 'Week') {
        return now.difference(date).inDays <= 7;
      }
      if (selectedPeriod == 'Month') {
        return now.difference(date).inDays <= 31;
      }
      return date.year == now.year;
    }).toList();

    return list;
  }

  String _formatDate(String? raw) {
    final date = raw == null ? null : DateTime.tryParse(raw);
    if (date == null) return raw ?? '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Recent Classifications', 'हाल के वर्गीकरण', 'अलीकडील वर्गीकरण')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: selectedPeriod,
            items: [
              DropdownMenuItem(
                value: 'Week',
                child: Text(_t('Week', 'सप्ताह', 'आठवडा')),
              ),
              DropdownMenuItem(
                value: 'Month',
                child: Text(_t('Month', 'महीना', 'महिना')),
              ),
              DropdownMenuItem(
                value: 'Year',
                child: Text(_t('Year', 'वर्ष', 'वर्ष')),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => selectedPeriod = value);
            },
            decoration: InputDecoration(
              labelText: _t('Show uploads by', 'अपलोड दिखाएं', 'अपलोड दाखवा'),
            ),
          ),
          const SizedBox(height: 16),
          if (filteredItems.isEmpty)
            Padding(
              padding: const EdgeInsets.all(30),
              child: Center(
                child: Text(
                  _t(
                    'No classified images in this period yet.',
                    'इस अवधि में अभी कोई वर्गीकृत तस्वीर नहीं है।',
                    'या कालावधीत अजून वर्गीकृत फोटो नाहीत.',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ...filteredItems.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: SizedBox(
                  width: 62,
                  height: 62,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: item['imagePath'] != null &&
                            File(item['imagePath'] as String).existsSync()
                        ? Image.file(
                            File(item['imagePath'] as String),
                            fit: BoxFit.cover,
                          )
                        : Icon(Icons.image, color: accent),
                  ),
                ),
                title: Text(
                  item['material'] as String? ?? 'Electronic Scrap',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${_formatDate(item['date'] as String?)}\n'
                  '${_t('Weight', 'वजन', 'वजन')}: ${item['weight']} • '
                  '${_t('Price', 'कीमत', 'किंमत')}: ${item['price']}\n'
                  '${_t('Confidence', 'विश्वास', 'विश्वास')}: ${item['confidence']}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClassifyResultScreen(
                      result: item,
                      language: widget.language,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentTab extends StatefulWidget {
  final AppLanguage language;
  final String paymentPreference;
  final ValueChanged<String> onPaymentPreferenceChanged;
  final ReNovaStorage? storage;

  const PaymentTab({
    super.key,
    required this.language,
    required this.paymentPreference,
    required this.onPaymentPreferenceChanged,
    this.storage,
  });

  @override
  State<PaymentTab> createState() => _PaymentTabState();
}

class _PaymentTabState extends State<PaymentTab> {
  late String selectedMode;
  final TextEditingController upiController = TextEditingController();
  final TextEditingController accountController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  bool saveUpiDetails = true;
  String cashStatus = 'received';
  bool qrGenerated = false;

  String _t(String en, String hi, String mr) =>
      _LanguageText.t(widget.language, en, hi, mr);

  @override
  void initState() {
    super.initState();
    selectedMode = widget.paymentPreference == 'UPI / Digital Wallet'
        ? 'UPI'
        : 'Cash';
  }

  @override
  void dispose() {
    upiController.dispose();
    accountController.dispose();
    amountController.dispose();
    super.dispose();
  }

  String _upiQrData() {
    final upiId = upiController.text.trim();
    final amount = amountController.text.trim();

    if (upiId.isEmpty) return '';

    final params = <String>[
      'pa=${Uri.encodeComponent(upiId)}',
      'pn=${Uri.encodeComponent('ReNova')}',
      if (amount.isNotEmpty) 'am=${Uri.encodeComponent(amount)}',
      'cu=INR',
    ];

    return 'upi://pay?${params.join('&')}';
  }

  Future<void> _recordPayment() async {
    final mode = selectedMode;
    final details = mode == 'Cash'
        ? (cashStatus == 'received'
            ? _t('Cash received', 'नकद प्राप्त हुआ', 'रोख मिळाली')
            : _t('Cash yet to receive', 'नकद प्राप्त होना बाकी है', 'रोख अजून मिळायची आहे'))
        : (upiController.text.trim().isEmpty
            ? _t('UPI details not entered', 'UPI विवरण दर्ज नहीं किया गया', 'UPI तपशील दिलेला नाही')
            : upiController.text.trim());

    final item = {
      'mode': mode,
      'details': details,
      'amount': amountController.text.trim().isEmpty
          ? '₹1,750'
          : '₹${amountController.text.trim()}',
      'date': DateTime.now().toIso8601String(),
    };

    await widget.storage?.savePayment(item);
    widget.onPaymentPreferenceChanged(
      mode == 'Cash' ? 'Cash' : 'UPI / Digital Wallet',
    );

    if (mode == 'UPI' && saveUpiDetails && upiController.text.trim().isNotEmpty) {
      await widget.storage?.saveUpiId(upiController.text.trim());
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_t(
          'Payment preference saved.',
          'भुगतान पसंद सहेजी गई।',
          'पेमेंट पसंती जतन झाली.',
        )),
      ),
    );
    setState(() {});
  }

  String _formatDate(String? raw) {
    final date = raw == null ? null : DateTime.tryParse(raw);
    if (date == null) return raw ?? '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;
    final history = widget.storage?.paymentHistory ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _t('Payments', 'भुगतान', 'पेमेंट'),
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: AppThemeColors.text(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _t(
            'Choose how you want to receive payment.',
            'भुगतान प्राप्त करने का तरीका चुनें।',
            'पेमेंट कसे घ्यायचे ते निवडा.',
          ),
          style: TextStyle(color: AppThemeColors.muted(context)),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _paymentModeCard(
                context,
                'Cash',
                Icons.payments_outlined,
                _t('Cash', 'नकद', 'रोख'),
                accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _paymentModeCard(
                context,
                'UPI',
                Icons.qr_code_2,
                'UPI',
                accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: selectedMode == 'Cash'
              ? _cashDetails(context)
              : _upiDetails(context),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _recordPayment,
            icon: const Icon(Icons.save),
            label: Text(_t('Save Payment Mode', 'भुगतान तरीका सहेजें', 'पेमेंट पद्धत जतन करा')),
          ),
        ),
        const SizedBox(height: 26),
        Text(
          _t('Payment History', 'भुगतान इतिहास', 'पेमेंट इतिहास'),
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: AppThemeColors.text(context),
          ),
        ),
        const SizedBox(height: 10),
        if (history.isEmpty)
          Text(
            _t(
              'No payments recorded yet.',
              'अभी कोई भुगतान दर्ज नहीं है।',
              'अजून कोणतेही पेमेंट नोंदलेले नाही.',
            ),
            style: TextStyle(color: AppThemeColors.muted(context)),
          ),
        ...history.map(
          (item) => Card(
            child: ListTile(
              leading: Icon(
                item['mode'] == 'UPI' ? Icons.qr_code_2 : Icons.payments_outlined,
                color: accent,
              ),
              title: Text(
                '${item['mode']} • ${item['amount']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${_t('Mode', 'तरीका', 'पद्धत')}: ${item['mode']}\n'
                '${_t('Date', 'तारीख', 'तारीख')}: ${_formatDate(item['date'] as String?)}',
              ),
              isThreeLine: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _paymentModeCard(
    BuildContext context,
    String mode,
    IconData icon,
    String title,
    Color accent,
  ) {
    final selected = selectedMode == mode;
    return InkWell(
      onTap: () => setState(() => selectedMode = mode),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.15)
              : AppThemeColors.card(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 34, color: accent),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: accent,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _cashDetails(BuildContext context) {
    final accent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;
    return Container(
      key: const ValueKey('cash'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemeColors.card(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.payments, size: 34),
            title: Text(_t('Cash Payment', 'नकद भुगतान', 'रोख पेमेंट')),
            subtitle: Text(
              _t(
                'Receive the amount in cash and keep the transaction record.',
                'राशि नकद प्राप्त करें और लेनदेन का रिकॉर्ड रखें।',
                'रक्कम रोख घ्या आणि व्यवहाराची नोंद ठेवा.',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _t('Payment Status', 'भुगतान स्थिति', 'पेमेंट स्थिती'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppThemeColors.text(context),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(_t('Cash received', 'नकद प्राप्त हुआ', 'रोख मिळाली')),
                selected: cashStatus == 'received',
                selectedColor: accent.withValues(alpha: 0.25),
                onSelected: (_) => setState(() => cashStatus = 'received'),
              ),
              ChoiceChip(
                label: Text(_t('Cash yet to receive', 'नकद प्राप्त होना बाकी है', 'रोख अजून मिळायची आहे')),
                selected: cashStatus == 'pending',
                selectedColor: accent.withValues(alpha: 0.25),
                onSelected: (_) => setState(() => cashStatus = 'pending'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _upiDetails(BuildContext context) {
    return Container(
      key: const ValueKey('upi'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemeColors.card(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          TextField(
            controller: upiController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.alternate_email),
              labelText: _t('UPI ID', 'UPI आईडी', 'UPI आयडी'),
              hintText: 'name@upi',
            ),
            onChanged: (_) => setState(() => qrGenerated = false),
          ),
          if ((widget.storage?.savedUpiId ?? '').isNotEmpty &&
              widget.storage!.savedUpiId != upiController.text.trim()) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.history, size: 16),
                label: Text(
                  '${_t('Recently used', 'हाल ही में उपयोग किया गया', 'अलीकडे वापरलेले')}: ${widget.storage!.savedUpiId}',
                ),
                onPressed: () {
                  setState(() {
                    upiController.text = widget.storage!.savedUpiId!;
                  });
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: accountController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.account_balance),
              labelText: _t('Bank / Wallet Reference (optional)', 'बैंक / वॉलेट संदर्भ (वैकल्पिक)', 'बँक / वॉलेट संदर्भ (पर्यायी)'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.currency_rupee),
              labelText: _t('Amount (₹)', 'राशि (₹)', 'रक्कम (₹)'),
              hintText: 'e.g. 500',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          if (upiController.text.trim().isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => qrGenerated = true),
                icon: const Icon(Icons.qr_code_2),
                label: Text(_t('Generate UPI', 'UPI जनरेट करें', 'UPI तयार करा')),
              ),
            ),
          if (qrGenerated && _upiQrData().isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: QrImageView(
                data: _upiQrData(),
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
          ],
          if (qrGenerated && _upiQrData().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _t('Scan with any UPI app', 'किसी भी UPI ऐप से स्कैन करें', 'कोणत्याही UPI अॅपने स्कॅन करा'),
              style: TextStyle(
                color: AppThemeColors.muted(context),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _t('Save UPI details?', 'UPI विवरण सहेजें?', 'UPI तपशील जतन करायचे?'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppThemeColors.text(context),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                ChoiceChip(
                  label: Text(_t('Yes', 'हाँ', 'होय')),
                  selected: saveUpiDetails,
                  onSelected: (_) => setState(() => saveUpiDetails = true),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: Text(_t('No', 'नहीं', 'नाही')),
                  selected: !saveUpiDetails,
                  onSelected: (_) => setState(() => saveUpiDetails = false),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _t(
                'For a real QR/UPI transaction flow, connect a payment gateway in the production backend.',
                'वास्तविक QR/UPI लेनदेन के लिए उत्पादन बैकएंड में पेमेंट गेटवे जोड़ें।',
                'वास्तविक QR/UPI व्यवहारासाठी उत्पादन बॅकएंडमध्ये पेमेंट गेटवे जोडा.',
              ),
              style: TextStyle(
                color: AppThemeColors.muted(context),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
