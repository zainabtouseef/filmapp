import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/director_producer_demo_data.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';

class DPBargainingCenterScreen extends StatelessWidget {
  const DPBargainingCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final negotiations = DirectorProducerDemoData.negotiations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dpHeaderAction(
          context,
          icon: Icons.forum_outlined,
          label: 'Thread',
          onTap: () => Navigator.pushNamed(
            context,
            DirectorProducerRoutes.negotiationThread,
            arguments: negotiations.first.id,
          ),
        ),
        const SizedBox(height: 8),
        DPResponsiveGrid(
          minWidth: 300,
          children: negotiations
              .map(
                (negotiation) => _NegotiationCard(
                  title: negotiation.candidate,
                  project: negotiation.project,
                  subtitle: negotiation.requirement,
                  rate: negotiation.currentRate,
                  status: negotiation.status,
                  expiry: negotiation.expiry,
                  onTap: () => Navigator.pushNamed(
                    context,
                    DirectorProducerRoutes.negotiationThread,
                    arguments: negotiation.id,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _NegotiationCard extends StatelessWidget {
  final String title;
  final String project;
  final String subtitle;
  final String rate;
  final String status;
  final String expiry;
  final VoidCallback onTap;

  const _NegotiationCard({
    required this.title,
    required this.project,
    required this.subtitle,
    required this.rate,
    required this.status,
    required this.expiry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tone = status == 'Your move'
        ? DpTone.warning
        : status == 'Accepted'
            ? DpTone.success
            : status == 'Expiring'
                ? DpTone.danger
                : DpTone.info;
    return GestureDetector(
      onTap: onTap,
      child: DPGlassCard(
        selected: status == 'Your move' || status == 'Expiring',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: dpText(context, title, strong: true)),
                DPStatusChip(label: status, tone: tone),
              ],
            ),
            const SizedBox(height: 6),
            dpText(context, '$project - $subtitle'),
            const SizedBox(height: 9),
            Row(
              children: [
                Text(
                  rate,
                  style: AppTextStyles.metricNumberCompact
                      .copyWith(color: colors.textPrimary),
                ),
                const Spacer(),
                DPStatusChip(label: expiry, tone: DpTone.warning),
              ],
            ),
            const SizedBox(height: 9),
            DPHolographicButton(
              label: 'Open Negotiation',
              icon: Icons.chat_bubble_outline_rounded,
              onTap: onTap,
              secondary: true,
            ),
          ],
        ),
      ),
    );
  }
}
