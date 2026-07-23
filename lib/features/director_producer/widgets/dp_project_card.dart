import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/dp_project.dart';
import 'dp_budget_health_bar.dart';
import 'dp_glass_card.dart';
import 'dp_holographic_button.dart';

Color _stageColor(BuildContext context, String status) {
  final colors = context.appColors;
  return switch (status) {
    'Shooting' => colors.success,
    'Casting' || 'Negotiating' => colors.goldMid,
    'Draft' => colors.textTertiary,
    _ => colors.infoBlue,
  };
}

class DPProjectCard extends StatelessWidget {
  final DpProject project;
  final VoidCallback? onOpen;

  const DPProjectCard({
    super.key,
    required this.project,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final urgent = project.pendingActions > 7;
    final stageColor = _stageColor(context, project.status);
    return DPGlassCard(
      selected: urgent,
      accentColor: stageColor,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (project.coverImageUrl?.isNotEmpty == true) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 16 / 7,
                  child: Image.network(
                    project.coverImageUrl!,
                    fit: BoxFit.cover,
                    semanticLabel: '${project.title} project cover',
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: colors.softSurface,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.movie_creation_outlined,
                        color: colors.iconMuted,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle.copyWith(
                          color: colors.textPrimary,
                          fontSize: 15.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${project.city} · ${project.dateRange}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.smallMeta
                            .copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _DotLabel(label: project.type, color: colors.goldDark),
              ],
            ),
            const SizedBox(height: 10),
            DPBudgetHealthBar(
              value: project.budgetHealth,
              label: 'Budget health',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 7,
              children: [
                _DotLabel(label: project.status, color: stageColor),
                _DotLabel(
                  label: '${project.pendingActions} actions',
                  color: project.pendingActions > 7
                      ? colors.danger
                      : colors.success,
                ),
                _DotLabel(
                  label: 'Shoot ${project.shootDate}',
                  color: colors.textTertiary,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(height: 1, color: colors.borderMuted),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${project.bookingsCount} bookings · ${project.contractsCount} contracts · ${project.paymentsStatus}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption
                        .copyWith(color: colors.textSecondary),
                  ),
                ),
                const SizedBox(width: 10),
                DPHolographicButton(
                  label: 'Open Hub',
                  icon: Icons.open_in_new_rounded,
                  onTap: onOpen,
                  secondary: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DotLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _DotLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption
              .copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
