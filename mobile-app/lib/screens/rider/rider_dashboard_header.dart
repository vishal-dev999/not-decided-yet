import 'dart:io';

import 'package:flutter/material.dart';

import '../../constants/app_enums.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_theme.dart';

class RiderDashboardHeader extends StatelessWidget {
  final String riderName;
  final String? profileImagePath;
  final AppLanguage language;
  final ReNovaThemeMode themeMode;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationTap;

  const RiderDashboardHeader({
    super.key,
    required this.riderName,
    required this.profileImagePath,
    required this.language,
    required this.themeMode,
    required this.onProfileTap,
    required this.onNotificationTap,
  });

  String _greeting() {
    switch (language) {
      case AppLanguage.hindi:
        return 'सुप्रभात';
      case AppLanguage.marathi:
        return 'शुभ प्रभात';
      case AppLanguage.english:
        return 'Good Morning';
    }
  }

  String _riderLabel() {
    switch (language) {
      case AppLanguage.hindi:
        return 'राइडर';
      case AppLanguage.marathi:
        return 'राइडर';
      case AppLanguage.english:
        return 'Rider';
    }
  }

  String _todayLabel() {
    switch (language) {
      case AppLanguage.hindi:
        return 'आज के लिए आपके पिकअप';
      case AppLanguage.marathi:
        return 'आजचे तुमचे पिकअप';
      case AppLanguage.english:
        return 'Your assigned pickups for today';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeMode == ReNovaThemeMode.dark;

    final cardColor =
        isDark ? AppColors.cardBg : AppColors.lightCard;

    final backgroundColor =
        isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground;

    final primaryColor =
        isDark
            ? AppColors.primaryGold
            : AppColors.featherGreen;

    final textColor =
        isDark ? Colors.white : AppColors.lightText;

    final secondaryTextColor = isDark
        ? Colors.white70
        : AppColors.lightText.withValues(alpha: 0.62);

    final displayName = riderName.trim().isEmpty
        ? _riderLabel()
        : riderName.trim();

    final hasProfileImage =
        profileImagePath != null &&
        profileImagePath!.trim().isNotEmpty &&
        File(profileImagePath!).existsSync();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        15,
        11,
        16,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: primaryColor.withValues(
            alpha: isDark ? 0.18 : 0.12,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.14 : 0.05,
            ),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----------------------------------------------------
          // PROFILE / ACCOUNT BUTTON
          // ----------------------------------------------------

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onProfileTap,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(
                    alpha: 0.12,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withValues(
                      alpha: 0.20,
                    ),
                  ),
                ),
                child: ClipOval(
                  child: hasProfileImage
                      ? Image.file(
                          File(profileImagePath!),
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Icons.person_rounded,
                          size: 27,
                          color: primaryColor,
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ----------------------------------------------------
          // GREETING + ACCOUNT DETAILS
          // ----------------------------------------------------

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 3),

                Row(
                  children: [
                    Icon(
                      Icons.delivery_dining_rounded,
                      size: 15,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _riderLabel(),
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                Text(
                  _todayLabel(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ----------------------------------------------------
          // NOTIFICATION BUTTON
          // ----------------------------------------------------

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onNotificationTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryColor.withValues(
                      alpha: isDark ? 0.18 : 0.12,
                    ),
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: 25,
                        color: textColor,
                      ),
                    ),

                    Positioned(
                      top: 7,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: cardColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
