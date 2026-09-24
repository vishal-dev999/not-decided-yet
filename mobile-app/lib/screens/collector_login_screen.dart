import 'package:flutter/material.dart';

import '../constants/app_enums.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import 'main_dashboard_container.dart';

class CollectorLoginScreen extends StatefulWidget {
  final AppLanguage language;
  final ReNovaStorage storage;
  final ReNovaThemeMode themeMode;
  final ValueChanged<ReNovaThemeMode> onThemeChanged;

  const CollectorLoginScreen({
    super.key,
    required this.language,
    required this.storage,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<CollectorLoginScreen> createState() => _CollectorLoginScreenState();
}

class _CollectorLoginScreenState extends State<CollectorLoginScreen> {
  final _phoneController = TextEditingController(text: '9876543210');
  final _pinController = TextEditingController(text: '1234');
  final _nameController = TextEditingController();
  final _cityController = TextEditingController(text: 'Bhubaneswar');

  bool _isRegistering = false;
  bool _isLoading = false;
  String? _errorMessage;

  String _t(String en, String hi, String mr) {
    switch (widget.language) {
      case AppLanguage.hindi:
        return hi;
      case AppLanguage.marathi:
        return mr;
      case AppLanguage.english:
        return en;
    }
  }

  // --- Backend Environment Selector Dialog ---
  void _showBackendConfigDialog(BuildContext context) {
    final TextEditingController urlController = TextEditingController(
      text: AuthService.getBaseUrl(widget.storage),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppThemeColors.card(context),
        title: Text(
          _t(
            'Configure Backend URL',
            'बैकएंड यूआरएल कॉन्फ़िगर करें',
            'बॅकएंड URL कॉन्फिगर करा',
          ),
          style: TextStyle(color: AppThemeColors.text(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _t(
                'Enter Ngrok URL or select a preset for local testing:',
                'स्थानीय परीक्षण के लिए Ngrok यूआरएल दर्ज करें या प्रीसेट चुनें:',
                'स्थानिक चाचणीसाठी Ngrok URL प्रविष्ट करा किंवा प्रीसेट निवडा:',
              ),
              style: TextStyle(
                color: AppThemeColors.muted(context),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'https://xxxx.ngrok-free.app or http://10.0.2.2:8000',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('Localhost'),
                  onPressed: () => urlController.text = 'http://localhost:8000',
                ),
                ActionChip(
                  label: const Text('Android Emulator'),
                  onPressed: () => urlController.text = 'http://10.0.2.2:8000',
                ),
                ActionChip(
                  label: const Text('Ngrok Tunnel'),
                  onPressed: () => urlController.text =
                      'https://your-ngrok-url.ngrok-free.app',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_t('Cancel', 'रद्द करें', 'रद्द करा')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.featherGreen,
            ),
            onPressed: () async {
              await widget.storage.setCustomBaseUrl(urlController.text.trim());
              Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.featherGreen,
                    content: Text(
                      _t(
                        'Backend URL updated successfully!',
                        'बैकएंड यूआरएल सफलतापूर्वक अपडेट किया गया!',
                        'बॅकएंड URL यशस्वीरित्या अद्यतन केले!',
                      ),
                    ),
                  ),
                );
              }
            },
            child: Text(
              _t('Save', 'सहेजें', 'जतन करा'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();
    final name = _nameController.text.trim();
    final city = _cityController.text.trim();

    if (phone.length != 10 || pin.length != 4) {
      setState(() {
        _errorMessage = _t(
          'Enter 10-digit phone & 4-digit PIN',
          '10 अंकों का फोन और 4 अंकों का पिन दर्ज करें',
          '10 अंकी फोन आणि 4 अंकी पिन टाका',
        );
      });
      return;
    }

    if (_isRegistering && name.isEmpty) {
      setState(() {
        _errorMessage = _t(
          'Please enter your full name',
          'कृपया अपना पूरा नाम दर्ज करें',
          'कृपया तुमचे पूर्ण नाव टाका',
        );
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = _isRegistering
        ? await AuthService.registerCollector(
            phone: phone,
            pin: pin,
            fullName: name,
            language: widget.language == AppLanguage.hindi
                ? 'hi'
                : widget.language == AppLanguage.marathi
                ? 'mr'
                : 'en',
            city: city.isEmpty ? 'Bhubaneswar' : city, // 👈 Dynamically passed!
            storage: widget.storage,
          )
        : await AuthService.loginCollector(
            phone: phone,
            pin: pin,
            storage: widget.storage,
          );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainDashboardContainer(
            collectorName:
                widget.storage.collectorName ??
                (_isRegistering ? name : 'Collector'),
            location:
                widget.storage.location ??
                (city.isEmpty ? 'Bhubaneswar' : city),
            language: widget.language,
            themeMode: widget.themeMode,
            onThemeChanged: widget.onThemeChanged,
            storage: widget.storage,
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = res['message'] as String? ?? 'Authentication failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Collector Login', 'कलेक्टर लॉगिन', 'कलेक्टर लॉगिन')),
        actions: [
          IconButton(
            tooltip: _t(
              'Configure Backend URL',
              'बैकएंड यूआरएल कॉन्फ़िगर करें',
              'बॅकएंड URL कॉन्फिगर करा',
            ),
            icon: const Icon(Icons.settings_ethernet),
            onPressed: () => _showBackendConfigDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              CircleAvatar(
                radius: 32,
                backgroundColor: activeAccent.withValues(alpha: 0.15),
                child: Icon(Icons.recycling, size: 36, color: activeAccent),
              ),
              const SizedBox(height: 20),
              Text(
                _isRegistering
                    ? _t(
                        'Create Account',
                        'नया खाता बनाएं',
                        'नवीन खाते तयार करा',
                      )
                    : _t(
                        'Collector Sign-In',
                        'कबाड़ीवाला प्रवेश',
                        'कबाडीवाला लॉगिन',
                      ),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppThemeColors.text(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isRegistering
                    ? _t(
                        'Register as a certified scrap collector',
                        'प्रमाणित कबाड़ संग्राहक के रूप में पंजीकरण करें',
                        'प्रमाणित भंगार संकलक म्हणून नोंदणी करा',
                      )
                    : _t(
                        'Enter registered phone and 4-digit PIN',
                        'पंजीकृत फोन नंबर और 4 अंकों का पिन दर्ज करें',
                        'नोंदणीकृत फोन आणि 4 अंकी पिन टाका',
                      ),
                style: TextStyle(
                  fontSize: 13,
                  color: AppThemeColors.muted(context),
                ),
              ),
              const SizedBox(height: 28),

              // Name Field (Only on Register)
              if (_isRegistering) ...[
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: _t('Full Name', 'पूरा नाम', 'पूर्ण नाव'),
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: _t(
                      'City / Mandi Area',
                      'शहर / मंडी क्षेत्र',
                      'शहर / बाजार परिसर',
                    ),
                    prefixIcon: const Icon(Icons.location_city_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Phone Field
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: _t('Phone Number', 'फ़ोन नंबर', 'फोन नंबर'),
                  prefixText: '+91 ',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4-Digit PIN Field
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: _t('4-Digit PIN', '4-अंकीय पिन', '4-अंकी पिन'),
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeAccent,
                    foregroundColor: AppColors.darkBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleSubmit,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          _isRegistering
                              ? _t(
                                  'Register & Start',
                                  'पंजीकरण करें और शुरू करें',
                                  'नोंदणी करा आणि सुरू करा',
                                )
                              : _t(
                                  'Login to Dashboard',
                                  'डैशबोर्ड में प्रवेश करें',
                                  'डॅशबोर्डवर जा',
                                ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),
              // Toggle Login <-> Register
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isRegistering = !_isRegistering;
                      _errorMessage = null;
                      if (_isRegistering) {
                        _phoneController.clear();
                        _pinController.clear();
                      } else {
                        _phoneController.text = '9876543210';
                        _pinController.text = '1234';
                      }
                    });
                  },
                  child: Text(
                    _isRegistering
                        ? _t(
                            'Already registered? Login here',
                            'पहले से पंजीकृत हैं? यहाँ लॉगिन करें',
                            'आधीच नोंदणी केली आहे? येथे लॉगिन करा',
                          )
                        : _t(
                            'New Collector? Create Account',
                            'नया कबाड़ी? खाता बनाएं',
                            'नवीन कबाडी? खाते तयार करा',
                          ),
                    style: TextStyle(
                      color: activeAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              if (!_isRegistering) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.flash_on, size: 16),
                    label: const Text('Fill Demo Collector (Ramesh Sahu)'),
                    onPressed: () {
                      _phoneController.text = '9876543210';
                      _pinController.text = '1234';
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
