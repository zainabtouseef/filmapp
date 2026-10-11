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
import '../../../core/tour/tour_target.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/dashboard/dashboard_kit.dart';
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
    setState(() {
      _future = _load(force: true);
    });
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
    final accountName = _auth?.user?.displayName ?? 'Location Partner';
    final propertyName = property?.name ?? accountName;
    return PortalDashboardPage(
      children: [
        PortalHeroCard(
          initials: _initialsFor(propertyName),
          name: propertyName,
          badgeLabel: property == null
              ? 'Profile setup'
              : readableLocationStatus(property.status),
          stats: [
            PortalHeroStat(
              value: '${data.properties.length}',
              label: 'Properties',
            ),
            PortalHeroStat(
              value: '${openRequests.length}',
              label: 'Open requests',
            ),
            PortalHeroStat(
              value: '${upcoming.length}',
              label: 'Upcoming shoots',
            ),
          ],
          ctaLabel: property == null ? 'Create property' : 'Manage property',
          onCta: () => Navigator.pushNamed(
            context,
            LocationOwnerRoutes.listing,
          ),
          secondaryIcon: Icons.calendar_month_outlined,
          onSecondary: () => Navigator.pushNamed(
            context,
            LocationOwnerRoutes.calendar,
          ),
        ),
        TourTarget(
          id: 'location.dashboard.commandCentre',
          child: PortalCommandCenter(
            eyebrow: 'Location operations',
            title: 'Property Command Centre',
            subtitle:
                'Portfolio readiness, requests and shoot access in one view.',
            icon: Icons.location_city_outlined,
            primaryTitle:
                property == null ? 'Portfolio setup' : 'Active property',
            actionLabel:
                property == null ? 'Create property' : 'Manage property',
            onAction: () => Navigator.pushNamed(
              context,
              LocationOwnerRoutes.listing,
            ),
            primary: property == null
                ? const CoreEmptyState(
                    icon: Icons.add_location_alt_outlined,
                    title: 'Create your first property',
                    message:
                        'Add production areas, capacity, access details and a public listing.',
                  )
                : Column(
                    children: [
                      PortalCommandDataRow(
                        icon: Icons.apartment_outlined,
                        label: 'Property',
                        value: property.name,
                      ),
                      PortalCommandDataRow(
                        icon: Icons.place_outlined,
                        label: 'Public area',
                        value: property.publicAddress.isEmpty
                            ? property.areaName
                            : property.publicAddress,
                      ),
                      PortalCommandDataRow(
                        icon: Icons.dashboard_customize_outlined,
                        label: 'Shoot spaces',
                        value: '${property.spaces.length}',
                      ),
                      PortalCommandDataRow(
                        icon: Icons.verified_outlined,
                        label: 'Status',
                        value: readableLocationStatus(property.status),
                      ),
                    ],
                  ),
            actions: [
              PortalCommandAction(
                icon: Icons.move_to_inbox_outlined,
                title: 'Booking requests',
                subtitle: 'Review scope, dates and location terms',
                value: '${openRequests.length}',
                onTap: () => Navigator.pushNamed(
                  context,
                  LocationOwnerRoutes.requests,
                ),
              ),
              PortalCommandAction(
                icon: Icons.calendar_month_outlined,
                title: 'Availability calendar',
                subtitle: upcoming.isEmpty
                    ? 'No upcoming shoots'
                    : '${upcoming.length} upcoming shoot(s)',
                value: '${upcoming.length}',
                onTap: () => Navigator.pushNamed(
                  context,
                  LocationOwnerRoutes.calendar,
                ),
              ),
              PortalCommandAction(
                icon: Icons.rule_folder_outlined,
                title: 'Rules and restrictions',
                subtitle: 'Keep access and production limits current',
                onTap: () => Navigator.pushNamed(
                  context,
                  LocationOwnerRoutes.rules,
                ),
              ),
              PortalCommandAction(
                icon: Icons.health_and_safety_outlined,
                title: 'Safety and inspections',
                subtitle: 'Open check-in evidence and support',
                onTap: () => Navigator.pushNamed(
                  context,
                  LocationOwnerRoutes.checkIn,
                ),
              ),
            ],
          ),
        ),
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
            TourTarget(
              id: 'location.dashboard.safety',
              child: LocationSectionCard(
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
                      onTap: property == null
                          ? null
                          : () => Navigator.pushNamed(
                                context,
                                CoreRoutes.report,
                                arguments: {
                                  'reason':
                                      'Location issue for ${property.name}',
                                  'entity_type': 'location_property',
                                  'entity_id': property.publicId,
                                },
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _initialsFor(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
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
