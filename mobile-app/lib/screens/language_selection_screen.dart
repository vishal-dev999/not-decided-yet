import 'package:flutter/material.dart';

import '../constants/app_enums.dart';
import '../services/storage_service.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import '../widgets/theme_switch_button.dart';
import 'collector_login_screen.dart';

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
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

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
                    final storage = getStorage(context);

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CollectorLoginScreen(
                          language: widget.language,
                          storage: getStorage(context),
                          themeMode: widget.themeMode,
                          onThemeChanged: widget.onThemeChanged,
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
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

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
              color: selected ? activeAccent : AppThemeColors.faint(context),
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
