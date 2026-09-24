import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_controller.dart';
import '../../../core/analytics/analytics_models.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/casting/casting_controller.dart';
import '../../../core/casting/casting_models.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/profile/profile_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/dashboard/dashboard_kit.dart';
import '../../../shared/formatters/cine_format.dart';
import '../models/actor_talent_models.dart';
import '../routes/actor_talent_routes.dart';
import '../widgets/actor_talent_components.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

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
        _TalentHeroSection(
          profileFuture: _profileFuture,
          opportunitiesFuture: _opportunitiesFuture,
          castingFuture: _castingFuture,
        ),
        const SizedBox(height: 12),
        _OpportunityShortcutStrip(castingFuture: _castingFuture),
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
        _TalentWidgetGridSection(
          profileFuture: _profileFuture,
          opportunitiesFuture: _opportunitiesFuture,
        ),
        const SizedBox(height: 12),
        const _TalentKpiStrip(),
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

/// The dashboard's command header: the shared dashboard-kit hero card
/// carrying the talent's identity, live profile/response stats, and a
/// CTA that always points at the single most important next step —
/// profile completeness, then any audition awaiting a response, then a
/// pending offer, then an imminent secured booking, matching the same
/// priority order the previous message-style hero used.
class _TalentHeroSection extends StatelessWidget {
  final Future<_TalentProfileSnapshot>? profileFuture;
  final Future<List<Booking>>? opportunitiesFuture;
  final Future<_CastingDashboardData>? castingFuture;

  const _TalentHeroSection({
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
          return const SkeletonCard(height: 150);
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
        return _TalentHeroCard(
          snapshot: talentSnapshot,
          bookings: bookings,
          casting: casting,
        );
      },
    );
  }
}

class _TalentHeroCard extends StatelessWidget {
  final _TalentProfileSnapshot snapshot;
  final List<Booking> bookings;
  final _CastingDashboardData? casting;

  const _TalentHeroCard({
    required this.snapshot,
    required this.bookings,
    required this.casting,
  });

  @override
  Widget build(BuildContext context) {
    final talent = snapshot.talentProfile;
    final name = talent.screenName?.trim().isNotEmpty == true
        ? talent.screenName!.trim()
        : 'Talent';
    final completeness = _profileCompleteness(talent, snapshot.userProfile);

    final auditions = (casting?.applications ?? const [])
        .where((item) => item.isAudition)
        .toList();
    final pendingOffers = bookings
        .where((item) =>
            item.toActorOpportunity().status == ActorBookingStatus.sent ||
            item.toActorOpportunity().status ==
                ActorBookingStatus.underNegotiation)
        .toList();
    final upcoming = bookings
        .where((item) => item.status == 'secured')
        .where((item) =>
            item.startAt.difference(DateTime.now()).inDays <= 14 &&
            item.startAt.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    final awaitingResponse = auditions.length + pendingOffers.length;

    late final String ctaLabel;
    late final VoidCallback onCta;
    if (completeness < 70) {
      ctaLabel = 'Complete profile';
      onCta = () => Navigator.pushNamed(context, ActorTalentRoutes.profile);
    } else if (auditions.isNotEmpty) {
      final next = auditions.first;
      ctaLabel = 'Open audition';
      onCta = () => Navigator.pushNamed(
            context,
            ActorTalentRoutes.applicationDetail,
            arguments: next.publicId,
          );
    } else if (pendingOffers.isNotEmpty) {
      final offer = pendingOffers.first;
      ctaLabel = 'Review offer';
      onCta = () => Navigator.pushNamed(
            context,
            ActorTalentRoutes.offerDetail,
            arguments: offer.publicId,
          );
    } else if (upcoming.isNotEmpty) {
      ctaLabel = 'Open booking';
      onCta = () => Navigator.pushNamed(context, ActorTalentRoutes.bookings);
    } else {
      ctaLabel = 'Discover roles';
      onCta =
          () => Navigator.pushNamed(context, ActorTalentRoutes.opportunities);
    }

    return PortalHeroCard(
      initials: _initialsFor(name),
      name: name,
      badgeLabel: 'Verified talent',
      stats: [
        PortalHeroStat(value: '$completeness%', label: 'Profile complete'),
        PortalHeroStat(
          value: '$awaitingResponse',
          label: 'Awaiting your response',
        ),
        PortalHeroStat(
          value: '${upcoming.length}',
          label: 'Upcoming bookings',
        ),
      ],
      ctaLabel: ctaLabel,
      onCta: onCta,
    );
  }
}

class _HeroCard extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String message;

