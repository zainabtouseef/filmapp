import 'package:flutter/material.dart';

import '../../../../core/director/director_dashboard_models.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/cards/cine_card_system.dart';
import '../../../../shared/formatters/cine_format.dart';
import '../../routes/director_producer_routes.dart';
import '../dp_glass_card.dart';

/// Deals & Contracts — three pipeline-stage previews, with the complete
/// pipeline available from the parent section action.
class DPDealPipeline extends StatelessWidget {
  final List<DirectorPipelineItem> items;

  const DPDealPipeline({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final bookings = items.where((item) => item.kind == 'booking').toList();
    final contracts = items.where((item) => item.kind == 'contract').toList();
    final negotiating = bookings
        .where((item) =>
            ['sent', 'under_negotiation'].contains(item.status.toLowerCase()))
        .toList();
    final accepted = bookings
        .where((item) => ['accepted', 'confirmed', 'secured']
            .contains(item.status.toLowerCase()))
        .toList();
    final contractSent = contracts
        .where((item) => item.status.toLowerCase().contains('pending'))
        .toList();
    final signed = contracts
        .where((item) => item.status.toLowerCase().contains('signed'))
        .toList();

    int valueTotal(List<DirectorPipelineItem> stageItems) => stageItems
        .fold<int>(0, (sum, item) => sum + ((item.valueMinor ?? 0) ~/ 100));

    final stages = [
      _DealStageCard(
        label: 'Negotiating',
        tone: CineTone.warning,
        count: negotiating.length,
        total: valueTotal(negotiating),
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.bargaining),
      ),
      _DealStageCard(
        label: 'Offer accepted',
        tone: CineTone.information,
        count: accepted.length,
        total: valueTotal(accepted),
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.bargaining),
      ),
      _DealStageCard(
        label: 'Contract sent',
        tone: CineTone.premium,
        count: contractSent.length,
        total: valueTotal(contractSent),
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.contracts),
      ),
      _DealStageCard(
        label: 'Signed',
        tone: CineTone.positive,
        count: signed.length,
        total: valueTotal(signed),
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.contracts),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final columns = constraints.maxWidth >= 540
            ? 3
            : constraints.maxWidth >= 300
                ? 2
                : 1;
        final cardWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final stage in stages.take(3))
              SizedBox(width: cardWidth, child: stage),
          ],
        );
      },
    );
  }
}

class _DealStageCard extends StatelessWidget {
  final String label;
  final CineTone tone;
  final int count;
  final int total;
  final VoidCallback onTap;

  const _DealStageCard({
    required this.label,
    required this.tone,
    required this.count,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = cineToneColor(context, tone);
    return DPGlassCard(
      accentColor: color,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: AppTextStyles.heroSerifNumber.copyWith(
              color: colors.textPrimary,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${CineFormat.currency(total, compact: true)} total',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(color: colors.textTertiary),
          ),
        ],
      ),
    );
  }
}
