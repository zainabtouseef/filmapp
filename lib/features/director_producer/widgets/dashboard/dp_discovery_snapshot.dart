import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../routes/director_producer_routes.dart';
import '../dp_glass_card.dart';
import '../dp_holographic_button.dart';

/// Quick discovery shortcuts plus a rail of newly-joined / verified
/// candidates worth a producer's attention.
class DPDiscoverySnapshot extends StatelessWidget {
  const DPDiscoverySnapshot({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

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
          'LIVE DISCOVERY',
          style: AppTextStyles.panelLabel.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 10),
        DPGlassCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.cloud_done_outlined, color: colors.success, size: 19),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Discovery results now come from the live marketplace database. Open marketplace to browse seeded Pakistani talent, crew, locations, and equipment with public media.',
                  style: AppTextStyles.smallMeta
                      .copyWith(color: colors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
