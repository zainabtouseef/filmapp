import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../cards/cine_card_system.dart';

/// Dashboard-kit metric card with a small sparkline (polyline + end dot)
/// beside a value/delta/label column.
class PortalSparklineCard extends StatelessWidget {
  final String value;
  final String? delta;
  final String label;

  /// Series of 0..1-normalized points; rendered left-to-right.
  final List<double> series;

  const PortalSparklineCard({
    super.key,
    required this.value,
    required this.label,
    required this.series,
    this.delta,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CardShell(
      radius: AppRadius.panel,
      density: CardDensity.compact,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: AppTextStyles.metricNumberCompact
                          .copyWith(color: colors.textPrimary, fontSize: 22),
                    ),
                    if (delta != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        delta!,
                        style: AppTextStyles.smallMeta.copyWith(
                          color: colors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta
                      .copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 76,
            height: 40,
            child: CustomPaint(
              painter: _SparklinePainter(
                series: series,
                color: colors.goldMid,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> series;
  final Color color;

  const _SparklinePainter({required this.series, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (series.length < 2) return;
    final path = Path();
    final step = size.width / (series.length - 1);
    for (var i = 0; i < series.length; i++) {
      final x = i * step;
      final y = size.height - (series[i].clamp(0.0, 1.0) * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    canvas.drawPath(path, linePaint);

    final lastX = (series.length - 1) * step;
    final lastY = size.height - (series.last.clamp(0.0, 1.0) * size.height);
    canvas.drawCircle(Offset(lastX, lastY), 3.2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.series != series || oldDelegate.color != color;
}
