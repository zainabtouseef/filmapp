import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/actor_talent_demo_data.dart';
import '../widgets/actor_talent_components.dart';

/// AT-03 Portfolio & Showreel Manager
class AT03PortfolioShowreelScreen extends StatefulWidget {
  const AT03PortfolioShowreelScreen({super.key});

  @override
  State<AT03PortfolioShowreelScreen> createState() =>
      _AT03PortfolioShowreelScreenState();
}

class _AT03PortfolioShowreelScreenState
    extends State<AT03PortfolioShowreelScreen> {
  String query = '';
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ActorTalentDemoStore.instance,
      builder: (context, _) {
        final store = ActorTalentDemoStore.instance;
        final items = store.portfolioItems.where((item) {
          final matchQuery = query.trim().isEmpty ||
              item.title.toLowerCase().contains(query.toLowerCase()) ||
              item.category.toLowerCase().contains(query.toLowerCase());
          final matchFilter = filter == 'All' || item.category == filter;
          return matchQuery && matchFilter;
        }).toList();
        return Column(
          children: [
            ActorSearchFilterBar(
              query: query,
              onQueryChanged: (value) => setState(() => query = value),
              filters: const [
                'All',
                'Headshots',
                'Drama Clips',
                'Ads',
                'Voice Samples',
              ],
              selectedFilter: filter,
              onFilterChanged: (value) => setState(() => filter = value),
            ),
            const SizedBox(height: 12),
            ActorSectionCard(
              title: 'Media Library',
              icon: Icons.video_library_outlined,
              actionText: 'Upload',
              onActionTap: () {
                store.addPortfolioDemoItem();
                actorSnack(context, 'Upload preview added for moderation');
              },
              child: items.isEmpty
                  ? const CoreEmptyState(
                      icon: Icons.collections_outlined,
                      title: 'No media found',
                      message: 'Change the filter or upload a new clip.',
                    )
                  : ActorResponsiveGrid(
                      minWidth: 230,
                      children: [
                        for (final item in items)
                          _PortfolioCard(itemId: item.id),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  final String itemId;

  const _PortfolioCard({required this.itemId});

  @override
  Widget build(BuildContext context) {
    final store = ActorTalentDemoStore.instance;
    final item = store.portfolioItems.firstWhere((value) => value.id == itemId);
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ActorMediaFrame(
          imageUrl: item.imageUrl,
          title: item.title,
          badge: item.duration,
          fallbackIcon: Icons.movie_creation_outlined,
          aspectRatio: item.category == 'Headshots' ? 4 / 5 : 16 / 10,
          compact: true,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardLabel.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (item.cover) StatusChip(label: 'Cover', color: colors.goldMid),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            StatusChip(label: item.category, color: colors.infoBlue),
            StatusChip(
              label: item.status,
              color: item.status == 'Public' ? colors.success : colors.goldMid,
            ),
            StatusChip(label: 'Watermarked', color: colors.infoPurple),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: CoreSecondaryButton(
                icon: Icons.visibility_outlined,
                label: 'Preview',
                compact: true,
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (dialogContext) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ActorMediaFrame(
                            imageUrl: item.imageUrl,
                            title: item.title,
                            badge: item.duration,
                            fallbackIcon: Icons.movie_creation_outlined,
                            aspectRatio:
                                item.category == 'Headshots' ? 4 / 5 : 16 / 10,
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
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CorePrimaryButton(
                icon: Icons.star_outline_rounded,
                label: 'Cover',
                compact: true,
                onTap: () {
                  store.setCover(item.id);
                  actorSnack(context, '${item.title} is now public cover');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
