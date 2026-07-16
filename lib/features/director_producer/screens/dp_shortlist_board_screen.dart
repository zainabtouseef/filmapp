import 'package:flutter/material.dart';

import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/director_producer_demo_data.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';

class DPShortlistBoardScreen extends StatelessWidget {
  const DPShortlistBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final columns = const ['Talent', 'Models', 'Crew', 'Locations'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dpHeaderAction(
          context,
          icon: Icons.manage_search_rounded,
          label: 'Discover',
          onTap: () =>
              Navigator.pushNamed(context, DirectorProducerRoutes.marketplace),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            // Keyed off total window width (matches AdminScreenScaffold's
            // own AppBreakpoints.laptop side-nav threshold) so columns
            // don't suddenly shrink back to scroll-width right when the
            // side nav appears.
            final width = context.isDesktopWidth
                ? (constraints.maxWidth - 36) / 4
                : 278.0;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final column in columns) ...[
                    SizedBox(
                      width: width,
                      child: _ShortlistColumn(category: column),
                    ),
                    if (column != columns.last) const SizedBox(width: 12),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ShortlistColumn extends StatelessWidget {
  final String category;

  const _ShortlistColumn({required this.category});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final items = DirectorProducerDemoData.candidates
        .where((candidate) => candidate.category == category)
        .take(4)
        .toList();
    return DPGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.toUpperCase(),
            style: AppTextStyles.sectionHeaderStyle.copyWith(
              color: colors.textPrimary,
              fontSize: 14,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DPGlassCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: dpText(context, item.name, strong: true)),
                        DPStatusChip(
                            label: '${item.rating}', tone: DpTone.warning),
                      ],
                    ),
                    const SizedBox(height: 6),
                    dpText(context, '${item.city} - ${item.rateRange}'),
                    const SizedBox(height: 10),
                    DPHolographicButton(
                      label: 'Compare',
                      icon: Icons.compare_arrows_rounded,
                      onTap: () => Navigator.pushNamed(
                        context,
                        DirectorProducerRoutes.profile,
                        arguments: item.id,
                      ),
                      secondary: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
