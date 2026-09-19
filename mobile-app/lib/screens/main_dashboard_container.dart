import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_enums.dart';
import '../main.dart';
import '../services/storage_service.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import '../widgets/animated_bell_icon.dart';
import '../widgets/theme_switch_button.dart';

import 'classify_bulk_screen.dart';
import 'safety_screen.dart';
import 'settings_screen.dart';

import 'tabs/market_rates_tab.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/payment_tab.dart';
import 'tabs/pickup_tab.dart';
import 'tabs/pickup_upload_tab.dart';
import 'tabs/recy_chatbot_sheet.dart';

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

  String get pickupText {
    switch (currentLanguage) {
      case AppLanguage.english:
        return 'My Lots';
      case AppLanguage.hindi:
        return 'मेरे लॉट';
      case AppLanguage.marathi:
        return 'माझे लॉट';
    }
  }

  String get ratesText {
    switch (currentLanguage) {
      case AppLanguage.hindi:
        return 'बाजार भाव';
      case AppLanguage.marathi:
        return 'बाजार दर';
      case AppLanguage.english:
      default:
        return 'Market Rates';
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
                leading: const Icon(
                  Icons.center_focus_strong,
                  color: AppColors.primaryGold,
                ),
                title: Text(classifyScrapText),
                subtitle: const Text(
                  'Single item analysis via Camera or Gallery',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    currentIndex = 4;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.apps, color: AppColors.primaryGold),
                title: Text(classifyBulkText),
                subtitle: const Text(
                  'Record bulk scrap lot for weight & price',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClassifyBulkScreen(
                        storage: widget.storage,
                        language: currentLanguage,
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
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    final tabs = [
      DashboardTab(
        language: currentLanguage,
        storage: widget.storage,
        onNavigateTab: (index) {
          if (index == 4) {
            _showClassifyOptionsModal(context);
          } else {
            setState(() {
              currentIndex = index;
            });
          }
        },
      ),
      PickupTab(language: currentLanguage),
      MarketRatesTab(language: currentLanguage),
      PaymentTab(
        language: currentLanguage,
        paymentPreference: paymentPreference,
        onPaymentPreferenceChanged: _changePayment,
        storage: widget.storage,
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
                Icon(Icons.recycling, color: activeAccent),
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
              icon: Icon(Icons.health_and_safety_outlined, color: activeAccent),
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
              icon: Icon(Icons.settings, color: activeAccent),
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
                        await widget.storage.prefs.setString(
                          'language',
                          lang.name,
                        );
                        final appState = context
                            .findAncestorStateOfType<ReNovaAppState>();
                        if (appState != null) {
                          await appState.changeLanguage(lang);
                        }
                      },
                      onProfileUpdated:
                          (
                            newName,
                            newLoc,
                            newPay,
                            newImg,
                            newAge,
                            newOther,
                          ) async {
                            await _saveProfile(
                              newName,
                              newLoc,
                              newPay,
                              newImg,
                              newAge,
                              newOther,
                            );
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
            AnimatedBellIconButton(onPressed: _showNotifications),
            themeSwitchButton(context, widget.themeMode, widget.onThemeChanged),
          ],
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: tabs[currentIndex],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            if (index == 4) {
              // Changed from 5 to 4
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
              selectedIcon: Icon(Icons.dashboard, color: activeAccent),
              label: dashboardText,
            ),
            NavigationDestination(
              icon: const Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2, color: activeAccent),
              label: pickupText,
            ),
            // Market price
            NavigationDestination(
              icon: const Icon(Icons.trending_up_outlined),
              selectedIcon: Icon(Icons.trending_up, color: activeAccent),
              label: ratesText,
            ),
            NavigationDestination(
              icon: const Icon(Icons.account_balance_wallet),
              selectedIcon: Icon(
                Icons.account_balance_wallet,
                color: activeAccent,
              ),
              label: paymentText,
            ),
            NavigationDestination(
              icon: const Icon(Icons.auto_awesome),
              selectedIcon: Icon(Icons.auto_awesome, color: activeAccent),
              label: classifyText,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePayment(String value) async {
    setState(() {
      paymentPreference = value;
    });

    await widget.storage.prefs.setString('payment_preference', value);
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
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemeColors.card(context),
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

  Widget _notificationTile(IconData icon, String title, String subtitle) {
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: activeAccent.withValues(alpha: 0.15),
        child: Icon(icon, color: activeAccent),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppThemeColors.muted(context)),
      ),
    );
  }
}
