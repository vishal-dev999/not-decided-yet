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
import 'recycler_nearby.dart';

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
  State<MainDashboardContainer> createState() =>
      _MainDashboardContainerState();
}

class _MainDashboardContainerState
    extends State<MainDashboardContainer>
    with SingleTickerProviderStateMixin {
  late AppLanguage currentLanguage;
  late String collectorName;
  late String location;

  // 0 = Market Rates
  // 1 = My Lots
  // 2 = Payment
  // 3 = Recyclers
  // 4 = Classify
  int currentIndex = 0;

  // Dashboard is now the Home screen.
  bool isHome = true;

  String paymentPreference = 'Cash';
  String? profileImagePath;
  String? uploadedPickupPath;

  // -----------------------------------------------------------
  // HOME / MENU ANIMATION
  // -----------------------------------------------------------
  late AnimationController _homeMenuAnimationController;
  late Animation<double> _homeMenuScale;
  late Animation<double> _homeMenuRotation;

  @override
  void initState() {
    super.initState();

    currentLanguage = widget.language;
    collectorName = widget.collectorName;
    location = widget.location;

    paymentPreference =
        widget.storage.paymentPreference ?? 'Cash';

    profileImagePath =
        widget.storage.profileImagePath;

    uploadedPickupPath =
        widget.storage.pickupImagePath;

    // ---------------------------------------------------------
    // Three-line menu animation.
    //
    // This gives the hamburger button a quick scale + rotation
    // animation whenever Home is opened.
    // ---------------------------------------------------------
    _homeMenuAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _homeMenuScale = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(
      CurvedAnimation(
        parent: _homeMenuAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _homeMenuRotation = Tween<double>(
      begin: 0.0,
      end: 0.04,
    ).animate(
      CurvedAnimation(
        parent: _homeMenuAnimationController,
        curve: Curves.easeOut,
      ),
    );

    // Animate the Home/menu button when the dashboard starts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animateHomeMenu();
      }
    });
  }

  @override
  void dispose() {
    _homeMenuAnimationController.dispose();
    super.dispose();
  }

  Future<void> _animateHomeMenu() async {
    if (!mounted) return;

    await _homeMenuAnimationController.forward();

    if (!mounted) return;

    await _homeMenuAnimationController.reverse();
  }

  // -----------------------------------------------------------
  // HOME
  // -----------------------------------------------------------
  String get homeText {
    switch (currentLanguage) {
      case AppLanguage.english:
        return 'Home';
      case AppLanguage.hindi:
        return 'होम';
      case AppLanguage.marathi:
        return 'होम';
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

  String get recyclerNearbyText {
    switch (currentLanguage) {
      case AppLanguage.english:
        return 'Recyclers';
      case AppLanguage.hindi:
        return 'Recyclers';
      case AppLanguage.marathi:
        return 'Recyclers';
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

  // -----------------------------------------------------------
  // CLASSIFY MODAL
  // -----------------------------------------------------------
  void _showClassifyOptionsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemeColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
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
                    isHome = false;
                    currentIndex = 4;
                  });
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.apps,
                  color: AppColors.primaryGold,
                ),
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
                        isHome = true;
                      });

                      _animateHomeMenu();
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

  // -----------------------------------------------------------
  // MARKET RATES
  // -----------------------------------------------------------
  void _openMarketRates() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MarketRatesTab(
          language: currentLanguage,
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // GO HOME
  // -----------------------------------------------------------
  void _goHome() {
    setState(() {
      isHome = true;
    });

    // Quick hamburger/menu highlight animation.
    _animateHomeMenu();
  }

  @override
  Widget build(BuildContext context) {
    final activeAccent =
        AppThemeColors.isDark(context)
            ? AppColors.primaryGold
            : AppColors.featherGreen;

    // -------------------------------------------------------
    // HOME / DASHBOARD
    // -------------------------------------------------------
    final dashboard = DashboardTab(
      language: currentLanguage,
      storage: widget.storage,
      onNavigateTab: (index) {
        if (index == 4) {
          _showClassifyOptionsModal(context);
        } else if (index == 0) {
          // Rates shortcut on Home continues to open
          // the complete Market Rates page.
          _openMarketRates();
        } else {
          setState(() {
            isHome = false;
            currentIndex = index;
          });
        }
      },
    );

    // -------------------------------------------------------
    // BOTTOM NAVIGATION TABS
    // -------------------------------------------------------
    final tabs = [
      MarketRatesTab(
        language: currentLanguage,
      ),

      PickupTab(
        language: currentLanguage,
      ),

      PaymentTab(
        language: currentLanguage,
        paymentPreference: paymentPreference,
        onPaymentPreferenceChanged: _changePayment,
        storage: widget.storage,
      ),

      RecyclerNearbyScreen(
        language: currentLanguage,
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
      // -------------------------------------------------------
      // BACK BUTTON BEHAVIOR
      // -------------------------------------------------------
      //
      // If already on Home:
      //     normal system back behavior.
      //
      // If inside any taskbar tab:
      //     Back -> Home/Dashboard.
      // -------------------------------------------------------
      canPop: isHome,
      onPopInvoked: (didPop) {
        if (!didPop && !isHome) {
          setState(() {
            isHome = true;
          });

          // Animate hamburger when returning Home.
          _animateHomeMenu();
        }
      },

      child: Scaffold(
        appBar: AppBar(

          // ---------------------------------------------------
          // TOP-LEFT THREE-LINE HOME BUTTON
          // ---------------------------------------------------
          leading: AnimatedBuilder(
            animation: _homeMenuAnimationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _homeMenuScale.value,
                child: Transform.rotate(
                  angle: _homeMenuRotation.value,
                  child: child,
                ),
              );
            },
            child: IconButton(
              tooltip: 'Home',
              icon: Icon(
                Icons.menu,
                color: activeAccent,
                size: 28,
              ),
              onPressed: _goHome,
            ),
          ),

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
                    builder: (_) => SafetyTab(
                      language: currentLanguage,
                    ),
                  ),
                ).then((_) {
                  if (mounted) {
                    setState(() {
                      isHome = true;
                    });

                    _animateHomeMenu();
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
                      onThemeChanged:
                          widget.onThemeChanged,
                      storage: widget.storage,
                      onLanguageChanged:
                          (lang) async {
                        setState(() {
                          currentLanguage = lang;
                        });

                        await widget.storage.prefs
                            .setString(
                          'language',
                          lang.name,
                        );

                        final appState = context
                            .findAncestorStateOfType<
                                ReNovaAppState>();

                        if (appState != null) {
                          await appState.changeLanguage(
                            lang,
                          );
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
                      isHome = true;
                    });

                    _animateHomeMenu();
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

        // -------------------------------------------------------
        // BODY
        // -------------------------------------------------------
        body: AnimatedSwitcher(
          duration: const Duration(
            milliseconds: 300,
          ),
          child: isHome
              ? dashboard
              : tabs[currentIndex],
        ),

        // -------------------------------------------------------
        // BOTTOM TASKBAR
        // -------------------------------------------------------
        //
        // Market Rates | My Lots | Payment | Recyclers | Classify
        //
        // IMPORTANT:
        // On Home, NO taskbar item is visually highlighted.
        // -------------------------------------------------------
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 72,

            labelTextStyle:
                WidgetStateProperty.resolveWith<TextStyle>(
              (states) {
                final selected =
                    states.contains(
                  WidgetState.selected,
                );

                // When on Home, suppress selected styling.
                final shouldHighlight =
                    !isHome && selected;

                return TextStyle(
                  fontSize: 11,
                  fontWeight: shouldHighlight
                      ? FontWeight.w700
                      : FontWeight.w500,
                  height: 1.0,
                );
              },
            ),

            iconTheme:
                WidgetStateProperty.resolveWith<IconThemeData>(
              (states) {
                final selected =
                    states.contains(
                  WidgetState.selected,
                );

                // When on Home, suppress selected styling.
                final shouldHighlight =
                    !isHome && selected;

                return IconThemeData(
                  size: shouldHighlight ? 22 : 21,
                  color: shouldHighlight
                      ? activeAccent
                      : AppThemeColors.muted(
                          context,
                        ),
                );
              },
            ),
          ),

          child: NavigationBar(
            height: 72,

            // Flutter's NavigationBar requires a selectedIndex.
            // We use 0 internally on Home, but the theme above
            // prevents Market Rates from visually appearing
            // selected while Home is active.
            selectedIndex: isHome ? 0 : currentIndex,

            onDestinationSelected: (index) {
              // -------------------------------------------------
              // MARKET RATES
              // -------------------------------------------------
              if (index == 0) {
                setState(() {
                  isHome = false;
                  currentIndex = 0;
                });
              }

              // -------------------------------------------------
              // MY LOTS
              // -------------------------------------------------
              else if (index == 1) {
                setState(() {
                  isHome = false;
                  currentIndex = 1;
                });
              }

              // -------------------------------------------------
              // PAYMENT
              // -------------------------------------------------
              else if (index == 2) {
                setState(() {
                  isHome = false;
                  currentIndex = 2;
                });
              }

              // -------------------------------------------------
              // RECYCLERS
              // -------------------------------------------------
              else if (index == 3) {
                setState(() {
                  isHome = false;
                  currentIndex = 3;
                });
              }

              // -------------------------------------------------
              // CLASSIFY
              // -------------------------------------------------
              else if (index == 4) {
                _showClassifyOptionsModal(context);
              }
            },

            destinations: [
              // ------------------------------------------------
              // MARKET RATES
              // ------------------------------------------------
              NavigationDestination(
                icon: const Icon(
                  Icons.trending_up_outlined,
                ),
                selectedIcon: const Icon(
                  Icons.trending_up,
                ),
                label: ratesText,
              ),

              // ------------------------------------------------
              // MY LOTS
              // ------------------------------------------------
              NavigationDestination(
                icon: const Icon(
                  Icons.inventory_2_outlined,
                ),
                selectedIcon: const Icon(
                  Icons.inventory_2,
                ),
                label: pickupText,
              ),

              // ------------------------------------------------
              // PAYMENT
              // ------------------------------------------------
              NavigationDestination(
                icon: const Icon(
                  Icons.account_balance_wallet_outlined,
                ),
                selectedIcon: const Icon(
                  Icons.account_balance_wallet,
                ),
                label: paymentText,
              ),

              // ------------------------------------------------
              // RECYCLERS
              // ------------------------------------------------
              NavigationDestination(
                icon: const Icon(
                  Icons.recycling_outlined,
                ),
                selectedIcon: const Icon(
                  Icons.recycling,
                ),
                label: recyclerNearbyText,
              ),

              // ------------------------------------------------
              // CLASSIFY
              // ------------------------------------------------
              NavigationDestination(
                icon: const Icon(
                  Icons.auto_awesome_outlined,
                ),
                selectedIcon: const Icon(
                  Icons.auto_awesome,
                ),
                label: classifyText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changePayment(String value) async {
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
      imagePath =
          await widget.storage.saveImagePermanently(
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
      location: location,
      age: age,
      otherDetails: otherDetails,
      language: currentLanguage.name,
      paymentPreference: newPayment,
      profileImagePath: imagePath,
    );
  }

  void _showNotifications() {
    final activeAccent =
        AppThemeColors.isDark(context)
            ? AppColors.primaryGold
            : AppColors.featherGreen;

    showModalBottomSheet(
      context: context,
      backgroundColor:
          AppThemeColors.card(context),
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
    final activeAccent =
        AppThemeColors.isDark(context)
            ? AppColors.primaryGold
            : AppColors.featherGreen;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            activeAccent.withValues(alpha: 0.15),
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
          color: AppThemeColors.muted(context),
        ),
      ),
    );
  }
}
