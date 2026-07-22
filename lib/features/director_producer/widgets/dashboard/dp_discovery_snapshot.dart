import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/director_producer_demo_data.dart';
import '../../routes/director_producer_routes.dart';
import '../dp_glass_card.dart';
import '../dp_holographic_button.dart';
import '../dp_status_chip.dart';

/// Quick discovery shortcuts plus a rail of newly-joined / verified
/// candidates worth a producer's attention.
class DPDiscoverySnapshot extends StatelessWidget {
  const DPDiscoverySnapshot({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final newTalent = DirectorProducerDemoData.candidates
        .where((candidate) => candidate.isNew || candidate.verified)
        .take(6)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            DPHolographicButton(
              label: 'Find Talent',
              icon: Icons.theater_comedy_outlined,
              onTap: () => Navigator.pushNamed(
                context,
                DirectorProducerRoutes.marketplace,
                arguments: {'category': 'Talent'},
              ),
              secondary: true,
            ),
            DPHolographicButton(
              label: 'Find Locations',
              icon: Icons.location_city_outlined,
              onTap: () => Navigator.pushNamed(
                context,
                DirectorProducerRoutes.marketplace,
                arguments: {'category': 'Locations'},
              ),
              secondary: true,
            ),
            DPHolographicButton(
              label: 'Find Equipment',
              icon: Icons.video_camera_back_outlined,
              onTap: () => Navigator.pushNamed(
                context,
                DirectorProducerRoutes.marketplace,
                arguments: {'category': 'Media & Equipment'},
              ),
              secondary: true,
            ),
            DPHolographicButton(
              label: 'Find Crew',
              icon: Icons.groups_2_outlined,
              onTap: () => Navigator.pushNamed(
                context,
                DirectorProducerRoutes.marketplace,
                arguments: {'category': 'Crew'},
              ),
              secondary: true,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'NEW ON CINECONNECT',
          style: AppTextStyles.panelLabel.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final candidate in newTalent) ...[
                SizedBox(
                  width: 220,
                  child: DPGlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                candidate.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.cardLabel
                                    .copyWith(color: colors.textPrimary),
                              ),
                            ),
                            Icon(Icons.star_rounded,
                                size: 14, color: colors.goldDark),
                            const SizedBox(width: 2),
                            Text(
                              '${candidate.rating}',
                              style: AppTextStyles.caption
                                  .copyWith(color: colors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${candidate.category} • ${candidate.city}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.smallMeta
                              .copyWith(color: colors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            if (candidate.isNew)
                              const DPStatusChip(
                                  label: 'NEW', tone: DpTone.warning),
                            if (candidate.verified)
                              const DPStatusChip(
                                label: 'Verified',
                                tone: DpTone.success,
                                icon: Icons.verified_outlined,
                              ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        DPHolographicButton(
                          label: 'View',
                          icon: Icons.arrow_forward_rounded,
                          secondary: true,
                          onTap: () => Navigator.pushNamed(
                            context,
                            DirectorProducerRoutes.profile,
                            arguments: candidate.id,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
