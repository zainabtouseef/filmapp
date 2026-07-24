import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/trust_safety/trust_safety_controller.dart';
import '../../../core/trust_safety/trust_safety_models.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/widgets/status_chip.dart';
import '../models/actor_talent_models.dart';
import '../routes/actor_talent_routes.dart';
import '../widgets/actor_talent_components.dart';

/// AT-11 Reputation & Reviews
class AT11ReputationReviewsScreen extends StatefulWidget {
  const AT11ReputationReviewsScreen({super.key});

  @override
  State<AT11ReputationReviewsScreen> createState() =>
      _AT11ReputationReviewsScreenState();
}

class _AT11ReputationReviewsScreenState
    extends State<AT11ReputationReviewsScreen> {
  Future<UserReviewsDto>? _reviewsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reviewsFuture ??= _loadReviews();
  }

  Future<UserReviewsDto>? _loadReviews() {
    final auth = AuthScope.maybeOf(context);
    final trustSafety = TrustSafetyScope.maybeOf(context);
    final userId = auth?.user?.publicId;
    if (auth == null ||
        trustSafety == null ||
        !auth.isAuthenticated ||
        userId == null) {
      return null;
    }
    return trustSafety.userReviews(userId);
  }

  void _refresh() {
    setState(() => _reviewsFuture = _loadReviews());
  }

  @override
  Widget build(BuildContext context) {
    if (_reviewsFuture == null) {
      return const ActorSectionCard(
        title: 'Public Reputation',
        icon: Icons.stars_outlined,
        tone: ActorTone.blue,
        child: CoreEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Sign in to view live reviews',
          message:
              'Reputation data is loaded from completed CineConnect bookings.',
        ),
      );
    }
    return FutureBuilder<UserReviewsDto>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonCard(height: 460);
        }
        if (snapshot.hasError || snapshot.data == null) {
          return _ReviewsLoadError(onRetry: _refresh);
        }
        return _LiveReputation(data: snapshot.data!);
      },
    );
  }
}

class _LiveReputation extends StatelessWidget {
  final UserReviewsDto data;

  const _LiveReputation({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ActorSectionCard(
          title: 'Public Reputation',
          icon: Icons.stars_outlined,
          tone: data.reviewCount == 0 ? ActorTone.blue : ActorTone.gold,
          child: _RatingSummary(
            rating: data.ratingAverage,
            reviewCount: data.reviewCount,
          ),
        ),
        const SizedBox(height: 12),
        ActorTwoColumn(
          left: ActorSectionCard(
            title: 'Published Reviews',
            icon: Icons.rate_review_outlined,
            child: data.reviews.isEmpty
                ? const CoreEmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No published reviews',
                    message:
                        'Reviews appear after a secured booking is completed.',
                  )
                : Column(
                    children: [
                      for (var i = 0; i < data.reviews.length; i++)
                        _LiveReviewCard(
                          review: data.reviews[i],
                          showDivider: i != data.reviews.length - 1,
                        ),
                    ],
                  ),
          ),
          right: const _ReputationGuidance(),
        ),
      ],
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final double rating;
  final int reviewCount;

  const _RatingSummary({
    required this.rating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Container(
          width: 76,
          height: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.goldMid.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colors.goldMid.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            reviewCount == 0 ? '-' : rating.toStringAsFixed(1),
            style: AppTextStyles.metricNumber.copyWith(
              color: colors.textPrimary,
              fontSize: 30,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 2,
                children: [
                  for (var i = 1; i <= 5; i++)
                    Icon(
                      i <= rating.round()
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 21,
                      color: colors.goldMid,
                    ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                reviewCount == 0
                    ? 'No public rating yet'
                    : '$reviewCount verified booking ${reviewCount == 1 ? 'review' : 'reviews'}',
                style: AppTextStyles.cardLabel.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Only published reviews from completed CineConnect bookings count.',
                style: AppTextStyles.smallMeta.copyWith(
                  color: colors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LiveReviewCard extends StatelessWidget {
  final ReviewDto review;
  final bool showDivider;

  const _LiveReviewCard({
    required this.review,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final reviewText = review.text?.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.reviewer.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusChip(
                label: '${review.rating} / 5',
                icon: Icons.star_rounded,
                color: colors.goldMid,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Verified booking ${review.bookingId}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
          ),
          if (reviewText != null && reviewText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              reviewText,
              style: AppTextStyles.body.copyWith(
                color: colors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReputationGuidance extends StatelessWidget {
  const _ReputationGuidance();

  @override
  Widget build(BuildContext context) {
    return ActorSectionCard(
      title: 'Profile Strength',
      icon: Icons.workspace_premium_outlined,
      child: Column(
        children: [
          const ActorInfoRow(
            icon: Icons.schedule_rounded,
            label: 'Offer responses',
            value: 'Reply before expiry',
          ),
          const ActorInfoRow(
            icon: Icons.event_available_outlined,
            label: 'Availability',
            value: 'Keep shoot dates current',
          ),
          const ActorInfoRow(
            icon: Icons.video_library_outlined,
            label: 'Casting media',
            value: 'Lead with current work',
          ),
          const SizedBox(height: 8),
          CorePrimaryButton(
            icon: Icons.add_photo_alternate_outlined,
            label: 'Improve portfolio',
            compact: true,
            onTap: () =>
                Navigator.pushNamed(context, ActorTalentRoutes.portfolio),
          ),
        ],
      ),
    );
  }
}

class _ReviewsLoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _ReviewsLoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ActorSectionCard(
      title: 'Reviews unavailable',
      icon: Icons.cloud_off_outlined,
      tone: ActorTone.danger,
      child: Column(
        children: [
          const CoreEmptyState(
            icon: Icons.sync_problem_outlined,
            title: 'Could not load published reviews',
            message: 'Check your connection and try again.',
          ),
          const SizedBox(height: 10),
          CoreSecondaryButton(
            icon: Icons.refresh_rounded,
            label: 'Try again',
            compact: true,
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}
