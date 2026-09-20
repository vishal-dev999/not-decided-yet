import 'package:flutter/material.dart';

class AppColors {
  // ============================================================
  // RECYLINK BRAND PALETTE
  // ============================================================

  // Deep forest green — primary brand colour
  static const Color deepForest = Color(0xFF285B3F);

  // Main RecyLink green
  static const Color brandGreen = Color(0xFF397A50);

  // Leaf green from the logo
  static const Color leafGreen = Color(0xFF76A45F);

  // Soft sage green
  static const Color sageGreen = Color(0xFFA8C596);

  // Very light sage for subtle backgrounds/highlights
  static const Color softSage = Color(0xFFDCE8D7);

  // ============================================================
  // LIGHT MODE
  // ============================================================

  // Warm off-white — main application background
  static const Color lightBackground = Color(0xFFFAFBF6);

  // Pure white — cards and elevated surfaces
  static const Color lightCard = Color(0xFFFFFFFF);

  // Main text
  static const Color lightText = Color(0xFF203126);

  // Secondary text
  static const Color lightMuted = Color(0xFF627267);

  // Very subtle text
  static const Color lightFaint = Color(0xFF8B998F);

  // Borders/dividers
  static const Color lightBorder = Color(0xFFDCE4D9);

  // ============================================================
  // DARK MODE
  // ============================================================

  // Deep green-black
  static const Color darkBackground = Color(0xFF0E1711);

  // Dark green card
  static const Color cardBg = Color(0xFF17231A);

  // Slightly lighter dark surface
  static const Color darkSurface = Color(0xFF1D2C20);

  // Main dark-mode text
  static const Color darkText = Color(0xFFF4F7F1);

  // Secondary dark-mode text
  static const Color darkMuted = Color(0xFFB7C5B9);

  // Faint dark-mode text
  static const Color darkFaint = Color(0xFF87968A);

  // Dark-mode borders
  static const Color darkBorder = Color(0xFF2B3B2E);

  // ============================================================
  // SEMANTIC / FUNCTIONAL COLOURS
  // ============================================================

  static const Color success = Color(0xFF4F8A57);

  static const Color warning = Color(0xFFD99B3D);

  static const Color danger = Color(0xFFD85C5C);

  static const Color info = Color(0xFF5F8F72);

  // ============================================================
  // COMPATIBILITY ALIASES
  // ============================================================
  // These keep existing screens from breaking if they still
  // reference the older colour names.

  static const Color primaryGold = brandGreen;

  static const Color accentCoral = leafGreen;

  static const Color mintGreen = sageGreen;

  static const Color lightGreen = brandGreen;

  static const Color ColorGold = leafGreen;

  static const Color featherGreen = brandGreen;
}