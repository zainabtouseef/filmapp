import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/contracts/contract_models.dart';
import '../../../core/contracts/contracts_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/payments/payment_models.dart';
import '../../../core/payments/payments_controller.dart';
import '../../../core/profile/profile_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/tour/tour_target.dart';
import '../../../core/trust_safety/trust_safety_controller.dart';
import '../../../core/trust_safety/trust_safety_models.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/dashboard/dashboard_kit.dart';
import '../models/crew_services_models.dart';
import '../routes/crew_services_routes.dart';
import '../widgets/crew_services_components.dart';

class CR01CrewDashboardScreen extends StatefulWidget {
  const CR01CrewDashboardScreen({super.key});

  @override
  State<CR01CrewDashboardScreen> createState() =>
      _CR01CrewDashboardScreenState();
}

class _CR01CrewDashboardScreenState extends State<CR01CrewDashboardScreen> {
  Future<_CrewDashboardData>? _future;
  AuthController? _auth;
  BookingsController? _bookings;
  ContractsController? _contracts;
  PaymentsController? _payments;
  TrustSafetyController? _trust;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.maybeOf(context);
    final bookings = BookingsScope.maybeOf(context);
    final contracts = ContractsScope.maybeOf(context);
    final payments = PaymentsScope.maybeOf(context);
    final trust = TrustSafetyScope.maybeOf(context);
    if (auth == null ||
        bookings == null ||
        contracts == null ||
        payments == null ||
        trust == null) {
      return;
    }
    if (identical(auth, _auth) &&
        identical(bookings, _bookings) &&
        identical(contracts, _contracts) &&
        identical(payments, _payments) &&
        identical(trust, _trust)) {
      return;
    }
    _auth = auth;
    _bookings = bookings;
    _contracts = contracts;
    _payments = payments;
    _trust = trust;
    _future = _load();
  }

  Future<_CrewDashboardData> _load({bool force = false}) async {
    final values = await Future.wait([
      _auth!.myProfile(),
      _bookings!.bookings(role: 'provider', force: force),
      _bookings!.availability(),
      _contracts!.contracts(force: force),
      _payments!.dashboard(force: force),
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
        // Reputation is supplementary dashboard data. Keep the workspace
        // usable during auth hydration or a transient review-service error.
      }
    }
    final bookings = (values[1] as List<Booking>)
        .where((booking) => booking.category == 'crew')
        .toList();
    final bookingIds = bookings.map((booking) => booking.publicId).toSet();
    return _CrewDashboardData(
      name: user?.displayName ?? 'Crew Provider',
      profile: profile,
      bookings: bookings,
      availability: values[2] as List<AvailabilityEntry>,
      contracts: (values[3] as List<CineContract>)
          .where((contract) => bookingIds.contains(contract.bookingId))
          .toList(),
      payments: values[4] as PaymentDashboardDto,
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
        title: 'Sign in to load crew operations',
        message:
            'Profile, availability, requests, contracts and earnings come from your live account.',
      );
    }
    return FutureBuilder<_CrewDashboardData>(
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
            title: 'Crew workspace unavailable',
            message:
                'The live workspace could not be loaded: ${snapshot.error}',
            actionLabel: 'Try again',
            onAction: _reload,
          );
        }
        return _CrewDashboardBody(data: snapshot.data!);
      },
    );
  }
}

/// Live crew workspace body — dashboard-kit composition: hero → quick stat
/// tiles → widget grid (clock + earnings ring + availability calendar) →
/// production pipeline + action-required rail.
class _CrewDashboardBody extends StatelessWidget {
  final _CrewDashboardData data;

