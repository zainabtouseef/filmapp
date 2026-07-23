import 'package:flutter/material.dart';

import '../../../../core/director/director_dashboard_models.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../routes/director_producer_routes.dart';
import '../dp_glass_card.dart';
import '../dp_status_chip.dart';

/// "Needs your attention" — a compact preview of the three highest-priority
/// items, with the full list available from the parent section action.
class DPPriorityActions extends StatelessWidget {
  final List<DirectorPriorityAction> items;

  const DPPriorityActions({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final previewItems = items.take(3).toList();
    if (items.isEmpty) {
      return Row(
        children: [
          Icon(Icons.check_circle_outline_rounded,
              color: colors.success, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'All caught up — nothing needs your attention right now.',
              style:
                  AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        for (var i = 0; i < previewItems.length; i++) ...[
          _PriorityCard(item: previewItems[i]),
          if (i != previewItems.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PriorityCard extends StatelessWidget {
  final DirectorPriorityAction item;

  const _PriorityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = dpToneColor(context, item.dpTone);
    final route = item.route.contains(':id')
        ? DirectorProducerRoutes.projectDetail
        : item.route;
    return DPGlassCard(
      accentColor: color,
      padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
      onTap: () => Navigator.pushNamed(
        context,
        route,
        arguments: item.argument,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DpDotLabel(
                  label: item.urgency.toUpperCase(),
                  tone: item.dpTone,
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption
                      .copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: colors.iconMuted, size: 22),
        ],
      ),
    );
  }
}
