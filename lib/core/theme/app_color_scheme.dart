import 'package:flutter/material.dart';

/// Semantic, theme-aware color tokens for CineConnect.
///
/// Always consume colors through `context.appColors` in screens and
/// widgets — never hardcode a Color literal directly in a dashboard.
/// If a token you need is missing, add it here (and to both the
/// [light] and [dark] instances below) rather than inlining a value.
extension CineThemeContext on BuildContext {
  CineThemeColors get appColors =>
      Theme.of(this).extension<CineThemeColors>() ?? CineThemeColors.dark;
}

@immutable
class CineThemeColors extends ThemeExtension<CineThemeColors> {
  final bool isLight;
  final Color background;
  final Color surface;
  final Color softSurface;
  final Color elevatedSurface;
  final Color mutedSurface;
  final Color overlaySurface;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color icon;
  final Color iconMuted;
  final Color border;
  final Color borderMuted;
  final Color goldLight;
  final Color goldMid;
  final Color goldDark;
  final Color goldGlow;
  final Color shadow;
  final Color success;
  final Color warning;
  final Color infoBlue;
  final Color infoPurple;
  final Color danger;
  final Color onGold;
  final Color porcelain;
  final Color holographicTeal;
  final Color holographicCyan;
  final Color focusRing;
  final Color surfaceHighlight;
  final LinearGradient backgroundGradient;
  final LinearGradient glassGradient;
  final LinearGradient searchGradient;
  final LinearGradient activeChipGradient;
  final LinearGradient inactiveChipGradient;
  final LinearGradient filterGradient;
  final LinearGradient cardGradient;
  final LinearGradient navGradient;
  final LinearGradient goldGradient;

  const CineThemeColors({
    required this.isLight,
    required this.background,
    required this.surface,
    required this.softSurface,
    required this.elevatedSurface,
    required this.mutedSurface,
    required this.overlaySurface,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.icon,
    required this.iconMuted,
    required this.border,
    required this.borderMuted,
    required this.goldLight,
    required this.goldMid,
    required this.goldDark,
    required this.goldGlow,
    required this.shadow,
    required this.success,
    required this.warning,
    required this.infoBlue,
    required this.infoPurple,
    required this.danger,
    required this.onGold,
    required this.porcelain,
    required this.holographicTeal,
    required this.holographicCyan,
    required this.focusRing,
    required this.surfaceHighlight,
    required this.backgroundGradient,
    required this.glassGradient,
    required this.searchGradient,
    required this.activeChipGradient,
    required this.inactiveChipGradient,
    required this.filterGradient,
    required this.cardGradient,
    required this.navGradient,
    required this.goldGradient,
  });

