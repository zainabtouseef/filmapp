import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../cards/cine_card_system.dart';

/// Dashboard-kit "needs attention" row: a thin preset over
/// [PriorityActionCard] using a trailing chevron instead of the default
/// status-badge/action-button column, matching the design's attention list.
class PortalAttentionRow extends StatelessWidget {
  final String kindLabel;
  final String title;
  final String meta;
  final IconData icon;
  final CineTone tone;
  final VoidCallback? onTap;

  const PortalAttentionRow({
    super.key,
    required this.kindLabel,
    required this.title,
    required this.meta,
    required this.icon,
    this.tone = CineTone.warning,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PriorityActionCard(
      title: title,
      metadata: meta,
      priority: kindLabel,
      icon: icon,
      tone: tone,
      onTap: onTap,
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: colors.textTertiary,
      ),
    );
  }
}