  const _HeroCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.message,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The opportunity/application/audition shortcut launchpad — a dashboard-kit
/// module grid. Counts are real casting-application figures already loaded
/// for the casting overview section below, not fabricated.
class _OpportunityShortcutStrip extends StatelessWidget {
  final Future<_CastingDashboardData>? castingFuture;

  const _OpportunityShortcutStrip({required this.castingFuture});

  @override
  Widget build(BuildContext context) {
    if (castingFuture == null) {
      return const _ShortcutGrid(
          activeApplications: null, auditionsCount: null);
    }
    return FutureBuilder<_CastingDashboardData>(
      future: castingFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final activeApplications = data?.applications
            .where(
              (item) => !const {
                'draft',
                'selected',
                'rejected',
                'withdrawn',
              }.contains(item.status),
            )
            .length;
        final auditionsCount =
            data?.applications.where((item) => item.isAudition).length;
        return _ShortcutGrid(
          activeApplications: activeApplications,
          auditionsCount: auditionsCount,
        );
      },
    );
  }
}

class _ShortcutGrid extends StatelessWidget {
  final int? activeApplications;
  final int? auditionsCount;

  const _ShortcutGrid({
    required this.activeApplications,
    required this.auditionsCount,
  });

  @override
  Widget build(BuildContext context) {
    final modules = [
      PortalModuleCard(
        icon: Icons.travel_explore_outlined,
        name: 'Browse Opportunities',
        description: 'Find live casting calls and apply for roles.',
        actionLabel: 'Open opportunities',
        tone: CineTone.premium,
        onTap: () =>
            Navigator.pushNamed(context, ActorTalentRoutes.opportunities),
      ),
      PortalModuleCard(
        icon: Icons.assignment_outlined,
        name: 'My Applications',
        count: (activeApplications ?? 0) > 0 ? activeApplications : null,
        description: 'Track submitted roles, updates and next steps.',
        actionLabel: 'Open tracker',
        tone: CineTone.information,
        onTap: () =>
            Navigator.pushNamed(context, ActorTalentRoutes.applications),
      ),
      PortalModuleCard(
        icon: Icons.video_camera_front_outlined,
        name: 'Auditions',
        count: (auditionsCount ?? 0) > 0 ? auditionsCount : null,
        description: 'See audition invites, callbacks and meeting rounds.',
        actionLabel: 'Open auditions',
        tone: CineTone.warning,
        onTap: () => Navigator.pushNamed(context, ActorTalentRoutes.auditions),
      ),
    ];

    return ActorSectionCard(
      title: 'Quick Access',
      icon: Icons.dashboard_customize_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = AppSpacing.md;
          final columns = (constraints.maxWidth / 230).floor().clamp(1, 3);
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final module in modules)
                SizedBox(width: width, child: module),
            ],
          );
        },
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
        return _IdentityCard(snapshot: data);
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

/// A mini month calendar of the actor's booking dates — built from the real
/// `Booking.startAt` dates already loaded for the opportunities/priority
/// actions sections, no fabricated sample events.
class _BookingCalendarSection extends StatefulWidget {
  final Future<List<Booking>>? future;
  final bool decorated;

  const _BookingCalendarSection({
    required this.future,
    this.decorated = true,
  });

  @override
  State<_BookingCalendarSection> createState() =>
      _BookingCalendarSectionState();
}

