import 'package:flutter/material.dart';

import '../constants/app_text.dart';
import 'home_page.dart'; // Needed for Navigator.pushReplacement -> HomePage
import '../services/location_service.dart';
import '../services/database_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController nameController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF092B2A),
              Color(0xFF124E4A),
              Color(0xFF176B5B),
              Color(0xFFB9877E),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -80,
                right: -60,
                child: _circle(230, Colors.white.withValues(alpha: 0.07)),
              ),
              Positioned(
                bottom: -100,
                left: -70,
                child: _circle(260, Colors.white.withOpacity(0.06)),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // LOGO
                      Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.recycling_rounded,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'ReNova',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        AppText.get('welcome'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // LOGIN CARD
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.96),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppText.get('enter_name'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF174A43),
                              ),
                            ),

                            const SizedBox(height: 10),

                            TextField(
                              controller: nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                hintText: 'Your name',
                                prefixIcon: const Icon(Icons.person_outline),
                                filled: true,
                                fillColor: const Color(0xFFF2F7F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(17),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            Text(
                              AppText.get('choose_language'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF174A43),
                              ),
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                _languageButton('English', AppLanguage.english),
                                const SizedBox(width: 7),
                                _languageButton('हिन्दी', AppLanguage.hindi),
                                const SizedBox(width: 7),
                                _languageButton('मराठी', AppLanguage.marathi),
                              ],
                            ),

                            const SizedBox(height: 26),

                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _continue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF176B5B),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(17),
                                  ),
                                ),
                                child: Text(
                                  AppText.get('continue'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Recycle • Earn • Renew',
                        style: TextStyle(
                          color: Colors.white70,
                          letterSpacing: 1,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _continue() async {
    final String enteredName = nameController.text.trim();

    if (enteredName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }

    // 1. Show loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // 2. Fetch current GPS position
      final position = await LocationService.determinePosition();

      // 3. Save profile & coordinates to SQLite
      await DatabaseHelper.instance.saveUserProfile(
        name: enteredName,
        language: selectedLanguage.name,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );

      // 4. Navigate to HomePage if still on this screen
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage(userName: enteredName)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _languageButton(String text, AppLanguage language) {
    final bool selected = selectedLanguage == language;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedLanguage = language;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF176B5B) : const Color(0xFFEAF2EF),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : const Color(0xFF176B5B),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
