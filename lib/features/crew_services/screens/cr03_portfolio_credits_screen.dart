import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/crew_services_demo_data.dart';
import '../models/crew_services_models.dart';
import '../widgets/crew_services_components.dart';

class CR03PortfolioCreditsScreen extends StatefulWidget {
  const CR03PortfolioCreditsScreen({super.key});

  @override
  State<CR03PortfolioCreditsScreen> createState() =>
      _CR03PortfolioCreditsScreenState();
}

class _CR03PortfolioCreditsScreenState
    extends State<CR03PortfolioCreditsScreen> {
  String _tab = 'Featured';

  @override
  Widget build(BuildContext context) {
    final store = CrewServicesDemoStore.instance;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final credits = _credits(store).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CrewSectionCard(
              title: 'Credits command',
              icon: Icons.video_library_outlined,
              selected: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final tab in [
                          'Featured',
                          'Drama',
                          'Commercial',
                          'All'
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CoreChip(
                              label: tab,
                              selected: _tab == tab,
                              onTap: () => setState(() => _tab = tab),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusChip(
                        label: '${store.credits.length} CREDITS',
                        color: colors.infoBlue,
                      ),
                      StatusChip(
                        label: store.portfolioUploadPending
                            ? 'UPLOAD PENDING'
                            : 'MODERATION CLEAR',
                        color: store.portfolioUploadPending
                            ? colors.goldMid
                            : colors.success,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CrewResponsiveGrid(
              minWidth: 280,
              children: [
                for (final credit in credits)
                  _CreditCard(
                    credit: credit,
                    onToggle: () {
                      store.toggleFeaturedCredit(credit.id);
                      crewSnack(context, 'Featured order updated');
                    },
                    onPreview: () => showDialog<void>(
                      context: context,
                      builder: (dialogContext) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: const EdgeInsets.all(24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CrewMediaFrame(
                                imageUrl: credit.imageUrl,
                                title: credit.title,
                                badge: credit.year,
                                fallbackIcon: Icons.video_library_outlined,
                                aspectRatio: 16 / 9,
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
                if (store.portfolioUploadPending)
                  CrewSectionCard(
                    title: 'Moderation preview',
                    icon: Icons.cloud_upload_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CrewMediaFrame(
                          imageUrl:
                              'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=900&q=80',
                          title: 'New lighting breakdown',
                          badge: 'Pending',
                          fallbackIcon: Icons.image_outlined,
                          aspectRatio: 16 / 9,
                          compact: true,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Upload created a local preview and moderation state.',
                          style: AppTextStyles.smallMeta.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            CorePrimaryButton(
              icon: Icons.cloud_upload_outlined,
              label: 'Upload work proof',
              compact: true,
              onTap: () {
                store.addPortfolioUpload();
                crewSnack(context, 'Portfolio upload queued for moderation');
              },
            ),
          ],
        );
      },
    );
  }

  Iterable<CrewCredit> _credits(CrewServicesDemoStore store) {
    return store.credits.where((credit) {
      return switch (_tab) {
        'Featured' => credit.featured,
        'Drama' => credit.category == 'Drama',
        'Commercial' => credit.category == 'Commercial',
        _ => true,
      };
    });
  }
}

class _CreditCard extends StatelessWidget {
  final CrewCredit credit;
  final VoidCallback onToggle;
  final VoidCallback onPreview;

  const _CreditCard({
    required this.credit,
    required this.onToggle,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 20,
      padding: const EdgeInsets.all(12),
      selected: credit.featured,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CrewMediaFrame(
            imageUrl: credit.imageUrl,
            title: credit.title,
            badge: credit.year,
            fallbackIcon: Icons.video_library_outlined,
            aspectRatio: 16 / 9,
            compact: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  credit.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusChip(
                label: credit.featured
                    ? 'FEATURED'
                    : credit.category.toUpperCase(),
                color: credit.featured ? colors.goldMid : colors.infoBlue,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${credit.role} - ${credit.category}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.play_circle_outline,
                  label: 'Preview',
                  compact: true,
                  onTap: onPreview,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.push_pin_outlined,
                  label: 'Feature',
                  compact: true,
                  onTap: onToggle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
