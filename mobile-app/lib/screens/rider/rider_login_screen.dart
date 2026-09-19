import 'package:flutter/material.dart';

import '../../constants/app_enums.dart';
import '../../services/storage_service.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_theme.dart';
import 'rider_dashboard_screen.dart';

class RiderLoginScreen extends StatefulWidget {
  final AppLanguage language;
  final ReNovaThemeMode themeMode;
  final Future<void> Function(ReNovaThemeMode) onThemeChanged;
  final ReNovaStorage storage;

  const RiderLoginScreen({
    super.key,
    required this.language,
    required this.themeMode,
    required this.onThemeChanged,
    required this.storage,
  });

  @override
  State<RiderLoginScreen> createState() => _RiderLoginScreenState();
}

class _RiderLoginScreenState extends State<RiderLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _text(
    String english,
    String hindi,
    String marathi,
  ) {
    switch (widget.language) {
      case AppLanguage.hindi:
        return hindi;
      case AppLanguage.marathi:
        return marathi;
      case AppLanguage.english:
        return english;
    }
  }

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Please enter your mobile number and password.',
              'कृपया अपना मोबाइल नंबर और पासवर्ड दर्ज करें।',
              'कृपया तुमचा मोबाईल नंबर आणि पासवर्ड टाका.',
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Rider authentication can be connected to the backend here.
    // For now, this opens the Rider dashboard after validation.
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RiderDashboardScreen(
          language: widget.language,
          themeMode: widget.themeMode,
          onThemeChanged: widget.onThemeChanged,
          storage: widget.storage,
          riderName: 'Rider',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeMode == ReNovaThemeMode.dark;

    final backgroundColor = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;

    final cardColor = isDark
        ? AppColors.cardBg
        : AppColors.lightCard;

    final primaryColor = isDark
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    final textColor = isDark
        ? Colors.white
        : AppColors.lightText;

    final secondaryTextColor = isDark
        ? Colors.white70
        : AppColors.lightText.withValues(alpha: 0.65);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ------------------------------------------------
              // TOP BRANDING
              // ------------------------------------------------

              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.local_shipping_rounded,
                      color: primaryColor,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ReNova',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 54),

              // ------------------------------------------------
              // HEADER
              // ------------------------------------------------

              Text(
                _text(
                  'Rider Login',
                  'राइडर लॉगिन',
                  'राइडर लॉगिन',
                ),
                style: TextStyle(
                  color: textColor,
                  fontSize: 31,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                _text(
                  'Sign in to view your assigned e-waste pickups.',
                  'अपने निर्धारित ई-वेस्ट पिकअप देखने के लिए लॉगिन करें।',
                  'तुम्हाला दिलेले ई-वेस्ट पिकअप पाहण्यासाठी लॉगिन करा.',
                ),
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 34),

              // ------------------------------------------------
              // LOGIN CARD
              // ------------------------------------------------

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.18 : 0.06,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text(
                        'Account',
                        'खाता',
                        'खाते',
                      ),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Mobile number
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: _text(
                          'Mobile number',
                          'मोबाइल नंबर',
                          'मोबाईल नंबर',
                        ),
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                          color: primaryColor,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.045)
                            : Colors.black.withValues(alpha: 0.025),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Password
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: _text(
                          'Password',
                          'पासवर्ड',
                          'पासवर्ड',
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline_rounded,
                          color: primaryColor,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: secondaryTextColor,
                          ),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.045)
                            : Colors.black.withValues(alpha: 0.025),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: isDark
                              ? Colors.black
                              : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: isDark
                                      ? Colors.black
                                      : Colors.white,
                                ),
                              )
                            : Text(
                                _text(
                                  'Login',
                                  'लॉगिन',
                                  'लॉगिन',
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ------------------------------------------------
              // ROLE INFORMATION
              // ------------------------------------------------

              Center(
                child: Text(
                  _text(
                    'Rider account provided by your recycler company',
                    'राइडर अकाउंट आपकी रीसायक्लर कंपनी द्वारा प्रदान किया गया है',
                    'राइडर अकाउंट तुमच्या रीसायक्लर कंपनीने दिलेले आहे',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
