import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../cards/mini_trend_card.dart';
import '../layout/admin_section_header.dart';

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
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surface.withValues(alpha: colors.isLight ? 0.9 : 0.78),
            Colors.black.withValues(alpha: colors.isLight ? 0.02 : 0.23),
            colors.infoBlue.withValues(alpha: colors.isLight ? 0.04 : 0.025),
          ],
        ),
        border: Border.all(
          color:
              colors.textPrimary.withValues(alpha: colors.isLight ? 0.1 : 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isLight ? 0.08 : 0.34),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          if (quiet)
            Row(
              children: [
                Icon(icon, size: 15, color: colors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.panelLabel
                        .copyWith(color: colors.textSecondary),
                  ),
                ),
                if (actionText != null)
                  GestureDetector(
                    onTap: onActionTap,
                    child: Text(
                      actionText!,
                      style: AppTextStyles.sectionAction
                          .copyWith(color: colors.goldDark, fontSize: 12),
                    ),
                  ),
              ],
            )
          else
            AdminSectionHeader(
              title: title,
              icon: icon,
              actionText: actionText,
              onActionTap: onActionTap,
              iconColor: colors.textPrimary,
            ),
          const SizedBox(height: 12),
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
