import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_widgets.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/casting/casting_controller.dart';
import '../../../core/casting/casting_models.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/profile/profile_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/cards/glass_section_card.dart';
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
  Future<_CastingDashboardData>? _castingFuture;

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
    final casting = CastingScope.maybeOf(context);
    if (_castingFuture == null && casting != null) {
      _castingFuture = _loadCasting(casting);
    }
  }

  Future<_CastingDashboardData> _loadCasting(
    CastingController casting,
  ) async {
    final values = await Future.wait<Object>([
      casting.roles(force: true),
      casting.actorApplications(force: true),
    ]);
    return _CastingDashboardData(
      roles: (values[0] as CastingRolePage).roles,
      applications: values[1] as List<CastingApplication>,
    );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PriorityActionHero(
          profileFuture: _profileFuture,
          opportunitiesFuture: _opportunitiesFuture,
          castingFuture: _castingFuture,
        ),
        const SizedBox(height: 12),
        const _OpportunityShortcutStrip(),
        const SizedBox(height: 12),
        ActorSectionCard(
          title: 'Talent Snapshot',
          icon: Icons.auto_awesome_outlined,
          actionText: 'Edit profile',
          onActionTap: () =>
              Navigator.pushNamed(context, ActorTalentRoutes.profile),
          selected: _profileFuture == null,
          child: _TalentSnapshotContent(future: _profileFuture),
        ),
        const SizedBox(height: 12),
        const PersonalDashboardKpiStrip(
          fallbackMessage:
              'Live dashboard metrics are temporarily unavailable.',
        ),
        const SizedBox(height: 12),
        _CastingDashboardOverview(future: _castingFuture),
        const SizedBox(height: 12),
        ActorTwoColumn(
          left: _PendingWork(
            future: _opportunitiesFuture,
            onRefresh: _refreshOpportunities,
          ),
          right: _DashboardSideRail(profileFuture: _profileFuture),
        ),
      ],
    );
  }
}

class _OpportunityShortcutStrip extends StatelessWidget {
  const _OpportunityShortcutStrip();

  @override
  Widget build(BuildContext context) {
    return ActorResponsiveGrid(
      minWidth: 245,
      children: [
        _ShortcutCard(
          icon: Icons.travel_explore_outlined,
          title: 'Browse Opportunities',
          message: 'Find live casting calls and apply for roles.',
          label: 'Open opportunities',
          route: ActorTalentRoutes.opportunities,
          tone: ActorTone.gold,
        ),
        _ShortcutCard(
          icon: Icons.assignment_outlined,
          title: 'My Applications',
          message: 'Track submitted roles, updates and next steps.',
          label: 'Open tracker',
          route: ActorTalentRoutes.applications,
          tone: ActorTone.blue,
        ),
        _ShortcutCard(
          icon: Icons.video_camera_front_outlined,
          title: 'Auditions',
          message: 'See audition invites, callbacks and meeting rounds.',
          label: 'Open auditions',
          route: ActorTalentRoutes.auditions,
          tone: ActorTone.purple,
        ),
      ],
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String label;
  final String route;
  final ActorTone tone;

  const _ShortcutCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.label,
    required this.route,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return ActorSectionCard(
      title: title,
      icon: icon,
      tone: tone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: AppTextStyles.smallMeta.copyWith(
              color: context.appColors.textSecondary,
              height: 1.32,
            ),
          ),
          const SizedBox(height: 10),
          CorePrimaryButton(
            icon: Icons.arrow_forward_rounded,
            label: label,
            compact: true,
            onTap: () => Navigator.pushNamed(context, route),
          ),
        ],
      ),
    );
  }
}

/// The single most important next step, shown above everything else so a
/// first-time actor never has to hunt for what to do — priority order is
/// profile completeness, then any audition awaiting a response, then a
/// pending offer, then an imminent secured booking.
class _PriorityActionHero extends StatelessWidget {
  final Future<_TalentProfileSnapshot>? profileFuture;
  final Future<List<Booking>>? opportunitiesFuture;
  final Future<_CastingDashboardData>? castingFuture;

