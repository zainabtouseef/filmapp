import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/operations/operations_controller.dart';
import '../../../core/operations/operations_models.dart';
import '../../../core/profile/profile_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/uploads/upload_repository.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../widgets/media_equipment_components.dart';

class ME02ProviderProfileScreen extends StatefulWidget {
  const ME02ProviderProfileScreen({super.key});

  @override
  State<ME02ProviderProfileScreen> createState() =>
      _ME02ProviderProfileScreenState();
}

class _ME02ProviderProfileScreenState extends State<ME02ProviderProfileScreen> {
  Future<_ProfileData>? _dataFuture;
  bool _uploadingAvatar = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dataFuture != null) return;
    _reload();
  }

  void _reload() {
    final operations = OperationsScope.maybeOf(context);
    final auth = AuthScope.maybeOf(context);
    if (operations == null || auth == null) return;
    _dataFuture = _load(operations, auth);
  }

  Future<_ProfileData> _load(
    OperationsController operations,
    AuthController auth,
  ) async {
    final profile = await operations.equipmentProfile(force: true);
    final items = await operations.equipmentItems(force: true);
    final userProfile = await auth.myProfile();
    return _ProfileData(profile: profile, items: items, userProfile: userProfile);
  }

  Future<void> _pickAvatar() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    final item = result?.files.single;
    final bytes = item?.bytes;
    if (item == null || bytes == null) return;
    setState(() => _uploadingAvatar = true);
    try {
      final uploaded = await auth.uploadFile(
        purpose: 'profile_media',
        file: PickedFileData(
          name: item.name,
          mimeType: switch (item.extension?.toLowerCase()) {
            'png' => 'image/png',
            'webp' => 'image/webp',
            _ => 'image/jpeg',
          },
          bytes: bytes,
        ),
      );
      final current = await auth.myProfile();
      await auth.updateMyProfile(
        bio: current.bio ?? '',
        cityId: current.city?.publicId,
        visibility: 'public',
        websiteUrl: current.websiteUrl,
        socialLinks: current.socialLinks,
        avatarFileId: uploaded.publicId,
      );
      if (!mounted) return;
      setState(_reload);
      mediaSnack(context, 'Provider photo updated');
    } catch (error) {
      if (mounted) mediaSnack(context, 'Could not upload photo: $error');
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dataFuture == null) {
      return const InlineNotice(
        message: 'Preview mode. Sign in to manage the provider profile.',
        icon: Icons.visibility_outlined,
      );
    }
    return FutureBuilder<_ProfileData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const InlineNotice(
            message: 'Loading provider profile...',
            icon: Icons.hourglass_top_rounded,
          );
        }
        if (snapshot.hasError) {
          return InlineNotice(
            message: 'Could not load provider profile: ${snapshot.error}',
            icon: Icons.cloud_off_outlined,
          );
        }
        final data = snapshot.data!;
        final profile = data.profile;
        if (profile == null) {
          return CoreEmptyState(
            icon: Icons.storefront_outlined,
            title: 'Create the provider profile',
            message:
                'Directors need a verified business name, service coverage, equipment categories, and operating terms.',
            actionLabel: 'Create provider profile',
            onAction: () => _showEditor(userProfile: data.userProfile),
          );
        }
        return Column(
          children: [
            MediaSectionCard(
              title: 'Provider Identity',
              icon: Icons.badge_outlined,
              selected: true,
              child: MediaTwoColumn(
                left: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _uploadingAvatar ? null : _pickAvatar,
                      child: Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: context.appColors.softSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.appColors.border),
                          image: data.userProfile.avatarFile?.publicUrl == null
                              ? null
                              : DecorationImage(
                                  image: NetworkImage(
                                    data.userProfile.avatarFile!.publicUrl!,
                                  ),
                                  fit: BoxFit.cover,
                                ),
                        ),
                        child: _uploadingAvatar
                            ? Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: context.appColors.goldDark,
                                  ),
                                ),
                              )
                            : data.userProfile.avatarFile == null
                                ? Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: context.appColors.goldDark,
                                    size: 54,
                                  )
                                : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.name,
                      style: AppTextStyles.sectionHeading.copyWith(
                        color: context.appColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile.bio.isEmpty
                          ? 'Add a concise description of equipment quality, operators, transport, and service standards.'
                          : profile.bio,
                      style: AppTextStyles.body.copyWith(
                        color: context.appColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusChip(
                          label: _title(profile.providerType),
                          color: context.appColors.infoBlue,
                        ),
                        StatusChip(
                          label: _title(profile.verificationStatus),
                          color: profile.verificationStatus == 'verified'
                              ? context.appColors.success
                              : context.appColors.goldMid,
                        ),
                        StatusChip(
                          label: profile.visibility == 'public'
                              ? 'Marketplace public'
                              : 'Marketplace hidden',
                          color: profile.visibility == 'public'
                              ? context.appColors.success
                              : context.appColors.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
                right: Column(
                  children: [
                    MediaInfoRow(
                      icon: Icons.map_outlined,
                      label: 'Coverage',
                      value: profile.coverage.isEmpty
                          ? 'Not configured'
                          : profile.coverage,
                    ),
                    MediaInfoRow(
                      icon: Icons.category_outlined,
                      label: 'Services',
                      value: profile.serviceCategories.isEmpty
                          ? 'Not configured'
                          : profile.serviceCategories,
                    ),
                    MediaInfoRow(
                      icon: Icons.alternate_email_rounded,
                      label: 'Instagram',
                      value: data.userProfile.socialLinks['instagram']
                              ?.toString() ??
                          'Not connected',
                    ),
                    MediaInfoRow(
                      icon: Icons.music_note_rounded,
                      label: 'TikTok',
                      value: data.userProfile.socialLinks['tiktok']
                              ?.toString() ??
                          'Not connected',
                    ),
                    MediaInfoRow(
                      icon: Icons.inventory_2_outlined,
                      label: 'Inventory',
                      value: '${data.items.length} registered assets',
                    ),
                    MediaInfoRow(
                      icon: Icons.link_outlined,
                      label: 'Director listing',
                      value: profile.listingId == null
                          ? 'Created when profile saves'
                          : profile.listingId!,
                    ),
                    const SizedBox(height: 10),
                    CorePrimaryButton(
                      icon: Icons.edit_outlined,
                      label: 'Edit provider profile',
                      compact: true,
                      onTap: () => _showEditor(
                        profile: profile,
                        userProfile: data.userProfile,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            MediaTwoColumn(
              left: MediaSectionCard(
                title: 'Marketplace Inventory Preview',
                icon: Icons.video_library_outlined,
                child: data.items.isEmpty
                    ? const CoreEmptyState(
                        icon: Icons.videocam_outlined,
                        title: 'No inventory yet',
                        message:
                            'Add rentable assets before producers can compare equipment.',
                      )
                    : MediaResponsiveGrid(
                        minWidth: 180,
                        children: [
                          for (final item in data.items.take(6))
                            _InventoryPreview(item: item),
                        ],
                      ),
              ),
              right: MediaSectionCard(
                title: 'Trust Readiness',
                icon: Icons.verified_user_outlined,
                child: Column(
                  children: [
                    MediaInfoRow(
                      icon: Icons.verified_outlined,
                      label: 'Business verification',
                      value: _title(profile.verificationStatus),
                    ),
                    MediaInfoRow(
                      icon: Icons.qr_code_rounded,
                      label: 'Serial protection',
                      value: 'Private encrypted registry',
                    ),
                    MediaInfoRow(
                      icon: Icons.policy_outlined,
                      label: 'Rental protection',
                      value: 'Deposits and inspections required',
                    ),
                    MediaInfoRow(
                      icon: Icons.star_outline_rounded,
                      label: 'Rating',
                      value: profile.ratingAverage == 0
                          ? 'New provider'
                          : '${profile.ratingAverage / 100}',
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

  void _showEditor({
    EquipmentProfileDto? profile,
    required UserProfile userProfile,
  }) {
    final name = TextEditingController(text: profile?.name ?? '');
    final coverage = TextEditingController(text: profile?.coverage ?? '');
    final categories =
        TextEditingController(text: profile?.serviceCategories ?? '');
    final bio = TextEditingController(text: profile?.bio ?? '');
    final instagram = TextEditingController(
      text: userProfile.socialLinks['instagram']?.toString() ?? '',
    );
    final tiktok = TextEditingController(
      text: userProfile.socialLinks['tiktok']?.toString() ?? '',
    );
    var providerType = profile?.providerType ?? 'rental_house';
    var visibility = profile?.visibility ?? 'public';
    showMediaSheet(
      context,
      title:
          profile == null ? 'Create provider profile' : 'Edit provider profile',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CoreTextField(
                controller: name,
                label: 'Business or provider name',
                icon: Icons.business_outlined,
              ),
              const SizedBox(height: 10),
              Text(
                'Provider type',
                style: AppTextStyles.cardLabel.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in const [
                    'rental_house',
                    'individual_owner',
                    'production_supplier',
                  ])
                    CoreChip(
                      label: _title(value),
                      selected: providerType == value,
                      onTap: () => setSheetState(() => providerType = value),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: coverage,
                label: 'Service coverage',
                icon: Icons.map_outlined,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: categories,
                label: 'Equipment and crew categories',
                icon: Icons.category_outlined,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: bio,
                label: 'Provider description',
                icon: Icons.notes_outlined,
                maxLines: 4,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CoreTextField(
                      controller: instagram,
                      label: 'Instagram',
                      icon: Icons.alternate_email_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CoreTextField(
                      controller: tiktok,
                      label: 'TikTok',
                      icon: Icons.music_note_rounded,
                    ),
                  ),
                ],
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Public in Director discovery'),
                subtitle:
                    const Text('Can be hidden without deleting inventory.'),
                value: visibility == 'public',
                onChanged: (value) => setSheetState(
                  () => visibility = value ? 'public' : 'private',
                ),
              ),
              const SizedBox(height: 10),
              CorePrimaryButton(
                icon: Icons.save_outlined,
                label: 'Save provider profile',
                onTap: () async {
                  if (name.text.trim().length < 2 ||
                      coverage.text.trim().length < 2 ||
                      categories.text.trim().length < 2) {
                    mediaSnack(
                      context,
                      'Complete name, coverage, and service categories',
                    );
                    return;
                  }
                  final operations = OperationsScope.maybeOf(context);
                  final auth = AuthScope.maybeOf(context);
                  if (operations == null || auth == null) return;
                  try {
                    await operations.upsertEquipmentProfile(
                      name: name.text.trim(),
                      providerType: providerType,
                      coverage: coverage.text.trim(),
                      serviceCategories: categories.text.trim(),
                      bio: bio.text.trim(),
                      visibility: visibility,
                    );
                    await auth.updateMyProfile(
                      bio: userProfile.bio ?? '',
                      cityId: userProfile.city?.publicId,
                      visibility: 'public',
                      websiteUrl: userProfile.websiteUrl,
                      socialLinks: {
                        if (instagram.text.trim().isNotEmpty)
                          'instagram': instagram.text.trim(),
                        if (tiktok.text.trim().isNotEmpty)
                          'tiktok': tiktok.text.trim(),
                      },
                    );
                    if (!mounted || !context.mounted) return;
                    Navigator.pop(context);
                    setState(_reload);
                    mediaSnack(this.context, 'Provider profile saved');
                  } catch (error) {
                    if (context.mounted) {
                      mediaSnack(context, 'Could not save profile: $error');
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      name.dispose();
      coverage.dispose();
      categories.dispose();
      bio.dispose();
      instagram.dispose();
      tiktok.dispose();
    });
  }
}

class _InventoryPreview extends StatelessWidget {
  final EquipmentItemDto item;

  const _InventoryPreview({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 8,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.videocam_outlined, color: colors.goldDark, size: 28),
          const SizedBox(height: 8),
          Text(
            item.modelName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.cardLabel.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.category} · ${mediaMoney(item.dayRateMinor ~/ 100)}/day',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileData {
  final EquipmentProfileDto? profile;
  final List<EquipmentItemDto> items;
  final UserProfile userProfile;

  const _ProfileData({
    required this.profile,
    required this.items,
    required this.userProfile,
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
