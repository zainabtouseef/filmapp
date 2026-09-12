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
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/provider_workspace_hero.dart';
import '../models/media_equipment_models.dart';
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
        message: 'Preview mode. Sign in to load equipment operations.',
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
    final metrics = [
      MediaMetric(
        label: 'Inventory',
        value: '${data.items.length}',
        delta:
            '${data.items.where((item) => item.status == 'available').length} available',
        icon: Icons.videocam_outlined,
        tone: MediaTone.blue,
        route: MediaEquipmentRoutes.inventory,
      ),
      MediaMetric(
        label: 'Requests',
        value: '${openRequests.length}',
        delta: 'open decisions',
        icon: Icons.inbox_outlined,
        tone: MediaTone.gold,
        route: MediaEquipmentRoutes.requests,
      ),
      const MediaMetric(
        label: 'Opportunities',
        value: 'Live',
        delta: 'Open production needs',
        icon: Icons.travel_explore_outlined,
        tone: MediaTone.blue,
        route: MediaEquipmentRoutes.opportunities,
      ),
      MediaMetric(
        label: 'Utilization',
        value: '$utilization%',
        delta: 'booked or service',
        icon: Icons.query_stats_outlined,
        tone: MediaTone.green,
        route: MediaEquipmentRoutes.availability,
      ),
      MediaMetric(
        label: 'Inspections',
        value: '${pendingInspections.length}',
        delta: 'awaiting closure',
        icon: Icons.fact_check_outlined,
        tone: MediaTone.purple,
        route: MediaEquipmentRoutes.handover,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProviderWorkspaceHero(
          imageUrl: data.userProfile.coverFile?.publicUrl ?? '',
          avatarUrl: data.userProfile.avatarFile?.publicUrl,
          eyebrow: 'Camera, grip and equipment services',
          title: data.profile?.name ?? data.displayName,
          summary: data.profile?.bio.trim().isNotEmpty == true
              ? data.profile!.bio
              : 'Show directors the equipment, operator support and production coverage available for their next shoot.',
          badge: data.profile?.visibility == 'public'
              ? 'Director visible'
              : 'Profile setup',
          fallbackIcon: Icons.video_camera_back_outlined,
          accentColor: colors.infoBlue,
          facts: [
            ProviderHeroFact(
              icon: Icons.inventory_2_outlined,
              label: 'Inventory',
              value: '${data.items.length} tracked asset(s)',
            ),
            ProviderHeroFact(
              icon: Icons.widgets_outlined,
              label: 'Packages',
              value: '${data.packages.length} production kit(s)',
            ),
            ProviderHeroFact(
              icon: Icons.location_on_outlined,
              label: 'Coverage',
              value: data.profile?.coverage.isNotEmpty == true
                  ? data.profile!.coverage
                  : data.userProfile.city?.name ?? 'Add coverage',
            ),
          ],
          primaryLabel: 'Manage inventory',
          primaryIcon: Icons.inventory_2_outlined,
          onPrimary: () =>
              Navigator.pushNamed(context, MediaEquipmentRoutes.inventory),
          secondaryLabel: 'Edit provider profile',
          secondaryIcon: Icons.edit_outlined,
          onSecondary: () =>
              Navigator.pushNamed(context, MediaEquipmentRoutes.profile),
        ),
        const SizedBox(height: 14),
        MediaKpiRail(metrics: metrics),
        const SizedBox(height: 12),
        MediaTwoColumn(
          left: MediaSectionCard(
            title: 'Workspace Readiness',
            icon: Icons.storefront_outlined,
            selected: data.profile != null,
            child: data.profile == null
                ? CoreEmptyState(
                    icon: Icons.storefront_outlined,
                    title: 'Provider profile required',
                    message:
                        'Create the business identity before publishing inventory.',
                    actionLabel: 'Create profile',
                    onAction: () => Navigator.pushNamed(
                      context,
                      MediaEquipmentRoutes.profile,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: colors.infoBlue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.video_camera_back_outlined,
                              color: colors.infoBlue,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.profile!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.cardLabel.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data.profile!.coverage.isEmpty
                                      ? 'Coverage not configured'
                                      : data.profile!.coverage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.smallMeta.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusChip(
                            label: _title(data.profile!.verificationStatus),
                            color:
                                data.profile!.verificationStatus == 'verified'
                                    ? colors.success
                                    : colors.goldMid,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      MediaInfoRow(
                        icon: Icons.inventory_2_outlined,
                        label: 'Inventory',
                        value: '${data.items.length} assets',
                      ),
                      MediaInfoRow(
                        icon: Icons.widgets_outlined,
                        label: 'Packages',
                        value:
                            '${data.packages.where((item) => item.status == 'published').length} published',
                      ),
                      MediaInfoRow(
                        icon: Icons.visibility_outlined,
                        label: 'Director discovery',
                        value: _title(data.profile!.visibility),
                      ),
                    ],
                  ),
          ),
          right: MediaSectionCard(
            title: 'Action Required',
            icon: Icons.priority_high_rounded,
            child: pendingInspections.isEmpty && openRequests.isEmpty
                ? const CoreEmptyState(
                    icon: Icons.task_alt_outlined,
                    title: 'No urgent actions',
                    message:
                        'Booking decisions and inspection signatures are current.',
                  )
                : Column(
                    children: [
                      if (openRequests.isNotEmpty)
                        _ActionRow(
                          icon: Icons.move_to_inbox_outlined,
                          title: '${openRequests.length} booking request(s)',
                          subtitle: 'Review scope, dates, price, and terms',
                          onTap: () => Navigator.pushNamed(
                            context,
                            MediaEquipmentRoutes.requests,
                          ),
                        ),
                      if (pendingInspections.isNotEmpty)
                        _ActionRow(
                          icon: Icons.fact_check_outlined,
                          title:
                              '${pendingInspections.length} open inspection(s)',
                          subtitle: 'Capture condition and required signatures',
                          onTap: () => Navigator.pushNamed(
                            context,
                            pendingInspections.first.inspectionType == 'return'
                                ? MediaEquipmentRoutes.returns
                                : MediaEquipmentRoutes.handover,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        MediaResponsiveGrid(
          minWidth: 280,
          children: [
            _DashboardBlock(
              title: 'Recent Requests',
              icon: Icons.move_to_inbox_outlined,
              child: data.bookings.isEmpty
                  ? const Text('No equipment bookings yet.')
                  : Column(
                      children: [
                        for (final booking in data.bookings.take(3))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => Navigator.pushNamed(
                                context,
                                MediaEquipmentRoutes.requests,
                                arguments: booking.publicId,
                              ),
                              child: GlassSectionCard(
                                radius: 8,
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Project ${booking.projectId}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.cardLabel
                                                .copyWith(
                                              color: colors.textPrimary,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            booking.requester.displayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.smallMeta
                                                .copyWith(
                                              color: colors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    StatusChip(
                                      label: _title(booking.status),
                                      color: colors.goldMid,
                                    ),
                                  ],
                                ),
                              ),
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

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: GlassSectionCard(
          radius: 8,
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
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.iconMuted),
            ],
          ),
        ),
      ),
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
