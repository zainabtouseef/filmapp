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

  static TextStyle _serif(TextStyle style) =>
      GoogleFonts.playfairDisplay(textStyle: style);
  static TextStyle _sans(TextStyle style) =>
      GoogleFonts.inter(textStyle: style);

  // ---- Display / serif headings -----------------------------------------
  static TextStyle get displayLarge => _serif(const TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.05,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      ));

  static TextStyle get heading => _serif(const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.1,
        color: AppColors.textPrimary,
      ));

  static TextStyle get sectionTitle => _serif(const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
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

  // ---- Price -------------------------------------------------------------
  static TextStyle get price => _sans(const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.gold,
      ));
}
