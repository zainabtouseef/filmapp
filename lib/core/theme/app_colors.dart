import 'package:flutter/material.dart';

/// CineConnect raw color palette (legacy / non-theme-aware constants).
///
/// Prefer `context.appColors` (see app_color_scheme.dart) for anything
/// that needs to react to light/dark mode. This file only holds a few
/// standalone constants still referenced by non-themed widgets (e.g. the
/// portrait placeholder).
///
/// Do not hardcode new colors in screens — add them here or to
/// app_color_scheme.dart and consume via the theme.
class AppColors {
  AppColors._();

  // ---- Backgrounds -------------------------------------------------------
  static const Color background = Color(0xFF07070A);
  static const Color backgroundElevated = Color(0xFF121215);

  /// Glass card fill (used with low opacity + border).
  static const Color glassFill = Color(0x1A101820);
  static const Color glassFillStrong = Color(0x261A2530);

  /// Solid-ish card base for opaque cards.
  static const Color card = Color(0xFF121215);
  static const Color cardMuted = Color(0xFF17171B);

  // ---- Gold accents ------------------------------------------------------
  static const Color gold = Color(0xFFE5C46E);
  static const Color goldBright = Color(0xFFF4C76A);
  static const Color goldDeep = Color(0xFFC88A1E);
  static const Color goldGlow = Color(0x44D4AF37);

  // ---- Text --------------------------------------------------------------
  static const Color textPrimary = Color(0xFFF3F0E7);
  static const Color textSecondary = Color(0xFFC6C0B0);
  static const Color textTertiary = Color(0xFF8B8677);

  // ---- Borders -----------------------------------------------------------
  static const Color border = Color(0xFF1A1A1D);
  static const Color borderMuted = Color(0xFF131316);
  static const Color borderGold = Color(0x99D4AF37);

  // ---- Status ------------------------------------------------------------
  static const Color success = Color(0xFF6FB585);
  static const Color successSoft = Color(0xFF3E8C5E);
  static const Color infoBlue = Color(0xFF7FA8CC);
  static const Color infoPurple = Color(0xFF9B8BE0);
}
