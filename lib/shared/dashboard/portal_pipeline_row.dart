import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../cards/cine_card_system.dart';

/// Dashboard-kit pipeline/list-table row: avatar-initials chip, name/sub,
/// a meta line with a thin progress bar, a status pill, and a compact
/// icon button + CTA button.
///
/// This is a plain row (divider on top, hover highlight) meant to live
/// inside one shared `CardShell` section alongside sibling rows — matching
/// the design, where these are rows in a list, not individually bordered
/// cards.
class PortalPipelineRow extends StatelessWidget {
  final String initials;
  final String title;
  final String subtitle;
  final String? metaLabel;
  final double? progress;
  final String status;
  final CineTone tone;
  final IconData secondaryIcon;
  final VoidCallback? onSecondaryTap;
  final String ctaLabel;
  final VoidCallback? onCta;
  final VoidCallback? onTap;
  final bool showDivider;

  const PortalPipelineRow({
    super.key,
    required this.initials,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.ctaLabel,
    this.metaLabel,
    this.progress,
    this.tone = CineTone.neutral,
    this.secondaryIcon = Icons.chat_bubble_outline_rounded,
    this.onSecondaryTap,
    this.onCta,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final toneColor = cineToneColor(context, tone);
    return InkWell(
      onTap: onTap,
      hoverColor: colors.softSurface,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(top: BorderSide(color: colors.borderMuted))
              : null,
        ),
        child: Row(
          children: [
            EntityAvatar(label: initials, size: 40, twoLetterInitials: true),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle
                        .copyWith(fontSize: 13.5, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.smallMeta.copyWith(
                      color: colors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            if (metaLabel != null) ...[
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      metaLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.smallMeta
                          .copyWith(color: colors.textSecondary),
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: progress!.clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: colors.softSurface,
                          valueColor: AlwaysStoppedAnimation<Color>(toneColor),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(width: AppSpacing.md),
            CineStatusBadge(label: status, tone: tone),
            const SizedBox(width: 6),
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: onSecondaryTap,
                icon:
                    Icon(secondaryIcon, size: 14, color: colors.textSecondary),
                style: IconButton.styleFrom(
                  side: BorderSide(color: colors.border),
                  shape: const CircleBorder(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            OutlinedButton(
              onPressed: onCta,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                side: BorderSide(color: colors.border),
                shape: const StadiumBorder(),
                textStyle: AppTextStyles.smallMeta.copyWith(fontSize: 12),
                foregroundColor: colors.textPrimary,
              ),
              child: Text(ctaLabel),
            ),
          ],
        ),
      ),
    );
  }
}
