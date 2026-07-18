import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../actor_talent/widgets/actor_talent_components.dart';
import '../data/model_extension_demo_data.dart';
import '../models/model_extension_models.dart';
import '../routes/model_extension_routes.dart';

/// MD-01 Campaign Categories Setup
class MD01CampaignCategoriesScreen extends StatefulWidget {
  const MD01CampaignCategoriesScreen({super.key});

  @override
  State<MD01CampaignCategoriesScreen> createState() =>
      _MD01CampaignCategoriesScreenState();
}

class _MD01CampaignCategoriesScreenState
    extends State<MD01CampaignCategoriesScreen> {
  Future<ModelProfileDto?>? _profileFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final specialist = SpecialistScope.maybeOf(context);
    _profileFuture ??= specialist?.modelProfile(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ModelExtensionDemoStore.instance,
      builder: (context, _) {
        final store = ModelExtensionDemoStore.instance;
        return Column(
          children: [
            ActorSectionCard(
              title: 'Model Profile Extension',
              icon: Icons.category_outlined,
              selected: store.selectedCategoryCount < 6,
              child: ActorTwoColumn(
                left: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StepWizardIndicator(currentStep: 1, totalSteps: 3),
                    const SizedBox(height: 14),
                    if (_profileFuture != null)
                      FutureBuilder<ModelProfileDto?>(
                        future: _profileFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: InlineNotice(
                                message: 'Loading live model profile...',
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
                                  'Live model extension: ${live.campaignCategories.length} category rule(s), ${live.usageRights.length} rights.',
                              icon: Icons.cloud_done_outlined,
                              tone: CoreStatusTone.success,
                            ),
                          );
                        },
                      ),
                    const ActorMediaFrame(
                      imageUrl: ModelExtensionDemoData.heroImage,
                      title: 'Campaign fit preview',
                      badge: 'Model',
                      fallbackIcon: Icons.style_outlined,
                      aspectRatio: 16 / 10,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusChip(
                          label: '${store.selectedCategoryCount} selected',
                          color: context.appColors.goldMid,
                        ),
                        StatusChip(
                          label: '${store.publicCategoryCount} visible',
                          color: context.appColors.infoBlue,
                        ),
                        StatusChip(
                          label: store.savedToContractRules
                              ? 'Saved'
                              : 'Draft state',
                          color: store.savedToContractRules
                              ? context.appColors.success
                              : context.appColors.goldMid,
                        ),
                      ],
                    ),
                  ],
                ),
                right: Column(
                  children: const [
                    ActorInfoRow(
                      icon: Icons.visibility_outlined,
                      label: 'Public view',
                      value: 'Directors see visible categories',
                    ),
                    ActorInfoRow(
                      icon: Icons.verified_user_outlined,
                      label: 'Review',
                      value: 'Saved changes update demo entity',
                    ),
                    ActorInfoRow(
                      icon: Icons.link_outlined,
                      label: 'Connected to',
                      value: 'DP-06, DP-10, SC-12',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ActorSectionCard(
              title: 'Campaign Categories',
              icon: Icons.tune_outlined,
              actionText: 'Save',
              onActionTap: () async {
                store.saveCategories();
                final specialist = SpecialistScope.maybeOf(context);
                if (specialist != null) {
                  try {
                    await specialist.updateModelCampaignCategories(
                      store.categories
                          .map(
                            (category) => {
                              'category': category.label,
                              'selected': category.selected,
                              'public_visible': category.publicVisible,
                            },
                          )
                          .toList(),
                    );
                    if (context.mounted) {
                      setState(() => _profileFuture =
                          specialist.modelProfile(force: true));
                    }
                  } catch (error) {
                    if (context.mounted) {
                      actorSnack(context, 'Live category save skipped: $error');
                    }
                  }
                }
                if (!context.mounted) return;
                actorSnack(context, 'Campaign categories saved');
                await Future.delayed(const Duration(milliseconds: 600));
                if (context.mounted) {
                  Navigator.pushNamed(
                      context, ModelExtensionRoutes.usageRights);
                }
              },
              child: ActorResponsiveGrid(
                minWidth: 150,
                children: [
                  for (final category in store.categories)
                    _CategoryCard(category: category),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ModelCampaignCategory category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final store = ModelExtensionDemoStore.instance;
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
            onTap: () => store.toggleCategory(category.id),
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
                onChanged: category.selected
                    ? (_) => store.toggleCategoryVisibility(category.id)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
