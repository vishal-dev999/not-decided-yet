import 'package:flutter/material.dart';

import 'app_colors.dart'; // Needed because AppThemeColors uses AppColors

enum ReNovaThemeMode { light, dark }

class AppThemeColors {
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color background(BuildContext context) {
    return isDark(context)
        ? AppColors.darkBackground
        : AppColors.lightBackground;
  }

  static Color card(BuildContext context) {
    return isDark(context) ? AppColors.cardBg : AppColors.lightCard;
  }

  static Color text(BuildContext context) {
    return isDark(context) ? Colors.white : AppColors.lightText;
  }

  static Color muted(BuildContext context) {
    return isDark(context) ? Colors.white60 : AppColors.lightMuted;
  }

  static Color faint(BuildContext context) {
    return isDark(context) ? Colors.white54 : AppColors.lightFaint;
  }

  static Color veryFaint(BuildContext context) {
    return isDark(context) ? Colors.white38 : const Color(0xFFA0A8B5);
  }
}
