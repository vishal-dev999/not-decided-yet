import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_enums.dart';
import '../main.dart';
import '../services/storage_service.dart';
import '../themes/app_theme.dart';
import '../widgets/animated_bell_icon.dart';

import 'classify_bulk_screen.dart';
import 'safety_screen.dart';
import 'settings_screen.dart';
import 'recycler_nearby.dart';

import 'tabs/market_rates_tab.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/payment_tab.dart';
import 'tabs/inventory_tab.dart';
import 'tabs/item_scanner_tab.dart';

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

  int currentIndex = 0;
  bool isHome = true;

  String paymentPreference = 'Cash';
  String? profileImagePath;
  String? uploadedPickupPath;

  late AnimationController _homeMenuAnimationController;
  late Animation<double> _homeMenuScale;
  late Animation<double> _homeMenuRotation;

  @override
  void initState() {
    super.initState();

    currentLanguage = widget.language;
    collectorName = widget.collectorName;
    location = widget.location;

    paymentPreference = widget.storage.paymentPreference ?? 'Cash';

    profileImagePath = widget.storage.profileImagePath;

    uploadedPickupPath = widget.storage.pickupImagePath;

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
                leading: Icon(
                  Icons.center_focus_strong,
                  color: AppThemeColors.primary(context),
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

  void _goHome() {
    setState(() {
      isHome = true;
    });

    _animateHomeMenu();
  }

  void _selectBottomTab(int index) {
    if (index == 4) {
      _showClassifyOptionsModal(context);
      return;
    }

    setState(() {
      isHome = false;
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeAccent = AppThemeColors.primary(context);

    final dashboard = DashboardTab(
      language: currentLanguage,
      storage: widget.storage,
      onNavigateTab: (index) {
        if (index == 4) {
          _showClassifyOptionsModal(context);
        } else {
          setState(() {
            isHome = false;
            currentIndex = index;
          });
        }
      },
    );

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

    final bool homeIsHighlighted = isHome;

    return PopScope(
      canPop: isHome,
      onPopInvoked: (didPop) {
        if (!didPop && !isHome) {
          setState(() {
            isHome = true;
          });

          _animateHomeMenu();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor:
              Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,

          // Small Home button instead of hamburger menu.
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
            child: Container(
              margin: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: homeIsHighlighted
                    ? activeAccent.withValues(alpha: 0.15)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                tooltip: homeText,
                icon: Icon(
                  Icons.home_outlined,
                  color: activeAccent,
                  size: homeIsHighlighted ? 28 : 26,
                ),
                onPressed: _goHome,
              ),
            ),
          ),

          // Larger RecyLink logo and name.
          title: Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Image.asset(
              widget.themeMode == ReNovaThemeMode.dark
                  ? 'assets/images/recy_link_logo_dark.jpeg'
                  : 'assets/images/recy_link_logo.png',
              width: 185,
              height: 62,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
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
                      onProfileUpdated: (
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
          ],
        ),

        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isHome
              ? dashboard
              : tabs[currentIndex],
        ),

        // ------------------------------------------------------------
        // RIDER DASHBOARD STYLE BOTTOM TASKBAR
        // ------------------------------------------------------------
        bottomNavigationBar: _buildBottomNavigationBar(
          AppThemeColors.card(context),
          activeAccent,
          Theme.of(context).textTheme.bodyLarge?.color ??
              Colors.black,
          AppThemeColors.muted(context),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // BOTTOM NAVIGATION BAR
  // Same visual design/proportions as Rider Dashboard.
  // Existing 5 Main Dashboard destinations are preserved.
  // ------------------------------------------------------------------
  Widget _buildBottomNavigationBar(
    Color cardColor,
    Color primaryColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          12,
          0,
          12,
          10,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.07,
              ),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            _bottomNavItem(
              index: 0,
              icon: Icons.trending_up_outlined,
              activeIcon: Icons.trending_up,
              label: ratesText,
              primaryColor: primaryColor,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            _bottomNavItem(
              index: 1,
              icon: Icons.inventory_2_outlined,
              activeIcon: Icons.inventory_2,
              label: pickupText,
              primaryColor: primaryColor,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            _bottomNavItem(
              index: 2,
              icon: Icons.account_balance_wallet_outlined,
              activeIcon: Icons.account_balance_wallet,
              label: paymentText,
              primaryColor: primaryColor,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            _bottomNavItem(
              index: 3,
              icon: Icons.recycling_outlined,
              activeIcon: Icons.recycling,
              label: recyclerNearbyText,
              primaryColor: primaryColor,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            _bottomNavItem(
              index: 4,
              icon: Icons.auto_awesome_outlined,
              activeIcon: Icons.auto_awesome,
              label: classifyText,
              primaryColor: primaryColor,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color primaryColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final isSelected = !isHome && currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectBottomTab(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            vertical: 7,
            horizontal: 5,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(
                    alpha: 0.12,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(
                  milliseconds: 180,
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  key: ValueKey(
                    isSelected,
                  ),
                  size: 21,
                  color: isSelected
                      ? primaryColor
                      : secondaryTextColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected
                      ? primaryColor
                      : secondaryTextColor,
                  fontSize: 9.5,
                  fontWeight: isSelected
                      ? FontWeight.w800
                      : FontWeight.w500,
                ),
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
      location: location,
      age: age,
      otherDetails: otherDetails,
      language: currentLanguage.name,
      paymentPreference: newPayment,
      profileImagePath: imagePath,
    );
  }

  void _showNotifications() {
    final activeAccent = AppThemeColors.primary(context);

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

  Widget _notificationTile(
    IconData icon,
    String title,
    String subtitle,
  ) {
    final activeAccent = AppThemeColors.primary(context);

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
