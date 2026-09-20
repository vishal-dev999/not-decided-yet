import 'package:flutter/material.dart';

import '../constants/app_enums.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';

class RoleSelectionScreen extends StatefulWidget {
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  final ReNovaThemeMode themeMode;
  final ValueChanged<ReNovaThemeMode> onThemeChanged;

  final void Function(BuildContext context) onScrapCollectorSelected;
  final void Function(BuildContext context) onRiderSelected;

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

class _RoleSelectionScreenState
    extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _taglineAnimationController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late Animation<double> _taglineScaleAnimation;
  late Animation<double> _taglineFadeAnimation;

  @override
  void initState() {
    super.initState();

    // ------------------------------------------------
    // MAIN SCREEN ANIMATION
    // ------------------------------------------------

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();

    // ------------------------------------------------
    // PREMIUM TAGLINE ANIMATION
    // ------------------------------------------------

    _taglineAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _taglineScaleAnimation = TweenSequence<double>(
      [
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.72,
            end: 1.10,
          ).chain(
            CurveTween(
              curve: Curves.easeOutBack,
            ),
          ),
          weight: 55,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1.10,
            end: 0.96,
          ).chain(
            CurveTween(
              curve: Curves.easeInOut,
            ),
          ),
          weight: 20,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.96,
            end: 1.0,
          ).chain(
            CurveTween(
              curve: Curves.easeOut,
            ),
          ),
          weight: 25,
        ),
      ],
    ).animate(_taglineAnimationController);

    _taglineFadeAnimation = CurvedAnimation(
      parent: _taglineAnimationController,
      curve: const Interval(
        0.0,
        0.55,
        curve: Curves.easeOut,
      ),
    );

    Future.delayed(
      const Duration(milliseconds: 420),
      () {
        if (mounted) {
          _taglineAnimationController.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _taglineAnimationController.dispose();
    super.dispose();
  }

  String get welcomeText {
    switch (widget.language) {
      case AppLanguage.english:
        return 'Welcome to ReNova';
      case AppLanguage.hindi:
        return 'ReNova में आपका स्वागत है';
      case AppLanguage.marathi:
        return 'ReNova मध्ये आपले स्वागत आहे';
    }
  }

  String get subtitleText {
    switch (widget.language) {
      case AppLanguage.english:
        return 'Connect • Collect • Recycle';
      case AppLanguage.hindi:
        return 'Connect • Collect • Recycle';
      case AppLanguage.marathi:
        return 'Connect • Collect • Recycle';
    }
  }

  String get chooseRoleText {
    switch (widget.language) {
      case AppLanguage.english:
        return 'Select your role';
      case AppLanguage.hindi:
        return 'अपनी भूमिका चुनें';
      case AppLanguage.marathi:
        return 'तुमची भूमिका निवडा';
    }
  }

  String get collectorTitle {
    switch (widget.language) {
      case AppLanguage.english:
        return 'Scrap Collector';
      case AppLanguage.hindi:
        return 'कबाड़ कलेक्टर';
      case AppLanguage.marathi:
        return 'भंगार कलेक्टर';
    }
  }

  String get collectorDescription {
    switch (widget.language) {
      case AppLanguage.english:
        return 'Collect, classify and sell scrap at fair prices';
      case AppLanguage.hindi:
        return 'कबाड़ इकट्ठा करें, वर्गीकृत करें और उचित कीमत पर बेचें';
      case AppLanguage.marathi:
        return 'भंगार गोळा करा, वर्गीकरण करा आणि योग्य किमतीत विका';
    }
  }

  String get riderTitle {
    switch (widget.language) {
      case AppLanguage.english:
        return 'Rider';
      case AppLanguage.hindi:
        return 'राइडर';
      case AppLanguage.marathi:
        return 'रायडर';
    }
  }

  String get riderDescription {
    switch (widget.language) {
      case AppLanguage.english:
        return 'Pick up e-waste from collectors and deliver it to recyclers';
      case AppLanguage.hindi:
        return 'कलेक्टर से ई-कचरा लेकर रीसाइक्लर तक पहुंचाएं';
      case AppLanguage.marathi:
        return 'कलेक्टरकडून ई-कचरा घेऊन रिसायकलरपर्यंत पोहोचवा';
    }
  }

  String get languageText {
    switch (widget.language) {
      case AppLanguage.english:
        return 'Language';
      case AppLanguage.hindi:
        return 'भाषा';
      case AppLanguage.marathi:
        return 'भाषा';
    }
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemeColors.card(context),
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  languageText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppThemeColors.text(context),
                  ),
                ),
                const SizedBox(height: 16),
                _languageOption(
                  title: 'English',
                  language: AppLanguage.english,
                ),
                _languageOption(
                  title: 'हिन्दी',
                  language: AppLanguage.hindi,
                ),
                _languageOption(
                  title: 'मराठी',
                  language: AppLanguage.marathi,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _languageOption({
    required String title,
    required AppLanguage language,
  }) {
    final bool selected = widget.language == language;
    final accent = AppThemeColors.primary(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      leading: Icon(
        selected
            ? Icons.radio_button_checked
            : Icons.radio_button_off,
        color: selected
            ? accent
            : AppThemeColors.muted(context),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight:
              selected ? FontWeight.w700 : FontWeight.w500,
          color: AppThemeColors.text(context),
        ),
      ),
      onTap: () {
        widget.onLanguageChanged(language);
        Navigator.pop(context);
      },
    );
  }

  Widget _roleCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final accent = AppThemeColors.primary(context);
    final cardColor = AppThemeColors.card(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accent.withValues(alpha: 0.14),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  size: 31,
                  color: accent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppThemeColors.text(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color:
                            AppThemeColors.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 17,
                color: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------
  // PREMIUM TAGLINE
  // ------------------------------------------------

  Widget _buildPremiumTagline() {
    final accent = AppThemeColors.primary(context);
    final textColor = AppThemeColors.text(context);

    return FadeTransition(
      opacity: _taglineFadeAnimation,
      child: ScaleTransition(
        scale: _taglineScaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: accent.withValues(alpha: 0.24),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.08),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.45),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 9),
              Text(
                subtitleText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.35,
                ),
              ),
              const SizedBox(width: 9),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.45),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppThemeColors.primary(context);
    final bool isDark =
        widget.themeMode == ReNovaThemeMode.dark;

    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                22,
                18,
                22,
                30,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.center,
                children: [
                  // ==================================================
                  // TOP CONTROLS
                  // ==================================================

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.end,
                    children: [
                      // LANGUAGE BUTTON
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(14),
                          onTap: _showLanguageSelector,
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: AppThemeColors.card(
                                context,
                              ),
                              borderRadius:
                                  BorderRadius.circular(14),
                              border: Border.all(
                                color: accent.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.language_rounded,
                                  size: 18,
                                  color: accent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.language ==
                                          AppLanguage.english
                                      ? 'EN'
                                      : widget.language ==
                                              AppLanguage.hindi
                                          ? 'HI'
                                          : 'MR',
                                  style: TextStyle(
                                    fontWeight:
                                        FontWeight.w700,
                                    fontSize: 12,
                                    color:
                                        AppThemeColors.text(
                                      context,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // THEME SWITCH
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              AppThemeColors.card(context),
                          borderRadius:
                              BorderRadius.circular(14),
                          border: Border.all(
                            color: accent.withValues(
                              alpha: 0.12,
                            ),
                          ),
                        ),
                        child: Switch(
                          value: isDark,
                          onChanged: (value) {
                            widget.onThemeChanged(
                              value
                                  ? ReNovaThemeMode.dark
                                  : ReNovaThemeMode.light,
                            );
                          },
                          activeThumbColor: accent,
                          activeTrackColor:
                              accent.withValues(alpha: 0.30),
                          inactiveThumbColor:
                              AppThemeColors.muted(context),
                          inactiveTrackColor:
                              AppThemeColors.muted(context)
                                  .withValues(alpha: 0.18),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 34),

                  // ==================================================
                  // LOGO
                  // ==================================================

                  Image.asset(
                    isDark
                        ? 'assets/images/recy_link_logo_dark.jpeg'
                        : 'assets/images/recy_link_logo.png',
                    width: 220,
                    height: 82,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // PREMIUM TAGLINE
                  // ==================================================

                  _buildPremiumTagline(),

                  const SizedBox(height: 24),

                  // ==================================================
                  // WELCOME
                  // ==================================================

                  Text(
                    welcomeText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppThemeColors.text(context),
                    ),
                  ),

                  const SizedBox(height: 34),

                  // ==================================================
                  // ROLE TITLE
                  // ==================================================

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      chooseRoleText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppThemeColors.text(context),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ==================================================
                  // SCRAP COLLECTOR
                  // ==================================================

                  _roleCard(
                    icon: Icons.recycling_rounded,
                    title: collectorTitle,
                    description: collectorDescription,
                    onTap: () {
                      widget.onScrapCollectorSelected(
                        context,
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // RIDER
                  // ==================================================

                  _roleCard(
                    icon: Icons.delivery_dining_rounded,
                    title: riderTitle,
                    description: riderDescription,
                    onTap: () {
                      widget.onRiderSelected(
                        context,
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // BOTTOM INFO
                  // ==================================================

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.eco_outlined,
                        size: 17,
                        color: accent,
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          'Formal Recycling & Fair Price Bridge',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                AppThemeColors.muted(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
