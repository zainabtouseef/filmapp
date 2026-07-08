import 'package:flutter/material.dart';

/// Standalone gradient tokens extracted from the original AppColors.
///
/// The live, theme-aware gradients used throughout the app live on
/// [CineThemeColors] (see app_color_scheme.dart) — e.g. `context.appColors
/// .goldGradient`. These are kept as documented, non-theme-reactive
/// fallbacks/reference tokens.
class AppGradients {
  AppGradients._();

  static const Gradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF4C76A), Color(0xFFE2AA43), Color(0xFFC88A1E)],
    stops: [0.0, 0.52, 1.0],
  );

  static const Gradient goldStroke = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF4C76A),
      Color(0x66F4C76A),
      Color(0x22FFFFFF),
      Color(0xAAC88A1E),
    ],
    stops: [0.0, 0.34, 0.62, 1.0],
  );

  static const Gradient page = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF050607),
      Color(0xFF070A0D),
      Color(0xFF0A0D10),
      Color(0xFF080604),
    ],
    stops: [0.0, 0.42, 0.72, 1.0],
  );
}
