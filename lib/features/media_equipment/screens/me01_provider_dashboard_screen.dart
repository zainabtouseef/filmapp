import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/media_equipment_demo_data.dart';
import '../routes/media_equipment_routes.dart';
import '../widgets/media_equipment_components.dart';

class ME01ProviderDashboardScreen extends StatelessWidget {
  const ME01ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = MediaEquipmentDemoStore.instance;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final item = store.activeItem;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MediaKpiRail(metrics: MediaEquipmentDemoData.metrics),
            const SizedBox(height: 12),
            MediaTwoColumn(
              left: MediaSectionCard(
                title: 'Today workload',
                icon: Icons.local_shipping_outlined,
                selected: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MediaFrame(
                      imageUrl: item.imageUrl,
                      title: item.modelName,
                      badge: item.serial,
                      fallbackIcon: Icons.videocam_outlined,
                      aspectRatio: 16 / 8.8,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusChip(
                          label: item.category.toUpperCase(),
                          icon: Icons.category_outlined,
                          color: colors.infoBlue,
                        ),
                        StatusChip(
                          label: item.available ? 'AVAILABLE' : 'BOOKED',
                          icon: item.available
                              ? Icons.check_circle_outline
                              : Icons.lock_clock_outlined,
                          color:
                              item.available ? colors.success : colors.goldMid,
                        ),
                        StatusChip(
                          label: mediaMoney(item.dayRate),
                          icon: Icons.payments_outlined,
                          color: colors.goldMid,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    MediaInfoRow(
                      icon: Icons.confirmation_number_outlined,
                      label: 'Serial',
                      value: item.serial,
                    ),
                    MediaInfoRow(
                      icon: Icons.verified_outlined,
                      label: 'Condition',
                      value: item.condition,
                    ),
                    MediaInfoRow(
                      icon: Icons.location_city_outlined,
                      label: 'Pickup hub',
                      value: item.city,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: CoreSecondaryButton(
                            icon: Icons.qr_code_scanner_rounded,
                            label: 'Handover',
                            compact: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              MediaEquipmentRoutes.handover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CorePrimaryButton(
                            icon: Icons.calendar_month_outlined,
                            label: 'Schedule',
                            compact: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              MediaEquipmentRoutes.availability,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              right: MediaSectionCard(
                title: 'Action required',
                icon: Icons.priority_high_rounded,
                child: store.activeTasks.isEmpty
                    ? _EmptyTasks()
                    : MediaTaskRail(tasks: store.activeTasks),
              ),
            ),
            const SizedBox(height: 12),
            MediaResponsiveGrid(
              minWidth: 280,
              children: [
                _DashboardBlock(
                  title: 'Pending requests',
                  icon: Icons.move_to_inbox_outlined,
                  child: Column(
                    children: [
                      for (final request
                          in MediaEquipmentDemoData.requests.take(2))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.pushNamed(
                              context,
                              MediaEquipmentRoutes.requests,
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
                                  MediaBookingStatusChip(
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
                _DashboardBlock(
                  title: 'Utilization',
                  icon: Icons.query_stats_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MediaMiniBarChart(
                        values: const [24, 38, 31, 49, 44, 57, 52],
                        colors: [
                          colors.goldMid,
                          colors.infoBlue,
                          colors.infoPurple,
                        ],
                        height: 94,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Camera bodies and drone packages are driving the week.',
                        style: AppTextStyles.smallMeta.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _DashboardBlock(
                  title: 'Quick actions',
                  icon: Icons.bolt_outlined,
                  child: MetricActionRail(
                    items: [
                      MetricActionItem(
                        icon: Icons.add_box_outlined,
                        value: 'Add',
                        title: 'Inventory',
                        subtitle: 'New item',
                        accentColor: colors.goldMid,
                        onTap: () {
                          store.addDemoInventoryItem();
                          Navigator.pushNamed(
                            context,
                            MediaEquipmentRoutes.inventory,
                          );
                        },
                      ),
                      MetricActionItem(
                        icon: Icons.inventory_2_outlined,
                        value: 'Build',
                        title: 'Package',
                        subtitle: 'Kit bundle',
                        accentColor: colors.infoBlue,
                        onTap: () => Navigator.pushNamed(
                          context,
                          MediaEquipmentRoutes.packages,
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
      },
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

class _EmptyTasks extends StatelessWidget {
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
            'Pickup, return and negotiation alerts will appear here.',
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
