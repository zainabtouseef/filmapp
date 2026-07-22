import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/director_producer_demo_data.dart';
import '../../models/dp_contract.dart';
import '../../models/dp_negotiation.dart';
import '../../routes/director_producer_routes.dart';
import '../dp_glass_card.dart';
import '../dp_status_chip.dart';

/// Deals and Contracts Pipeline — negotiations and contracts regrouped
/// into pipeline stages instead of two separate, unrelated lists.
class DPDealPipeline extends StatelessWidget {
  const DPDealPipeline({super.key});

  @override
  Widget build(BuildContext context) {
    final negotiations = DirectorProducerDemoData.negotiations;
    final contracts = DirectorProducerDemoData.contracts;

    final negotiating = negotiations
        .where(
            (n) => ['Their move', 'Your move', 'Expiring'].contains(n.status))
        .toList();
    final accepted = negotiations.where((n) => n.status == 'Accepted').toList();
    final contractSent =
        contracts.where((c) => c.status == 'Pending Signature').toList();
    final signed = contracts.where((c) => c.status == 'Signed').toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StageColumn(
            label: 'Negotiating',
            tone: DpTone.warning,
            children: [
              for (final n in negotiating.take(4)) _NegotiationCard(item: n),
            ],
          ),
          const SizedBox(width: 10),
          _StageColumn(
            label: 'Offer Accepted',
            tone: DpTone.info,
            children: [
              for (final n in accepted.take(4)) _NegotiationCard(item: n),
            ],
          ),
          const SizedBox(width: 10),
          _StageColumn(
            label: 'Contract Sent',
            tone: DpTone.purple,
            children: [
              for (final c in contractSent.take(4)) _ContractCard(item: c),
            ],
          ),
          const SizedBox(width: 10),
          _StageColumn(
            label: 'Signed',
            tone: DpTone.success,
            children: [
              for (final c in signed.take(4)) _ContractCard(item: c),
            ],
          ),
        ],
      ),
    );
  }
}

class _StageColumn extends StatelessWidget {
  final String label;
  final DpTone tone;
  final List<Widget> children;

  const _StageColumn({
    required this.label,
    required this.tone,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: 216,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dpToneColor(context, tone),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$label (${children.length})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.panelLabel
                      .copyWith(color: colors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (children.isEmpty)
            Text(
              'Nothing here.',
              style:
                  AppTextStyles.smallMeta.copyWith(color: colors.textTertiary),
            )
          else
            for (final child in children) ...[
              child,
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _NegotiationCard extends StatelessWidget {
  final DpNegotiation item;

  const _NegotiationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        DirectorProducerRoutes.negotiationThread,
        arguments: item.id,
      ),
      child: DPGlassCard(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.candidate,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardLabel
                    .copyWith(color: colors.textPrimary)),
            const SizedBox(height: 3),
            Text(
              item.project,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTextStyles.caption.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 6),
            DPStatusChip(label: item.currentRate, tone: DpTone.neutral),
          ],
        ),
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  final DpContract item;

  const _ContractCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, DirectorProducerRoutes.contracts),
      child: DPGlassCard(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.candidate,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardLabel
                    .copyWith(color: colors.textPrimary)),
            const SizedBox(height: 3),
            Text(
              item.project,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTextStyles.caption.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 6),
            DPStatusChip(label: item.value, tone: DpTone.neutral),
          ],
        ),
      ),
    );
  }
}
