import 'package:flutter/material.dart';

/// CineConnect color system — dark cinematic luxury.
///
/// Near-black backgrounds, warm metallic gold accents, ivory text,
/// muted warm greys, and soft green for availability/success states.
class AppColors {
  AppColors._();

  // ---- Backgrounds -------------------------------------------------------
  /// Deepest base — behind everything.
  static const Color background = Color(0xFF050607);

  /// Slightly lifted surface used for the cinematic gradient bottom.
  static const Color backgroundElevated = Color(0xFF0D1014);

  /// Glass card fill (used with low opacity + border).
  static const Color glassFill = Color(0x1A101820);
  static const Color glassFillStrong = Color(0x261A2530);

  /// Solid-ish card base for opaque cards.
  static const Color card = Color(0xFF0E1217);
  static const Color cardMuted = Color(0xFF151A21);

  // ---- Gold accents ------------------------------------------------------
  /// Primary warm metallic gold.
  static const Color gold = Color(0xFFF0BD59);
  static const Color goldBright = Color(0xFFF4C76A);
  static const Color goldDeep = Color(0xFFC88A1E);
  static const Color goldGlow = Color(0x44C88A1E); // for shadows / glows

  /// Metallic gold gradient (primary CTA button).
  static const Gradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF4C76A), Color(0xFFE2AA43), Color(0xFFC88A1E)],
    stops: [0.0, 0.52, 1.0],
  );

  static const Gradient goldStrokeGradient = LinearGradient(
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

  /// Subtle cinematic page gradient (top near-black -> warm hint at bottom).
  static const Gradient pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF050607),
      Color(0xFF070A0D),
      Color(0xFF0A0D10),
      Color(0xFF080604)
    ],
    stops: [0.0, 0.42, 0.72, 1.0],
  );

  // ---- Text --------------------------------------------------------------
  /// Ivory / off-white — primary text.
  static const Color textPrimary = Color(0xFFF7F0E7);

  /// Muted warm grey — secondary text.
  static const Color textSecondary = Color(0xFFAAA39A);

  /// Faint warm grey — tertiary / captions.
  static const Color textTertiary = Color(0xFF756F68);

  // ---- Borders -----------------------------------------------------------
  static const Color border = Color(0xFF29313A);
  static const Color borderMuted = Color(0xFF1A2028);
  static const Color borderGold = Color(0x99DFA84A);

  // ---- Status ------------------------------------------------------------
  /// Soft green for availability dots / success badges.
  static const Color success = Color(0xFF4FB477);
  static const Color successSoft = Color(0xFF3E8C5E);

  // Icon accent hues used in the trust row.
  static const Color infoBlue = Color(0xFF6C93D6);
  static const Color infoPurple = Color(0xFF9E7BD6);
}
