import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';

/// Canonical page heading for every CineConnect portal.
///
/// Page titles use the same Archivo scale as Marketplace. Editorial serif is
/// reserved for hero copy and card content, so navigation between screens does
/// not change typeface, weight, or alignment.
class PortalPageHeader extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? trailing;
  final int titleMaxLines;

  const PortalPageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.trailing,
    this.titleMaxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (eyebrow case final value? when value.trim().isNotEmpty) ...[
              Text(
                value.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.micro.copyWith(
                  color: colors.goldDark,
                  fontSize: compact ? 10.5 : 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: compact ? 1.8 : 2.4,
                ),
              ),
              SizedBox(height: compact ? 5 : 7),
            ],
            Semantics(
              header: true,
              child: Text(
                title,
                maxLines: titleMaxLines,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.heading.copyWith(
                  color: colors.textPrimary,
                  fontSize: compact ? 32 : 46,
                  fontWeight: FontWeight.w700,
                  height: 1.02,
                  letterSpacing: compact ? -0.7 : -1.25,
                ),
              ),
            ),
            if (subtitle case final value? when value.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Text(
                  value,
                  style: AppTextStyles.bodyMuted.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        );

        final action = trailing;
        if (action == null) return titleBlock;
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 14),
              Align(alignment: Alignment.centerLeft, child: action),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 24),
            Flexible(child: action),
          ],
        );
      },
    );
  }
}
