import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_widgets.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/profile/profile_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../data/actor_talent_demo_data.dart';
import '../models/actor_talent_models.dart';
import '../routes/actor_talent_routes.dart';
import '../widgets/actor_talent_components.dart';

/// AT-01 Talent Dashboard
class AT01TalentDashboardScreen extends StatefulWidget {
  const AT01TalentDashboardScreen({super.key});

  @override
  State<AT01TalentDashboardScreen> createState() =>
      _AT01TalentDashboardScreenState();
}

class _AT01TalentDashboardScreenState extends State<AT01TalentDashboardScreen> {
  Future<_TalentProfileSnapshot>? _profileFuture;
  Future<List<Booking>>? _opportunitiesFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.maybeOf(context);
    if (_profileFuture == null && auth != null && auth.isAuthenticated) {
      _profileFuture = _loadProfile(auth);
    }
    final bookings = BookingsScope.maybeOf(context);
    if (_opportunitiesFuture == null && bookings != null) {
      _opportunitiesFuture = bookings.opportunities(force: true);
    }
  }

  Future<_TalentProfileSnapshot> _loadProfile(AuthController auth) async {
    final values = await Future.wait<Object>([
      auth.myProfile(),
      auth.talentProfile(),
    ]);
    return _TalentProfileSnapshot(
      userProfile: values[0] as UserProfile,
      talentProfile: values[1] as TalentProfile,
    );
  }

  void _refreshOpportunities() {
    final bookings = BookingsScope.maybeOf(context);
    if (bookings == null) return;
    setState(() {
      _opportunitiesFuture = bookings.opportunities(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ActorTalentDemoStore.instance,
      builder: (context, _) {
        final store = ActorTalentDemoStore.instance;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ActorSectionCard(
              title: 'Talent Snapshot',
              icon: Icons.auto_awesome_outlined,
              actionText: 'Edit profile',
              onActionTap: () =>
                  Navigator.pushNamed(context, ActorTalentRoutes.profile),
              selected: store.profileCompleteness < 80,
              child: _TalentSnapshotContent(
                future: _profileFuture,
                store: store,
              ),
            ),
            const SizedBox(height: 12),
            const PersonalDashboardKpiStrip(
              fallbackMessage:
                  'Live dashboard metrics are temporarily unavailable.',
            ),
            const SizedBox(height: 12),
            ActorTwoColumn(
              left: _PendingWork(
                future: _opportunitiesFuture,
                onRefresh: _refreshOpportunities,
              ),
              right: _DashboardSideRail(
                opportunitiesFuture: _opportunitiesFuture,
                profileFuture: _profileFuture,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TalentProfileSnapshot {
  final UserProfile userProfile;
  final TalentProfile talentProfile;

  const _TalentProfileSnapshot({
    required this.userProfile,
    required this.talentProfile,
  });
}

class _TalentSnapshotContent extends StatelessWidget {
  final Future<_TalentProfileSnapshot>? future;
  final ActorTalentDemoStore store;

  const _TalentSnapshotContent({
    required this.future,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    if (future == null) {
      return ActorTwoColumn(
        left: _IdentityCard(store: store),
        right: ActorProgressMeter(value: store.profileCompleteness),
      );
    }
    return FutureBuilder<_TalentProfileSnapshot>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonCard(
            height: 150,
            density: CardDensity.compact,
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const CoreEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load casting profile',
            message: 'Open Casting Profile to retry before editing.',
          );
        }
        final data = snapshot.data!;
        return ActorTwoColumn(
          left: _IdentityCard(store: store, snapshot: data),
          right: ActorProgressMeter(
            value: _profileCompleteness(
              data.talentProfile,
              data.userProfile,
            ),
          ),
        );
      },
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final ActorTalentDemoStore store;
  final _TalentProfileSnapshot? snapshot;

  const _IdentityCard({
    required this.store,
    this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final liveSnapshot = snapshot;
    final talent = liveSnapshot?.talentProfile;
    final live = liveSnapshot != null;
    final stageName = !live
        ? store.profileStageName
        : talent?.screenName?.trim().isNotEmpty == true
            ? talent!.screenName!.trim()
            : 'Casting profile incomplete';
    final city = live
        ? liveSnapshot.userProfile.city?.name ?? 'City not added'
        : store.profileCity;
    final languages = !live
        ? store.profileLanguages
        : talent!.languages.isEmpty
            ? 'No languages added'
            : talent.languages.map((item) => item.language).join(', ');
    final availability =
        talent?.availabilityStatus.replaceAll('_', ' ') ?? 'draft profile';
    final agency = live
        ? _bioProfileValue(liveSnapshot.userProfile.bio, 'Agency').isEmpty
            ? 'Independent'
            : _bioProfileValue(liveSnapshot.userProfile.bio, 'Agency')
        : store.agency;
    return Row(
      children: [
        SizedBox(
          width: 82,
          child: ActorMediaFrame(
            imageUrl: live ? '' : ActorTalentDemoData.profileImage,
            title: stageName,
            badge: 'Talent',
            fallbackIcon: Icons.person_outline_rounded,
            aspectRatio: 1,
            compact: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stageName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sectionHeading.copyWith(
                  color: colors.textPrimary,
                  fontSize: 19,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$city - $languages',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.smallMeta.copyWith(
                  color: colors.textSecondary,
                  height: 1.28,
                ),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  ActorStatusLabel(label: agency),
                  ActorStatusLabel(
                    label: availability,
                    tone: talent == null ? ActorTone.gold : ActorTone.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PendingWork extends StatelessWidget {
  final Future<List<Booking>>? future;
  final VoidCallback onRefresh;

  const _PendingWork({
    required this.future,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return ActorSectionCard(
      title: 'Priority Actions',
      icon: Icons.priority_high_rounded,
      actionText: future == null ? 'Inbox' : 'Refresh',
      onActionTap: future == null
          ? () => Navigator.pushNamed(
                context,
                ActorTalentRoutes.opportunities,
              )
          : onRefresh,
      child: future == null
          ? _DemoPendingWork(store: ActorTalentDemoStore.instance)
          : FutureBuilder<List<Booking>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SkeletonCard(
                    height: 168,
                    density: CardDensity.compact,
                  );
                }
                if (snapshot.hasError) {
                  return const InlineNotice(
                    message:
                        'Could not load live offers. Refresh to try again.',
                    tone: CoreStatusTone.warning,
                  );
                }
                final rows = snapshot.data ?? const [];
                if (rows.isEmpty) return const _NoActivityCard();
                return Column(
                  children: [
                    for (final booking in rows.take(4))
                      _LiveActionRow(booking: booking),
                  ],
                );
              },
            ),
    );
  }
}

class _DemoPendingWork extends StatelessWidget {
  final ActorTalentDemoStore store;

  const _DemoPendingWork({required this.store});

  @override
  Widget build(BuildContext context) {
    return store.activeTasks.isEmpty
        ? const _NoActivityCard()
        : ActorTaskRail(tasks: store.activeTasks);
  }
}

class _LiveActionRow extends StatelessWidget {
  final Booking booking;

  const _LiveActionRow({required this.booking});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final opportunity = booking.toActorOpportunity();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.borderMuted),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_activity_outlined,
            color: colors.goldDark,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${opportunity.role} from ${opportunity.producer}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${opportunity.fee} - ${opportunity.expiry}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(
              context,
              ActorTalentRoutes.offerDetail,
              arguments: booking.publicId,
            ),
            child: const Text('Review'),
          ),
        ],
      ),
    );
  }
}

class _DashboardSideRail extends StatelessWidget {
  final Future<List<Booking>>? opportunitiesFuture;
  final Future<_TalentProfileSnapshot>? profileFuture;

  const _DashboardSideRail({
    required this.opportunitiesFuture,
    required this.profileFuture,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ActorSectionCard(
          title: 'Next Opportunity',
          icon: Icons.local_activity_outlined,
          actionText: 'Open inbox',
          onActionTap: () =>
              Navigator.pushNamed(context, ActorTalentRoutes.opportunities),
          child: opportunitiesFuture == null
              ? const _DemoPrimaryMatch()
              : FutureBuilder<List<Booking>>(
                  future: opportunitiesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SkeletonCard(
                        height: 190,
                        density: CardDensity.compact,
                      );
                    }
                    final rows = snapshot.data ?? const [];
                    if (snapshot.hasError || rows.isEmpty) {
                      return const CoreEmptyState(
                        icon: Icons.inbox_outlined,
                        title: 'No active opportunity',
                        message: 'New offers will appear here.',
                      );
                    }
                    return _LivePrimaryMatch(booking: rows.first);
                  },
                ),
        ),
        const SizedBox(height: 12),
        ActorSectionCard(
          title: 'Reputation Snapshot',
          icon: Icons.stars_outlined,
          actionText: 'Reviews',
          onActionTap: () =>
              Navigator.pushNamed(context, ActorTalentRoutes.reputation),
          child: FutureBuilder<_TalentProfileSnapshot>(
            future: profileFuture,
            builder: (context, snapshot) {
              if (profileFuture != null &&
                  snapshot.connectionState == ConnectionState.waiting) {
                return const SkeletonCard(
                  height: 112,
                  density: CardDensity.compact,
                );
              }
              if (profileFuture != null && snapshot.hasError) {
                return const CoreEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Rating unavailable',
                  message: 'Open Reviews to retry.',
                );
              }
              final profile = snapshot.data?.userProfile;
              return Column(
                children: [
                  ActorInfoRow(
                    icon: Icons.star_outline_rounded,
                    label: 'Public rating',
                    value: profile == null
                        ? 'Preview'
                        : profile.reviewCount == 0
                            ? 'No reviews yet'
                            : '${profile.ratingAverage.toStringAsFixed(1)} / 5 · ${profile.reviewCount} reviews',
                  ),
                  const ActorInfoRow(
                    icon: Icons.schedule_rounded,
                    label: 'Response habit',
                    value: 'Reply before expiry',
                  ),
                  const ActorInfoRow(
                    icon: Icons.workspace_premium_outlined,
                    label: 'Trust setup',
                    value: 'KYC and safety',
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LivePrimaryMatch extends StatelessWidget {
  final Booking booking;

  const _LivePrimaryMatch({required this.booking});

  @override
  Widget build(BuildContext context) {
    final opportunity = booking.toActorOpportunity();
    return Column(
      children: [
        ActorInfoRow(
          icon: Icons.badge_outlined,
          label: opportunity.role,
          value: opportunity.fee,
        ),
        ActorInfoRow(
          icon: Icons.apartment_outlined,
          label: 'Producer',
          value: opportunity.producer,
        ),
        ActorInfoRow(
          icon: Icons.date_range_outlined,
          label: 'Dates',
          value: opportunity.dates,
        ),
        const SizedBox(height: 6),
        CorePrimaryButton(
          icon: Icons.rate_review_outlined,
          label: 'Review terms',
          compact: true,
          onTap: () => Navigator.pushNamed(
            context,
            ActorTalentRoutes.offerDetail,
            arguments: booking.publicId,
          ),
        ),
      ],
    );
  }
}

class _DemoPrimaryMatch extends StatelessWidget {
  const _DemoPrimaryMatch();

  @override
  Widget build(BuildContext context) {
    final first = ActorTalentDemoData.opportunities.first;
    final status = ActorTalentDemoStore.instance.opportunityStatus(first);
    return Column(
      children: [
        ActorMediaFrame(
          imageUrl: first.imageUrl,
          title: first.projectTitle,
          badge: first.expiry,
          fallbackIcon: Icons.movie_filter_outlined,
        ),
        const SizedBox(height: 10),
        ActorInfoRow(
          icon: Icons.badge_outlined,
          label: first.role,
          value: first.fee,
        ),
        ActorInfoRow(
          icon: Icons.verified_outlined,
          label: 'Status',
          value: ActorTalentDemoData.statusLabel(status),
        ),
      ],
    );
  }
}

class _NoActivityCard extends StatelessWidget {
  const _NoActivityCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        'No urgent actions. Your profile and availability remain visible.',
        style: AppTextStyles.cardLabel.copyWith(color: colors.success),
      ),
    );
  }
}

class ActorStatusLabel extends StatelessWidget {
  final String label;
  final ActorTone tone;

  const ActorStatusLabel({
    super.key,
    required this.label,
    this.tone = ActorTone.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(label),
      labelStyle: AppTextStyles.micro.copyWith(
        color: actorToneColor(context, tone),
        letterSpacing: 0,
        fontWeight: FontWeight.w900,
      ),
      backgroundColor: actorToneColor(context, tone).withValues(alpha: 0.12),
      side: BorderSide(
        color: actorToneColor(context, tone).withValues(alpha: 0.3),
      ),
    );
  }
}

String _bioProfileValue(String? bio, String label) {
  final prefix = '$label:';
  for (final line in (bio ?? '').split('\n')) {
    if (line.toLowerCase().startsWith(prefix.toLowerCase())) {
      return line.substring(prefix.length).trim();
    }
  }
  return '';
}

int _profileCompleteness(
  TalentProfile talent,
  UserProfile profile,
) {
  final checks = <bool>[
    (talent.screenName ?? '').trim().isNotEmpty,
    (profile.bio ?? '').trim().isNotEmpty,
    profile.city != null,
    talent.languages.isNotEmpty,
    (talent.ageRange ?? '').trim().isNotEmpty,
    talent.heightCm != null,
    talent.dayRateMinor != null,
    (talent.unionNote ?? '').trim().isNotEmpty,
  ];
  return ((checks.where((value) => value).length / checks.length) * 100)
      .round();
}
