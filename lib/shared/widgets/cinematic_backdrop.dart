import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import 'cine_v3_motion.dart';

/// Theme background shared by every portal. The V3 treatment keeps the
/// navigation shell untouched while adding the soft cinematic washes and
/// very low-contrast drifting bubbles used by the Director experiences.
class CinematicBackdrop extends StatelessWidget {
  const CinematicBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(gradient: colors.backgroundGradient),
      child: Stack(
        fit: StackFit.expand,
        children: const [
          CineV3AtmosphericWash(),
          Opacity(
            opacity: .24,
            child: CineV3BubbleField(count: 7),
          ),
        ],
      ),
    );
  }
}
