import 'package:flutter/material.dart';

import '../../constants/app_enums.dart';
import '../../models/rider_pickup.dart';
import '../../services/storage_service.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_theme.dart';
import 'rider_navigation_screen.dart';

class RiderPickupDetailsScreen extends StatelessWidget {
  final AppLanguage language;
  final ReNovaThemeMode themeMode;
  final Future<void> Function(ReNovaThemeMode) onThemeChanged;
  final ReNovaStorage storage;
  final RiderPickup pickup;

  const RiderPickupDetailsScreen({
    super.key,
    required this.language,
    required this.themeMode,
    required this.onThemeChanged,
    required this.storage,
    required this.pickup,
  });

  String _text(
    String english,
    String hindi,
    String marathi,
  ) {
    switch (language) {
      case AppLanguage.hindi:
        return hindi;
      case AppLanguage.marathi:
        return marathi;
      case AppLanguage.english:
        return english;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        themeMode == ReNovaThemeMode.dark;

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
        : AppColors.lightText.withValues(
            alpha: 0.65,
          );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        title: Text(
          _text(
            'Pickup details',
            'पिकअप विवरण',
            'पिकअप तपशील',
          ),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // STATUS HEADER
            // --------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.16,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _text(
                            'Pickup assigned',
                            'पिकअप निर्धारित',
                            'पिकअप नियुक्त',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pickup.time,
                          style: TextStyle(
                            color: Colors.white.withValues(
                              alpha: 0.82,
                            ),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------
            // PICKUP INFORMATION
            // --------------------------------------------------

            Text(
              _text(
                'Pickup information',
                'पिकअप जानकारी',
                'पिकअप माहिती',
              ),
              style: TextStyle(
                color: textColor,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _detailRow(
                    icon: Icons.storefront_outlined,
                    title: _text(
                      'Collection point',
                      'कलेक्शन पॉइंट',
                      'कलेक्शन पॉइंट',
                    ),
                    value: pickup.name,
                    textColor: textColor,
                    secondaryTextColor:
                        secondaryTextColor,
                    primaryColor: primaryColor,
                  ),

                  const Divider(height: 25),

                  _detailRow(
                    icon: Icons.badge_outlined,
                    title: _text(
                      'Contact person',
                      'संपर्क व्यक्ति',
                      'संपर्क व्यक्ती',
                    ),
                    value: pickup.person,
                    textColor: textColor,
                    secondaryTextColor:
                        secondaryTextColor,
                    primaryColor: primaryColor,
                  ),

                  if (pickup.phone != null &&
                      pickup.phone!.trim().isNotEmpty) ...[
                    const Divider(height: 25),
                    _detailRow(
                      icon: Icons.phone_outlined,
                      title: _text(
                        'Phone',
                        'फोन',
                        'फोन',
                      ),
                      value: pickup.phone!,
                      textColor: textColor,
                      secondaryTextColor:
                          secondaryTextColor,
                      primaryColor: primaryColor,
                    ),
                  ],

                  const Divider(height: 25),

                  _detailRow(
                    icon: Icons.location_on_outlined,
                    title: _text(
                      'Location',
                      'स्थान',
                      'स्थान',
                    ),
                    value: pickup.location,
                    textColor: textColor,
                    secondaryTextColor:
                        secondaryTextColor,
                    primaryColor: primaryColor,
                  ),

                  const Divider(height: 25),

                  _detailRow(
                    icon: Icons.home_outlined,
                    title: _text(
                      'Address',
                      'पता',
                      'पत्ता',
                    ),
                    value: pickup.address,
                    textColor: textColor,
                    secondaryTextColor:
                        secondaryTextColor,
                    primaryColor: primaryColor,
                  ),

                  const Divider(height: 25),

                  _detailRow(
                    icon: Icons.route_outlined,
                    title: _text(
                      'Distance',
                      'दूरी',
                      'अंतर',
                    ),
                    value: pickup.distance,
                    textColor: textColor,
                    secondaryTextColor:
                        secondaryTextColor,
                    primaryColor: primaryColor,
                  ),

                  const Divider(height: 25),

                  _detailRow(
                    icon: Icons.schedule_outlined,
                    title: _text(
                      'Scheduled time',
                      'निर्धारित समय',
                      'नियोजित वेळ',
                    ),
                    value: pickup.time,
                    textColor: textColor,
                    secondaryTextColor:
                        secondaryTextColor,
                    primaryColor: primaryColor,
                  ),

                  const Divider(height: 25),

                  _detailRow(
                    icon: Icons.fingerprint_rounded,
                    title: _text(
                      'Pickup ID',
                      'पिकअप आईडी',
                      'पिकअप आयडी',
                    ),
                    value: pickup.id,
                    textColor: textColor,
                    secondaryTextColor:
                        secondaryTextColor,
                    primaryColor: primaryColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------
            // EXPECTED MATERIAL
            // --------------------------------------------------

            Text(
              _text(
                'Expected e-waste',
                'अपेक्षित ई-वेस्ट',
                'अपेक्षित ई-वेस्ट',
              ),
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: pickup.expectedMaterials.isEmpty
                  ? _materialRow(
                      icon: Icons.devices_other_outlined,
                      title: _text(
                        'Expected material',
                        'अपेक्षित सामग्री',
                        'अपेक्षित सामग्री',
                      ),
                      value: pickup.expectedMaterial,
                      textColor: textColor,
                      secondaryTextColor:
                          secondaryTextColor,
                      primaryColor: primaryColor,
                    )
                  : Column(
                      children: List.generate(
                        pickup.expectedMaterials.length,
                        (index) {
                          final material =
                              pickup.expectedMaterials[index];

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index ==
                                      pickup.expectedMaterials
                                              .length -
                                          1
                                  ? 0
                                  : 14,
                            ),
                            child: _materialRow(
                              icon:
                                  Icons.devices_other_outlined,
                              title: material.name,
                              value: material.quantity,
                              textColor: textColor,
                              secondaryTextColor:
                                  secondaryTextColor,
                              primaryColor: primaryColor,
                            ),
                          );
                        },
                      ),
                    ),
            ),

            const SizedBox(height: 28),

            // --------------------------------------------------
            // START NAVIGATION
            // --------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          RiderNavigationScreen(
                        language: language,
                        themeMode: themeMode,
                        onThemeChanged:
                            onThemeChanged,
                        storage: storage,
                        pickup: pickup,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.navigation_rounded,
                ),
                label: Text(
                  _text(
                    'Start navigation',
                    'नेविगेशन शुरू करें',
                    'नेव्हिगेशन सुरू करा',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: isDark
                      ? Colors.black
                      : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String title,
    required String value,
    required Color textColor,
    required Color secondaryTextColor,
    required Color primaryColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: primaryColor.withValues(
              alpha: 0.10,
            ),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 10.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _materialRow({
    required IconData icon,
    required String title,
    required String value,
    required Color textColor,
    required Color secondaryTextColor,
    required Color primaryColor,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: primaryColor.withValues(
              alpha: 0.10,
            ),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}