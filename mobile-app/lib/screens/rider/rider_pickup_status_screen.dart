import 'package:flutter/material.dart';

import '../../constants/app_enums.dart';
import '../../models/rider_pickup.dart';
import '../../services/storage_service.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_theme.dart';
import 'rider_pickup_proof_screen.dart';

class RiderPickupStatusScreen extends StatefulWidget {
  final AppLanguage language;
  final ReNovaThemeMode themeMode;
  final Future<void> Function(ReNovaThemeMode) onThemeChanged;
  final ReNovaStorage storage;
  final RiderPickup pickup;

  const RiderPickupStatusScreen({
    super.key,
    required this.language,
    required this.themeMode,
    required this.onThemeChanged,
    required this.storage,
    required this.pickup,
  });

  @override
  State<RiderPickupStatusScreen> createState() =>
      _RiderPickupStatusScreenState();
}

class _RiderPickupStatusScreenState
    extends State<RiderPickupStatusScreen> {
  int currentStep = 2;

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

  @override
  Widget build(BuildContext context) {
    final isDark =
        widget.themeMode == ReNovaThemeMode.dark;

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

    final steps = [
      _StepData(
        icon: Icons.assignment_rounded,
        title: _text(
          'Assigned',
          'निर्धारित',
          'नियुक्त',
        ),
      ),
      _StepData(
        icon: Icons.navigation_rounded,
        title: _text(
          'En Route',
          'रास्ते में',
          'मार्गावर',
        ),
      ),
      _StepData(
        icon: Icons.location_on_rounded,
        title: _text(
          'Arrived',
          'पहुंच गए',
          'पोहोचलो',
        ),
      ),
      _StepData(
        icon: Icons.inventory_2_rounded,
        title: _text(
          'Collecting',
          'संग्रह जारी',
          'संकलन सुरू',
        ),
      ),
      _StepData(
        icon: Icons.check_circle_rounded,
        title: _text(
          'Collected',
          'एकत्र किया',
          'संकलित',
        ),
      ),
    ];

    final pickupPhone = widget.pickup.phone;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        title: Text(
          _text(
            'Pickup status',
            'पिकअप स्थिति',
            'पिकअप स्थिती',
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
            // CURRENT STATUS
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
                      Icons.location_on_rounded,
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
                            'You have arrived',
                            'आप पहुंच गए हैं',
                            'तुम्ही पोहोचलात',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _text(
                            'Ready to start collection',
                            'संग्रह शुरू करने के लिए तैयार',
                            'संकलन सुरू करण्यासाठी तयार',
                          ),
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

            Text(
              _text(
                'Pickup progress',
                'पिकअप प्रगति',
                'पिकअप प्रगती',
              ),
              style: TextStyle(
                color: textColor,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 14),

            // --------------------------------------------------
            // TIMELINE
            // --------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: List.generate(
                  steps.length,
                  (index) {
                    final completed =
                        index <= currentStep;
                    final active =
                        index == currentStep;

                    return _timelineItem(
                      data: steps[index],
                      index: index,
                      completed: completed,
                      active: active,
                      isLast: index == steps.length - 1,
                      primaryColor: primaryColor,
                      textColor: textColor,
                      secondaryTextColor:
                          secondaryTextColor,
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------
            // COLLECTION POINT
            // --------------------------------------------------

            Text(
              _text(
                'Collection point',
                'कलेक्शन पॉइंट',
                'कलेक्शन पॉइंट',
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
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(
                            alpha: 0.10,
                          ),
                          borderRadius:
                              BorderRadius.circular(13),
                        ),
                        child: Icon(
                          Icons.storefront_outlined,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.pickup.name,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pickupPhone == null ||
                                      pickupPhone.trim().isEmpty
                                  ? widget.pickup.person
                                  : '${widget.pickup.person} • $pickupPhone',
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(
                        alpha: 0.06,
                      ),
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 17,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.pickup.address,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.badge_outlined,
                              size: 16,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pickup ID: ${widget.pickup.id}',
                                style: TextStyle(
                                  color:
                                      secondaryTextColor,
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------
            // ACTION
            // --------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  // ------------------------------------------------
                  // MOVE TO PICKUP PROOF
                  // ------------------------------------------------

                  if (currentStep == 3) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            RiderPickupProofScreen(
                          language: widget.language,
                          themeMode: widget.themeMode,
                          onThemeChanged:
                              widget.onThemeChanged,
                          storage: widget.storage,
                          pickup: widget.pickup,
                        ),
                      ),
                    );

                    return;
                  }

                  setState(() {
                    if (currentStep < steps.length - 1) {
                      currentStep++;
                    }
                  });
                },
                icon: Icon(
                  currentStep == 3
                      ? Icons.camera_alt_rounded
                      : Icons.arrow_forward_rounded,
                ),
                label: Text(
                  currentStep == 3
                      ? _text(
                          'Add pickup proof',
                          'पिकअप प्रमाण जोड़ें',
                          'पिकअप पुरावा जोडा',
                        )
                      : _text(
                          'Update status',
                          'स्थिति अपडेट करें',
                          'स्थिती अपडेट करा',
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
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timelineItem({
    required _StepData data,
    required int index,
    required bool completed,
    required bool active,
    required bool isLast,
    required Color primaryColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 42,
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: completed
                      ? primaryColor
                      : primaryColor.withValues(
                          alpha: 0.08,
                        ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  completed
                      ? Icons.check_rounded
                      : data.icon,
                  color: completed
                      ? (widget.themeMode ==
                              ReNovaThemeMode.dark
                          ? Colors.black
                          : Colors.white)
                      : secondaryTextColor,
                  size: 19,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 42,
                  margin: const EdgeInsets.symmetric(
                    vertical: 3,
                  ),
                  color: index < currentStep
                      ? primaryColor
                      : primaryColor.withValues(
                          alpha: 0.12,
                        ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.only(
              top: 8,
              bottom: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    data.title,
                    style: TextStyle(
                      color: completed
                          ? textColor
                          : secondaryTextColor,
                      fontSize: 14,
                      fontWeight: active
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                ),
                if (active)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      _text(
                        'Current',
                        'वर्तमान',
                        'सध्याचे',
                      ),
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepData {
  final IconData icon;
  final String title;

  const _StepData({
    required this.icon,
    required this.title,
  });
}