class _BookingCalendarSectionState extends State<_BookingCalendarSection> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.future == null) {
      return const CoreEmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'Sign in to see your booking calendar',
        message: 'Confirmed and pending booking dates appear here.',
      );
    }
    return FutureBuilder<List<Booking>>(
      future: widget.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonCard(
            height: 220,
            density: CardDensity.compact,
          );
        }
        if (snapshot.hasError) {
          return const InlineNotice(
            message: 'Could not load your booking calendar.',
            tone: CoreStatusTone.warning,
          );
        }
        return _buildCalendar(context, snapshot.data ?? const []);
      },
    );
  }

  Widget _buildCalendar(BuildContext context, List<Booking> bookings) {
    final colors = context.appColors;
    final now = DateTime.now();
    final eventDays = <int>{
      for (final booking in bookings)
        if (booking.startAt.year == _visibleMonth.year &&
            booking.startAt.month == _visibleMonth.month)
          booking.startAt.day,
    };

    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    // Sunday-first grid; DateTime.weekday is 1=Mon..7=Sun.
    final leadingBlanks = firstOfMonth.weekday % 7;

    final days = <PortalCalendarDay>[
      for (var i = 0; i < leadingBlanks; i++)
        const PortalCalendarDay(day: 0, inCurrentMonth: false),
      for (var day = 1; day <= daysInMonth; day++)
        PortalCalendarDay(
          day: day,
          isToday: now.year == _visibleMonth.year &&
              now.month == _visibleMonth.month &&
              now.day == day,
          hasEvents: eventDays.contains(day),
          eventColor: colors.goldMid,
        ),
    ];

    return PortalMiniCalendar(
      monthLabel:
          '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
      dayNames: const ['S', 'M', 'T', 'W', 'T', 'F', 'S'],
      days: days,
      onPrevMonth: () => _shiftMonth(-1),
      onNextMonth: () => _shiftMonth(1),
      decorated: widget.decorated,
    );
  }
}

/// macOS-widget-style grid: a live clock, a profile-completeness ring, and
/// the booking calendar (real `Booking.startAt` dates) — all frosted-glass,
/// fixed-size widgets that cascade in together, replacing the previous
/// ring-metric-card + calendar layout.
class _TalentWidgetGridSection extends StatelessWidget {
  final Future<_TalentProfileSnapshot>? profileFuture;
  final Future<List<Booking>>? opportunitiesFuture;

  const _TalentWidgetGridSection({
    required this.profileFuture,
    required this.opportunitiesFuture,
  });

  static const _clockRingWidth = 168.0 * 2 + 14;

  @override
  Widget build(BuildContext context) {
    return PortalStaggeredReveal(
      children: [
        // FittedBox: on the narrowest mobile widths the shell's content
        // column can be tighter than the clock+ring's combined natural
        // width, which would otherwise clamp the SizedBox and overflow the
        // Row inside it. scaleDown measures the group at full size first
        // and only shrinks it (uniformly, no clipping) when space is
        // tight — a no-op on any layout wide enough to fit it natively.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: _clockRingWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const PortalLiveClockWidget(),
                    const SizedBox(width: 14),
                    _ProfileCompletenessRing(future: profileFuture),
                  ],
                ),
                const SizedBox(height: 14),
                PortalGlassFireWidget(width: _clockRingWidth, height: 118),
              ],
            ),
          ),
        ),
        PortalGlassWidgetCard(
          width: 340,
          child: _BookingCalendarSection(
            future: opportunitiesFuture,
            decorated: false,
          ),
        ),
      ],
    );
  }
}

class _ProfileCompletenessRing extends StatelessWidget {
  final Future<_TalentProfileSnapshot>? future;

  const _ProfileCompletenessRing({required this.future});

  @override
  Widget build(BuildContext context) {
    if (future == null) {
      return const PortalGlassRingWidget(
        progress: 0,
        value: '—',
        label: 'Profile\ncompleteness',
      );
    }
    return FutureBuilder<_TalentProfileSnapshot>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return const PortalGlassRingWidget(
            progress: 0,
            value: '—',
            label: 'Profile\ncompleteness',
          );
        }
        final data = snapshot.data!;
        final completeness =
            _profileCompleteness(data.talentProfile, data.userProfile);
        return PortalGlassRingWidget(
          progress: completeness / 100,
          value: '$completeness%',
          label: 'Profile\ncompleteness',
          tone: completeness >= 80 ? CineTone.positive : CineTone.premium,
        );
      },
    );
  }
}

/// Live KPI strip — a dashboard-kit quick-stat-tile row over the same
/// `PersonalDashboardDto` the previous `PersonalDashboardKpiStrip` rendered.
/// Fetches independently (mirroring that shared widget's own fetch-once
/// pattern) so the shared `core/analytics/analytics_widgets.dart` widget
/// used by other portals' dashboards is left untouched.
class _TalentKpiStrip extends StatefulWidget {
  const _TalentKpiStrip();

