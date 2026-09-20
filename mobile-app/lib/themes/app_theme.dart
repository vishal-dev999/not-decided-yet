import 'package:flutter/material.dart';

import 'app_colors.dart';

enum ReNovaThemeMode { light, dark }

class AppThemeColors {
  // ============================================================
  // THEME DETECTION
  // ============================================================

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  // ============================================================
  // BACKGROUND
  // ============================================================

  static Color background(BuildContext context) {
    return isDark(context)
        ? AppColors.darkBackground
        : AppColors.lightBackground;
  }

  // ============================================================
  // CARDS
  // ============================================================

  static Color card(BuildContext context) {
    return isDark(context)
        ? AppColors.cardBg
        : AppColors.lightCard;
  }

  // ============================================================
  // PRIMARY BRAND COLOUR
  // ============================================================

  static Color primary(BuildContext context) {
    return isDark(context)
        ? AppColors.leafGreen
        : AppColors.deepForest;
  }

  // ============================================================
  // SECONDARY BRAND COLOUR
  // ============================================================

  static Color secondary(BuildContext context) {
    return isDark(context)
        ? AppColors.sageGreen
        : AppColors.brandGreen;
  }

  // ============================================================
  // TEXT
  // ============================================================

  static Color text(BuildContext context) {
    return isDark(context)
        ? AppColors.darkText
        : AppColors.lightText;
  }

  // ============================================================
  // MUTED TEXT
  // ============================================================

  static Color muted(BuildContext context) {
    return isDark(context)
        ? AppColors.darkMuted
        : AppColors.lightMuted;
  }

  // ============================================================
  // FAINT TEXT
  // ============================================================

  static Color faint(BuildContext context) {
    return isDark(context)
        ? AppColors.darkFaint
        : AppColors.lightFaint;
  }

  // ============================================================
  // VERY FAINT TEXT
  // ============================================================

  static Color veryFaint(BuildContext context) {
    return isDark(context)
        ? AppColors.darkFaint.withValues(alpha: 0.65)
        : const Color(0xFFA0AA9F);
  }

  // ============================================================
  // BORDER
  // ============================================================

  static Color border(BuildContext context) {
    return isDark(context)
        ? AppColors.darkBorder
        : AppColors.lightBorder;
  }

  // ============================================================
  // SUBTLE GREEN BACKGROUND
  // ============================================================

  static Color softAccent(BuildContext context) {
    return isDark(context)
        ? AppColors.brandGreen.withValues(alpha: 0.18)
        : AppColors.softSage;
  }

  // ============================================================
  // PRIMARY ICON / BUTTON COLOUR
  // ============================================================

  static Color icon(BuildContext context) {
    return isDark(context)
        ? AppColors.leafGreen
        : AppColors.deepForest;
  }
}