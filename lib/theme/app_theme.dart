import 'package:flutter/material.dart';

import 'app_text_styles.dart';

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
  final Color infoBlue;
  final Color infoPurple;
  final Color onGold;
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
    required this.infoBlue,
    required this.infoPurple,
    required this.onGold,
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
    background: Color(0xFFFAF8F3),
    surface: Color(0xFFFFFFFF),
    softSurface: Color(0xFFF7F4EE),
    card: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF16171A),
    textSecondary: Color(0xFF6F7278),
    textTertiary: Color(0xFF96989D),
    icon: Color(0xFF363A40),
    iconMuted: Color(0xFF70737A),
    border: Color(0xFFE8E1D6),
    borderMuted: Color(0xFFF0EAE1),
    goldLight: Color(0xFFE8B85A),
    goldMid: Color(0xFFD89A28),
    goldDark: Color(0xFFB97816),
    goldGlow: Color(0x33D89A28),
    shadow: Color(0x240F1720),
    success: Color(0xFF20D37A),
    infoBlue: Color(0xFF2785DF),
    infoPurple: Color(0xFF9D3DDF),
    onGold: Color(0xFFFFFFFF),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFFEFB),
        Color(0xFFFAF8F3),
        Color(0xFFF7F4EE),
      ],
    ),
    glassGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xF7FFFFFF), Color(0xEBFBF8F2), Color(0xF2FFFFFF)],
    ),
    searchGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xF7FBF8F2), Color(0xFFFFFFFF)],
    ),
    activeChipGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFFFFAEF), Color(0xFFFFFFFF)],
    ),
    inactiveChipGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xF8FBF9F5), Color(0xFFFFFFFF)],
    ),
    filterGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFAFBF8F2), Color(0xFFFFFFFF)],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFFDFBF8), Color(0xFFFFFFFF)],
    ),
    navGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xF8FFFFFF), Color(0xF2FBF8F3)],
    ),
    goldGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE8B85A), Color(0xFFD89A28), Color(0xFFB97816)],
    ),
  );

  static const dark = CineThemeColors(
    isLight: false,
    background: Color(0xFF050607),
    surface: Color(0xFF0B0F12),
    softSurface: Color(0xFF101418),
    card: Color(0xFF0B0F12),
    textPrimary: Color(0xFFF7F3EA),
    textSecondary: Color(0xFFAAA39A),
    textTertiary: Color(0xFF756F68),
    icon: Color(0xFFF7F3EA),
    iconMuted: Color(0xFFAAA39A),
    border: Color(0xFF2A2D30),
    borderMuted: Color(0xFF1A2028),
    goldLight: Color(0xFFF4C76A),
    goldMid: Color(0xFFE2A52E),
    goldDark: Color(0xFFC88A1E),
    goldGlow: Color(0x44C88A1E),
    shadow: Color(0x99000000),
    success: Color(0xFF20D37A),
    infoBlue: Color(0xFF5AA9FF),
    infoPurple: Color(0xFFC078FF),
    onGold: Color(0xFF17120A),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF050607),
        Color(0xFF06080A),
        Color(0xFF090C0F),
        Color(0xFF050607),
      ],
      stops: [0.0, 0.42, 0.72, 1.0],
    ),
    glassGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xD10A0E12), Color(0xB310151A), Color(0xA007090B)],
    ),
    searchGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xEA0B0E11), Color(0xD111161A), Color(0xF007090B)],
      stops: [0.0, 0.52, 1.0],
    ),
    activeChipGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xEA0A0D10), Color(0xD1111417), Color(0xA1090A0B)],
    ),
    inactiveChipGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xD10A0E12), Color(0xB311161B), Color(0xA007090B)],
    ),
    filterGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xDE0A0E12), Color(0xC210151A), Color(0xB0080A0D)],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF07090B), Color(0xFF0B0F12), Color(0xCC101418)],
    ),
    navGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xEE0C1014), Color(0xF807090B)],
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
    Color? infoBlue,
    Color? infoPurple,
    Color? onGold,
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
      infoBlue: infoBlue ?? this.infoBlue,
      infoPurple: infoPurple ?? this.infoPurple,
      onGold: onGold ?? this.onGold,
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
      infoBlue: Color.lerp(infoBlue, other.infoBlue, t)!,
      infoPurple: Color.lerp(infoPurple, other.infoPurple, t)!,
      onGold: Color.lerp(onGold, other.onGold, t)!,
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
}

/// Global ThemeData for CineConnect.
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
