import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// CineConnect typography.
///
/// Elegant serif for display / headings (Playfair Display),
/// premium sans-serif for UI text (Inter), loaded via google_fonts.
///
/// Do not create ad-hoc TextStyles in screens — add a new named style
/// here (or `.copyWith()` an existing one) so typography stays consistent.
class AppTextStyles {
  AppTextStyles._();

  static const String serif = 'PlayfairDisplay';
  static const String sans = 'Inter';
  static const String dashboard = 'Inter';

  static TextStyle _sans(TextStyle style) =>
      GoogleFonts.inter(textStyle: style);
  static TextStyle _dashboard(TextStyle style) =>
      GoogleFonts.inter(textStyle: style);

  // ---- Display headings --------------------------------------------------
  static TextStyle get displayLarge => _dashboard(const TextStyle(
        fontSize: 38,
        fontWeight: FontWeight.w700,
        height: 1.08,
        color: AppColors.textPrimary,
      ));

  static TextStyle get heading => _dashboard(const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.12,
        color: AppColors.textPrimary,
      ));

  static TextStyle get sectionTitle => _dashboard(const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AppColors.textPrimary,
      ));

  // ---- Brand -------------------------------------------------------------
  static TextStyle get brand => _sans(const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.8,
        color: AppColors.textPrimary,
      ));

  static TextStyle get tagline => _sans(const TextStyle(
        fontSize: 8.6,
        fontWeight: FontWeight.w600,
        letterSpacing: 3.1,
        color: AppColors.textSecondary,
      ));

  // ---- Body / UI sans ----------------------------------------------------
  static TextStyle get bodyLarge => _sans(const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ));

  static TextStyle get body => _sans(const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ));

  static TextStyle get bodyMuted => _sans(const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ));

  static TextStyle get label => _sans(const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ));

  static TextStyle get caption => _sans(const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ));

  static TextStyle get micro => _sans(const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: AppColors.textSecondary,
      ));

  // ---- Premium admin dashboard ------------------------------------------
  static TextStyle get dashboardTitleStyle => _dashboard(const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: 0,
        color: AppColors.textPrimary,
      ));

  static TextStyle get sectionHeaderStyle => _dashboard(const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0,
        color: AppColors.textPrimary,
      ));

  static TextStyle get sectionActionStyle => _dashboard(const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1.05,
        letterSpacing: 0,
        color: AppColors.gold,
      ));

  static TextStyle get cardLabelStyle => _dashboard(const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.12,
        color: AppColors.textSecondary,
      ));

  static TextStyle get metricNumberStyle => _dashboard(const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1,
        letterSpacing: 0,
        color: AppColors.textPrimary,
        fontFeatures: [FontFeature.tabularFigures()],
      ));

  static TextStyle get smallMetaStyle => _dashboard(const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        height: 1.1,
        letterSpacing: 0,
        color: AppColors.textSecondary,
      ));

  static TextStyle get screenTitle => dashboardTitleStyle;

  static TextStyle get sectionHeading => sectionHeaderStyle;

  static TextStyle get adminSectionTitle => sectionHeaderStyle;

  static TextStyle get sectionAction => sectionActionStyle;

  static TextStyle get cardLabel => cardLabelStyle;

  static TextStyle get metricNumber => metricNumberStyle;

  static TextStyle get smallMetricNumber => _dashboard(const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1,
        letterSpacing: 0,
        color: AppColors.textPrimary,
        fontFeatures: [FontFeature.tabularFigures()],
      ));

  static TextStyle get smallMeta => smallMetaStyle;

  static TextStyle get statusText => smallMetaStyle.copyWith(
        fontWeight: FontWeight.w700,
      );

  static TextStyle get footerAction => sectionActionStyle;

  // ---- Compact card language ---------------------------------------------
  /// Content title inside a card (listing name, dispute type, ticket id).
  /// Use instead of `sectionHeaderStyle` for anything that isn't an
  /// all-caps eyebrow label — sentence case, no letter-spacing.
  static TextStyle get cardTitle => _dashboard(const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.textPrimary,
      ));

  /// Quiet eyebrow label for a sub-panel inside an already-titled screen
  /// (e.g. a two-column panel header). Deliberately lighter than
  /// [sectionHeaderStyle] so it doesn't read as a second page heading.
  static TextStyle get panelLabel => _dashboard(const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: 0.6,
        color: AppColors.textSecondary,
      ));

  /// Mid-scale figure for a number inline inside a list-style card
  /// (rate, budget total) — smaller than [metricNumber], which is
  /// reserved for dedicated metric tiles.
  static TextStyle get metricNumberCompact => _dashboard(const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.0,
        color: AppColors.textPrimary,
        fontFeatures: [FontFeature.tabularFigures()],
      ));

  // ---- Price -------------------------------------------------------------
  static TextStyle get price => _sans(const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.gold,
      ));
}
