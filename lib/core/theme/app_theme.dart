import 'package:flutter/material.dart';

import 'app_color_scheme.dart';
import 'app_text_styles.dart';

/// Global ThemeData for CineConnect.
///
/// Do not build ad-hoc ThemeData or hardcode colors in screens — add
/// new decoration helpers here so every dashboard stays consistent.
class AppTheme {
  AppTheme._();

  static ThemeData get dark => _theme(Brightness.dark, CineThemeColors.dark);

  static ThemeData get light => _theme(Brightness.light, CineThemeColors.light);

  static ThemeData _theme(Brightness brightness, CineThemeColors colors) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      splashColor: colors.goldGlow,
      highlightColor: Colors.transparent,
      extensions: <ThemeExtension<dynamic>>[colors],
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.goldMid,
        brightness: brightness,
        primary: colors.goldMid,
        secondary: colors.goldLight,
        surface: colors.surface,
        onPrimary: colors.onGold,
        onSurface: colors.textPrimary,
      ),
      textTheme: base.textTheme.copyWith(
        displayLarge: AppTextStyles.displayLarge.copyWith(
          color: colors.textPrimary,
        ),
        headlineMedium: AppTextStyles.heading.copyWith(
          color: colors.textPrimary,
        ),
        titleLarge: AppTextStyles.sectionTitle.copyWith(
          color: colors.textPrimary,
        ),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(
          color: colors.textPrimary,
        ),
        bodyMedium: AppTextStyles.body.copyWith(
          color: colors.textPrimary,
        ),
        labelLarge: AppTextStyles.label.copyWith(
          color: colors.textPrimary,
        ),
        bodySmall: AppTextStyles.caption.copyWith(
          color: colors.textSecondary,
        ),
      ),
      iconTheme: IconThemeData(color: colors.iconMuted, size: 22),
      dividerColor: colors.border,
    );
  }

  // ---- Reusable decorations ---------------------------------------------

  /// Glass card look: subtle translucent fill + theme border.
  static BoxDecoration glassCard(
    BuildContext context, {
    double radius = 20,
    bool goldBorder = false,
    bool glow = false,
  }) {
    final colors = context.appColors;

    return BoxDecoration(
      gradient: colors.glassGradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: goldBorder ? colors.goldMid : colors.border,
        width: 1,
      ),
      boxShadow: glow
          ? [
              BoxShadow(
                color: colors.goldGlow,
                blurRadius: 30,
                spreadRadius: -6,
              ),
            ]
          : null,
    );
  }

  static BoxDecoration chip(BuildContext context, {bool active = false}) {
    final colors = context.appColors;

    return BoxDecoration(
      gradient:
          active ? colors.activeChipGradient : colors.inactiveChipGradient,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(
        color: active ? colors.goldMid : colors.border,
        width: 1,
      ),
      boxShadow: active
          ? [
              BoxShadow(
                color: colors.goldGlow,
                blurRadius: 16,
                spreadRadius: -4,
              ),
            ]
          : null,
    );
  }
}