  @override
  State<_TalentKpiStrip> createState() => _TalentKpiStripState();
}

class _TalentKpiStripState extends State<_TalentKpiStrip> {
  Future<PersonalDashboardDto>? _future;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // See `PersonalDashboardKpiStrip`: fetch once per mount, not on every
    // AnalyticsScope notification, to avoid an unbounded fetch loop.
    if (_started) return;
    _started = true;
    final analytics = AnalyticsScope.maybeOf(context);
    _future = analytics == null
        ? Future.error(StateError('AnalyticsScope missing'))
        : analytics.personalDashboard(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PersonalDashboardDto>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonCard(height: 150, density: CardDensity.compact);
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const InlineNotice(
            message:
                'Live dashboard metrics are temporarily unavailable — showing preview dashboard metrics below.',
            tone: CoreStatusTone.warning,
          );
        }
        final data = snapshot.data!;
        // "Pending offers" is dropped here — it's a subset of the hero's
        // own "Awaiting your response" figure (auditions + pending offers),
        // so keeping both would just show overlapping counts.
        final tiles = [
          PortalQuickStatTile(
            icon: Icons.lock_outline,
            value: CineFormat.currency(
              data.securedValueMinor ~/ 100,
              compact: true,
            ),
            label: 'Secured value',
            delta: 'Across bookings',
            tone: CineTone.positive,
          ),
          PortalQuickStatTile(
            icon: Icons.star_outline_rounded,
            value: data.ratingAverage.toStringAsFixed(1),
            label: 'Public rating',
            delta: data.reviewCount == 0
                ? 'No reviews yet'
                : '${data.reviewCount} reviews',
            tone: CineTone.premium,
            onTap: () => Navigator.pushNamed(context, CoreRoutes.review),
          ),
          PortalQuickStatTile(
            icon: Icons.notifications_none_rounded,
            value: '${data.unreadNotifications}',
            label: 'Unread alerts',
            delta:
                '${data.openDisputes} disputes · ${data.openSupportTickets} support',
            tone: CineTone.warning,
            onTap: () => Navigator.pushNamed(context, CoreRoutes.notifications),
          ),
        ];
        return LayoutBuilder(
          builder: (context, constraints) {
            const gap = 9.0;
            final columns = constraints.maxWidth < 360
                ? 1
                : constraints.maxWidth < 700
                    ? 2
                    : 3;
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final tile in tiles) SizedBox(width: width, child: tile),
              ],
            );
          },
        );
      },
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
                final rows = (snapshot.data ?? const []).take(4).toList();
                if (rows.isEmpty) return const _NoActivityCard();
                return Column(
                  children: [
                    for (var i = 0; i < rows.length; i++)
                      _PriorityPipelineRow(
                        booking: rows[i],
                        showDivider: i != 0,
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _PriorityPipelineRow extends StatelessWidget {
  final Booking booking;
  final bool showDivider;

  const _PriorityPipelineRow({
    required this.booking,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final opportunity = booking.toActorOpportunity();
    return PortalPipelineRow(
      initials: _initialsFor(opportunity.producer),
      title: opportunity.role,
      subtitle: opportunity.producer,
      metaLabel: opportunity.fee,
      status: actorStatusLabel(opportunity.status),
      tone: _cineToneForBookingStatus(opportunity.status),
      ctaLabel: 'Review',
      onCta: () => Navigator.pushNamed(
        context,
        ActorTalentRoutes.offerDetail,
        arguments: booking.publicId,
      ),
      showDivider: showDivider,
    );
  }
}

CineTone _cineToneForBookingStatus(ActorBookingStatus status) =>
    switch (status) {
      ActorBookingStatus.secured ||
      ActorBookingStatus.closed ||
      ActorBookingStatus.termsApproved =>
        CineTone.positive,
      ActorBookingStatus.paymentPending ||
      ActorBookingStatus.underVerification ||
      ActorBookingStatus.contractPending =>
        CineTone.premium,
      ActorBookingStatus.disputed => CineTone.critical,
      _ => CineTone.information,
    };

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

String _initialsFor(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}
