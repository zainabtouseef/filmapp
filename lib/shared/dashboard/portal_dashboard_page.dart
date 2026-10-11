import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/cine_hover_zoom.dart';

/// Canonical vertical composition for every CineConnect portal dashboard.
///
/// The supplied dashboard reference uses an 18 px rhythm between its hero,
/// live strip, planning widgets, and operational sections. Keeping that
/// rhythm here prevents role dashboards from drifting as their live content
/// evolves independently.
class PortalDashboardPage extends StatelessWidget {
  final List<Widget> children;
  final double gap;
  final CrossAxisAlignment crossAxisAlignment;
  final bool showLiveStrip;

  const PortalDashboardPage({
    super.key,
    required this.children,
    this.gap = 18,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.showLiveStrip = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('portal-dashboard-page'),
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index != 0) SizedBox(height: gap),
          children[index],
          if (index == 0 && showLiveStrip) ...[
            SizedBox(height: gap),
            const PortalDashboardLiveStrip(),
          ],
        ],
      ],
    );
  }
}

/// Compact live activity ribbon placed immediately below every dashboard
/// hero, matching the supplied portal reference.
class PortalDashboardLiveStrip extends StatelessWidget {
  const PortalDashboardLiveStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final items = <({IconData icon, String title, String meta})>[
      (
        icon: Icons.sync_rounded,
        title: 'Workspace connected',
        meta: 'Live CineConnect records',
      ),
      (
        icon: Icons.bolt_rounded,
        title: 'Actions ready',
        meta: 'Role tools and approvals',
      ),
      (
        icon: Icons.verified_user_outlined,
        title: 'Secure session',
        meta: 'Verified portal access',
      ),
    ];
    return CineHoverZoom(
      scale: 1.003,
      pressedScale: 1.008,
      child: Container(
        height: 44,
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color:
                  colors.shadow.withValues(alpha: colors.isLight ? 0.08 : 0.28),
              blurRadius: 22,
              spreadRadius: -14,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: colors.danger,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: colors.danger, blurRadius: 7),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'LIVE',
                    style: AppTextStyles.micro.copyWith(
                      color: colors.danger,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 20, color: colors.border),
            Expanded(
              child: ClipRect(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      for (var index = 0; index < items.length; index++) ...[
                        if (index != 0) const SizedBox(width: 34),
                        _LiveStripItem(
                          icon: items[index].icon,
                          title: items[index].title,
                          meta: items[index].meta,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveStripItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String meta;

  const _LiveStripItem({
    required this.icon,
    required this.title,
    required this.meta,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: colors.goldSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 12, color: colors.goldDark),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.smallMeta.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          meta,
          style: AppTextStyles.smallMeta.copyWith(
            color: colors.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
