import 'package:flutter/material.dart';

import '../../../../core/director/director_dashboard_models.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/cards/cine_card_system.dart';
import '../../../../shared/dashboard/dashboard_kit.dart';
import '../../routes/director_producer_routes.dart';
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
    final route = item.route.contains(':id')
        ? DirectorProducerRoutes.projectDetail
        : item.route;
    return PortalAttentionRow(
      kindLabel: item.urgency,
      title: item.title,
      meta: item.subtitle,
      icon: Icons.priority_high_rounded,
      tone: _cineToneFor(item.dpTone),
      onTap: () => Navigator.pushNamed(
        context,
        route,
        arguments: item.argument,
      ),
    );
  }
}

CineTone _cineToneFor(DpTone tone) => switch (tone) {
      DpTone.neutral => CineTone.neutral,
      DpTone.info => CineTone.information,
      DpTone.success => CineTone.positive,
      DpTone.warning => CineTone.warning,
      DpTone.danger => CineTone.critical,
      DpTone.purple => CineTone.information,
    };
