
import 'package:flutter/material.dart';

import '../main.dart'; // Needed to access ReNovaAppState
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';

Widget themeSwitchButton(
  BuildContext context,
  ReNovaThemeMode mode,
  ValueChanged<ReNovaThemeMode> onChanged,
) {
  final state = context.findAncestorStateOfType<ReNovaAppState>();
  final currentMode = state?.themeMode ?? mode;
  final isDark = currentMode == ReNovaThemeMode.dark;

  return IconButton(
    tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
    icon: Icon(
      isDark ? Icons.light_mode : Icons.dark_mode,
      color: isDark ? AppColors.primaryGold : AppColors.featherGreen,
    ),
    onPressed: () {
      final newMode = isDark ? ReNovaThemeMode.light : ReNovaThemeMode.dark;
      if (state != null) {
        state.changeTheme(newMode);
      } else {
        onChanged(newMode);
      }
    },
  );
}