  const _CrewDashboardBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final openRequests = data.bookings
        .where((booking) =>
            {'sent', 'viewed', 'under_negotiation'}.contains(booking.status))
        .toList();
    final confirmed = data.bookings
        .where((booking) =>
            {'accepted', 'secured', 'in_progress'}.contains(booking.status))
        .toList();
    final unsigned =
        data.contracts.where((contract) => !contract.isSigned).toList();
    final availableDays =
        data.availability.where((entry) => entry.status == 'available').length;
    // "Requests" now lives in the hero's own stat strip, and "Confirmed"
    // is an exact duplicate of the hero's "Active projects" figure — both
    // dropped here to avoid showing the same counts twice.
    final metrics = [
      CrewMetric(
        label: 'Available',
        value: '$availableDays',
        delta: 'Calendar blocks',
        icon: Icons.event_available_outlined,
        tone: CrewTone.blue,
        route: CrewServicesRoutes.availability,
      ),
      CrewMetric(
        label: 'Contracts',
        value: '${unsigned.length}',
        delta: 'Awaiting signature',
        icon: Icons.draw_outlined,
        tone: CrewTone.purple,
        route: CrewServicesRoutes.contracts,
      ),
      CrewMetric(
        label: 'Rating',
        value: data.reviews.reviewCount == 0
            ? 'New'
            : data.reviews.ratingAverage.toStringAsFixed(1),
        delta: '${data.reviews.reviewCount} verified reviews',
        icon: Icons.star_outline_rounded,
        tone: CrewTone.gold,
        route: CrewServicesRoutes.ratings,
      ),
    ];
    final pipelineBookings =
        {...openRequests, ...confirmed, ...data.bookings}.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TourTarget(
          id: 'crew.dashboard.hero',
          child: _CrewHero(
            data: data,
            confirmedCount: confirmed.length,
            openRequestsCount: openRequests.length,
          ),
        ),
        const SizedBox(height: 14),
        TourTarget(
          id: 'crew.dashboard.quickStats',
          child: _CrewQuickStats(metrics: metrics),
        ),
        const SizedBox(height: 14),
        _CrewWidgetGridSection(data: data),
        const SizedBox(height: 14),
        CrewTwoColumn(
          left: TourTarget(
            id: 'crew.dashboard.pipeline',
            child: CrewSectionCard(
              title: 'Production Pipeline',
              icon: Icons.movie_creation_outlined,
              actionText: 'View all',
              onActionTap: () =>
                  Navigator.pushNamed(context, CrewServicesRoutes.requests),
              selected: pipelineBookings.isNotEmpty,
              child: pipelineBookings.isEmpty
                  ? const CoreEmptyState(
                      icon: Icons.movie_filter_outlined,
                      title: 'Ready for the next production',
                      message:
                          'Open projects and direct crew requests will appear here as soon as a director connects.',
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < pipelineBookings.length; i++)
                          _BookingPipelineRow(
                            booking: pipelineBookings[i],
                            showDivider: i != 0,
                          ),
                      ],
                    ),
            ),
          ),
          right: TourTarget(
            id: 'crew.dashboard.actionRequired',
            child: CrewSectionCard(
              title: 'Action required',
              icon: Icons.priority_high_rounded,
              child: Column(
                children: [
                  PortalAttentionRow(
                    kindLabel: 'Requests',
                    title: '${openRequests.length} open request(s)',
                    meta: 'Review project scope, dates and fees',
                    icon: Icons.move_to_inbox_outlined,
                    tone: openRequests.isEmpty
                        ? CineTone.positive
                        : CineTone.warning,
                    onTap: () => Navigator.pushNamed(
                        context, CrewServicesRoutes.requests),
                  ),
                  const SizedBox(height: 10),
                  PortalAttentionRow(
                    kindLabel: 'Contracts',
                    title: '${unsigned.length} unsigned contract(s)',
                    meta: 'Review terms and signature progress',
                    icon: Icons.draw_outlined,
                    tone:
                        unsigned.isEmpty ? CineTone.positive : CineTone.warning,
                    onTap: () => Navigator.pushNamed(
                        context, CrewServicesRoutes.contracts),
                  ),
                  const SizedBox(height: 10),
                  PortalAttentionRow(
                    kindLabel: 'Opportunities',
                    title: 'Open opportunities',
                    meta: 'Pitch your services to active productions',
                    icon: Icons.travel_explore_outlined,
                    tone: CineTone.information,
                    onTap: () => Navigator.pushNamed(
                        context, CrewServicesRoutes.opportunities),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dashboard-kit hero: provider identity, active-project/earnings stats,
/// and the "edit profile" / "open portfolio" actions carried over from the
/// previous `ProviderWorkspaceHero`.
class _CrewHero extends StatelessWidget {
  final _CrewDashboardData data;
  final int confirmedCount;
  final int openRequestsCount;

  const _CrewHero({
    required this.data,
    required this.confirmedCount,
    required this.openRequestsCount,
  });

  @override
  Widget build(BuildContext context) {
    return PortalHeroCard(
      initials: _initialsFor(data.name),
      name: data.name,
      badgeLabel:
          data.profile.visibility == 'public' ? 'Discoverable' : 'Private',
      stats: [
        PortalHeroStat(value: '$confirmedCount', label: 'Active projects'),
        PortalHeroStat(
          value: crewMoney(data.payments.creditMinor ~/ 100),
          label: 'Verified earnings',
        ),
        PortalHeroStat(
          value: '$openRequestsCount',
          label: 'Open requests',
        ),
      ],
      ctaLabel: 'Edit public profile',
      onCta: () => Navigator.pushNamed(context, CrewServicesRoutes.profile),
      secondaryIcon: Icons.video_library_outlined,
      onSecondary: () =>
          Navigator.pushNamed(context, CrewServicesRoutes.portfolio),
    );
  }
}

class _CrewQuickStats extends StatelessWidget {
  final List<CrewMetric> metrics;

  const _CrewQuickStats({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 9.0;
        final columns = constraints.maxWidth < 360
            ? 1
            : constraints.maxWidth < 700
                ? 2
                : 3;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: PortalQuickStatTile(
                  icon: metric.icon,
                  value: metric.value,
                  label: metric.label,
                  delta: metric.delta,
                  tone: _crewCineTone(metric.tone),
                  onTap: () => Navigator.pushNamed(context, metric.route),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// macOS-widget-style grid: a live clock, an earnings-progress ring (real
/// credit/pending-release payment totals), and the availability calendar
/// (real `AvailabilityEntry.startAt` dates) — all frosted-glass, fixed-size
/// widgets that cascade in together, rather than a stretched ring card
/// beside a full-width calendar.
class _CrewWidgetGridSection extends StatelessWidget {
  final _CrewDashboardData data;

  const _CrewWidgetGridSection({required this.data});

  static const _clockRingWidth = 168.0 * 2 + 14;
  static const _calendarWidth = 340.0;

  /// Below this, there's room for both groups side by side exactly as
  /// designed. Above it, don't leave the clock group pinned at its fixed
  /// width with dead space beside it — let each group fill the row.
  static const _sideBySideThreshold = _clockRingWidth + 14 + _calendarWidth;

  @override
  Widget build(BuildContext context) {
    final credit = data.payments.creditMinor;
    final pending = data.payments.pendingReleaseMinor;
    final total = credit + pending;
    final progress = total == 0 ? 0.0 : credit / total;

    final clockRingRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const PortalLiveClockWidget(),
        const SizedBox(width: 14),
        PortalGlassRingWidget(
          progress: progress,
          value: crewMoney(credit ~/ 100),
          label: 'Earnings cleared\nthis cycle',
          tone: CineTone.premium,
        ),
      ],
    );
    final calendarCard = TourTarget(
      id: 'crew.dashboard.calendarWidget',
      child: PortalGlassWidgetCard(
        width: _calendarWidth,
        child: _CrewAvailabilityCalendar(
          availability: data.availability,
          decorated: false,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= _sideBySideThreshold) {
          return PortalStaggeredReveal(
            children: [
              SizedBox(
                width: _clockRingWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    clockRingRow,
                    const SizedBox(height: 14),
                    PortalGlassFireWidget(width: _clockRingWidth, height: 118),
                  ],
                ),
              ),
              calendarCard,
            ],
          );
        }

        // Not enough room for both groups side by side: each group fills
        // the actual available width instead of sitting pinned at a fixed
        // pixel size with dead space left beside it.
        final clockRingGroup = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: width < _clockRingWidth
                  ? FittedBox(fit: BoxFit.scaleDown, child: clockRingRow)
                  : clockRingRow,
            ),
            const SizedBox(height: 14),
            PortalGlassFireWidget(width: width, height: 118),
          ],
        );

        return PortalStaggeredReveal(
          children: [
            SizedBox(width: width, child: clockRingGroup),
            Center(
              child: width < _calendarWidth
                  ? FittedBox(fit: BoxFit.scaleDown, child: calendarCard)
                  : calendarCard,
            ),
          ],
        );
      },
    );
  }
}

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

/// Mini month calendar with event dots computed from the real availability
/// blocks (`AvailabilityEntry.startAt` where `status == 'available'`) — no
/// fabricated/sample data.
class _CrewAvailabilityCalendar extends StatefulWidget {
  final List<AvailabilityEntry> availability;
  final bool decorated;

  const _CrewAvailabilityCalendar({
    required this.availability,
    this.decorated = true,
  });

  @override
  State<_CrewAvailabilityCalendar> createState() =>
      _CrewAvailabilityCalendarState();
}

class _CrewAvailabilityCalendarState extends State<_CrewAvailabilityCalendar> {
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
    final colors = context.appColors;
    final now = DateTime.now();
    final eventDays = <int>{
      for (final entry in widget.availability)
        if (entry.status == 'available' &&
            entry.startAt.year == _visibleMonth.year &&
            entry.startAt.month == _visibleMonth.month)
          entry.startAt.day,
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

/// One booking mapped onto the shared pipeline row — replaces the previous
/// single-item "current production flow" spotlight with a real multi-item
/// list drawn from open + confirmed (then remaining) bookings.
class _BookingPipelineRow extends StatelessWidget {
  final Booking booking;
  final bool showDivider;

  const _BookingPipelineRow({
    required this.booking,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final status = crewBookingStatusFromString(booking.status);
    return PortalPipelineRow(
      initials: _initialsFor(booking.projectTitle),
      title: booking.projectTitle,
      subtitle: booking.requirementTitle ?? booking.listingTitle,
      metaLabel: '${_date(booking.startAt)} – ${_date(booking.endAt)}',
      status: crewBookingStatusLabel(status),
      tone: _bookingStatusTone(status),
      ctaLabel: 'Open',
      onCta: () => Navigator.pushNamed(context, CrewServicesRoutes.requests),
      onTap: () => Navigator.pushNamed(context, CrewServicesRoutes.requests),
      showDivider: showDivider,
    );
  }
}

CineTone _crewCineTone(CrewTone tone) => switch (tone) {
      CrewTone.gold => CineTone.premium,
      CrewTone.blue => CineTone.information,
      CrewTone.green => CineTone.positive,
      CrewTone.purple => CineTone.information,
      CrewTone.danger => CineTone.critical,
      CrewTone.neutral => CineTone.neutral,
    };

CineTone _bookingStatusTone(CrewBookingStatus status) => switch (status) {
      CrewBookingStatus.secured ||
      CrewBookingStatus.inProgress ||
      CrewBookingStatus.closed =>
        CineTone.positive,
      CrewBookingStatus.paymentPending ||
      CrewBookingStatus.contractPending ||
      CrewBookingStatus.requestReceived =>
        CineTone.warning,
      CrewBookingStatus.rejected ||
      CrewBookingStatus.disputed =>
        CineTone.critical,
      CrewBookingStatus.underNegotiation => CineTone.information,
    };

String _initialsFor(String value) {
  final parts =
      value.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

class _CrewDashboardData {
  final String name;
  final UserProfile profile;
  final List<Booking> bookings;
  final List<AvailabilityEntry> availability;
  final List<CineContract> contracts;
  final PaymentDashboardDto payments;
  final UserReviewsDto reviews;

  const _CrewDashboardData({
    required this.name,
    required this.profile,
    required this.bookings,
    required this.availability,
    required this.contracts,
    required this.payments,
    required this.reviews,
  });
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