  static const light = CineThemeColors(
    isLight: true,
    background: Color(0xFFF3F5F7),
    surface: Color(0xFFF8FAFB),
    softSurface: Color(0xFFEEF1F3),
    elevatedSurface: Color(0xFFFFFFFF),
    mutedSurface: Color(0xFFE5E9EC),
    overlaySurface: Color(0xF7FFFFFF),
    card: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF202428),
    textSecondary: Color(0xFF5F686F),
    textTertiary: Color(0xFF707A82),
    icon: Color(0xFF293138),
    iconMuted: Color(0xFF6D777F),
    border: Color(0xFFD6DDE2),
    borderMuted: Color(0xFFE6EAED),
    goldLight: Color(0xFFD8B96F),
    goldMid: Color(0xFFB28735),
    goldDark: Color(0xFF7B5A20),
    goldGlow: Color(0x18B28735),
    shadow: Color(0x18131A20),
    success: Color(0xFF27764F),
    warning: Color(0xFFA66518),
    infoBlue: Color(0xFF326B8E),
    infoPurple: Color(0xFF705C84),
    danger: Color(0xFFB74636),
    onGold: Color(0xFF171A1D),
    porcelain: Color(0xFFF0F3F4),
    holographicTeal: Color(0xFF247B75),
    holographicCyan: Color(0xFF3F9299),
    focusRing: Color(0xFF247B75),
    surfaceHighlight: Color(0xFFFFFFFF),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFBFCFD),
        Color(0xFFF5F7F8),
        Color(0xFFEEF1F3),
      ],
    ),
    glassGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFF9FAFB), Color(0xFFFFFFFF)],
    ),
    searchGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFB), Color(0xFFFFFFFF)],
    ),
    activeChipGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFFFF9ED), Color(0xFFFFFFFF)],
    ),
    inactiveChipGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFF7F9FA), Color(0xFFFFFFFF)],
    ),
    filterGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFF7F9FA), Color(0xFFFFFFFF)],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFFAFBFC), Color(0xFFFFFFFF)],
    ),
    navGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFFFFF), Color(0xFAF7F9FA)],
    ),
    goldGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFD7B769), Color(0xFFB08A3E), Color(0xFF8E6D2B)],
    ),
  );

  static const dark = CineThemeColors(
    isLight: false,
    background: Color(0xFF14171A),
    surface: Color(0xFF1B1F23),
    softSurface: Color(0xFF22272B),
    elevatedSurface: Color(0xFF272C31),
    mutedSurface: Color(0xFF20252A),
    overlaySurface: Color(0xF5272C31),
    card: Color(0xFF24292D),
    textPrimary: Color(0xFFF2F4F5),
    textSecondary: Color(0xFFAFB6BC),
    textTertiary: Color(0xFF969EA5),
    icon: Color(0xFFF2F4F5),
    iconMuted: Color(0xFFA4ADB4),
    border: Color(0xFF3D454B),
    borderMuted: Color(0xFF31383D),
    goldLight: Color(0xFFF0C66E),
    goldMid: Color(0xFFDCA83E),
    goldDark: Color(0xFFC18B29),
    goldGlow: Color(0x2EDCA83E),
    shadow: Color(0x70000000),
    success: Color(0xFF67BC8C),
    warning: Color(0xFFD3A054),
    infoBlue: Color(0xFF78AFD0),
    infoPurple: Color(0xFFA78EBA),
    danger: Color(0xFFE47D70),
    onGold: Color(0xFF171A1D),
    porcelain: Color(0xFF2C3236),
    holographicTeal: Color(0xFF5BB1A6),
    holographicCyan: Color(0xFF75C0C5),
    focusRing: Color(0xFF6BC1B6),
    surfaceHighlight: Color(0xFF3B4247),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF14171A),
        Color(0xFF181C1F),
        Color(0xFF1C2024),
        Color(0xFF14171A),
      ],
      stops: [0.0, 0.42, 0.72, 1.0],
    ),
    glassGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF292E33), Color(0xFF252A2F), Color(0xFF23282C)],
    ),
    searchGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF292E33), Color(0xFF252A2F), Color(0xFF23282C)],
      stops: [0.0, 0.52, 1.0],
    ),
    activeChipGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2C3033), Color(0xFF292C2B), Color(0xFF252A2E)],
    ),
    inactiveChipGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF272C31), Color(0xFF252A2F), Color(0xFF23282C)],
    ),
    filterGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF292E33), Color(0xFF252A2F), Color(0xFF23282C)],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF292E33), Color(0xFF272C31), Color(0xFF24292D)],
    ),
    navGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF292E33), Color(0xFF22272B)],
    ),
    goldGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF4C76A), Color(0xFFE2A52E), Color(0xFFC88A1E)],
    ),
  );

  @override
  ThemeExtension<CineThemeColors> copyWith({
    bool? isLight,
    Color? background,
    Color? surface,
    Color? softSurface,
    Color? elevatedSurface,
    Color? mutedSurface,
    Color? overlaySurface,
    Color? card,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? icon,
    Color? iconMuted,
    Color? border,
    Color? borderMuted,
    Color? goldLight,
    Color? goldMid,
    Color? goldDark,
    Color? goldGlow,
    Color? shadow,
    Color? success,
    Color? warning,
    Color? infoBlue,
    Color? infoPurple,
    Color? danger,
    Color? onGold,
    Color? porcelain,
    Color? holographicTeal,
    Color? holographicCyan,
    Color? focusRing,
    Color? surfaceHighlight,
    LinearGradient? backgroundGradient,
    LinearGradient? glassGradient,
    LinearGradient? searchGradient,
    LinearGradient? activeChipGradient,
    LinearGradient? inactiveChipGradient,
    LinearGradient? filterGradient,
    LinearGradient? cardGradient,
    LinearGradient? navGradient,
    LinearGradient? goldGradient,
  }) {
    return CineThemeColors(
      isLight: isLight ?? this.isLight,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      softSurface: softSurface ?? this.softSurface,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
      mutedSurface: mutedSurface ?? this.mutedSurface,
      overlaySurface: overlaySurface ?? this.overlaySurface,
      card: card ?? this.card,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      icon: icon ?? this.icon,
      iconMuted: iconMuted ?? this.iconMuted,
      border: border ?? this.border,
      borderMuted: borderMuted ?? this.borderMuted,
      goldLight: goldLight ?? this.goldLight,
      goldMid: goldMid ?? this.goldMid,
      goldDark: goldDark ?? this.goldDark,
      goldGlow: goldGlow ?? this.goldGlow,
      shadow: shadow ?? this.shadow,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      infoBlue: infoBlue ?? this.infoBlue,
      infoPurple: infoPurple ?? this.infoPurple,
      danger: danger ?? this.danger,
      onGold: onGold ?? this.onGold,
      porcelain: porcelain ?? this.porcelain,
      holographicTeal: holographicTeal ?? this.holographicTeal,
      holographicCyan: holographicCyan ?? this.holographicCyan,
      focusRing: focusRing ?? this.focusRing,
      surfaceHighlight: surfaceHighlight ?? this.surfaceHighlight,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      glassGradient: glassGradient ?? this.glassGradient,
      searchGradient: searchGradient ?? this.searchGradient,
      activeChipGradient: activeChipGradient ?? this.activeChipGradient,
      inactiveChipGradient: inactiveChipGradient ?? this.inactiveChipGradient,
      filterGradient: filterGradient ?? this.filterGradient,
      cardGradient: cardGradient ?? this.cardGradient,
      navGradient: navGradient ?? this.navGradient,
      goldGradient: goldGradient ?? this.goldGradient,
    );
  }

  @override
  ThemeExtension<CineThemeColors> lerp(
    covariant ThemeExtension<CineThemeColors>? other,
    double t,
  ) {
    if (other is! CineThemeColors) return this;

    return CineThemeColors(
      isLight: t < 0.5 ? isLight : other.isLight,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      softSurface: Color.lerp(softSurface, other.softSurface, t)!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
      mutedSurface: Color.lerp(mutedSurface, other.mutedSurface, t)!,
      overlaySurface: Color.lerp(overlaySurface, other.overlaySurface, t)!,
      card: Color.lerp(card, other.card, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      icon: Color.lerp(icon, other.icon, t)!,
      iconMuted: Color.lerp(iconMuted, other.iconMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderMuted: Color.lerp(borderMuted, other.borderMuted, t)!,
      goldLight: Color.lerp(goldLight, other.goldLight, t)!,
      goldMid: Color.lerp(goldMid, other.goldMid, t)!,
      goldDark: Color.lerp(goldDark, other.goldDark, t)!,
      goldGlow: Color.lerp(goldGlow, other.goldGlow, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      infoBlue: Color.lerp(infoBlue, other.infoBlue, t)!,
      infoPurple: Color.lerp(infoPurple, other.infoPurple, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onGold: Color.lerp(onGold, other.onGold, t)!,
      porcelain: Color.lerp(porcelain, other.porcelain, t)!,
      holographicTeal: Color.lerp(holographicTeal, other.holographicTeal, t)!,
      holographicCyan: Color.lerp(holographicCyan, other.holographicCyan, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      surfaceHighlight:
          Color.lerp(surfaceHighlight, other.surfaceHighlight, t)!,
      backgroundGradient:
          LinearGradient.lerp(backgroundGradient, other.backgroundGradient, t)!,
      glassGradient:
          LinearGradient.lerp(glassGradient, other.glassGradient, t)!,
      searchGradient:
          LinearGradient.lerp(searchGradient, other.searchGradient, t)!,
      activeChipGradient:
          LinearGradient.lerp(activeChipGradient, other.activeChipGradient, t)!,
      inactiveChipGradient: LinearGradient.lerp(
          inactiveChipGradient, other.inactiveChipGradient, t)!,
      filterGradient:
          LinearGradient.lerp(filterGradient, other.filterGradient, t)!,
      cardGradient: LinearGradient.lerp(cardGradient, other.cardGradient, t)!,
      navGradient: LinearGradient.lerp(navGradient, other.navGradient, t)!,
      goldGradient: LinearGradient.lerp(goldGradient, other.goldGradient, t)!,
    );
  }

  /// Iridescent teal-to-cyan accent for premium/AI-adjacent surfaces
  /// (assistant orb, smart-suggestion chips) — kept separate from the
  /// gold brand gradient so it reads as a distinct "intelligence" cue.
  LinearGradient get holographicGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [holographicTeal, holographicCyan],
      );
}
