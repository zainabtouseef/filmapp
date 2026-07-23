import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import 'dp_glass_card.dart';
import 'dp_holographic_button.dart';

class DPPageHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onActionTap;
  final Widget? trailing;

  const DPPageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.actionLabel,
    this.actionIcon,
    this.onActionTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final action = trailing ??
        (actionLabel == null || actionIcon == null
            ? null
            : DPHolographicButton(
                label: actionLabel!,
                icon: actionIcon!,
                onTap: onActionTap,
              ));

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.micro.copyWith(
            color: colors.goldDark,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.heroSerifNumber.copyWith(
            color: colors.textPrimary,
            fontSize: 30,
          ),
        ),
      ],
    );

    if (action == null) return heading;

    return LayoutBuilder(
      builder: (context, constraints) {
        final reservedForAction = trailing == null ? 260.0 : 360.0;
        final titlePainter = TextPainter(
          text: TextSpan(
            text: title,
            style: AppTextStyles.heroSerifNumber.copyWith(fontSize: 30),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
        final fitsInline =
            constraints.maxWidth - reservedForAction - 12 >= titlePainter.width;
        final stackAction = constraints.maxWidth < 620 && !fitsInline;
        if (stackAction) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading,
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth,
                    minHeight: 44,
                  ),
                  child: action,
                ),
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: heading),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: trailing == null ? 260 : 360,
                minHeight: 44,
              ),
              child: action,
            ),
          ],
        );
      },
    );
  }
}

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
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: colors.goldDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (actionText != null)
                TextButton(onPressed: onActionTap, child: Text(actionText!)),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: colors.borderMuted),
          const SizedBox(height: 14),
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
  return Align(
    alignment: Alignment.centerRight,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280, minHeight: 44),
      child: DPHolographicButton(
        label: label,
        icon: icon,
        onTap: onTap,
      ),
    ),
  );
}
