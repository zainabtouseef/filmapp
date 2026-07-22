import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/cards/cine_card_system.dart';
import '../dp_status_chip.dart';
import 'dp_dashboard_insights.dart';

/// The Priority Action Centre — every item is a live, tappable item
/// derived from real data state (see [dpPriorityItems]), grouped by
/// urgency instead of a flat, hardcoded list.
class DPPriorityActions extends StatelessWidget {
  const DPPriorityActions({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final items = dpPriorityItems();
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

    const order = ['Critical', 'Due today', 'Waiting on you', 'Expiring soon'];
    final grouped = <String, List<DpPriorityItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.urgency, () => []).add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final urgency in order)
          if (grouped[urgency] case final group?) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 7, top: 2),
              child: Text(
                urgency.toUpperCase(),
                style: AppTextStyles.micro.copyWith(color: colors.textTertiary),
              ),
            ),
            for (final item in group) _PriorityTile(item: item),
            const SizedBox(height: 4),
          ],
      ],
    );
  }
}

class _PriorityTile extends StatelessWidget {
  final DpPriorityItem item;

  const _PriorityTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PriorityActionCard(
        title: item.title,
        metadata: item.subtitle,
        priority: item.urgency,
        icon: item.icon,
        tone: cineToneFromColor(context, dpToneColor(context, item.tone)),
        onTap: () => Navigator.pushNamed(
          context,
          item.route,
          arguments: item.argument,
        ),
      ),
    );
  }
}
