import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class DPV3Palette {
  final bool dark;
  final Color background;
  final Color card;
  final Color cardAlt;
  final Color line;
  final Color lineSoft;
  final Color ink;
  final Color inkSoft;
  final Color muted;
  final Color gold;
  final Color goldFill;
  final Color goldLight;
  final Color goldSoft;
  final Color goldTint;
  final Color positive;
  final Color warning;
  final Color negative;
  final Color info;
  final Color violet;
  final Color glass;
  final Color glassLine;
  final Color holoBorder;
  final Color ice;
  final Color mint;
  final Color lavender;
  final Color peach;

  const DPV3Palette({
    required this.dark,
    required this.background,
    required this.card,
    required this.cardAlt,
    required this.line,
    required this.lineSoft,
    required this.ink,
    required this.inkSoft,
    required this.muted,
    required this.gold,
    required this.goldFill,
    required this.goldLight,
    required this.goldSoft,
    required this.goldTint,
    required this.positive,
    required this.warning,
    required this.negative,
    required this.info,
    required this.violet,
    required this.glass,
    required this.glassLine,
    required this.holoBorder,
    required this.ice,
    required this.mint,
    required this.lavender,
    required this.peach,
  });

  static DPV3Palette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkMode : light;
  }

  static const light = DPV3Palette(
    dark: false,
    background: Color(0xFFF5F3EE),
    card: Color(0xFFFFFFFF),
    cardAlt: Color(0xFFFAF8F3),
    line: Color(0x1717150E),
    lineSoft: Color(0x0D17150E),
    ink: Color(0xFF17150E),
    inkSoft: Color(0xFF4A4539),
    muted: Color(0xFF857F6E),
    gold: Color(0xFF9C7614),
    goldFill: Color(0xFFD3B55F),
    goldLight: Color(0xFFE9D08A),
    goldSoft: Color(0xFFF8F1DE),
    goldTint: Color(0xFFF3E8CB),
    positive: Color(0xFF2F7A4C),
    warning: Color(0xFFA66A14),
    negative: Color(0xFFB0402F),
    info: Color(0xFF2F6690),
    violet: Color(0xFF6150A8),
    glass: Color(0x9EFFFFFF),
    glassLine: Color(0x2E9C7614),
    holoBorder: Color(0xF2FFFFFF),
    ice: Color(0xFF8EC3E6),
    mint: Color(0xFF93D3AE),
    lavender: Color(0xFFB7A8EC),
    peach: Color(0xFFEDB79D),
  );

  static const darkMode = DPV3Palette(
    dark: true,
    background: Color(0xFF070708),
    card: Color(0xFF111113),
    cardAlt: Color(0xFF161618),
    line: Color(0x14FFFFFF),
    lineSoft: Color(0x0BFFFFFF),
    ink: Color(0xFFF4F1E8),
    inkSoft: Color(0xFFC7C1B1),
    muted: Color(0xFF8C8778),
    gold: Color(0xFFE6C46C),
    goldFill: Color(0xFFD4AF37),
    goldLight: Color(0xFFF0D78C),
    goldSoft: Color(0x21D4AF37),
    goldTint: Color(0x38D4AF37),
    positive: Color(0xFF6CB887),
    warning: Color(0xFFDDA75A),
    negative: Color(0xFFE07F6D),
    info: Color(0xFF7EAAD0),
    violet: Color(0xFFA395E6),
    glass: Color(0x0EFFFFFF),
    glassLine: Color(0x38D4AF37),
    holoBorder: Color(0x33FFFFFF),
    ice: Color(0xFFA9D4F2),
    mint: Color(0xFFA8E0C0),
    lavender: Color(0xFFC9BDF5),
    peach: Color(0xFFF2C6B2),
  );

  LinearGradient get heroGradient => dark
      ? const LinearGradient(
          begin: Alignment(-1, -0.7),
          end: Alignment(1, 0.7),
          colors: [Color(0xFF1B160B), Color(0xFF0D0C0A), Color(0xFF1D170B)],
          stops: [0, .5, 1],
        )
      : const LinearGradient(
          begin: Alignment(-1, -0.7),
          end: Alignment(1, 0.7),
          colors: [Color(0xFFF2E4BF), Color(0xFFFBF6E8), Color(0xFFF4E7C4)],
          stops: [0, .48, 1],
        );

  LinearGradient get cinePlannerGradient => dark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF17171A), Color(0xFF121214)],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFFAF7F0), Color(0xFFF4F6F8)],
        );

  LinearGradient get holographic => dark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x1AFFFFFF),
            Color(0x218CBFFF),
            Color(0x1CFF96DC),
            Color(0x26FFD778),
            Color(0x14FFFFFF),
          ],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xCCFFFFFF),
            Color(0x99D2EAFF),
            Color(0x8CFFDDF6),
            Color(0xB3FFF2CC),
            Color(0xCCFFFFFF),
          ],
        );

  List<BoxShadow> get softShadow => [
        BoxShadow(
          color: dark ? const Color(0xA6000000) : const Color(0x2616130A),
          blurRadius: dark ? 34 : 32,
          spreadRadius: -20,
          offset: const Offset(0, 14),
        ),
        if (!dark)
          const BoxShadow(
            color: Color(0x0A16130A),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
      ];

  List<BoxShadow> get posterShadow => [
        BoxShadow(
          color: dark ? const Color(0xC9000000) : const Color(0x4216130A),
          blurRadius: 42,
          spreadRadius: -18,
          offset: const Offset(0, 20),
        ),
      ];
}

TextStyle dpV3Sans(
  double size,
  DPV3Palette p, {
  FontWeight weight = FontWeight.w500,
  double? height,
  double? letterSpacing,
  Color? color,
  FontStyle? fontStyle,
}) {
  return GoogleFonts.archivo(
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacing,
    color: color ?? p.ink,
    fontStyle: fontStyle,
  );
}

TextStyle dpV3Serif(
  double size,
  DPV3Palette p, {
  FontWeight weight = FontWeight.w600,
  double? height,
  double? letterSpacing,
  Color? color,
  FontStyle? fontStyle,
}) {
  return GoogleFonts.newsreader(
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacing,
    color: color ?? p.ink,
    fontStyle: fontStyle,
  );
}
