import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../actor_talent/widgets/actor_talent_components.dart';
import '../data/model_extension_demo_data.dart';

/// MD-03 Portfolio Categories
class MD03PortfolioCategoriesScreen extends StatefulWidget {
  const MD03PortfolioCategoriesScreen({super.key});

  @override
  State<MD03PortfolioCategoriesScreen> createState() =>
      _MD03PortfolioCategoriesScreenState();
}

class _MD03PortfolioCategoriesScreenState
    extends State<MD03PortfolioCategoriesScreen> {
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ModelExtensionDemoStore.instance,
      builder: (context, _) {
        final store = ModelExtensionDemoStore.instance;
        final categories = [
          'All',
          ...store.portfolio.map((item) => item.category).toSet()
        ];
        final items = store.portfolio
            .where((item) => filter == 'All' || item.category == filter)
            .toList();
        return Column(
          children: [
            ActorSectionCard(
              title: 'Model Identity Frame',
              icon: Icons.photo_camera_front_outlined,
              child: ActorTwoColumn(
                left: const ActorMediaFrame(
                  imageUrl: ModelExtensionDemoData.heroImage,
                  title: 'Editorial public profile',
                  badge: 'Watermarked',
                  fallbackIcon: Icons.style_outlined,
                  aspectRatio: 16 / 10,
                ),
                right: Column(
                  children: [
                    const ActorInfoRow(
                      icon: Icons.verified_user_outlined,
                      label: 'Trust',
                      value: 'KYC verified',
                    ),
                    const ActorInfoRow(
                      icon: Icons.water_drop_outlined,
                      label: 'Preview',
                      value: 'Auto-watermarked',
                    ),
                    ActorInfoRow(
                      icon: Icons.collections_outlined,
                      label: 'Assets',
                      value: '${store.portfolio.length} model frames',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ActorSectionCard(
              title: 'Portfolio Categories',
              icon: Icons.photo_library_outlined,
              actionText: 'Upload',
              onActionTap: () {
                store.addPortfolioPreview();
                actorSnack(context, 'Model upload preview sent to moderation');
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final category in categories)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => filter = category),
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(minHeight: 44),
                                child: Center(
                                  child: StatusChip(
                                    label: category,
                                    color: filter == category
                                        ? context.appColors.goldMid
                                        : context.appColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ActorResponsiveGrid(
                    minWidth: 210,
                    children: [
                      for (final item in items)
                        _PortfolioAssetCard(id: item.id),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PortfolioAssetCard extends StatelessWidget {
  final String id;

  const _PortfolioAssetCard({required this.id});

  @override
  Widget build(BuildContext context) {
    final store = ModelExtensionDemoStore.instance;
    final asset = store.portfolio.firstWhere((item) => item.id == id);
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ActorMediaFrame(
          imageUrl: asset.imageUrl,
          title: asset.title,
          badge: asset.category,
          fallbackIcon: Icons.photo_library_outlined,
          aspectRatio: 4 / 5,
          compact: true,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                asset.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardLabel.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (asset.cover) StatusChip(label: 'Cover', color: colors.goldMid),
          ],
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            StatusChip(
              label: asset.status,
              color: asset.status == 'Public' ? colors.success : colors.goldMid,
            ),
            StatusChip(label: 'Preview safe', color: colors.infoBlue),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: CoreSecondaryButton(
                icon: Icons.visibility_outlined,
                label: asset.status == 'Public' ? 'Unpublish' : 'Publish',
                compact: true,
                onTap: () {
                  store.togglePortfolioStatus(asset.id);
                  actorSnack(context, '${asset.title} visibility updated');
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CorePrimaryButton(
                icon: Icons.star_outline_rounded,
                label: 'Cover',
                compact: true,
                onTap: () {
                  store.setPortfolioCover(asset.id);
                  actorSnack(context, '${asset.title} set as model cover');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
