import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../constants/app_enums.dart';
import '../../services/auth_service.dart';
import '../../services/database_helper.dart';
import '../../services/storage_service.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_theme.dart';
import '../../widgets/theme_switch_button.dart';
import 'collector_login_screen.dart';
import 'collector_tools_screen.dart';
import 'safety_screen.dart';

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
    String name,
    String location,
    String payment,
    XFile? image,
    String age,
    String otherDetails,
  )
  onProfileUpdated;
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
        return en;
    }
  }

  // --- Real Logout Flow ---
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppThemeColors.card(context),
        title: Text(
          _t('Confirm Logout', 'लॉगआउट की पुष्टि करें', 'लॉगआउटची पुष्टी करा'),
          style: TextStyle(color: AppThemeColors.text(context)),
        ),
        content: Text(
          _t(
            'Are you sure you want to log out?',
            'क्या आप वाकई लॉगआउट करना चाहते हैं?',
            'तुम्हाला खात्री आहे की तुम्ही लॉगआउट करू इच्छिता?',
          ),
          style: TextStyle(color: AppThemeColors.muted(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t('Cancel', 'रद्द करें', 'रद्द करा')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_t('Log Out', 'लॉगआउट', 'लॉगआउट')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // 1. Clear local SQLite user queue and profile
      await DatabaseHelper.instance.clearUserDataOnLogout();

      // 2. Clear stored auth tokens/session
      if (widget.storage != null) {
        await widget.storage!.clearAuthSession();
      }

      // 3. Navigate back to login
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => CollectorLoginScreen(
              language: selectedLanguage,
              storage: widget.storage!,
              themeMode: widget.themeMode,
              onThemeChanged: widget.onThemeChanged,
            ),
          ),
          (route) => false,
        );
      }
    }
  }

  // --- Live Backend Diagnostic Info ---
  Future<void> _checkServerConnection() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    String statusText = '';
    bool isConnected = false;

    try {
      final response = await http
          .get(Uri.parse('${AuthService.baseUrl}/health'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        isConnected = true;
        statusText =
            'Backend is Online!\n'
            'Endpoint: ${AuthService.baseUrl}\n'
            'Service: ${data['service'] ?? 'FastAPI'}\n'
            'Collector ID: ${widget.storage?.collectorId ?? 'N/A'}';
      } else {
        statusText =
            'Server responded with status code: ${response.statusCode}';
      }
    } catch (e) {
      statusText =
          'Unable to reach backend at ${AuthService.baseUrl}.\n\n'
          'Details: $e\n\n'
          'Did you run `adb reverse tcp:8000 tcp:8000`?';
    }

    if (!mounted) return;
    Navigator.pop(context); // close loader

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppThemeColors.card(context),
        title: Row(
          children: [
            Icon(
              isConnected ? Icons.check_circle : Icons.error_outline,
              color: isConnected ? Colors.green : Colors.redAccent,
            ),
            const SizedBox(width: 8),
            Text(
              isConnected ? 'Connected' : 'Connection Failed',
              style: TextStyle(color: AppThemeColors.text(context)),
            ),
          ],
        ),
        content: Text(
          statusText,
          style: TextStyle(color: AppThemeColors.muted(context), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('Close', 'बंद करें', 'बंद करा')),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: widget.collectorName);
    final locationController = TextEditingController(text: widget.location);
    final ageController = TextEditingController(
      text: widget.storage?.age ?? '',
    );
    final otherController = TextEditingController(
      text: widget.storage?.otherDetails ?? '',
    );
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
                _t(
                  'Edit Profile',
                  'प्रोफ़ाइल संपादित करें',
                  'प्रोफाइल संपादित करा',
                ),
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
                      initialValue: currentPayment,
                      items: ['Cash', 'UPI / Digital Wallet']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => currentPayment = val);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: _t(
                          'Payment Preference',
                          'भुगतान पसंद',
                          'पेमेंट पसंती',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: otherController,
                      decoration: InputDecoration(
                        labelText: _t(
                          'Other Details',
                          'अन्य विवरण',
                          'इतर तपशील',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeAccent,
                      ),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final img = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (img != null) {
                          setDialogState(() => pickedFile = img);
                        }
                      },
                      icon: const Icon(
                        Icons.photo_library,
                        color: AppColors.darkBackground,
                      ),
                      label: Text(
                        pickedFile == null
                            ? _t(
                                'Change Profile Picture',
                                'प्रोफ़ाइल चित्र बदलें',
                                'प्रोफाइल फोटो बदला',
                              )
                            : _t(
                                'Image Selected',
                                'चित्र चुना गया',
                                'फोटो निवडला',
                              ),
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
    final hasValidImage =
        widget.profileImagePath != null &&
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
                      ? const Icon(
                          Icons.person,
                          size: 50,
                          color: AppColors.darkBackground,
                        )
                      : null,
                ),
                const SizedBox(height: 14),
                Text(
                  widget.collectorName.isEmpty
                      ? _t('User', 'उपयोगकर्ता', 'वापरकर्ता')
                      : widget.collectorName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppThemeColors.text(context),
                  ),
                ),
                const SizedBox(height: 16),
                _detailRow(
                  Icons.badge,
                  _t('Collector ID', 'कलेक्टर आईडी', 'कलेक्टर आयडी'),
                  widget.storage?.collectorId ?? 'RN-COL-2026-01428',
                ),
                _detailRow(
                  Icons.location_on,
                  _t('Location', 'स्थान', 'स्थान'),
                  widget.location.isEmpty
                      ? _t('Not specified', 'निर्दिष्ट नहीं', 'नमूद नाही')
                      : widget.location,
                ),
                _detailRow(
                  Icons.payments,
                  _t('Payment', 'भुगतान', 'पेमेंट'),
                  widget.paymentPreference,
                ),
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
                      _t(
                        'Edit Profile',
                        'प्रोफ़ाइल संपादित करें',
                        'प्रोफाइल संपादित करा',
                      ),
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
      title: Text(
        label,
        style: TextStyle(color: AppThemeColors.muted(context), fontSize: 12),
      ),
      subtitle: Text(
        value,
        style: TextStyle(color: AppThemeColors.text(context), fontSize: 15),
      ),
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

  @override
  Widget build(BuildContext context) {
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

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
          const SizedBox(height: 20),

          Text(
            _t(
              'Account & Preferences',
              'खाता और प्राथमिकताएं',
              'खाते आणि प्राधान्ये',
            ),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.text(context),
            ),
          ),
          const SizedBox(height: 12),

          _settingsButton(
            Icons.person_outline,
            _t('Profile', 'प्रोफ़ाइल', 'प्रोफाइल'),
            _t(
              'View account details and edit your profile',
              'खाते का विवरण देखें और प्रोफ़ाइल संपादित करें',
              'खाते तपशील पहा आणि प्रोफाइल संपादित करा',
            ),
            _showProfileDetails,
          ),
          _settingsButton(
            Icons.language,
            _t('App Language', 'ऐप की भाषा', 'अ‍ॅपची भाषा'),
            _t(
              'Change app text and safety audio language',
              'ऐप का टेक्स्ट और सुरक्षा ऑडियो भाषा बदलें',
              'अ‍ॅपचा मजकूर आणि सुरक्षा ऑडिओ भाषा बदला',
            ),
            _showLanguagePicker,
          ),
          _settingsButton(
            Icons.build_circle_outlined,
            _t('Collector Tools', 'कलेक्टर टूल्स', 'कलेक्टर टूल्स'),
            _t(
              'Weekly price board and recyclers nearby',
              'साप्ताहिक मूल्य बोर्ड और पास के रीसायकलर',
              'साप्ताहिक किंमत बोर्ड आणि जवळचे रीसायकलर',
            ),
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CollectorToolsScreen(language: selectedLanguage),
              ),
            ),
          ),
          _settingsButton(
            Icons.help_outline,
            _t(
              'Safety Guidelines',
              'सुरक्षा दिशानिर्देश',
              'सुरक्षा मार्गदर्शक तत्त्वे',
            ),
            _t(
              'Handling e-waste safely in the field',
              'मैदान में ई-कचरे का सुरक्षित निपटान',
              'क्षेत्रात ई-कचरा सुरक्षितपणे हाताळणे',
            ),
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SafetyTab(language: selectedLanguage),
              ),
            ),
          ),

          const SizedBox(height: 20),
          Text(
            _t(
              'Developer & Diagnostics',
              'डेवलपर और डायग्नोस्टिक्स',
              'डेव्हलपर आणि निदान',
            ),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.text(context),
            ),
          ),
          const SizedBox(height: 12),

          _settingsButton(
            Icons.network_check,
            _t(
              'Server Connection Test',
              'सर्वर कनेक्शन जांच',
              'सर्व्हर कनेक्शन चाचणी',
            ),
            _t(
              'Verify status of FastAPI backend at ${AuthService.baseUrl}',
              'FastAPI बैकएंड स्थिति की जाँच करें',
              'FastAPI बॅकएंड स्थिती तपासा',
            ),
            _checkServerConnection,
          ),
          _settingsButton(
            Icons.restart_alt,
            _t(
              'Reseed Local Database',
              'स्थानीय डेटाबेस रीसीड करें',
              'स्थानिक डेटाबेस रीसीड करा',
            ),
            _t(
              'Reload benchmark rates into SQLite',
              'SQLite में बेंचमार्क दरें फिर से लोड करें',
              'SQLite मध्ये बेंचमार्क दर पुन्हा लोड करा',
            ),
            () async {
              await DatabaseHelper.instance.clearAndReseedPrices();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Local SQLite benchmarks reseeded successfully!',
                    ),
                  ),
                );
              }
            },
          ),

          const SizedBox(height: 24),

          // --- The Logout Button ---
          Container(
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.3),
              ),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.redAccent,
                child: Icon(Icons.logout, color: Colors.white),
              ),
              title: Text(
                _t('Log Out', 'लॉगआउट करें', 'लॉगआउट करा'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              subtitle: Text(
                _t(
                  'End collector session and return to login',
                  'सत्र समाप्त करें और लॉगिन पर लौटें',
                  'सत्र समाप्त करा आणि लॉगिनवर परत या',
                ),
                style: TextStyle(
                  color: AppThemeColors.muted(context),
                  fontSize: 12,
                ),
              ),
              onTap: _handleLogout,
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _profileQuickBar() {
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    final hasValidImage =
        widget.profileImagePath != null &&
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
            tooltip: _t(
              'Edit Profile',
              'प्रोफ़ाइल संपादित करें',
              'प्रोफाइल संपादित करा',
            ),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        trailing: Icon(
          Icons.chevron_right,
          color: AppThemeColors.faint(context),
        ),
        onTap: onTap,
      ),
    );
  }
}
