import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/layout/portal_adaptive_collection.dart';
import '../../../shared/layout/portal_page_header.dart';
import '../../../shared/layout/portal_reference_design.dart';
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
    final action = trailing ??
        (actionLabel == null || actionIcon == null
            ? null
            : DPHolographicButton(
                label: actionLabel!,
                icon: actionIcon!,
                onTap: onActionTap,
              ));

    return PortalPageHeader(
      eyebrow: eyebrow,
      title: title,
      trailing: action,
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
    return PortalAdaptiveCollection(
      minWidth: minWidth,
      gap: gap,
      children: children,
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
    return PortalSplitView(
      primary: left,
      secondary: right,
      breakpoint: AppBreakpoints.tablet,
      primaryFlex: 1,
      secondaryFlex: 1,
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
    final route = ModalRoute.of(context)?.settings.name;
    if (PortalReferenceDesign.usesReference(route)) {
      return SectionContainer(
        title: title,
        leading: IconBadge(
          icon: icon,
          tone: cineToneFromColor(context, colors.goldDark),
          compact: true,
        ),
        action: actionText == null
            ? null
            : TextButton(onPressed: onActionTap, child: Text(actionText!)),
        treatment: SectionTreatment.open,
        child: child,
      );
    }
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
  required VoidCallback? onTap,
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
