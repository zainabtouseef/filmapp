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
    background: Color(0xFFF7F5F0),
    surface: Color(0xFFFBFAF6),
    softSurface: Color(0xFFF3EFE5),
    elevatedSurface: Color(0xFFFFFFFF),
    mutedSurface: Color(0xFFECE8DF),
    overlaySurface: Color(0xF2FFFFFF),
    card: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF17150E),
    textSecondary: Color(0xFF4A463B),
    textTertiary: Color(0xFF8A8475),
    icon: Color(0xFF302B20),
    iconMuted: Color(0xFF8A8475),
    border: Color(0x1A17150E),
    borderMuted: Color(0x0F17150E),
    goldLight: Color(0xFFEBD48F),
    goldMid: Color(0xFFD3B55F),
    goldDark: Color(0xFF9C7614),
    goldGlow: Color(0x45D3B55F),
    shadow: Color(0x2416130A),
    success: Color(0xFF3C7A55),
    warning: Color(0xFFA06B1F),
    infoBlue: Color(0xFF3F6E8F),
    infoPurple: Color(0xFF5E52A0),
    danger: Color(0xFFA0593C),
    onGold: Color(0xFF1A1408),
    porcelain: Color(0xFFF8F1DE),
    holographicTeal: Color(0xFF83BDD1),
    holographicCyan: Color(0xFFB8DDEE),
    focusRing: Color(0xFFB88D2A),
    surfaceHighlight: Color(0xFFFFFFFF),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFF7F5F0),
        Color(0xFFF3EFE7),
        Color(0xFFECE8DF),
      ],
    ),
    glassGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xF7FFFFFF), Color(0xEAF9F7F0), Color(0xF2FFFFFF)],
    ),
    searchGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xF7FFFFFF), Color(0xEAF8F4EA), Color(0xF2FFFFFF)],
    ),
    activeChipGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFEBD48F), Color(0xFFD3B55F), Color(0xFFC39B39)],
    ),
    inactiveChipGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xF5FFFFFF), Color(0xEEF8F5ED), Color(0xF5FFFFFF)],
    ),
    filterGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xF5FFFFFF), Color(0xEEF8F5ED), Color(0xF5FFFFFF)],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFFBFAF6), Color(0xFFFFFFFF)],
    ),
    navGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xF7FFFFFF), Color(0xF2FBFAF6)],
    ),
    goldGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFEBD48F), Color(0xFFD3B55F), Color(0xFFB88D2A)],
    ),
  );

  static const dark = CineThemeColors(
    isLight: false,
    background: Color(0xFF09090B),
    surface: Color(0xFF101013),
    softSurface: Color(0xFF17171B),
    elevatedSurface: Color(0xFF131316),
    mutedSurface: Color(0xFF1B1B20),
    overlaySurface: Color(0xF2141418),
    card: Color(0xFF131316),
    textPrimary: Color(0xFFF3F0E7),
    textSecondary: Color(0xFFC6C0B0),
    textTertiary: Color(0xFF8B8677),
    icon: Color(0xFFF3F0E7),
    iconMuted: Color(0xFF969181),
    border: Color(0x20FFFFFF),
    borderMuted: Color(0x12FFFFFF),
    goldLight: Color(0xFFEDD48A),
    goldMid: Color(0xFFD4AF37),
    goldDark: Color(0xFFE5C46E),
    goldGlow: Color(0x45D4AF37),
    shadow: Color(0xB0000000),
    success: Color(0xFF8FD3A9),
    warning: Color(0xFFDCC27A),
    infoBlue: Color(0xFF8FC2E6),
    infoPurple: Color(0xFFB2A4EC),
    danger: Color(0xFFE8AE94),
    onGold: Color(0xFF16120A),
    porcelain: Color(0xFF202024),
    holographicTeal: Color(0xFF8FCFE0),
    holographicCyan: Color(0xFFA9DFF0),
    focusRing: Color(0xFFE5C46E),
    surfaceHighlight: Color(0xFF24242A),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF030304),
        Color(0xFF09090B),
        Color(0xFF0E0E12),
        Color(0xFF09090B),
      ],
      stops: [0.0, 0.34, 0.72, 1.0],
    ),
    glassGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x18FFFFFF), Color(0x0F8FC2E6), Color(0x12B2A4EC)],
    ),
    searchGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF17171B), Color(0xFF131316), Color(0xFF17171B)],
    ),
    activeChipGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFEDD48A), Color(0xFFD4AF37), Color(0xFFB88D2A)],
    ),
    inactiveChipGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF17171B), Color(0xFF131316), Color(0xFF17171B)],
    ),
    filterGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF17171B), Color(0xFF131316), Color(0xFF17171B)],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF17171B), Color(0xFF131316), Color(0xFF101013)],
    ),
    navGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xF217171B), Color(0xF2131316)],
    ),
    goldGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFEDD48A), Color(0xFFD4AF37), Color(0xFFB88D2A)],
    ),
  );

  @override
  CineThemeColors copyWith({
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
