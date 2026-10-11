import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/operations/operations_controller.dart';
import '../../../core/operations/operations_models.dart';
import '../../../core/profile/profile_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/dashboard/dashboard_kit.dart';
import '../../../shared/formatters/cine_format.dart';
import '../routes/media_equipment_routes.dart';
import '../widgets/media_equipment_components.dart';

class ME01ProviderDashboardScreen extends StatefulWidget {
  const ME01ProviderDashboardScreen({super.key});

  @override
  State<ME01ProviderDashboardScreen> createState() =>
      _ME01ProviderDashboardScreenState();
}

class _ME01ProviderDashboardScreenState
    extends State<ME01ProviderDashboardScreen> {
  Future<_DashboardData>? _dataFuture;
  AuthController? _auth;
  OperationsController? _operations;
  BookingsController? _bookings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.maybeOf(context);
    final operations = OperationsScope.maybeOf(context);
    final bookings = BookingsScope.maybeOf(context);
    if (auth == null || operations == null || bookings == null) return;
    if (identical(auth, _auth) &&
        identical(operations, _operations) &&
        identical(bookings, _bookings)) {
      return;
    }
    _auth = auth;
    _operations = operations;
    _bookings = bookings;
    _dataFuture = _load(auth, operations, bookings);
  }

  Future<_DashboardData> _load(
    AuthController auth,
    OperationsController operations,
    BookingsController bookings,
  ) async {
    final values = await Future.wait([
      operations.equipmentProfile(force: true),
      operations.equipmentItems(force: true),
      operations.equipmentPackages(force: true),
      operations.equipmentInspections(force: true),
      bookings.bookings(role: 'provider', force: true),
      auth.myProfile(),
    ]);
    return _DashboardData(
      displayName: auth.user?.displayName ?? 'Equipment Provider',
      profile: values[0] as EquipmentProfileDto?,
      items: values[1] as List<EquipmentItemDto>,
      packages: values[2] as List<EquipmentPackageDto>,
      inspections: values[3] as List<EquipmentInspectionDto>,
      bookings: (values[4] as List<Booking>)
          .where((booking) => booking.category == 'equipment')
          .toList(),
      userProfile: values[5] as UserProfile,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_dataFuture == null) {
      return const InlineNotice(
        message: 'Sign in to load live equipment operations.',
        icon: Icons.visibility_outlined,
      );
    }
    return FutureBuilder<_DashboardData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const InlineNotice(
            message: 'Loading equipment workspace...',
            icon: Icons.hourglass_top_rounded,
          );
        }
        if (snapshot.hasError) {
          return InlineNotice(
            message: 'Could not load equipment workspace: ${snapshot.error}',
            icon: Icons.cloud_off_outlined,
          );
        }
        final data = snapshot.data!;
        return _DashboardBody(data: data);
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final _DashboardData data;

  const _DashboardBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final openRequests = data.bookings
        .where(
          (booking) =>
              {'sent', 'viewed', 'under_negotiation'}.contains(booking.status),
        )
        .toList();
    final unavailable =
        data.items.where((item) => item.status != 'available').length;
    final utilization = data.items.isEmpty
        ? 0
        : ((unavailable / data.items.length) * 100).round();
    final pendingInspections = data.inspections
        .where((inspection) => inspection.status != 'confirmed')
        .toList();
    final recentBookings = data.bookings.take(3).toList();
    return PortalDashboardPage(
      children: [
        PortalHeroCard(
          initials: _providerInitials(data.profile?.name ?? data.displayName),
          name: data.profile?.name ?? data.displayName,
          badgeLabel: data.profile?.visibility == 'public'
              ? 'Director visible'
              : 'Profile setup',
          stats: [
            PortalHeroStat(
              value: '${data.items.length}',
              label: 'Inventory',
            ),
            PortalHeroStat(
              value: '${data.packages.length}',
              label: 'Packages',
            ),
            PortalHeroStat(
              value: '$utilization%',
              label: 'Utilization',
            ),
          ],
          ctaLabel: 'Manage inventory',
          onCta: () =>
              Navigator.pushNamed(context, MediaEquipmentRoutes.inventory),
          secondaryIcon: Icons.edit_outlined,
          onSecondary: () =>
              Navigator.pushNamed(context, MediaEquipmentRoutes.profile),
        ),
        PortalCommandCenter(
          eyebrow: 'Equipment operations',
          title: 'Fleet Command Centre',
          subtitle: 'Provider readiness, bookings and inspections in one view.',
          icon: Icons.video_camera_back_outlined,
          primaryTitle:
              data.profile == null ? 'Workspace setup' : 'Provider profile',
          actionLabel: data.profile == null ? 'Create profile' : 'Edit profile',
          onAction: () => Navigator.pushNamed(
            context,
            MediaEquipmentRoutes.profile,
          ),
          primary: data.profile == null
              ? const CoreEmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'Provider profile required',
                  message:
                      'Create the business identity before publishing inventory.',
                )
              : Column(
                  children: [
                    PortalCommandDataRow(
                      icon: Icons.storefront_outlined,
                      label: 'Provider',
                      value: data.profile!.name,
                    ),
                    PortalCommandDataRow(
                      icon: Icons.place_outlined,
                      label: 'Coverage',
                      value: data.profile!.coverage.isEmpty
                          ? 'Not configured'
                          : data.profile!.coverage,
                    ),
                    PortalCommandDataRow(
                      icon: Icons.inventory_2_outlined,
                      label: 'Inventory',
                      value: '${data.items.length} assets',
                    ),
                    PortalCommandDataRow(
                      icon: Icons.visibility_outlined,
                      label: 'Discovery',
                      value: _title(data.profile!.visibility),
                    ),
                  ],
                ),
          actions: [
            PortalCommandAction(
              icon: Icons.move_to_inbox_outlined,
              title: 'Booking requests',
              subtitle: 'Review scope, dates, price and terms',
              value: '${openRequests.length}',
              onTap: () => Navigator.pushNamed(
                context,
                MediaEquipmentRoutes.requests,
              ),
            ),
            PortalCommandAction(
              icon: Icons.fact_check_outlined,
              title: 'Open inspections',
              subtitle: 'Capture condition and required signatures',
              value: '${pendingInspections.length}',
              onTap: () => Navigator.pushNamed(
                context,
                pendingInspections.isNotEmpty &&
                        pendingInspections.first.inspectionType == 'return'
                    ? MediaEquipmentRoutes.returns
                    : MediaEquipmentRoutes.handover,
              ),
            ),
            PortalCommandAction(
              icon: Icons.widgets_outlined,
              title: 'Published packages',
              subtitle: 'Manage bundles and marketplace pricing',
              value:
                  '${data.packages.where((item) => item.status == 'published').length}',
              onTap: () => Navigator.pushNamed(
                context,
                MediaEquipmentRoutes.packages,
              ),
            ),
            PortalCommandAction(
              icon: Icons.travel_explore_outlined,
              title: 'Open opportunities',
              subtitle: 'Apply equipment to active productions',
              onTap: () => Navigator.pushNamed(
                context,
                MediaEquipmentRoutes.opportunities,
              ),
            ),
          ],
        ),
        MediaResponsiveGrid(
          minWidth: 280,
          children: [
            _DashboardBlock(
              title: 'Recent Requests',
              icon: Icons.move_to_inbox_outlined,
              child: recentBookings.isEmpty
                  ? const Text('No equipment bookings yet.')
                  : Column(
                      children: [
                        for (var i = 0; i < recentBookings.length; i++)
                          PortalPipelineRow(
                            initials: recentBookings[i].requester.displayName,
                            title: recentBookings[i].projectTitle,
                            subtitle: recentBookings[i].requester.displayName,
                            metaLabel:
                                CineFormat.date(recentBookings[i].startAt),
                            status: _title(recentBookings[i].status),
                            tone: CineTone.premium,
                            ctaLabel: 'Review',
                            showDivider: i != 0,
                            onTap: () => Navigator.pushNamed(
                              context,
                              MediaEquipmentRoutes.requests,
                              arguments: recentBookings[i].publicId,
                            ),
                            onCta: () => Navigator.pushNamed(
                              context,
                              MediaEquipmentRoutes.requests,
                              arguments: recentBookings[i].publicId,
                            ),
                          ),
                      ],
                    ),
            ),
            _DashboardBlock(
              title: 'Fleet Health',
              icon: Icons.health_and_safety_outlined,
              child: Column(
                children: [
                  MediaInfoRow(
                    icon: Icons.check_circle_outline,
                    label: 'Available',
                    value:
                        '${data.items.where((item) => item.status == 'available').length}',
                  ),
                  MediaInfoRow(
                    icon: Icons.event_busy_outlined,
                    label: 'Reserved',
                    value:
                        '${data.items.where((item) => item.status == 'reserved').length}',
                  ),
                  MediaInfoRow(
                    icon: Icons.build_outlined,
                    label: 'Maintenance',
                    value:
                        '${data.items.where((item) => item.status == 'maintenance').length}',
                  ),
                ],
              ),
            ),
            _DashboardBlock(
              title: 'Quick Actions',
              icon: Icons.bolt_outlined,
              child: MetricActionRail(
                items: [
                  MetricActionItem(
                    icon: Icons.add_box_outlined,
                    value: 'Add',
                    title: 'Inventory',
                    subtitle: 'Asset',
                    accentColor: colors.goldMid,
                    onTap: () => Navigator.pushNamed(
                      context,
                      MediaEquipmentRoutes.inventory,
                    ),
                  ),
                  MetricActionItem(
                    icon: Icons.inventory_2_outlined,
                    value: 'Build',
                    title: 'Package',
                    subtitle: 'Bundle',
                    accentColor: colors.infoBlue,
                    onTap: () => Navigator.pushNamed(
                      context,
                      MediaEquipmentRoutes.packages,
                    ),
                  ),
                  MetricActionItem(
                    icon: Icons.travel_explore_outlined,
                    value: 'Open',
                    title: 'Opportunities',
                    subtitle: 'Apply',
                    accentColor: colors.success,
                    onTap: () => Navigator.pushNamed(
                      context,
                      MediaEquipmentRoutes.opportunities,
                    ),
                  ),
                  MetricActionItem(
                    icon: Icons.support_agent_outlined,
                    value: 'Report',
                    title: 'Issue',
                    subtitle: 'Support',
                    accentColor: colors.danger,
                    onTap: () => Navigator.pushNamed(
                      context,
                      CoreRoutes.report,
                      arguments: 'Media equipment provider support',
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

class _DashboardBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DashboardBlock({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MediaSectionCard(title: title, icon: icon, child: child);
  }
}

class _DashboardData {
  final String displayName;
  final UserProfile userProfile;
  final EquipmentProfileDto? profile;
  final List<EquipmentItemDto> items;
  final List<EquipmentPackageDto> packages;
  final List<EquipmentInspectionDto> inspections;
  final List<Booking> bookings;

  const _DashboardData({
    required this.displayName,
    required this.userProfile,
    required this.profile,
    required this.items,
    required this.packages,
    required this.inspections,
    required this.bookings,
  });
}

String _title(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _providerInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}
