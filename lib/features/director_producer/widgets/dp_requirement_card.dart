import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/dp_requirement.dart';
import 'dp_glass_card.dart';
import 'dp_holographic_button.dart';
import 'dp_status_chip.dart';

class DPRequirementCard extends StatelessWidget {
  final DpRequirement requirement;
  final VoidCallback? onFindMatches;

  const DPRequirementCard({
    super.key,
    required this.requirement,
    this.onFindMatches,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, color: colors.goldDark, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  requirement.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DPStatusChip(label: requirement.category, tone: DpTone.info),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            requirement.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DPStatusChip(
                  label: requirement.budgetRange, tone: DpTone.warning),
              DPStatusChip(label: requirement.dates, tone: DpTone.neutral),
              DPStatusChip(
                label: '${requirement.candidateCount} matches',
                tone: DpTone.success,
              ),
            ],
          ),
          const SizedBox(height: 9),
          DPHolographicButton(
            label: 'Find Matches',
            icon: Icons.manage_search_rounded,
            onTap: onFindMatches,
          ),
        ],
      ),
    );
  }

  IconData get _icon {
    return switch (requirement.category) {
      'Roles' => Icons.theater_comedy_outlined,
      'Models' => Icons.face_retouching_natural,
      'Locations' => Icons.location_city_outlined,
      'Media & Equipment' => Icons.videocam_outlined,
      'Crew' => Icons.groups_2_outlined,
      _ => Icons.auto_awesome_rounded,
    };
  }
}
