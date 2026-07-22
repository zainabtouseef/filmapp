import 'package:flutter/material.dart';

import '../cards/cine_card_system.dart';
import '../cards/mini_trend_card.dart';

class AdminLiveMonitoringSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onActionTap;
  final List<MiniTrendMetric> metrics;

  /// Use the light [AppTextStyles.panelLabel] treatment instead of the
  /// full [AdminSectionHeader] — for screens that already show a heavier
  /// heading above this section (e.g. a page title + another section
  /// header), so this doesn't read as a third equally-loud heading.
  final bool quiet;

  const AdminLiveMonitoringSection({
    super.key,
    required this.title,
    required this.metrics,
    this.icon = Icons.monitor_heart_outlined,
    this.actionText,
    this.onActionTap,
    this.quiet = false,
  });

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: title,
      leading: IconBadge(
        icon: icon,
        tone: CineTone.information,
        compact: true,
      ),
      action: actionText == null
          ? null
          : TextButton(onPressed: onActionTap, child: Text(actionText!)),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final gap = constraints.maxWidth < 420 ? 9.0 : 10.0;
              final rawTileWidth = (constraints.maxWidth - gap) / 2;
              final tileWidth = rawTileWidth < 0 ? 0.0 : rawTileWidth;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: metrics
                    .map(
                      (metric) => SizedBox(
                        width: tileWidth,
                        child: MiniTrendCard(metric: metric),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
