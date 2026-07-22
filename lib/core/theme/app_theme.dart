import 'package:flutter/material.dart';

import 'app_color_scheme.dart';
import 'app_radius.dart';
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
      dividerTheme: DividerThemeData(
        color: colors.borderMuted,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: colors.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colors.border),
        ),
      ),
      focusColor: colors.focusRing.withValues(alpha: 0.16),
      hoverColor: colors.holographicTeal.withValues(alpha: 0.05),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.elevatedSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: colors.focusRing, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          textStyle: AppTextStyles.label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          textStyle: AppTextStyles.label,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: colors.goldDark,
          textStyle: AppTextStyles.label,
        ),
      ),
    );
  }

  // ---- Reusable decorations ---------------------------------------------

  /// Glass card look: subtle translucent fill + theme border.
  static BoxDecoration glassCard(
    BuildContext context, {
    double radius = 18,
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
                blurRadius: 14,
                spreadRadius: -7,
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
      boxShadow: null,
    );
  }
}
