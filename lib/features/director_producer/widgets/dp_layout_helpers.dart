import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import 'dp_glass_card.dart';

class DPResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minWidth;
  final double gap;

  const DPResponsiveGrid({
    super.key,
    required this.children,
    this.minWidth = 280,
    this.gap = 12,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rawWidth = constraints.maxWidth;
        final count = rawWidth.isFinite
            ? (rawWidth / minWidth).floor().clamp(1, 4).toInt()
            : 1;
        final width = rawWidth.isFinite
            ? (rawWidth - (count - 1) * gap) / count
            : minWidth;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map(
                (child) => SizedBox(
                  width: width.isFinite ? width : minWidth,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class DPTwoColumn extends StatelessWidget {
  final Widget left;
  final Widget right;

  const DPTwoColumn({
    super.key,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppBreakpoints.tablet) {
          return Column(
            children: [
              left,
              const SizedBox(height: 12),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

/// A panel within a [DPTwoColumn]/[DPTwoColumn]-style layout that sits
/// *inside* a screen already introduced by a page-level [DPSectionHeader].
/// Its own label is deliberately quiet (small, muted, no icon glow) so a
/// screen with 2-3 panels doesn't read as 2-3 more page headings.
class DPSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final String? actionText;
  final VoidCallback? onActionTap;

  const DPSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: colors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.panelLabel
                      .copyWith(color: colors.textSecondary),
                ),
              ),
              if (actionText != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onActionTap,
                  child: Text(
                    actionText!,
                    style: AppTextStyles.caption
                        .copyWith(color: colors.goldDark, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

Widget dpText(BuildContext context, String text, {bool strong = false}) {
  final colors = context.appColors;
  return Text(
    text,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style:
        (strong ? AppTextStyles.cardLabel : AppTextStyles.smallMeta).copyWith(
      color: strong ? colors.textPrimary : colors.textSecondary,
      fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
      height: 1.28,
    ),
  );
}

Widget dpBullet(BuildContext context, String text) {
  final colors = context.appColors;
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_outline, color: colors.goldDark, size: 16),
        const SizedBox(width: 8),
        Expanded(child: dpText(context, text)),
      ],
    ),
  );
}

void dpSnack(BuildContext context, String message) {
  showCoreSnack(context, message);
}

/// A single quiet action for the top of a screen whose page title is
/// already shown by [DPShell] — used instead of repeating the title in a
/// second heading just to attach a CTA.
Widget dpHeaderAction(
  BuildContext context, {
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  final colors = context.appColors;
  return Align(
    alignment: Alignment.centerRight,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: colors.goldDark),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.sectionAction.copyWith(
                  color: colors.goldDark,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
