import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../data/director_producer_demo_data.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';

class DPStakeholderProfileScreen extends StatelessWidget {
  final String? candidateId;

  const DPStakeholderProfileScreen({super.key, this.candidateId});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final candidates = DirectorProducerDemoData.candidates;
    final candidate = candidates.firstWhere(
      (item) => item.id == candidateId,
      orElse: () => candidates.first,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dpHeaderAction(
          context,
          icon: Icons.send_outlined,
          label: 'Request',
          onTap: () => Navigator.pushNamed(
            context,
            DirectorProducerRoutes.bookingRequest,
          ),
        ),
        const SizedBox(height: 8),
        DPGlassCard(
          selected: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: colors.goldGlow.withValues(alpha: 0.2),
                child: Text(
                  candidate.avatarLabel,
                  style: AppTextStyles.metricNumberCompact
                      .copyWith(color: colors.textPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.name,
                      style: AppTextStyles.cardTitle
                          .copyWith(color: colors.textPrimary),
                    ),
                    const SizedBox(height: 5),
                    dpText(
                        context, '${candidate.category} - ${candidate.city}'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        DPStatusChip(
                          label: candidate.rateRange,
                          tone: DpTone.warning,
                        ),
                        DPStatusChip(
                          label: '${candidate.rating} rating',
                          tone: DpTone.success,
                        ),
                        const DPStatusChip(
                          label: 'Verified',
                          tone: DpTone.success,
                          icon: Icons.verified_outlined,
                        ),
                        const DPStatusChip(
                          label: 'Available',
                          tone: DpTone.info,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        DPTwoColumn(
          left: DPSectionCard(
            title: 'Portfolio Snapshot',
            icon: Icons.auto_awesome_mosaic_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dpText(context, candidate.notes, strong: true),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final skill in candidate.skills)
                      DPStatusChip(label: skill, tone: DpTone.info),
                  ],
                ),
                const SizedBox(height: 14),
                _MiniPortfolioGrid(colors: colors),
              ],
            ),
          ),
          right: DPSectionCard(
            title: 'Booking Intelligence',
            icon: Icons.insights_rounded,
            child: Column(
              children: [
                MetricActionRail(
                  items: [
                    MetricActionItem(
                      icon: Icons.insights_outlined,
                      value: '2h 20m',
                      title: 'Response time',
                      subtitle: 'Current',
                      accentColor: colors.goldDark,
                    ),
                    MetricActionItem(
                      icon: Icons.insights_outlined,
                      value: '96%',
                      title: 'Completion history',
                      subtitle: 'Current',
                      accentColor: colors.goldDark,
                    ),
                    MetricActionItem(
                      icon: Icons.insights_outlined,
                      value: '0 open',
                      title: 'Contract disputes',
                      subtitle: 'Current',
                      accentColor: colors.goldDark,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DPHolographicButton(
                  label: 'Send Booking Request',
                  icon: Icons.send_rounded,
                  onTap: () => Navigator.pushNamed(
                    context,
                    DirectorProducerRoutes.bookingRequest,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniPortfolioGrid extends StatelessWidget {
  final CineThemeColors colors;

  const _MiniPortfolioGrid({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        6,
        (index) => Container(
          width: 92,
          height: 68,
          decoration: BoxDecoration(
            gradient: index.isEven ? colors.goldGradient : colors.cardGradient,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Icon(
            Icons.movie_filter_outlined,
            color: index.isEven ? colors.onGold : colors.goldDark,
            size: 22,
          ),
        ),
      ),
    );
  }
}
