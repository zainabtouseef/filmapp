import 'package:flutter/material.dart';

import '../../../../core/director/director_dashboard_models.dart';
import '../../../../shared/cards/cine_card_system.dart';
import '../../../../shared/dashboard/dashboard_kit.dart';
import '../../../../shared/formatters/cine_format.dart';

/// Deals & Contracts — all four real pipeline stages rendered as a
/// connected flow (see [PortalPipelineFlow]).
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

    final stageBuckets = <({
      String label,
      CineTone tone,
      List<DirectorPipelineItem> items,
    })>[
      (label: 'Negotiating', tone: CineTone.warning, items: negotiating),
      (label: 'Offer accepted', tone: CineTone.information, items: accepted),
      (label: 'Contract sent', tone: CineTone.premium, items: contractSent),
      (label: 'Signed', tone: CineTone.positive, items: signed),
    ];

    final stages = [
      for (final bucket in stageBuckets)
        PortalPipelineStage(
          value: '${bucket.items.length}',
          label: bucket.label,
          sublabel:
              '${CineFormat.currency(valueTotal(bucket.items), compact: true)} total',
          color: cineToneColor(context, bucket.tone),
        ),
    ];

    return PortalPipelineFlow(stages: stages);
  }
}
