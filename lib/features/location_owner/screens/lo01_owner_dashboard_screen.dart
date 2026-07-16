import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/location_owner_demo_data.dart';
import '../routes/location_owner_routes.dart';
import '../widgets/location_owner_components.dart';

class LO01OwnerDashboardScreen extends StatelessWidget {
  const LO01OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = LocationOwnerDemoStore.instance;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final property = store.activeProperty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocationKpiRail(metrics: LocationOwnerDemoData.metrics),
            const SizedBox(height: 12),
            LocationTwoColumn(
              left: LocationSectionCard(
                title: 'Primary workload',
                icon: Icons.location_city_outlined,
                selected: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocationMediaFrame(
                      imageUrl: property.imageUrl,
                      title: property.name,
                      badge: property.publicAddress,
                      fallbackIcon: Icons.location_city_outlined,
                      aspectRatio: 16 / 8.8,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusChip(
                          label: '${property.capacity} crew capacity',
                          icon: Icons.groups_2_outlined,
                          color: colors.infoBlue,
                        ),
                        StatusChip(
                          label: '${property.parking} parking',
                          icon: Icons.local_parking_outlined,
                          color: colors.goldMid,
                        ),
                        StatusChip(
                          label: property.powerBackup
                              ? 'Power backup'
                              : 'No backup',
                          icon: Icons.bolt_outlined,
                          color: property.powerBackup
                              ? colors.success
                              : colors.textSecondary,
                        ),
                        StatusChip(
                          label: '${property.rating.toStringAsFixed(1)} rating',
                          icon: Icons.star_outline_rounded,
                          color: colors.infoPurple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LocationInfoRow(
                      icon: Icons.security_outlined,
                      label: 'Public address',
                      value: property.publicAddress,
                    ),
                    LocationInfoRow(
                      icon: Icons.lock_outline_rounded,
                      label: 'Exact address',
                      value: store.exactAddressEncrypted
                          ? property.encryptedAddressHint
                          : 'Shared after contract',
                    ),
                    LocationInfoRow(
                      icon: Icons.event_available_outlined,
                      label: 'Next secured shoot',
                      value: 'River Lights - Jul 20',
                    ),
                    const SizedBox(height: 10),
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
                            icon: Icons.calendar_month_outlined,
                            label: 'Calendar',
                            compact: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              LocationOwnerRoutes.calendar,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              right: LocationSectionCard(
                title: 'Action required',
                icon: Icons.priority_high_rounded,
                child: store.activeTasks.isEmpty
                    ? _CompactEmptyTasks(onReset: () {
                        locationSnack(
                            context, 'No urgent owner tasks right now');
                      })
                    : LocationTaskRail(tasks: store.activeTasks),
              ),
            ),
            const SizedBox(height: 12),
            LocationResponsiveGrid(
              minWidth: 280,
              children: [
                _DashboardSummaryCard(
                  title: 'Pending requests',
                  icon: Icons.move_to_inbox_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final request
                          in LocationOwnerDemoData.requests.take(2))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.pushNamed(
                              context,
                              LocationOwnerRoutes.requests,
                              arguments: request.id,
                            ),
                            child: GlassSectionCard(
                              radius: 16,
                              padding: const EdgeInsets.all(11),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          request.project,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                              AppTextStyles.cardLabel.copyWith(
                                            color: colors.textPrimary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${request.dates} - ${request.budget}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                              AppTextStyles.smallMeta.copyWith(
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  LocationBookingStatusChip(
                                    status: store.requestStatus(request),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _DashboardSummaryCard(
                  title: 'Deposit history',
                  icon: Icons.account_balance_wallet_outlined,
                  child: Column(
                    children: [
                      LocationInfoRow(
                        icon: Icons.lock_clock_outlined,
                        label: 'Held',
                        value: locationMoney(store.depositHeldAmount),
                      ),
                      LocationInfoRow(
                        icon: Icons.verified_outlined,
                        label: 'Released',
                        value: locationMoney(store.depositReleasedAmount),
                      ),
                      LocationInfoRow(
                        icon: Icons.report_problem_outlined,
                        label: 'Claim review',
                        value: store.damageClaimOpen ? 'Open' : 'None',
                      ),
                      const SizedBox(height: 8),
                      CoreSecondaryButton(
                        icon: Icons.receipt_long_outlined,
                        label: 'Open ledger',
                        compact: true,
                        onTap: () => Navigator.pushNamed(
                          context,
                          LocationOwnerRoutes.earnings,
                        ),
                      ),
                    ],
                  ),
                ),
                _DashboardSummaryCard(
                  title: 'Performance pulse',
                  icon: Icons.analytics_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocationMiniBarChart(
                        values: const [18, 30, 26, 41, 34, 49, 44],
                        colors: [
                          colors.goldMid,
                          colors.infoBlue,
                          colors.infoPurple,
                        ],
                        height: 92,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Better night-shoot pricing can lift conversion by 12%.',
                        style: AppTextStyles.smallMeta.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CoreSecondaryButton(
                        icon: Icons.open_in_new_rounded,
                        label: 'View performance',
                        compact: true,
                        onTap: () => Navigator.pushNamed(
                          context,
                          LocationOwnerRoutes.performance,
                        ),
                      ),
                    ],
                  ),
                ),
                _DashboardSummaryCard(
                  title: 'Safety links',
                  icon: Icons.health_and_safety_outlined,
                  child: Column(
                    children: [
                      CoreSecondaryButton(
                        icon: Icons.fact_check_outlined,
                        label: 'Check-in',
                        compact: true,
                        onTap: () => Navigator.pushNamed(
                          context,
                          LocationOwnerRoutes.checkIn,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CoreSecondaryButton(
                        icon: Icons.verified_user_outlined,
                        label: 'Check-out',
                        compact: true,
                        onTap: () => Navigator.pushNamed(
                          context,
                          LocationOwnerRoutes.checkOut,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CoreSecondaryButton(
                        icon: Icons.support_agent_outlined,
                        label: 'Report issue',
                        compact: true,
                        onTap: () => Navigator.pushNamed(
                          context,
                          CoreRoutes.report,
                          arguments: 'Location owner safety support',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _DashboardSummaryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DashboardSummaryCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LocationSectionCard(title: title, icon: icon, child: child);
  }
}

class _CompactEmptyTasks extends StatelessWidget {
  final VoidCallback onReset;

  const _CompactEmptyTasks({required this.onReset});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              color: colors.success, size: 24),
          const SizedBox(height: 8),
          Text(
            'No urgent tasks',
            style: AppTextStyles.cardLabel.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Requests, inspection evidence and deposit reviews will appear here.',
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          CoreSecondaryButton(
            icon: Icons.refresh_rounded,
            label: 'Check again',
            compact: true,
            onTap: onReset,
          ),
        ],
      ),
    );
  }
}
