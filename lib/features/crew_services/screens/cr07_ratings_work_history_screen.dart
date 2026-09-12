import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/profile/profile_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/trust_safety/trust_safety_controller.dart';
import '../../../core/trust_safety/trust_safety_models.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../widgets/crew_services_components.dart';

class CR07RatingsWorkHistoryScreen extends StatefulWidget {
  const CR07RatingsWorkHistoryScreen({super.key});

  @override
  State<CR07RatingsWorkHistoryScreen> createState() =>
      _CR07RatingsWorkHistoryScreenState();
}

class _CR07RatingsWorkHistoryScreenState
    extends State<CR07RatingsWorkHistoryScreen> {
  AuthController? _auth;
  BookingsController? _bookings;
  TrustSafetyController? _trust;
  Future<_ReputationData>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.maybeOf(context);
    final bookings = BookingsScope.maybeOf(context);
    final trust = TrustSafetyScope.maybeOf(context);
    if (auth == null || bookings == null || trust == null) return;
    if (identical(auth, _auth) &&
        identical(bookings, _bookings) &&
        identical(trust, _trust)) {
      return;
    }
    _auth = auth;
    _bookings = bookings;
    _trust = trust;
    _future = _load();
  }

  Future<_ReputationData> _load({bool force = false}) async {
    final values = await Future.wait([
      _auth!.myProfile(),
      _bookings!.bookings(role: 'provider', force: force),
    ]);
    final profile = values[0] as UserProfile;
    final user = _auth!.user;
    var reviews = UserReviewsDto(
      reviews: const [],
      ratingAverage: profile.ratingAverage,
      reviewCount: profile.reviewCount,
    );
    if (user != null) {
      try {
        reviews = await _trust!.userReviews(user.publicId);
      } catch (_) {
        // A review fetch must not hide the verified profile and work history.
      }
    }
    return _ReputationData(
      name: user?.displayName ?? 'Crew Provider',
      profile: profile,
      bookings: (values[1] as List<Booking>)
          .where((booking) => booking.category == 'crew')
          .toList(),
      reviews: reviews,
    );
  }

  void _reload() {
    if (_auth == null) return;
    setState(() => _future = _load(force: true));
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) {
      return const CoreEmptyState(
        icon: Icons.cloud_sync_outlined,
        title: 'Sign in to load reputation',
        message: 'Reviews and project history are verified by the backend.',
      );
    }
    return FutureBuilder<_ReputationData>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return CoreEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Reputation unavailable',
            message: 'Could not load reviews and booking history.',
            actionLabel: 'Try again',
            onAction: _reload,
          );
        }
        return _ReputationBody(data: snapshot.data!);
      },
    );
  }
}

class _ReputationBody extends StatelessWidget {
  final _ReputationData data;

  const _ReputationBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final completed = data.bookings
        .where((booking) => {'closed', 'completed'}.contains(booking.status))
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CrewTwoColumn(
          left: CrewMediaFrame(
            imageUrl: data.profile.coverFile?.publicUrl ?? '',
            title: data.name,
            badge: data.reviews.reviewCount == 0
                ? 'Building reputation'
                : '${data.reviews.ratingAverage.toStringAsFixed(1)} / 5',
            fallbackIcon: Icons.groups_2_outlined,
            aspectRatio: 16 / 9,
          ),
          right: CrewSectionCard(
            title: 'Verified reputation',
            icon: Icons.workspace_premium_outlined,
            selected: true,
            child: Column(
              children: [
                _RatingScore(reviews: data.reviews),
                const SizedBox(height: 14),
                CrewInfoRow(
                  icon: Icons.fact_check_outlined,
                  label: 'Completed projects',
                  value: '$completed',
                ),
                CrewInfoRow(
                  icon: Icons.movie_filter_outlined,
                  label: 'Recorded bookings',
                  value: '${data.bookings.length}',
                ),
                CrewInfoRow(
                  icon: Icons.visibility_outlined,
                  label: 'Profile visibility',
                  value: data.profile.visibility,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        CrewTwoColumn(
          left: CrewSectionCard(
            title: 'Director reviews',
            icon: Icons.reviews_outlined,
            child: data.reviews.reviews.isEmpty
                ? const CoreEmptyState(
                    icon: Icons.star_outline_rounded,
                    title: 'No published reviews yet',
                    message:
                        'Reviews can be submitted only against completed bookings and appear here after moderation.',
                  )
                : Column(
                    children: [
                      for (final review in data.reviews.reviews)
                        _ReviewCard(review: review),
                    ],
                  ),
          ),
          right: CrewSectionCard(
            title: 'Work history',
            icon: Icons.history_rounded,
            child: data.bookings.isEmpty
                ? const CoreEmptyState(
                    icon: Icons.work_history_outlined,
                    title: 'No verified projects yet',
                    message:
                        'Accepted and completed crew bookings create an auditable work history.',
                  )
                : Column(
                    children: [
                      for (final booking in data.bookings)
                        _HistoryRow(booking: booking),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _RatingScore extends StatelessWidget {
  final UserReviewsDto reviews;

  const _RatingScore({required this.reviews});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          reviews.reviewCount == 0
              ? 'NEW'
              : reviews.ratingAverage.toStringAsFixed(1),
          style: AppTextStyles.metricNumber.copyWith(
            color: colors.textPrimary,
            fontSize: reviews.reviewCount == 0 ? 28 : 42,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              reviews.reviewCount == 0
                  ? 'Complete projects to earn verified director reviews.'
                  : '${reviews.reviewCount} verified review(s)',
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewDto review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: GlassSectionCard(
        radius: 14,
        padding: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: colors.goldMid),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              review.reviewer.displayName,
                              style: AppTextStyles.cardLabel.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          StatusChip(
                            label: '${review.rating} / 5',
                            color: colors.goldMid,
                            icon: Icons.star_rounded,
                          ),
                        ],
                      ),
                      if (review.text?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 7),
                        Text(
                          review.text!,
                          style: AppTextStyles.smallMeta.copyWith(
                            color: colors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final Booking booking;

  const _HistoryRow({required this.booking});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.infoPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(Icons.movie_outlined, color: colors.infoPurple),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.projectTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${booking.requester.displayName} · ${booking.requirementTitle ?? booking.listingTitle}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusChip(
            label: booking.status.replaceAll('_', ' '),
            color: {'closed', 'completed'}.contains(booking.status)
                ? colors.success
                : colors.infoBlue,
          ),
        ],
      ),
    );
  }
}

class _ReputationData {
  final String name;
  final UserProfile profile;
  final List<Booking> bookings;
  final UserReviewsDto reviews;

  const _ReputationData({
    required this.name,
    required this.profile,
    required this.bookings,
    required this.reviews,
  });
}
