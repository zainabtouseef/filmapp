import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/crew_services_demo_data.dart';
import '../widgets/crew_services_components.dart';

class CR02ServiceProfileScreen extends StatelessWidget {
  const CR02ServiceProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = CrewServicesDemoStore.instance;
    final profile = CrewServicesDemoData.profile;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return CrewTwoColumn(
          left: CrewSectionCard(
            title: 'Service identity',
            icon: Icons.badge_outlined,
            selected: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CrewMediaFrame(
                  imageUrl: profile.imageUrl,
                  title: profile.name,
                  badge: store.profileService,
                  fallbackIcon: Icons.groups_2_outlined,
                  aspectRatio: 16 / 8.8,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusChip(
                      label: store.profilePublished ? 'PUBLIC' : 'HIDDEN',
                      icon: store.profilePublished
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: store.profilePublished
                          ? colors.success
                          : colors.goldMid,
                    ),
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
                  ],
                ),
                const SizedBox(height: 12),
                CrewInfoRow(
                  icon: Icons.engineering_outlined,
                  label: 'Service',
                  value: store.profileService,
                ),
                CrewInfoRow(
                  icon: Icons.location_city_outlined,
                  label: 'Base city',
                  value: profile.city,
                ),
                CrewInfoRow(
                  icon: Icons.map_outlined,
                  label: 'Coverage',
                  value: store.profileCoverage,
                ),
                CrewInfoRow(
                  icon: Icons.construction_outlined,
                  label: 'Owned kit',
                  value: profile.ownedKit,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CoreSecondaryButton(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        compact: true,
                        onTap: () => _showEditSheet(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CorePrimaryButton(
                        icon: store.profilePublished
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        label: store.profilePublished ? 'Unpublish' : 'Publish',
                        compact: true,
                        onTap: () {
                          store.toggleProfilePublished();
                          crewSnack(
                            context,
                            store.profilePublished
                                ? 'Service profile published'
                                : 'Service profile hidden',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          right: Column(
            children: [
              CrewSectionCard(
                title: 'Trust proof',
                icon: Icons.verified_user_outlined,
                child: Column(
                  children: [
                    CrewInfoRow(
                      icon: Icons.verified_outlined,
                      label: 'Verification',
                      value: 'KYC + role proof',
                    ),
                    CrewInfoRow(
                      icon: Icons.history_edu_outlined,
                      label: 'Experience',
                      value: profile.experience,
                    ),
                    CrewInfoRow(
                      icon: Icons.rate_review_outlined,
                      label: 'References',
                      value: '8 verified',
                    ),
                    const SizedBox(height: 8),
                    CoreSecondaryButton(
                      icon: Icons.open_in_new_rounded,
                      label: 'Preview public profile',
                      compact: true,
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (dialogContext) => Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: const EdgeInsets.all(24),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CrewSectionCard(
                                  title: 'As seen by producers',
                                  icon: Icons.visibility_outlined,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CrewMediaFrame(
                                        imageUrl: profile.imageUrl,
                                        title: profile.name,
                                        badge: store.profileService,
                                        fallbackIcon: Icons.groups_2_outlined,
                                        aspectRatio: 4 / 5,
                                      ),
                                      const SizedBox(height: 10),
                                      CrewInfoRow(
                                        icon: Icons.map_outlined,
                                        label: 'Coverage',
                                        value: store.profileCoverage,
                                      ),
                                      CrewInfoRow(
                                        icon: Icons.construction_outlined,
                                        label: 'Owned kit',
                                        value: profile.ownedKit,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                CoreSecondaryButton(
                                  icon: Icons.close_rounded,
                                  label: 'Close',
                                  compact: true,
                                  onTap: () => Navigator.pop(dialogContext),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CrewSectionCard(
                title: 'Rate snapshot',
                icon: Icons.payments_outlined,
                child: Column(
                  children: [
                    CrewInfoRow(
                      icon: Icons.today_outlined,
                      label: 'Day rate',
                      value: crewMoney(profile.dayRate),
                    ),
                    CrewInfoRow(
                      icon: Icons.more_time_outlined,
                      label: 'Overtime',
                      value: 'PKR 18,000/hr',
                    ),
                    CrewInfoRow(
                      icon: Icons.local_shipping_outlined,
                      label: 'Travel',
                      value: 'By city quote',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditSheet(BuildContext context) {
    final store = CrewServicesDemoStore.instance;
    final service = TextEditingController(text: store.profileService);
    final coverage = TextEditingController(text: store.profileCoverage);
    showCrewSheet(
      context,
      title: 'Edit service profile',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoreTextField(
            controller: service,
            label: 'Service label',
            icon: Icons.engineering_outlined,
          ),
          const SizedBox(height: 10),
          CoreTextField(
            controller: coverage,
            label: 'Coverage areas',
            icon: Icons.map_outlined,
          ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.save_outlined,
            label: 'Save profile',
            onTap: () {
              store.updateProfile(
                service: service.text.trim().isEmpty
                    ? store.profileService
                    : service.text.trim(),
                coverage: coverage.text.trim().isEmpty
                    ? store.profileCoverage
                    : coverage.text.trim(),
              );
              Navigator.pop(context);
              crewSnack(context, 'Profile changes saved');
            },
          ),
        ],
      ),
    ).whenComplete(() {
      service.dispose();
      coverage.dispose();
    });
  }
}