  const _PriorityActionHero({
    required this.profileFuture,
    required this.opportunitiesFuture,
    required this.castingFuture,
  });

  @override
  Widget build(BuildContext context) {
    final profile = profileFuture;
    if (profile == null) {
      return const _HeroCard(
        icon: Icons.login_rounded,
        eyebrow: 'Get started',
        title: 'Sign in to see your next step',
        message:
            'Your next priority — profile, auditions, offers or bookings — will show here once you sign in.',
      );
    }
    return FutureBuilder<List<Object?>>(
      future: Future.wait<Object?>([
        profile,
        opportunitiesFuture ?? Future.value(const <Booking>[]),
        castingFuture ?? Future.value(null),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonCard(height: 118);
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const _HeroCard(
            icon: Icons.cloud_off_outlined,
            eyebrow: 'Next step',
            title: 'Could not load your next step',
            message: 'Pull to refresh or reopen the dashboard to try again.',
          );
        }
        final results = snapshot.data!;
        final talentSnapshot = results[0] as _TalentProfileSnapshot;
        final bookings = results[1] as List<Booking>;
        final casting = results[2] as _CastingDashboardData?;
        return _resolveHero(context, talentSnapshot, bookings, casting);
      },
    );
  }

  Widget _resolveHero(
    BuildContext context,
    _TalentProfileSnapshot snapshot,
    List<Booking> bookings,
    _CastingDashboardData? casting,
  ) {
    final completeness =
        _profileCompleteness(snapshot.talentProfile, snapshot.userProfile);
    if (completeness < 70) {
      return _HeroCard(
        icon: Icons.badge_outlined,
        eyebrow: 'Next step · $completeness% complete',
        title: 'Complete your profile',
        message:
            'Directors match faster with actors who have a full profile — add the missing details to start appearing in more searches.',
        actionLabel: 'Complete profile',
        onAction: () => Navigator.pushNamed(context, ActorTalentRoutes.profile),
      );
    }

    final auditions = (casting?.applications ?? const [])
        .where((item) => item.isAudition)
        .toList();
    if (auditions.isNotEmpty) {
      final next = auditions.first;
      return _HeroCard(
        icon: Icons.video_camera_front_outlined,
        eyebrow: 'Next step · Audition',
        title: 'Respond to your audition invitation',
        message:
            '${next.role.title} for ${next.role.project.title} needs your response.',
        actionLabel: 'Open audition',
        onAction: () => Navigator.pushNamed(
          context,
          ActorTalentRoutes.applicationDetail,
          arguments: next.publicId,
        ),
      );
    }

    final pendingOffers = bookings
        .where((item) =>
            item.toActorOpportunity().status == ActorBookingStatus.sent ||
            item.toActorOpportunity().status ==
                ActorBookingStatus.underNegotiation)
        .toList();
    if (pendingOffers.isNotEmpty) {
      final offer = pendingOffers.first;
      return _HeroCard(
        icon: Icons.rate_review_outlined,
        eyebrow: 'Next step · Offer',
        title: 'Review your offer',
        message:
            '${offer.projectTitle} sent an offer that is waiting on your response.',
        actionLabel: 'Review offer',
        onAction: () => Navigator.pushNamed(
          context,
          ActorTalentRoutes.offerDetail,
          arguments: offer.publicId,
        ),
      );
    }

    final upcoming = bookings
        .where((item) => item.status == 'secured')
        .where((item) =>
            item.startAt.difference(DateTime.now()).inDays <= 14 &&
            item.startAt.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    if (upcoming.isNotEmpty) {
      final next = upcoming.first;
      final days = next.startAt.difference(DateTime.now()).inDays;
      return _HeroCard(
        icon: Icons.event_available_outlined,
        eyebrow: 'Next step · Upcoming booking',
        title: 'Confirm your upcoming booking',
        message: days <= 0
            ? '${next.projectTitle} call time is today — check the schedule and location.'
            : '${next.projectTitle} starts in $days day${days == 1 ? '' : 's'}.',
        actionLabel: 'Open booking',
        onAction: () =>
            Navigator.pushNamed(context, ActorTalentRoutes.bookings),
      );
    }

    return _HeroCard(
      icon: Icons.check_circle_outline_rounded,
      eyebrow: 'Next step',
      title: 'You are all caught up',
      message:
          'No pending actions right now. Browse new casting calls to keep your pipeline moving.',
      actionLabel: 'Discover roles',
      onAction: () =>
          Navigator.pushNamed(context, ActorTalentRoutes.opportunities),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _HeroCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 20,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: colors.goldGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: colors.onGold, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: AppTextStyles.micro.copyWith(
                    color: colors.goldDark,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: AppTextStyles.sectionHeading.copyWith(
                    color: colors.textPrimary,
                    fontSize: 19,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                    height: 1.32,
                  ),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(height: 12),
                  CorePrimaryButton(
                    icon: Icons.arrow_forward_rounded,
                    label: actionLabel!,
                    compact: true,
                    onTap: onAction,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CastingDashboardData {
  final List<CastingRole> roles;
  final List<CastingApplication> applications;

  const _CastingDashboardData({
    required this.roles,
    required this.applications,
  });
}

class _CastingDashboardOverview extends StatelessWidget {
  final Future<_CastingDashboardData>? future;

  const _CastingDashboardOverview({required this.future});

  @override
  Widget build(BuildContext context) {
    if (future == null) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<_CastingDashboardData>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ActorTwoColumn(
            left: SkeletonCard(height: 220),
            right: SkeletonCard(height: 220),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const InlineNotice(
            message: 'Casting updates are temporarily unavailable.',
            tone: CoreStatusTone.warning,
          );
        }
        final data = snapshot.data!;
        final active = data.applications
            .where(
              (item) => !const {
                'draft',
                'selected',
                'rejected',
                'withdrawn',
              }.contains(item.status),
            )
            .toList();
        final auditions =
            data.applications.where((item) => item.isAudition).toList();
        return ActorTwoColumn(
          left: ActorSectionCard(
            title: 'Recommended Roles',
            icon: Icons.manage_search_outlined,
            actionText: 'View all',
            onActionTap: () => Navigator.pushNamed(
              context,
              ActorTalentRoutes.opportunities,
            ),
            child: data.roles.isEmpty
                ? const CoreEmptyState(
                    icon: Icons.search_off_outlined,
                    title: 'No role recommendations',
                    message: 'New matching casting calls appear here.',
                  )
                : Column(
                    children: [
                      for (final role in data.roles.take(3))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.theater_comedy_outlined),
                          title: Text(role.title),
                          subtitle: Text(
                            '${role.project.title} · ${role.feeLabel}',
                          ),
                          trailing: IconButton(
                            tooltip: 'Open role',
                            icon: const Icon(Icons.arrow_forward_rounded),
                            onPressed: () => Navigator.pushNamed(
                              context,
                              ActorTalentRoutes.roleDetail,
                              arguments: role.publicId,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          right: ActorSectionCard(
            title: 'Application Activity',
            icon: Icons.assignment_outlined,
            actionText: 'Tracker',
            onActionTap: () => Navigator.pushNamed(
              context,
              ActorTalentRoutes.applications,
            ),
            tone: ActorTone.blue,
            child: Column(
              children: [
                ActorInfoRow(
                  icon: Icons.pending_actions_outlined,
                  label: 'Active applications',
                  value: '${active.length}',
                ),
                ActorInfoRow(
                  icon: Icons.video_camera_front_outlined,
                  label: 'Auditions and callbacks',
                  value: '${auditions.length}',
                ),
                ActorInfoRow(
                  icon: Icons.update_rounded,
                  label: 'Recent updates',
                  value: data.applications.isEmpty
                      ? 'No application updates'
                      : data.applications.first.statusLabel,
                ),
                if (auditions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  CorePrimaryButton(
                    icon: Icons.event_available_outlined,
                    label: 'Open next audition',
                    compact: true,
                    onTap: () => Navigator.pushNamed(
                      context,
                      ActorTalentRoutes.applicationDetail,
                      arguments: auditions.first.publicId,
                    ),
                  ),
                ],
              ],
            ),
          ),
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

  const _TalentSnapshotContent({required this.future});

  @override
  Widget build(BuildContext context) {
    if (future == null) {
      return const CoreEmptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Sign in to load your talent snapshot',
        message:
            'Identity, profile completeness, and reputation are fetched from the server.',
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
          left: _IdentityCard(snapshot: data),
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
  final _TalentProfileSnapshot snapshot;

  const _IdentityCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final talent = snapshot.talentProfile;
    final stageName = talent.screenName?.trim().isNotEmpty == true
        ? talent.screenName!.trim()
        : 'Casting profile incomplete';
    final city = snapshot.userProfile.city?.name ?? 'City not added';
    final languages = talent.languages.isEmpty
        ? 'No languages added'
        : talent.languages.map((item) => item.language).join(', ');
    final availability = talent.availabilityStatus.replaceAll('_', ' ');
    final agency =
        talent.representation['agency_name']?.toString().trim() ?? '';
    return Row(
      children: [
        SizedBox(
          width: 82,
          child: ActorMediaFrame(
            imageUrl: snapshot.userProfile.avatarFile?.publicUrl ?? '',
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
                  ActorStatusLabel(
                    label: agency.isEmpty ? 'Independent' : agency,
                  ),
                  ActorStatusLabel(
                    label: availability,
                    tone: ActorTone.green,
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
          ? const CoreEmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Sign in to load priority actions',
              message: 'Live offers and booking actions appear here.',
            )
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
  final Future<_TalentProfileSnapshot>? profileFuture;

  const _DashboardSideRail({required this.profileFuture});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ActorSectionCard(
          title: 'Manage Your Profile',
          icon: Icons.tune_rounded,
          tone: ActorTone.purple,
          child: const ActorTaskRail(
            tasks: [
              ActorTask(
                id: 'portfolio',
                title: 'Portfolio',
                subtitle: 'Photos, showreel, self-tapes',
                route: ActorTalentRoutes.portfolio,
                icon: Icons.video_library_outlined,
                tone: ActorTone.blue,
              ),
              ActorTask(
                id: 'calendar',
                title: 'Calendar',
                subtitle: 'Availability',
                route: ActorTalentRoutes.calendar,
                icon: Icons.calendar_month_outlined,
                tone: ActorTone.gold,
              ),
              ActorTask(
                id: 'rates',
                title: 'Rates',
                subtitle: 'Day rate & terms',
                route: ActorTalentRoutes.rates,
                icon: Icons.price_change_outlined,
                tone: ActorTone.green,
              ),
              ActorTask(
                id: 'safety',
                title: 'Safety',
                subtitle: 'Privacy & support',
                route: ActorTalentRoutes.safety,
                icon: Icons.health_and_safety_outlined,
                tone: ActorTone.purple,
              ),
            ],
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
                        ? 'No live profile'
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

int _profileCompleteness(
  TalentProfile talent,
  UserProfile profile,
) {
  final checks = <bool>[
    (talent.screenName ?? '').trim().isNotEmpty,
    (profile.bio ?? '').trim().isNotEmpty,
    profile.city != null,
    talent.languages.isNotEmpty,
    talent.skills.isNotEmpty,
    (talent.ageRange ?? '').trim().isNotEmpty,
    talent.heightCm != null,
    talent.dayRateMinor != null,
    profile.avatarFile != null,
    (profile.bio ?? '').trim().isNotEmpty,
    talent.credits.isNotEmpty || talent.training.isNotEmpty,
  ];
  return ((checks.where((value) => value).length / checks.length) * 100)
      .round();
}
