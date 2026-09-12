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
import '../../../core/theme/app_text_styles.dart';
import '../../../core/trust_safety/trust_safety_controller.dart';
import '../../../core/trust_safety/trust_safety_models.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/widgets/provider_workspace_hero.dart';
import '../../../shared/widgets/status_chip.dart';
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

class _CrewDashboardBody extends StatelessWidget {
  final _CrewDashboardData data;

  const _CrewDashboardBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
    final metrics = [
      CrewMetric(
        label: 'Requests',
        value: '${openRequests.length}',
        delta: openRequests.isEmpty ? 'Inbox clear' : 'Response needed',
        icon: Icons.move_to_inbox_outlined,
        tone: CrewTone.gold,
        route: CrewServicesRoutes.requests,
      ),
      CrewMetric(
        label: 'Confirmed',
        value: '${confirmed.length}',
        delta: 'Active projects',
        icon: Icons.movie_filter_outlined,
        tone: CrewTone.green,
        route: CrewServicesRoutes.requests,
      ),
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
    final nextBooking = confirmed.isNotEmpty
        ? confirmed.first
        : (data.bookings.isEmpty ? null : data.bookings.first);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProviderWorkspaceHero(
          imageUrl: data.profile.coverFile?.publicUrl ?? '',
          avatarUrl: data.profile.avatarFile?.publicUrl,
          eyebrow: 'Production-ready crew service',
          title: data.name,
          summary: data.profile.bio?.trim().isNotEmpty == true
              ? data.profile.bio!
              : 'Build a persuasive crew profile with production credits, availability and verified project history.',
          badge:
              data.profile.visibility == 'public' ? 'Discoverable' : 'Private',
          fallbackIcon: Icons.groups_2_outlined,
          accentColor: colors.infoPurple,
          facts: [
            ProviderHeroFact(
              icon: Icons.location_on_outlined,
              label: 'Base',
              value: data.profile.city?.name ?? 'Add city',
            ),
            ProviderHeroFact(
              icon: Icons.event_available_outlined,
              label: 'Schedule',
              value: '$availableDays available block(s)',
            ),
            ProviderHeroFact(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Verified earnings',
              value: crewMoney(data.payments.creditMinor ~/ 100),
            ),
          ],
          primaryLabel: 'Edit public profile',
          primaryIcon: Icons.edit_outlined,
          onPrimary: () =>
              Navigator.pushNamed(context, CrewServicesRoutes.profile),
          secondaryLabel: 'Open portfolio',
          secondaryIcon: Icons.video_library_outlined,
          onSecondary: () =>
              Navigator.pushNamed(context, CrewServicesRoutes.portfolio),
        ),
        const SizedBox(height: 14),
        CrewKpiRail(metrics: metrics),
        const SizedBox(height: 14),
        CrewTwoColumn(
          left: CrewSectionCard(
            title: 'Current production flow',
            icon: Icons.movie_creation_outlined,
            selected: nextBooking != null,
            child: nextBooking == null
                ? const CoreEmptyState(
                    icon: Icons.movie_filter_outlined,
                    title: 'Ready for the next production',
                    message:
                        'Open projects and direct crew requests will appear here as soon as a director connects.',
                  )
                : _BookingSpotlight(booking: nextBooking),
          ),
          right: CrewSectionCard(
            title: 'Action required',
            icon: Icons.priority_high_rounded,
            child: Column(
              children: [
                _ActionRow(
                  icon: Icons.move_to_inbox_outlined,
                  title: '${openRequests.length} open request(s)',
                  subtitle: 'Review project scope, dates and fees',
                  route: CrewServicesRoutes.requests,
                ),
                _ActionRow(
                  icon: Icons.draw_outlined,
                  title: '${unsigned.length} unsigned contract(s)',
                  subtitle: 'Review terms and signature progress',
                  route: CrewServicesRoutes.contracts,
                ),
                const _ActionRow(
                  icon: Icons.travel_explore_outlined,
                  title: 'Open opportunities',
                  subtitle: 'Pitch your services to active productions',
                  route: CrewServicesRoutes.opportunities,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BookingSpotlight extends StatelessWidget {
  final Booking booking;

  const _BookingSpotlight({required this.booking});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                booking.projectTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sectionHeading.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            StatusChip(
              label: booking.status.replaceAll('_', ' '),
              color: colors.goldMid,
            ),
          ],
        ),
        const SizedBox(height: 12),
        CrewInfoRow(
          icon: Icons.badge_outlined,
          label: 'Service',
          value: booking.requirementTitle ?? booking.listingTitle,
        ),
        CrewInfoRow(
          icon: Icons.person_outline_rounded,
          label: 'Producer',
          value: booking.requester.displayName,
        ),
        CrewInfoRow(
          icon: Icons.calendar_month_outlined,
          label: 'Dates',
          value: '${_date(booking.startAt)} – ${_date(booking.endAt)}',
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () =>
              Navigator.pushNamed(context, CrewServicesRoutes.requests),
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('Open request'),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(context, route),
        child: GlassSectionCard(
          radius: 12,
          padding: const EdgeInsets.all(11),
          child: Row(
            children: [
              Icon(icon, color: colors.goldDark),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.cardLabel.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.icon),
            ],
          ),
        ),
      ),
    );
  }
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
