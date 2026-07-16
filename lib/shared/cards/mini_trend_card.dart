import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/mini_line_chart.dart';

class MiniTrendMetric {
  final String label;
  final String value;
  final List<double> trendValues;
  final Color accentColor;

  const MiniTrendMetric({
    required this.label,
    required this.value,
    required this.trendValues,
    required this.accentColor,
  });
}

class MiniTrendCard extends StatelessWidget {
  final MiniTrendMetric metric;

  const MiniTrendCard({
    super.key,
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      height: 98,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surface.withValues(alpha: colors.isLight ? 0.86 : 0.58),
            Colors.black.withValues(alpha: colors.isLight ? 0.02 : 0.18),
          ],
        ),
        border: Border.all(
          color: colors.textPrimary
              .withValues(alpha: colors.isLight ? 0.09 : 0.08),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                child: Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 28,
                child: Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMetricNumber.copyWith(
                    color: colors.textPrimary,
                    fontSize: metric.value.length > 4 ? 19 : 22,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: constraints.maxHeight * 0.4,
                child: MiniLineChart(
                  values: metric.trendValues,
                  color: metric.accentColor,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
