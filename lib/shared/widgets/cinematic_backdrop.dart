import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';

/// Theme background with a clean, low-contrast cinematic falloff.
class CinematicBackdrop extends StatelessWidget {
  const CinematicBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(gradient: colors.backgroundGradient),
      child: const SizedBox.expand(),
    );
  }
}
