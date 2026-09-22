import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../cards/cine_card_system.dart';

/// Dashboard-kit agenda row: time + avatar/initials chip + title/meta.
///
/// Generalized from director_producer's `_TimelineRow`
/// (dp_today_timeline.dart), which lacked a leading/avatar slot — this
/// version adds one so it can front an agenda list across any portal.
class PortalAgendaRow extends StatelessWidget {
  final String time;
  final String initials;
  final String title;
  final String meta;
  final CineTone tone;
  final VoidCallback? onTap;
  final bool showDivider;

  const PortalAgendaRow({
    super.key,
    required this.time,
    required this.initials,
    required this.title,
    required this.meta,
    this.tone = CineTone.premium,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      hoverColor: colors.softSurface,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(top: BorderSide(color: colors.borderMuted))
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 46,
              child: Text(
                time,
                style: AppTextStyles.smallMeta.copyWith(
                  color: colors.goldDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
            EntityAvatar(label: initials, size: 32, twoLetterInitials: true),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle
                        .copyWith(fontSize: 12.5, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.smallMeta.copyWith(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
