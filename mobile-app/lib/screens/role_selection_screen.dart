import 'package:flutter/material.dart';

import '../constants/app_enums.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';

class RoleSelectionScreen extends StatefulWidget {
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  final ReNovaThemeMode themeMode;
  final ValueChanged<ReNovaThemeMode> onThemeChanged;

  // IMPORTANT:
  // The context comes from RoleSelectionScreen itself so that
  // Navigator.of(context) can correctly find the Navigator.
  final void Function(BuildContext context) onScrapCollectorSelected;

  final VoidCallback onRiderSelected;

  const RoleSelectionScreen({
    super.key,
    required this.language,
    required this.onLanguageChanged,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onScrapCollectorSelected,
    required this.onRiderSelected,
  });

  @override
  State<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  // ============================================================
  // TRANSLATION
  // ============================================================

  String _t(
    String en,
    String hi,
    String mr,
  ) {
    switch (widget.language) {
      case AppLanguage.hindi:
        return hi;

      case AppLanguage.marathi:
        return mr;

      case AppLanguage.english:
        return en;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppThemeColors.isDark(context);

    final Color activeAccent = isDark
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    final Color textColor = AppThemeColors.text(context);

    final Color mutedColor = AppThemeColors.muted(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 35),

              // ==================================================
              // RECYCLING SYMBOL
              // ==================================================

              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: activeAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.recycling,
                  size: 52,
                  color: activeAccent,
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // RECYLINK
              // ==================================================

              Text(
                'RecyLink',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _t(
                  'Connect. Collect. Recycle.',
                  'जुड़ें। एकत्र करें। पुनर्चक्रण करें।',
                  'जोडा. संकलित करा. पुनर्वापर करा.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: mutedColor,
                ),
              ),

              const SizedBox(height: 55),

              // ==================================================
              // SELECT ROLE
              // ==================================================

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _t(
                    'Select Role',
                    'भूमिका चुनें',
                    'भूमिका निवडा',
                  ),
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _t(
                    'Choose how you want to use RecyLink',
                    'चुनें कि आप RecyLink का उपयोग कैसे करना चाहते हैं',
                    'तुम्हाला RecyLink कसे वापरायचे आहे ते निवडा',
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: mutedColor,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // SCRAP COLLECTOR
              // ==================================================

              _RoleCard(
                icon: Icons.recycling,
                title: _t(
                  'ScrapCollector',
                  'कबाड़ संग्राहक',
                  'भंगार संकलक',
                ),
                subtitle: _t(
                  'Collect and manage scrap pickups',
                  'कबाड़ संग्रह और पिकअप प्रबंधित करें',
                  'भंगार संकलन आणि पिकअप व्यवस्थापित करा',
                ),
                accentColor: activeAccent,

                // IMPORTANT:
                // Pass the current screen's context.
                onTap: (context) {
                  widget.onScrapCollectorSelected(context);
                },
              ),

              const SizedBox(height: 16),

              // ==================================================
              // RIDER
              // ==================================================

              _RoleCard(
                icon: Icons.delivery_dining,
                title: _t(
                  'Rider',
                  'राइडर',
                  'रायडर',
                ),
                subtitle: _t(
                  'Pick up and deliver scrap',
                  'कबाड़ उठाएं और वितरित करें',
                  'भंगार उचला आणि पोहोचवा',
                ),
                accentColor: activeAccent,
                onTap: (_) {
                  widget.onRiderSelected();
                },
              ),

              const SizedBox(height: 35),

              // ==================================================
              // LANGUAGE
              // ==================================================

              Text(
                _t(
                  'Language',
                  'भाषा',
                  'भाषा',
                ),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: mutedColor,
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  // ==================================================
                  // ENGLISH
                  // ==================================================

                  _LanguageButton(
                    label: 'English',
                    selected:
                        widget.language == AppLanguage.english,
                    accentColor: activeAccent,
                    onTap: () {
                      widget.onLanguageChanged(
                        AppLanguage.english,
                      );
                    },
                  ),

                  // ==================================================
                  // HINDI
                  // ==================================================

                  _LanguageButton(
                    label: 'हिन्दी',
                    selected:
                        widget.language == AppLanguage.hindi,
                    accentColor: activeAccent,
                    onTap: () {
                      widget.onLanguageChanged(
                        AppLanguage.hindi,
                      );
                    },
                  ),

                  // ==================================================
                  // MARATHI
                  // ==================================================

                  _LanguageButton(
                    label: 'मराठी',
                    selected:
                        widget.language == AppLanguage.marathi,
                    accentColor: activeAccent,
                    onTap: () {
                      widget.onLanguageChanged(
                        AppLanguage.marathi,
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ROLE CARD
// ============================================================

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;

  // IMPORTANT:
  // This now receives BuildContext.
  final void Function(BuildContext context) onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppThemeColors.isDark(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        // Pass the RoleCard's context to the callback.
        onTap: () => onTap(context),

        borderRadius: BorderRadius.circular(18),

        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(
            color: isDark
                ? AppColors.cardBg
                : AppColors.lightCard,

            borderRadius: BorderRadius.circular(18),

            border: Border.all(
              color: accentColor.withValues(alpha: 0.22),
              width: 1,
            ),
          ),

          child: Row(
            children: [
              // ==================================================
              // ICON
              // ==================================================

              Container(
                width: 58,
                height: 58,

                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),

                  borderRadius: BorderRadius.circular(16),
                ),

                child: Icon(
                  icon,
                  size: 30,
                  color: accentColor,
                ),
              ),

              const SizedBox(width: 16),

              // ==================================================
              // TEXT
              // ==================================================

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppThemeColors.text(context),
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppThemeColors.muted(context),
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // ARROW
              // ==================================================

              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 17,
                color: accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// LANGUAGE BUTTON
// ============================================================

class _LanguageButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,

      style: OutlinedButton.styleFrom(
        backgroundColor: selected
            ? accentColor.withValues(alpha: 0.12)
            : Colors.transparent,

        side: BorderSide(
          color: selected
              ? accentColor
              : AppThemeColors.muted(context)
                  .withValues(alpha: 0.35),
        ),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      child: Text(
        label,
        style: TextStyle(
          color: selected
              ? accentColor
              : AppThemeColors.text(context),

          fontWeight: selected
              ? FontWeight.bold
              : FontWeight.w500,
        ),
      ),
    );
  }
}