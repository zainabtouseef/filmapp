import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/mini_line_chart.dart';
import 'cine_card_system.dart';

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
    return SizedBox(
      height: 108,
      child: CardShell(
        variant: CardVariant.compact,
        density: CardDensity.compact,
        tone: cineToneFromColor(context, metric.accentColor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metric.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardLabel.copyWith(
                color: colors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 5),
            MetricValue(value: metric.value),
            const SizedBox(height: 4),
            Expanded(
              child: MiniLineChart(
                values: metric.trendValues,
                color: metric.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
