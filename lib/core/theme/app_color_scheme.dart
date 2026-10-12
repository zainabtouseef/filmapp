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
  final Color goldSoft;
  final Color goldTint;
  final Color shadow;
  final Color success;
  final Color warning;
  final Color infoBlue;
  final Color infoPurple;
  final Color danger;
  final Color onGold;
  final Color porcelain;
  final Color railBackground;
  final Color railForeground;
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
    required this.goldSoft,
    required this.goldTint,
    required this.shadow,
    required this.success,
    required this.warning,
    required this.infoBlue,
    required this.infoPurple,
    required this.danger,
    required this.onGold,
    required this.porcelain,
    required this.railBackground,
    required this.railForeground,
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
    background: Color(0xFFF5F3EE),
    surface: Color(0xFFFAF8F3),
    softSurface: Color(0xFFFAF8F3),
    elevatedSurface: Color(0xFFFFFFFF),
    mutedSurface: Color(0xFFF3E8CB),
    overlaySurface: Color(0xF7FFFFFF),
    card: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF17150E),
    textSecondary: Color(0xFF4A4539),
    textTertiary: Color(0xFF857F6E),
    icon: Color(0xFF17150E),
    iconMuted: Color(0xFF857F6E),
    border: Color(0x1717150E),
    borderMuted: Color(0x0D17150E),
    goldLight: Color(0xFFE9D08A),
    goldMid: Color(0xFFD3B55F),
    goldDark: Color(0xFF9C7614),
    goldGlow: Color(0x26D3B55F),
    goldSoft: Color(0xFFF8F1DE),
    goldTint: Color(0xFFF3E8CB),
    shadow: Color(0x2616130A),
    success: Color(0xFF2F7A4C),
    warning: Color(0xFFA66A14),
    infoBlue: Color(0xFF2F6690),
    infoPurple: Color(0xFF6150A8),
    danger: Color(0xFFB0402F),
    onGold: Color(0xFF1A1408),
    porcelain: Color(0xFFF5F3EE),
    railBackground: Color(0xFFFFFFFF),
    railForeground: Color(0xFF17150E),
    holographicTeal: Color(0xFF247B75),
    holographicCyan: Color(0xFF3F9299),
    focusRing: Color(0xFF247B75),
    surfaceHighlight: Color(0xFFFFFFFF),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFF8F6F1),
        Color(0xFFF5F3EE),
        Color(0xFFF2EFE8),
      ],
    ),
    glassGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFFAF8F3), Color(0xFFFFFFFF)],
    ),
    searchGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFFAF8F3), Color(0xFFFFFFFF)],
    ),
    activeChipGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFF8F1DE), Color(0xFFFFFFFF)],
    ),
    inactiveChipGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFFAF8F3), Color(0xFFFFFFFF)],
    ),
    filterGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFFAF8F3), Color(0xFFFFFFFF)],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFFAF8F3), Color(0xFFFFFFFF)],
    ),
    navGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFFFFF), Color(0xFAFAF8F3)],
    ),
    goldGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE9D08A), Color(0xFFD3B55F), Color(0xFF9C7614)],
    ),
  );

  static const dark = CineThemeColors(
    isLight: false,
    background: Color(0xFF070708),
    surface: Color(0xFF111113),
    softSurface: Color(0xFF161618),
    elevatedSurface: Color(0xFF111113),
    mutedSurface: Color(0xFF161618),
    overlaySurface: Color(0xF5111113),
    card: Color(0xFF111113),
    textPrimary: Color(0xFFF4F1E8),
    textSecondary: Color(0xFFC7C1B1),
    textTertiary: Color(0xFF8C8778),
    icon: Color(0xFFF4F1E8),
    iconMuted: Color(0xFF8C8778),
    border: Color(0x14FFFFFF),
    borderMuted: Color(0x0DFFFFFF),
    goldLight: Color(0xFFF0D78C),
    goldMid: Color(0xFFD4AF37),
    goldDark: Color(0xFFE6C46C),
    goldGlow: Color(0x16D4AF37),
    goldSoft: Color(0x12D4AF37),
    goldTint: Color(0x1CD4AF37),
    shadow: Color(0x70000000),
    success: Color(0xFF6CB887),
    warning: Color(0xFFDDA75A),
    infoBlue: Color(0xFF7EAAD0),
    infoPurple: Color(0xFFA395E6),
    danger: Color(0xFFE07F6D),
    onGold: Color(0xFF15110A),
    porcelain: Color(0xFF2C3236),
    railBackground: Color(0xFF101013),
    railForeground: Color(0xFFE9E3D3),
    holographicTeal: Color(0xFF5BB1A6),
    holographicCyan: Color(0xFF75C0C5),
    focusRing: Color(0xFFD4AF37),
    surfaceHighlight: Color(0xFF17171B),
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
    Color? goldSoft,
    Color? goldTint,
    Color? shadow,
    Color? success,
    Color? warning,
    Color? infoBlue,
    Color? infoPurple,
    Color? danger,
    Color? onGold,
    Color? porcelain,
    Color? railBackground,
    Color? railForeground,
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
      goldSoft: goldSoft ?? this.goldSoft,
      goldTint: goldTint ?? this.goldTint,
      shadow: shadow ?? this.shadow,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      infoBlue: infoBlue ?? this.infoBlue,
      infoPurple: infoPurple ?? this.infoPurple,
      danger: danger ?? this.danger,
      onGold: onGold ?? this.onGold,
      porcelain: porcelain ?? this.porcelain,
      railBackground: railBackground ?? this.railBackground,
      railForeground: railForeground ?? this.railForeground,
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
      goldSoft: Color.lerp(goldSoft, other.goldSoft, t)!,
      goldTint: Color.lerp(goldTint, other.goldTint, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      infoBlue: Color.lerp(infoBlue, other.infoBlue, t)!,
      infoPurple: Color.lerp(infoPurple, other.infoPurple, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onGold: Color.lerp(onGold, other.onGold, t)!,
      porcelain: Color.lerp(porcelain, other.porcelain, t)!,
      railBackground: Color.lerp(railBackground, other.railBackground, t)!,
      railForeground: Color.lerp(railForeground, other.railForeground, t)!,
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

  /// Ambient top-left glow behind hero/feature cards — a dark-mode-only
  /// accent (the design spec explicitly turns this off in light mode),
  /// so it's derived from [isLight] rather than a stored field.
  Gradient get ambientGlow => isLight
      ? const RadialGradient(colors: [Colors.transparent, Colors.transparent])
      : RadialGradient(
          center: const Alignment(-0.85, -0.9),
          radius: 1.4,
          colors: [goldMid.withValues(alpha: 0.10), Colors.transparent],
        );

  /// Small blurred gold glow used under CTA underlines and hero accents.
  List<BoxShadow> get goldEdgeGlow => [
        BoxShadow(
          color: goldMid.withValues(alpha: 0.55),
          blurRadius: 10,
        ),
      ];
}
