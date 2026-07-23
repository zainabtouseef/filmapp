import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/operations/operations_controller.dart';
import '../../../core/operations/operations_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dataFuture != null) return;
    _reload();
  }

  void _reload() {
    final operations = OperationsScope.maybeOf(context);
    if (operations == null) return;
    _dataFuture = _load(operations);
  }

  Future<_ProfileData> _load(OperationsController operations) async {
    final profile = await operations.equipmentProfile(force: true);
    final items = await operations.equipmentItems(force: true);
    return _ProfileData(profile: profile, items: items);
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
            onAction: () => _showEditor(),
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
                    Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: context.appColors.softSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.appColors.border),
                      ),
                      child: Icon(
                        Icons.video_camera_back_outlined,
                        color: context.appColors.goldDark,
                        size: 54,
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
                      onTap: () => _showEditor(profile),
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

  void _showEditor([EquipmentProfileDto? profile]) {
    final name = TextEditingController(text: profile?.name ?? '');
    final coverage = TextEditingController(text: profile?.coverage ?? '');
    final categories =
        TextEditingController(text: profile?.serviceCategories ?? '');
    final bio = TextEditingController(text: profile?.bio ?? '');
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
                  if (operations == null) return;
                  try {
                    await operations.upsertEquipmentProfile(
                      name: name.text.trim(),
                      providerType: providerType,
                      coverage: coverage.text.trim(),
                      serviceCategories: categories.text.trim(),
                      bio: bio.text.trim(),
                      visibility: visibility,
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

  const _ProfileData({
    required this.profile,
    required this.items,
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
