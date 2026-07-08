import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';

/// The animated cinematic page background (gradient + gold glow +
/// vignette + subtle film-grain noise) used behind every dashboard.
class CinematicBackdrop extends StatelessWidget {
  const CinematicBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(gradient: colors.backgroundGradient),
      child: CustomPaint(
        painter: _CinematicBackdropPainter(colors),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CinematicBackdropPainter extends CustomPainter {
  final CineThemeColors colors;

  const _CinematicBackdropPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final goldPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          colors.goldGlow.withValues(alpha: colors.isLight ? 0.48 : 0.6),
          colors.goldGlow.withValues(alpha: colors.isLight ? 0.15 : 0.24),
          colors.goldGlow.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.28, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.88, size.height * 0.12),
          radius: size.width * 0.48,
        ),
      );
    canvas.drawRect(Offset.zero & size, goldPaint);

    final bluePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          colors.isLight ? const Color(0x14E8B85A) : const Color(0x20101A22),
          colors.isLight ? const Color(0x08FFFFFF) : const Color(0x10080F15),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.02, size.height * 0.42),
          radius: size.width * 0.64,
        ),
      );
    canvas.drawRect(Offset.zero & size, bluePaint);

    final topShadePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors.isLight
            ? const [
                Color(0x00FFFFFF),
                Color(0x0AF6E9D7),
                Color(0x18EDE2D4),
              ]
            : const [
                Color(0x00000000),
                Color(0x24000000),
                Color(0x4A000000),
              ],
        stops: [0.0, 0.52, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, topShadePaint);

    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.12,
        colors: colors.isLight
            ? const [
                Colors.transparent,
                Color(0x08B97816),
                Color(0x18B97816),
              ]
            : const [
                Colors.transparent,
                Color(0x66000000),
                Color(0xCC000000),
              ],
        stops: const [0.52, 0.82, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignettePaint);

    final noisePaint = Paint();
    for (var y = 0.0; y < size.height; y += 10) {
      for (var x = 0.0; x < size.width; x += 10) {
        final seed = ((x * 37 + y * 17).round() % 19);
        if (seed < 5) {
          noisePaint.color = (colors.isLight ? colors.goldDark : Colors.white)
              .withValues(
                  alpha: colors.isLight ? 0.006 : 0.007 + seed * 0.0015);
          canvas.drawCircle(
              Offset(x + seed, y + (seed * 0.7)), 0.45, noisePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CinematicBackdropPainter oldDelegate) =>
      oldDelegate.colors != colors;
}
