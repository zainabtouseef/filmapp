import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/profile/profile_models.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/provider_workspace_hero.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../actor_talent/widgets/actor_talent_components.dart';
import '../routes/model_extension_routes.dart';

class MD01CampaignCategoriesScreen extends StatefulWidget {
  const MD01CampaignCategoriesScreen({super.key});

  @override
  State<MD01CampaignCategoriesScreen> createState() =>
      _MD01CampaignCategoriesScreenState();
}

class _MD01CampaignCategoriesScreenState
    extends State<MD01CampaignCategoriesScreen> {
  SpecialistController? _specialist;
  AuthController? _auth;
  Future<ModelProfileDto?>? _profileFuture;
  Future<UserProfile>? _userProfileFuture;
  List<_CategoryDraft> _categories = const [];
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final specialist = SpecialistScope.maybeOf(context);
    final auth = AuthScope.maybeOf(context);
    if (specialist != null && !identical(specialist, _specialist)) {
      _specialist = specialist;
      _profileFuture = specialist.modelProfile(force: true);
    }
    if (auth != null && !identical(auth, _auth)) {
      _auth = auth;
      _userProfileFuture = auth.myProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final future = _profileFuture;
    if (future == null) {
      return const CoreEmptyState(
        icon: Icons.cloud_sync_outlined,
        title: 'Sign in to load model categories',
        message:
            'Campaign fit, public visibility and model category rules are fetched from the backend.',
      );
    }
    return FutureBuilder<ModelProfileDto?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
            title: 'Model categories unavailable',
            message: 'Could not load live model profile categories.',
            actionLabel: 'Try again',
            onAction: _reload,
          );
        }
        final profile = snapshot.data;
        if (_categories.isEmpty) {
          _categories = _draftsFor(profile);
        }
        final selectedCount = _categories.where((item) => item.selected).length;
        final publicCount = _categories
            .where((item) => item.selected && item.publicVisible)
            .length;
        return Column(
          children: [
            FutureBuilder<UserProfile>(
              future: _userProfileFuture,
              builder: (context, userSnapshot) {
                final userProfile = userSnapshot.data;
                final colors = context.appColors;
                return ProviderWorkspaceHero(
                  imageUrl: userProfile?.coverFile?.publicUrl ?? '',
                  avatarUrl: userProfile?.avatarFile?.publicUrl,
                  eyebrow: 'Commercial model profile',
                  title: _auth?.user?.displayName ?? 'Model Workspace',
                  summary: userProfile?.bio?.trim().isNotEmpty == true
                      ? userProfile!.bio!
                      : 'Present your campaign fit, commercial boundaries and usage rates in one director-ready profile.',
                  badge: userProfile?.visibility == 'public'
                      ? 'Director visible'
                      : 'Profile setup',
                  fallbackIcon: Icons.style_outlined,
                  accentColor: colors.goldDark,
                  facts: [
                    ProviderHeroFact(
                      icon: Icons.category_outlined,
                      label: 'Campaign categories',
                      value: '$selectedCount selected',
                    ),
                    ProviderHeroFact(
                      icon: Icons.policy_outlined,
                      label: 'Usage rights',
                      value: '${profile?.usageRights.length ?? 0} configured',
                    ),
                    ProviderHeroFact(
                      icon: Icons.location_on_outlined,
                      label: 'Base',
                      value: userProfile?.city?.name ?? 'Add city',
                    ),
                  ],
                  primaryLabel: 'Open opportunities',
                  primaryIcon: Icons.travel_explore_outlined,
                  onPrimary: () => Navigator.pushNamed(
                    context,
                    ModelExtensionRoutes.opportunities,
                  ),
                  secondaryLabel: 'Edit model profile',
                  secondaryIcon: Icons.edit_outlined,
                  onSecondary: () => Navigator.pushNamed(
                    context,
                    ModelExtensionRoutes.profile,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            ActorSectionCard(
              title: 'Model Profile Extension',
              icon: Icons.category_outlined,
              selected: selectedCount < 6,
              child: ActorTwoColumn(
                left: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StepWizardIndicator(currentStep: 1, totalSteps: 3),
                    const SizedBox(height: 14),
                    InlineNotice(
                      message: profile == null
                          ? 'No model extension profile exists yet. Saving categories will create live backend rules.'
                          : 'Live model extension: ${profile.campaignCategories.length} category rule(s), ${profile.usageRights.length} rights.',
                      icon: profile == null
                          ? Icons.info_outline_rounded
                          : Icons.cloud_done_outlined,
                      tone: profile == null
                          ? CoreStatusTone.info
                          : CoreStatusTone.success,
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<UserProfile>(
                      future: _userProfileFuture,
                      builder: (context, userSnapshot) => ActorMediaFrame(
                        imageUrl: userSnapshot.data?.coverFile?.publicUrl ?? '',
                        title: 'Campaign fit',
                        badge: 'Backend profile',
                        fallbackIcon: Icons.style_outlined,
                        aspectRatio: 16 / 10,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusChip(
                          label: '$selectedCount selected',
                          color: context.appColors.goldMid,
                        ),
                        StatusChip(
                          label: '$publicCount visible',
                          color: context.appColors.infoBlue,
                        ),
                        StatusChip(
                          label: profile == null ? 'Not saved' : 'Live rules',
                          color: profile == null
                              ? context.appColors.goldMid
                              : context.appColors.success,
                        ),
                      ],
                    ),
                  ],
                ),
                right: const Column(
                  children: [
                    ActorInfoRow(
                      icon: Icons.visibility_outlined,
                      label: 'Public view',
                      value: 'Directors see visible categories',
                    ),
                    ActorInfoRow(
                      icon: Icons.verified_user_outlined,
                      label: 'Review',
                      value: 'Saved changes update backend rules',
                    ),
                    ActorInfoRow(
                      icon: Icons.link_outlined,
                      label: 'Connected to',
                      value: 'Offers, rights and model releases',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ActorSectionCard(
              title: 'Campaign Categories',
              icon: Icons.tune_outlined,
              actionText: _saving ? 'Saving...' : 'Save',
              onActionTap: _saving ? null : _saveCategories,
              child: ActorResponsiveGrid(
                minWidth: 150,
                children: [
                  for (final category in _categories)
                    _CategoryCard(
                      category: category,
                      onToggleSelected: () => _toggleCategory(category.id),
                      onToggleVisible: category.selected
                          ? () => _toggleVisibility(category.id)
                          : null,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<_CategoryDraft> _draftsFor(ModelProfileDto? profile) {
    final existing = {
      for (final item
          in profile?.campaignCategories ?? const <ModelCampaignCategoryDto>[])
        _normalize(item.category): item,
    };
    return _categoryConfigs.map((config) {
      final live = existing[_normalize(config.label)];
      return _CategoryDraft(
        id: config.id,
        label: config.label,
        icon: config.icon,
        selected: live?.selected ?? false,
        publicVisible: live?.publicVisible ?? true,
      );
    }).toList();
  }

  void _toggleCategory(String id) {
    setState(() {
      _categories = _categories.map((item) {
        if (item.id != id) return item;
        final selected = !item.selected;
        return item.copyWith(
          selected: selected,
          publicVisible: selected ? item.publicVisible : false,
        );
      }).toList();
    });
  }

  void _toggleVisibility(String id) {
    setState(() {
      _categories = _categories.map((item) {
        if (item.id != id) return item;
        return item.copyWith(publicVisible: !item.publicVisible);
      }).toList();
    });
  }

  Future<void> _saveCategories() async {
    final specialist = _specialist;
    if (specialist == null) {
      actorSnack(context, 'Sign in to save model categories');
      return;
    }
    setState(() => _saving = true);
    try {
      await specialist.updateModelCampaignCategories(
        _categories
            .map(
              (category) => {
                'category': category.label,
                'selected': category.selected,
                'public_visible': category.publicVisible,
              },
            )
            .toList(),
      );
      if (!mounted) return;
      setState(() {
        _profileFuture = specialist.modelProfile(force: true);
        _categories = const [];
      });
      actorSnack(context, 'Campaign categories saved');
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        Navigator.pushNamed(context, ModelExtensionRoutes.usageRights);
      }
    } catch (error) {
      if (mounted) actorSnack(context, 'Could not save categories: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _reload() {
    final specialist = _specialist;
    if (specialist == null) return;
    setState(() {
      _categories = const [];
      _profileFuture = specialist.modelProfile(force: true);
      _userProfileFuture = _auth?.myProfile();
    });
  }
}

class _CategoryCard extends StatelessWidget {
  final _CategoryDraft category;
  final VoidCallback onToggleSelected;
  final VoidCallback? onToggleVisible;

  const _CategoryCard({
    required this.category,
    required this.onToggleSelected,
    required this.onToggleVisible,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: category.selected
            ? colors.activeChipGradient
            : colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: category.selected ? colors.goldMid : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggleSelected,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      category.icon,
                      color: category.selected
                          ? colors.goldDark
                          : colors.iconMuted,
                      size: 20,
                    ),
                    const Spacer(),
                    Icon(
                      category.selected
                          ? Icons.check_circle_outline
                          : Icons.circle_outlined,
                      color:
                          category.selected ? colors.success : colors.iconMuted,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Public',
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              Switch(
                value: category.publicVisible,
                onChanged:
                    onToggleVisible == null ? null : (_) => onToggleVisible!(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryDraft {
  final String id;
  final String label;
  final IconData icon;
  final bool selected;
  final bool publicVisible;

  const _CategoryDraft({
    required this.id,
    required this.label,
    required this.icon,
    required this.selected,
    required this.publicVisible,
  });

  _CategoryDraft copyWith({bool? selected, bool? publicVisible}) {
    return _CategoryDraft(
      id: id,
      label: label,
      icon: icon,
      selected: selected ?? this.selected,
      publicVisible: publicVisible ?? this.publicVisible,
    );
  }
}

typedef _CategoryConfig = ({String id, String label, IconData icon});

const _categoryConfigs = <_CategoryConfig>[
  (id: 'fashion', label: 'Fashion', icon: Icons.checkroom_outlined),
  (id: 'beauty', label: 'Beauty', icon: Icons.face_retouching_natural),
  (id: 'jewellery', label: 'Jewellery', icon: Icons.diamond_outlined),
  (id: 'lifestyle', label: 'Lifestyle', icon: Icons.local_florist_outlined),
  (id: 'sports', label: 'Sportswear', icon: Icons.sports_soccer_outlined),
  (id: 'luxury', label: 'Luxury', icon: Icons.workspace_premium_outlined),
  (id: 'commercial', label: 'Commercial', icon: Icons.campaign_outlined),
  (id: 'editorial', label: 'Editorial', icon: Icons.auto_stories_outlined),
  (id: 'bridal', label: 'Bridal', icon: Icons.favorite_border_rounded),
  (id: 'fitness', label: 'Fitness', icon: Icons.fitness_center_outlined),
  (id: 'runway', label: 'Runway', icon: Icons.directions_walk_outlined),
  (id: 'ecommerce', label: 'E-commerce', icon: Icons.shopping_bag_outlined),
];

String _normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
