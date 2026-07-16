import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/director_producer_demo_data.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_candidate_card.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';

class DPMarketplaceDiscoveryScreen extends StatefulWidget {
  const DPMarketplaceDiscoveryScreen({super.key});

  @override
  State<DPMarketplaceDiscoveryScreen> createState() =>
      _DPMarketplaceDiscoveryScreenState();
}

class _DPMarketplaceDiscoveryScreenState
    extends State<DPMarketplaceDiscoveryScreen> {
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final candidates = DirectorProducerDemoData.candidates.where((candidate) {
      return _category == 'All' || candidate.category == _category;
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dpHeaderAction(
          context,
          icon: Icons.tune_rounded,
          label: 'Filters',
          onTap: () =>
              Navigator.pushNamed(context, DirectorProducerRoutes.filters),
        ),
        const SizedBox(height: 6),
        const _MarketplaceSearchBar(),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final category in const [
                'All',
                'Talent',
                'Models',
                'Crew',
                'Locations',
                'Media & Equipment',
                'Agencies',
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _category = category),
                    child: DPStatusChip(
                      label: category,
                      tone: _category == category
                          ? DpTone.warning
                          : DpTone.neutral,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DPResponsiveGrid(
          minWidth: 300,
          children: candidates
              .take(12)
              .map(
                (candidate) => DPCandidateCard(
                  candidate: candidate,
                  onProfile: () => Navigator.pushNamed(
                    context,
                    DirectorProducerRoutes.profile,
                    arguments: candidate.id,
                  ),
                  onRequest: () => Navigator.pushNamed(
                    context,
                    DirectorProducerRoutes.bookingRequest,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _MarketplaceSearchBar extends StatelessWidget {
  const _MarketplaceSearchBar();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: colors.goldDark, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Search talent, crew, locations, media, agencies...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          DPHolographicButton(
            label: 'Smart Filters',
            icon: Icons.tune_rounded,
            onTap: () => Navigator.pushNamed(
              context,
              DirectorProducerRoutes.filters,
            ),
            secondary: true,
          ),
        ],
      ),
    );
  }
}
