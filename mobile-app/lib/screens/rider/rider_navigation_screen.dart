import 'package:flutter/material.dart';

import '../../constants/app_enums.dart';
import '../../models/rider_pickup.dart';
import '../../services/storage_service.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_theme.dart';
import 'rider_pickup_status_screen.dart';

class RiderNavigationScreen extends StatelessWidget {
  final AppLanguage language;
  final ReNovaThemeMode themeMode;
  final Future<void> Function(ReNovaThemeMode) onThemeChanged;
  final ReNovaStorage storage;

  /// The exact pickup selected by the rider.
  final RiderPickup pickup;

  const RiderNavigationScreen({
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

  void _handleCall(BuildContext context) {
    final phone = pickup.phone;

    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'No phone number is available for this pickup.',
              'इस पिकअप के लिए कोई फोन नंबर उपलब्ध नहीं है।',
              'या पिकअपसाठी फोन नंबर उपलब्ध नाही.',
            ),
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _text(
            'Calling ${pickup.person}...',
            '${pickup.person} को कॉल किया जा रहा है...',
            '${pickup.person} यांना कॉल केला जात आहे...',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeMode == ReNovaThemeMode.dark;

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
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        title: Text(
          _text(
            'Navigation',
            'नेविगेशन',
            'नेव्हिगेशन',
          ),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _text(
                      'Current location refreshed.',
                      'वर्तमान स्थान अपडेट किया गया।',
                      'सध्याचे स्थान अपडेट केले.',
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.my_location_rounded,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // --------------------------------------------------
                // MAP AREA
                // --------------------------------------------------

                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1C2420)
                        : const Color(0xFFE9EEE9),
                  ),
                  child: CustomPaint(
                    painter: _RoutePainter(
                      primaryColor: primaryColor,
                      isDark: isDark,
                    ),
                    child: Stack(
                      children: [
                        // Current location
                        Positioned(
                          left: 72,
                          bottom: 145,
                          child: _mapMarker(
                            icon: Icons.two_wheeler_rounded,
                            color: primaryColor,
                            isCurrentLocation: true,
                          ),
                        ),

                        // Selected pickup destination
                        Positioned(
                          right: 58,
                          top: 115,
                          child: _mapMarker(
                            icon: Icons.storefront_rounded,
                            color: Colors.redAccent,
                            isCurrentLocation: false,
                          ),
                        ),

                        Positioned(
                          left: 20,
                          top: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: 0.08,
                                  ),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.navigation_rounded,
                                  size: 17,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  _text(
                                    'Best route',
                                    'सर्वोत्तम मार्ग',
                                    'सर्वोत्तम मार्ग',
                                  ),
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
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

                // --------------------------------------------------
                // DESTINATION CARD
                // --------------------------------------------------

                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.12,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // --------------------------------------------------
                        // PICKUP HEADER
                        // --------------------------------------------------

                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius:
                                    BorderRadius.circular(13),
                              ),
                              child: Icon(
                                Icons.storefront_outlined,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pickup.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    pickup.address,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color:
                                          secondaryTextColor,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                _handleCall(context);
                              },
                              icon: Icon(
                                Icons.call_rounded,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // --------------------------------------------------
                        // CONTACT PERSON
                        // --------------------------------------------------

                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 17,
                              color: secondaryTextColor,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                pickup.person,
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // --------------------------------------------------
                        // PICKUP INFORMATION
                        // --------------------------------------------------

                        Row(
                          children: [
                            Expanded(
                              child: _infoItem(
                                icon: Icons.route_rounded,
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
                            ),
                            Expanded(
                              child: _infoItem(
                                icon: Icons.schedule_rounded,
                                title: _text(
                                  'Pickup time',
                                  'पिकअप समय',
                                  'पिकअप वेळ',
                                ),
                                value: pickup.time,
                                textColor: textColor,
                                secondaryTextColor:
                                    secondaryTextColor,
                                primaryColor: primaryColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // --------------------------------------------------
                        // PICKUP ID
                        // --------------------------------------------------

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(
                              alpha: 0.07,
                            ),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.confirmation_number_outlined,
                                size: 17,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _text(
                                  'Pickup ID',
                                  'पिकअप आईडी',
                                  'पिकअप आयडी',
                                ),
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                pickup.id,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // --------------------------------------------------
                        // I'VE ARRIVED
                        // --------------------------------------------------

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RiderPickupStatusScreen(
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
                              Icons.location_on_rounded,
                            ),
                            label: Text(
                              _text(
                                "I've Arrived",
                                'मैं पहुंच गया',
                                'मी पोहोचलो',
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
                                    BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapMarker({
    required IconData icon,
    required Color color,
    required bool isCurrentLocation,
  }) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 21,
      ),
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String title,
    required String value,
    required Color textColor,
    required Color secondaryTextColor,
    required Color primaryColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: primaryColor,
          size: 19,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 10.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoutePainter extends CustomPainter {
  final Color primaryColor;
  final bool isDark;

  _RoutePainter({
    required this.primaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.06)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;

    final routePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();

    path.moveTo(
      size.width * 0.20,
      size.height * 0.68,
    );

    path.cubicTo(
      size.width * 0.32,
      size.height * 0.58,
      size.width * 0.43,
      size.height * 0.74,
      size.width * 0.53,
      size.height * 0.53,
    );

    path.cubicTo(
      size.width * 0.64,
      size.height * 0.30,
      size.width * 0.73,
      size.height * 0.35,
      size.width * 0.82,
      size.height * 0.22,
    );

    canvas.drawPath(path, roadPaint);
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(
    covariant _RoutePainter oldDelegate,
  ) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.isDark != isDark;
  }
}