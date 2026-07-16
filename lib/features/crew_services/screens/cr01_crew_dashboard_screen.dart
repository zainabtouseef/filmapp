import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/crew_services_demo_data.dart';
import '../routes/crew_services_routes.dart';
import '../widgets/crew_services_components.dart';

class CR01CrewDashboardScreen extends StatelessWidget {
  const CR01CrewDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = CrewServicesDemoStore.instance;
    final profile = CrewServicesDemoData.profile;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CrewKpiRail(metrics: CrewServicesDemoData.metrics),
            const SizedBox(height: 12),
            CrewTwoColumn(
              left: CrewSectionCard(
                title: 'Next production day',
                icon: Icons.movie_filter_outlined,
                selected: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CrewMediaFrame(
                      imageUrl: profile.imageUrl,
                      title: profile.name,
                      badge: profile.service,
                      fallbackIcon: Icons.groups_2_outlined,
                      aspectRatio: 16 / 8.8,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusChip(
                          label: '${profile.rating.toStringAsFixed(1)} RATING',
                          icon: Icons.star_outline_rounded,
                          color: colors.infoPurple,
                        ),
                        StatusChip(
                          label: crewMoney(profile.dayRate),
                          icon: Icons.payments_outlined,
                          color: colors.goldMid,
                        ),
                        StatusChip(
                          label: profile.city.toUpperCase(),
                          icon: Icons.location_city_outlined,
                          color: colors.infoBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CrewInfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Next shoot',
                      value: 'River Lights - Jul 20',
                    ),
                    CrewInfoRow(
                      icon: Icons.construction_outlined,
                      label: 'Owned kit',
                      value: profile.ownedKit,
                    ),
                    CrewInfoRow(
                      icon: Icons.verified_outlined,
                      label: 'Experience',
                      value: profile.experience,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: CoreSecondaryButton(
                            icon: Icons.video_library_outlined,
                            label: 'Portfolio',
                            compact: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              CrewServicesRoutes.portfolio,
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
                              CrewServicesRoutes.availability,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              right: CrewSectionCard(
                title: 'Action required',
                icon: Icons.priority_high_rounded,
                child: store.activeTasks.isEmpty
                    ? _EmptyTasks()
                    : CrewTaskRail(tasks: store.activeTasks),
              ),
            ),
            const SizedBox(height: 12),
            CrewResponsiveGrid(
              minWidth: 280,
              children: [
                CrewSectionCard(
                  title: 'Request pulse',
                  icon: Icons.move_to_inbox_outlined,
                  child: Column(
                    children: [
                      for (final request
                          in CrewServicesDemoData.requests.take(2))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.pushNamed(
                              context,
                              CrewServicesRoutes.requests,
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
                                  CrewStatusChip(
                                    status: store.requestStatus(request),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      CoreSecondaryButton(
                        icon: Icons.open_in_new_rounded,
                        label: 'Open inbox',
                        compact: true,
                        onTap: () => Navigator.pushNamed(
                          context,
                          CrewServicesRoutes.requests,
                        ),
                      ),
                    ],
                  ),
                ),
                CrewSectionCard(
                  title: 'Profile strength',
                  icon: Icons.badge_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: store.profilePublished ? 0.86 : 0.62,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(999),
                        backgroundColor: colors.border,
                        color: colors.success,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Credits, kit proof and recent stills keep the crew boosted in marketplace search.',
                        style: AppTextStyles.smallMeta.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      CoreSecondaryButton(
                        icon: Icons.edit_outlined,
                        label: 'Improve profile',
                        compact: true,
                        onTap: () => Navigator.pushNamed(
                          context,
                          CrewServicesRoutes.profile,
                        ),
                      ),
                    ],
                  ),
                ),
                CrewSectionCard(
                  title: 'Earnings trend',
                  icon: Icons.query_stats_outlined,
                  child: Column(
                    children: [
                      CrewMiniBarChart(
                        values: const [18, 27, 24, 36, 42, 39, 51],
                        colors: [
                          colors.goldMid,
                          colors.infoBlue,
                          colors.infoPurple,
                        ],
                        height: 94,
                      ),
                      const SizedBox(height: 10),
                      CoreSecondaryButton(
                        icon: Icons.payments_outlined,
                        label: 'Open payments',
                        compact: true,
                        onTap: () => Navigator.pushNamed(
                          context,
                          CrewServicesRoutes.contracts,
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
            'Requests, contracts and profile prompts will appear here.',
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
