import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/actor_talent_demo_data.dart';
import '../models/actor_talent_models.dart';
import '../routes/actor_talent_routes.dart';
import '../widgets/actor_talent_components.dart';

/// AT-11 Reputation & Reviews
class AT11ReputationReviewsScreen extends StatelessWidget {
  const AT11ReputationReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ActorSectionCard(
          title: 'Rating Breakdown',
          icon: Icons.stars_outlined,
          child: Column(
            children: const [
              _RatingBar(label: 'Punctuality', value: 0.96),
              _RatingBar(label: 'Response time', value: 0.88),
              _RatingBar(label: 'Professionalism', value: 0.94),
              _RatingBar(label: 'On-set collaboration', value: 0.91),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ActorTwoColumn(
          left: ActorSectionCard(
            title: 'Director Reviews',
            icon: Icons.rate_review_outlined,
            child: Column(
              children: [
                for (final review in ActorTalentDemoData.reviews)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ReviewCard(review: review),
                  ),
              ],
            ),
          ),
          right: ActorSectionCard(
            title: 'Trust Signals',
            icon: Icons.workspace_premium_outlined,
            child: Column(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusChip(
                        label: 'Verified KYC',
                        color: context.appColors.success),
                    StatusChip(
                        label: 'Fast reply', color: context.appColors.infoBlue),
                    StatusChip(
                        label: 'Repeat hire', color: context.appColors.goldMid),
                    StatusChip(
                        label: 'Safe conduct',
                        color: context.appColors.infoPurple),
                  ],
                ),
                const SizedBox(height: 12),
                const ActorInfoRow(
                  icon: Icons.repeat_rounded,
                  label: 'Repeat-booking score',
                  value: '68%',
                ),
                const ActorInfoRow(
                  icon: Icons.lightbulb_outline,
                  label: 'Tip',
                  value: 'Add one fresh reel',
                ),
                CorePrimaryButton(
                  icon: Icons.add_photo_alternate_outlined,
                  label: 'Improve portfolio',
                  compact: true,
                  onTap: () =>
                      Navigator.pushNamed(context, ActorTalentRoutes.portfolio),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RatingBar extends StatelessWidget {
  final String label;
  final double value;

  const _RatingBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = value >= 0.9
        ? colors.success
        : value >= 0.7
            ? colors.goldMid
            : colors.danger;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: AppTextStyles.smallMeta.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 7,
              backgroundColor: colors.border,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ActorReview review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.reviewer,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusChip(label: '${review.rating}', color: colors.goldMid),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${review.project} - ${review.date}',
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            review.text,
            style: AppTextStyles.body.copyWith(
              color: colors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
