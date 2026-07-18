import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/operations/operations_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/media_equipment_demo_data.dart';
import '../widgets/media_equipment_components.dart';

class ME02ProviderProfileScreen extends StatefulWidget {
  const ME02ProviderProfileScreen({super.key});

  @override
  State<ME02ProviderProfileScreen> createState() =>
      _ME02ProviderProfileScreenState();
}

class _ME02ProviderProfileScreenState extends State<ME02ProviderProfileScreen> {
  bool _newUpload = false;
  Future<dynamic>? _profileFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final operations = OperationsScope.maybeOf(context);
    _profileFuture ??= operations?.equipmentProfile(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final store = MediaEquipmentDemoStore.instance;
    final profile = MediaEquipmentDemoData.profile;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Column(
          children: [
            MediaSectionCard(
              title: 'Provider identity',
              icon: Icons.badge_outlined,
              selected: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_profileFuture != null)
                    FutureBuilder<dynamic>(
                      future: _profileFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: InlineNotice(
                              message: 'Loading live provider profile...',
                              icon: Icons.hourglass_top_rounded,
                            ),
                          );
                        }
                        final live = snapshot.data;
                        if (live == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InlineNotice(
                            message:
                                'Live provider: ${live.name} · ${live.coverage}',
                            icon: Icons.cloud_done_outlined,
                            tone: CoreStatusTone.success,
                          ),
                        );
                      },
                    ),
                  MediaFrame(
                    imageUrl: profile.imageUrl,
                    title: store.profileName,
                    badge: profile.verification,
                    fallbackIcon: Icons.videocam_outlined,
                    aspectRatio: 16 / 8.8,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusChip(
                        label: profile.type.toUpperCase(),
                        icon: Icons.business_outlined,
                        color: colors.infoBlue,
                      ),
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.bio,
                    style: AppTextStyles.body.copyWith(
                      color: colors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  MediaResponsiveGrid(
                    minWidth: 230,
                    children: [
                      MediaInfoRow(
                        icon: Icons.location_city_outlined,
                        label: 'City',
                        value: profile.city,
                      ),
                      MediaInfoRow(
                        icon: Icons.map_outlined,
                        label: 'Coverage',
                        value: store.profileCoverage,
                      ),
                      MediaInfoRow(
                        icon: Icons.category_outlined,
                        label: 'Categories',
                        value: profile.serviceCategories,
                      ),
                    ],
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
                          label:
                              store.profilePublished ? 'Unpublish' : 'Publish',
                          compact: true,
                          onTap: () {
                            store.toggleProfilePublished();
                            mediaSnack(
                              context,
                              store.profilePublished
                                  ? 'Profile published'
                                  : 'Profile hidden',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            MediaTwoColumn(
              left: MediaSectionCard(
                title: 'Equipment gallery',
                icon: Icons.photo_library_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MediaResponsiveGrid(
                      minWidth: 160,
                      children: [
                        for (final item in store.inventory.take(4))
                          MediaFrame(
                            imageUrl: item.imageUrl,
                            title: item.modelName,
                            badge: item.category,
                            fallbackIcon: Icons.image_outlined,
                            aspectRatio: 1,
                            compact: true,
                          ),
                        if (_newUpload)
                          MediaFrame(
                            imageUrl:
                                'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=900&q=80',
                            title: 'New moderation preview',
                            badge: 'Pending',
                            fallbackIcon: Icons.image_outlined,
                            aspectRatio: 1,
                            compact: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CoreSecondaryButton(
                      icon: Icons.cloud_upload_outlined,
                      label: 'Upload preview',
                      compact: true,
                      onTap: () {
                        setState(() => _newUpload = true);
                        mediaSnack(
                            context, 'Media upload queued for moderation');
                      },
                    ),
                  ],
                ),
              ),
              right: MediaSectionCard(
                title: 'Trust badges',
                icon: Icons.verified_user_outlined,
                child: Column(
                  children: [
                    MediaInfoRow(
                      icon: Icons.verified_outlined,
                      label: 'Verification',
                      value: profile.verification,
                    ),
                    MediaInfoRow(
                      icon: Icons.policy_outlined,
                      label: 'Insurance proof',
                      value: 'Valid',
                    ),
                    MediaInfoRow(
                      icon: Icons.receipt_long_outlined,
                      label: 'Serial registry',
                      value: '${store.inventory.length} items',
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
                                MediaSectionCard(
                                  title: 'As seen by producers',
                                  icon: Icons.visibility_outlined,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      MediaFrame(
                                        imageUrl: profile.imageUrl,
                                        title: store.profileName,
                                        badge: profile.verification,
                                        fallbackIcon: Icons.videocam_outlined,
                                        aspectRatio: 4 / 5,
                                      ),
                                      const SizedBox(height: 10),
                                      MediaInfoRow(
                                        icon: Icons.map_outlined,
                                        label: 'Coverage',
                                        value: store.profileCoverage,
                                      ),
                                      MediaInfoRow(
                                        icon: Icons.category_outlined,
                                        label: 'Categories',
                                        value: profile.serviceCategories,
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
            ),
          ],
        );
      },
    );
  }

  void _showEditSheet(BuildContext context) {
    final store = MediaEquipmentDemoStore.instance;
    final name = TextEditingController(text: store.profileName);
    final coverage = TextEditingController(text: store.profileCoverage);
    showMediaSheet(
      context,
      title: 'Edit provider profile',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoreTextField(
            controller: name,
            label: 'Business name',
            icon: Icons.business_outlined,
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
            onTap: () async {
              final operations = OperationsScope.maybeOf(context);
              if (operations != null) {
                try {
                  await operations.upsertEquipmentProfile(
                    name: name.text.trim().isEmpty
                        ? store.profileName
                        : name.text.trim(),
                    coverage: coverage.text.trim().isEmpty
                        ? store.profileCoverage
                        : coverage.text.trim(),
                    serviceCategories:
                        MediaEquipmentDemoData.profile.serviceCategories,
                    bio: MediaEquipmentDemoData.profile.bio,
                  );
                  if (mounted) {
                    setState(() => _profileFuture =
                        operations.equipmentProfile(force: true));
                  }
                } catch (error) {
                  if (context.mounted) {
                    mediaSnack(context, 'Live profile save skipped: $error');
                  }
                }
              }
              store.updateProfile(
                name: name.text.trim().isEmpty
                    ? store.profileName
                    : name.text.trim(),
                coverage: coverage.text.trim().isEmpty
                    ? store.profileCoverage
                    : coverage.text.trim(),
              );
              if (context.mounted) {
                Navigator.pop(context);
                mediaSnack(context, 'Profile changes saved');
              }
            },
          ),
        ],
      ),
    ).whenComplete(() {
      name.dispose();
      coverage.dispose();
    });
  }
}
