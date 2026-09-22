import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/operations/operations_controller.dart';
import '../../../core/operations/operations_models.dart';
import '../../../core/payments/payment_models.dart';
import '../../../core/payments/payments_controller.dart';
import '../../../core/profile/profile_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/dashboard/dashboard_kit.dart';
import '../../../shared/widgets/status_chip.dart';
import '../models/location_owner_models.dart';
import '../routes/location_owner_routes.dart';
import '../widgets/location_owner_components.dart';
import '../widgets/location_owner_live.dart';

class LO01OwnerDashboardScreen extends StatefulWidget {
  const LO01OwnerDashboardScreen({super.key});

  @override
  State<LO01OwnerDashboardScreen> createState() =>
      _LO01OwnerDashboardScreenState();
}

class _LO01OwnerDashboardScreenState extends State<LO01OwnerDashboardScreen> {
  Future<_DashboardData>? _future;
  AuthController? _auth;
  OperationsController? _operations;
  BookingsController? _bookings;
  PaymentsController? _payments;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.maybeOf(context);
    final operations = OperationsScope.maybeOf(context);
    final bookings = BookingsScope.maybeOf(context);
    final payments = PaymentsScope.maybeOf(context);
    if (auth == null ||
        operations == null ||
        bookings == null ||
        payments == null) {
      return;
    }
    if (identical(auth, _auth) &&
        identical(operations, _operations) &&
        identical(bookings, _bookings) &&
        identical(payments, _payments)) {
      return;
    }
    _auth = auth;
    _operations = operations;
    _bookings = bookings;
    _payments = payments;
    _future = _load();
  }

  Future<_DashboardData> _load({bool force = false}) async {
    final values = await Future.wait([
      _auth!.myProfile(),
      _operations!.locationProperties(force: force),
      _bookings!.bookings(role: 'provider', force: force),
      _payments!.dashboard(force: force),
    ]);
    final properties = values[1] as List<LocationPropertyDto>;
    final bookings = values[2] as List<Booking>;
    return _DashboardData(
      userProfile: values[0] as UserProfile,
      properties: properties,
      bookings: bookings.where((item) => item.category == 'location').toList(),
      payments: values[3] as PaymentDashboardDto,
    );
  }

  void _reload() {
    if (_operations == null || _bookings == null || _payments == null) return;
    setState(() => _future = _load(force: true));
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) {
      return const CoreEmptyState(
        icon: Icons.cloud_sync_outlined,
        title: 'Sign in to load location data',
        message:
            'This dashboard only shows backend properties, booking requests, calendar activity and payment records.',
      );
    }
    return FutureBuilder<_DashboardData>(
      future: _future,
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
            title: 'Workspace unavailable',
            message: locationApiMessage(snapshot.error!),
            actionLabel: 'Try again',
            onAction: _reload,
          );
        }
        return _buildLive(context, snapshot.data!);
      },
    );
  }

  Widget _buildLive(BuildContext context, _DashboardData data) {
    final property = activeLocationProperty(data.properties);
    final openRequests = data.bookings.where((booking) {
      return {'sent', 'viewed', 'under_negotiation'}.contains(booking.status);
    }).toList();
    final upcoming = data.bookings.where((booking) {
      return {'accepted', 'secured', 'in_progress'}.contains(booking.status) &&
          booking.endAt.isAfter(DateTime.now());
    }).toList();
    final latestRequests = openRequests.take(3).toList();
    final metrics = [
      LocationMetric(
        label: 'Properties',
        value: '${data.properties.length}',
        delta: data.properties.any((item) => item.status == 'draft')
            ? 'Drafts need review'
            : 'Portfolio',
        icon: Icons.location_city_outlined,
        tone: LocationTone.blue,
        route: LocationOwnerRoutes.listing,
      ),
      LocationMetric(
        label: 'Open Requests',
        value: '${openRequests.length}',
        delta: openRequests.isEmpty ? 'Inbox clear' : 'Response needed',
        icon: Icons.inbox_outlined,
        tone: LocationTone.gold,
        route: LocationOwnerRoutes.requests,
      ),
      const LocationMetric(
        label: 'Opportunities',
        value: 'Live',
        delta: 'Apply to open needs',
        icon: Icons.travel_explore_outlined,
        tone: LocationTone.blue,
        route: LocationOwnerRoutes.opportunities,
      ),
      LocationMetric(
        label: 'Upcoming Shoots',
        value: '${upcoming.length}',
        delta: 'Accepted bookings',
        icon: Icons.movie_filter_outlined,
        tone: LocationTone.purple,
        route: LocationOwnerRoutes.calendar,
      ),
      LocationMetric(
        label: 'Earnings',
        value: 'PKR ${compactLocationMoney(data.payments.creditMinor ~/ 100)}',
        delta: data.payments.pendingReleaseMinor > 0
            ? 'Release pending'
            : 'Verified ledger',
        icon: Icons.account_balance_wallet_outlined,
        tone: LocationTone.green,
        route: LocationOwnerRoutes.earnings,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QuickStatsRow(metrics: metrics),
        const SizedBox(height: 12),
        LocationTwoColumn(
          left: property == null
              ? LocationSectionCard(
                  title: 'Property portfolio',
                  icon: Icons.add_location_alt_outlined,
                  selected: true,
                  child: CoreEmptyState(
                    icon: Icons.location_city_outlined,
                    title: 'Create your first property',
                    message:
                        'Add production areas, capacity, access details and a public listing.',
                    actionLabel: 'Create property',
                    onAction: () => Navigator.pushNamed(
                      context,
                      LocationOwnerRoutes.listing,
                    ),
                  ),
                )
              : _LivePropertyCard(
                  property: property,
                  fallbackImageUrl: data.userProfile.coverFile?.publicUrl ?? '',
                ),
          right: LocationSectionCard(
            title: 'Action required',
            icon: Icons.priority_high_rounded,
            tone: LocationTone.gold,
            child: _ActionList(
              property: property,
              openRequests: openRequests,
              upcoming: upcoming,
            ),
          ),
        ),
        const SizedBox(height: 12),
        LocationResponsiveGrid(
          minWidth: 280,
          children: [
            LocationSectionCard(
              title: 'Latest requests',
              icon: Icons.move_to_inbox_outlined,
              tone: LocationTone.blue,
              child: openRequests.isEmpty
                  ? _CompactStatus(
                      icon: Icons.inbox_outlined,
                      title: 'No open requests',
                      message:
                          'New location offers and counteroffers will appear here.',
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < latestRequests.length; i++)
                          _RequestPipelineRow(
                            booking: latestRequests[i],
                            showDivider: i != 0,
                          ),
                        const SizedBox(height: 4),
                        CoreSecondaryButton(
                          icon: Icons.open_in_new_rounded,
                          label: 'Open requests',
                          compact: true,
                          onTap: () => Navigator.pushNamed(
                            context,
                            LocationOwnerRoutes.requests,
                          ),
                        ),
                      ],
                    ),
            ),
            LocationSectionCard(
              title: 'Availability',
              icon: Icons.calendar_month_outlined,
              tone: LocationTone.purple,
              child: Column(
                children: [
                  LocationInfoRow(
                    icon: Icons.event_available_outlined,
                    label: 'Upcoming',
                    value: '${upcoming.length} bookings',
                  ),
                  LocationInfoRow(
                    icon: Icons.lock_clock_outlined,
                    label: 'Next shoot',
                    value: upcoming.isEmpty
                        ? 'None scheduled'
                        : shortLocationDate(upcoming.first.startAt),
                  ),
                  const SizedBox(height: 8),
                  CoreSecondaryButton(
                    icon: Icons.calendar_month_outlined,
                    label: 'Manage calendar',
                    compact: true,
                    onTap: () => Navigator.pushNamed(
                      context,
                      LocationOwnerRoutes.calendar,
                    ),
                  ),
                ],
              ),
            ),
            LocationSectionCard(
              title: 'Payments',
              icon: Icons.payments_outlined,
              tone: LocationTone.green,
              child: Column(
                children: [
                  LocationInfoRow(
                    icon: Icons.verified_outlined,
                    label: 'Credits',
                    value:
                        'PKR ${compactLocationMoney(data.payments.creditMinor ~/ 100)}',
                  ),
                  LocationInfoRow(
                    icon: Icons.pending_actions_outlined,
                    label: 'Pending release',
                    value:
                        'PKR ${compactLocationMoney(data.payments.pendingReleaseMinor ~/ 100)}',
                  ),
                  const SizedBox(height: 8),
                  CoreSecondaryButton(
                    icon: Icons.receipt_long_outlined,
                    label: 'Open earnings',
                    compact: true,
                    onTap: () => Navigator.pushNamed(
                      context,
                      LocationOwnerRoutes.earnings,
                    ),
                  ),
                ],
              ),
            ),
            LocationSectionCard(
              title: 'Open Opportunities',
              icon: Icons.travel_explore_outlined,
              tone: LocationTone.blue,
              child: Column(
                children: [
                  const LocationInfoRow(
                    icon: Icons.campaign_outlined,
                    label: 'Production needs',
                    value: 'Browse projects seeking locations',
                  ),
                  const LocationInfoRow(
                    icon: Icons.assignment_turned_in_outlined,
                    label: 'Applications',
                    value: 'Track submitted property pitches',
                  ),
                  const SizedBox(height: 8),
                  CorePrimaryButton(
                    icon: Icons.arrow_forward_rounded,
                    label: 'Browse opportunities',
                    compact: true,
                    onTap: () => Navigator.pushNamed(
                      context,
                      LocationOwnerRoutes.opportunities,
                    ),
                  ),
                ],
              ),
            ),
            LocationSectionCard(
              title: 'Safety & support',
              icon: Icons.health_and_safety_outlined,
              tone: LocationTone.danger,
              child: Column(
                children: [
                  CoreSecondaryButton(
                    icon: Icons.fact_check_outlined,
                    label: 'Check-in evidence',
                    compact: true,
                    onTap: () => Navigator.pushNamed(
                      context,
                      LocationOwnerRoutes.checkIn,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CoreSecondaryButton(
                    icon: Icons.support_agent_outlined,
                    label: 'Report an issue',
                    compact: true,
                    onTap: () => Navigator.pushNamed(
                      context,
                      CoreRoutes.report,
                      arguments: 'Location owner support',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The dashboard's top KPI rail — the shared dashboard-kit's quick-stat
/// tile row, reusing the exact same real metric values (`LocationMetric`)
/// the previous `LocationKpiRail` rendered.
class _QuickStatsRow extends StatelessWidget {
  final List<LocationMetric> metrics;

  const _QuickStatsRow({required this.metrics});

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
                  tone: _cineToneForLocation(metric.tone),
                  onTap: () => Navigator.pushNamed(context, metric.route),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Maps the location owner feature's own [LocationTone] palette onto the
/// dashboard-kit's [CineTone], matching the equivalence already used by
/// `cineToneFromColor` in location_owner_components.dart (both blue and
/// purple resolve to `information`).
CineTone _cineToneForLocation(LocationTone tone) => switch (tone) {
      LocationTone.gold => CineTone.premium,
      LocationTone.blue => CineTone.information,
      LocationTone.green => CineTone.positive,
      LocationTone.purple => CineTone.information,
      LocationTone.danger => CineTone.critical,
      LocationTone.neutral => CineTone.neutral,
    };

String _initialsFor(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

class _LivePropertyCard extends StatelessWidget {
  final LocationPropertyDto property;
  final String fallbackImageUrl;

  const _LivePropertyCard({
    required this.property,
    required this.fallbackImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return LocationSectionCard(
      title: 'Active property',
      icon: Icons.location_city_outlined,
      selected: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocationMediaFrame(
            imageUrl: property.mediaUrls.isEmpty
                ? fallbackImageUrl
                : property.mediaUrls.first,
            title: property.name,
            badge: readableLocationStatus(property.status),
            fallbackIcon: Icons.location_city_outlined,
            aspectRatio: 16 / 8.8,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(
                label: '${property.capacity ?? 0} crew',
                icon: Icons.groups_2_outlined,
                color: colors.infoBlue,
              ),
              StatusChip(
                label: '${property.parkingSpaces ?? 0} parking',
                icon: Icons.local_parking_outlined,
                color: colors.goldMid,
              ),
              if (property.powerBackup)
                StatusChip(
                  label: 'Power backup',
                  icon: Icons.bolt_outlined,
                  color: colors.success,
                ),
              if (property.accessible)
                StatusChip(
                  label: 'Accessible',
                  icon: Icons.accessible_outlined,
                  color: colors.infoPurple,
                ),
            ],
          ),
          const SizedBox(height: 12),
          LocationInfoRow(
            icon: Icons.place_outlined,
            label: 'Public area',
            value: property.publicAddress.isEmpty
                ? property.areaName
                : property.publicAddress,
          ),
          LocationInfoRow(
            icon: Icons.dashboard_customize_outlined,
            label: 'Shoot spaces',
            value: '${property.spaces.length}',
          ),
          LocationInfoRow(
            icon: Icons.star_outline_rounded,
            label: 'Rating',
            value: property.ratingAverage > 0
                ? property.ratingAverage.toStringAsFixed(1)
                : 'No reviews yet',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.rule_folder_outlined,
                  label: 'Rules',
                  compact: true,
                  onTap: () => Navigator.pushNamed(
                    context,
                    LocationOwnerRoutes.rules,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit property',
                  compact: true,
                  onTap: () => Navigator.pushNamed(
                    context,
                    LocationOwnerRoutes.listing,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionList extends StatelessWidget {
  final LocationPropertyDto? property;
  final List<Booking> openRequests;
  final List<Booking> upcoming;

  const _ActionList({
    required this.property,
    required this.openRequests,
    required this.upcoming,
  });

  @override
  Widget build(BuildContext context) {
    final actions = <({
      IconData icon,
      String kindLabel,
      String title,
      String detail,
      String route,
    })>[
      if (property == null)
        (
          icon: Icons.add_location_alt_outlined,
          kindLabel: 'Get started',
          title: 'Create a property profile',
          detail: 'Add the property before accepting booking requests.',
          route: LocationOwnerRoutes.listing,
        )
      else if (property!.status == 'draft')
        (
          icon: Icons.publish_outlined,
          kindLabel: 'Publish',
          title: 'Publish ${property!.name}',
          detail: 'Review rates and rules before making it discoverable.',
          route: LocationOwnerRoutes.listing,
        ),
      if (openRequests.isNotEmpty)
        (
          icon: Icons.inbox_outlined,
          kindLabel: 'Respond',
          title: '${openRequests.length} requests need a response',
          detail: 'Review dates, fee and production conditions.',
          route: LocationOwnerRoutes.requests,
        ),
      if (upcoming.isNotEmpty)
        (
          icon: Icons.fact_check_outlined,
          kindLabel: 'Prepare',
          title: 'Prepare the next handover',
          detail:
              'The next booking starts ${shortLocationDate(upcoming.first.startAt)}.',
          route: LocationOwnerRoutes.checkIn,
        ),
    ];
    if (actions.isEmpty) {
      return const _CompactStatus(
        icon: Icons.check_circle_outline_rounded,
        title: 'No urgent actions',
        message: 'New requests and inspection tasks will appear here.',
      );
    }
    return Column(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          PortalAttentionRow(
            kindLabel: actions[i].kindLabel,
            title: actions[i].title,
            meta: actions[i].detail,
            icon: actions[i].icon,
            onTap: () => Navigator.pushNamed(context, actions[i].route),
          ),
          if (i != actions.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _RequestPipelineRow extends StatelessWidget {
  final Booking booking;
  final bool showDivider;

  const _RequestPipelineRow({
    required this.booking,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final status = locationBookingStatusFromBooking(booking);
    void openRequest() => Navigator.pushNamed(
          context,
          LocationOwnerRoutes.requests,
          arguments: booking.publicId,
        );
    return PortalPipelineRow(
      initials: _initialsFor(booking.requester.displayName),
      title: booking.projectTitle,
      subtitle: booking.requester.displayName,
      metaLabel:
          '${locationBookingDates(booking)} · ${locationBookingAmount(booking)}',
      status: locationBookingStatusLabel(status),
      tone: cineToneFromColor(context, locationStatusColor(context, status)),
      ctaLabel: 'Review',
      showDivider: showDivider,
      onTap: openRequest,
      onCta: openRequest,
    );
  }
}

class _CompactStatus extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _CompactStatus({
    required this.icon,
    required this.title,
    required this.message,
  });

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.success, size: 22),
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
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
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

class _DashboardData {
  final UserProfile userProfile;
  final List<LocationPropertyDto> properties;
  final List<Booking> bookings;
  final PaymentDashboardDto payments;

  const _DashboardData({
    required this.userProfile,
    required this.properties,
    required this.bookings,
    required this.payments,
  });
}
