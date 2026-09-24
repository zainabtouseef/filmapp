import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../cards/cine_card_system.dart';
import 'portal_glass_widget_card.dart';

/// A compact square glass widget for a single ring stat — sized to sit
/// alongside [PortalLiveClockWidget] in a widget grid (macOS Stocks/
/// Activity-widget scale, not a full-width card).
class PortalGlassRingWidget extends StatelessWidget {
  final double progress;
  final String value;
  final String label;
  final CineTone tone;
  final double size;
  final VoidCallback? onTap;

  const PortalGlassRingWidget({
    super.key,
    required this.progress,
    required this.value,
    required this.label,
    this.tone = CineTone.premium,
    this.size = 168,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PortalGlassWidgetCard(
      width: size,
      height: size,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ProgressRing(value: progress, tone: tone, size: size * 0.38),
          SizedBox(height: size * 0.06),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: size * 0.115,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
              fontSize: size * 0.062,
            ),
          ),
        ],
      ),
    );
  }
}
