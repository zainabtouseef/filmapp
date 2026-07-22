import 'package:flutter/material.dart';

import '../../../core/core_ui/core_back_navigation.dart';
import '../../../core/core_ui/core_logout.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/layout/admin_bottom_nav.dart';
import '../../../shared/layout/admin_screen_scaffold.dart';
import '../../../shared/layout/admin_top_bar.dart';
import '../../../shared/layout/floating_portal_menu.dart';
import '../../../shared/widgets/app_header.dart' show ThemeToggleButton;
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/glass_card.dart';
import '../routes/legal_partner_routes.dart';

typedef LegalMenuEntry = ({
  String route,
  String screenId,
  String label,
  IconData icon,
});

const legalMenuEntries = <LegalMenuEntry>[
  (
    route: LegalPartnerRoutes.home,
    screenId: 'LG-01',
    label: 'Queue Dashboard',
    icon: Icons.dashboard_outlined,
  ),
  (
    route: LegalPartnerRoutes.contractReview,
    screenId: 'LG-02',
    label: 'Contract Review',
    icon: Icons.article_outlined,
  ),
  (
    route: LegalPartnerRoutes.templateReview,
    screenId: 'LG-03',
    label: 'Template Review',
    icon: Icons.library_books_outlined,
  ),
  (
    route: LegalPartnerRoutes.addendumReview,
    screenId: 'LG-04',
    label: 'Addendum Review',
    icon: Icons.post_add_outlined,
  ),
  (
    route: LegalPartnerRoutes.billing,
    screenId: 'LG-05',
    label: 'History & Billing',
    icon: Icons.receipt_long_outlined,
  ),
];

const _bottomDestinations = [
  CineBottomNavDestination(label: 'Queue', icon: Icons.dashboard_outlined),
  CineBottomNavDestination(label: 'Review', icon: Icons.article_outlined),
  CineBottomNavDestination(
      label: 'Templates', icon: Icons.library_books_outlined),
  CineBottomNavDestination(label: 'Addendums', icon: Icons.post_add_outlined),
  CineBottomNavDestination(label: 'Billing', icon: Icons.receipt_long_outlined),
];

class LegalPartnerShell extends StatelessWidget {
  final String routeName;
  final String title;
  final String screenId;
  final Widget child;

  const LegalPartnerShell({
    super.key,
    required this.routeName,
    required this.title,
    required this.screenId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AdminScreenScaffold(
      title: title,
      currentRoute: routeName,
      topBarBuilder: (context, wide, onMenuTap) => _LegalTopBar(
        screenId: screenId,
        wide: wide,
        onMenuTap: onMenuTap,
      ),
      sideNavBuilder: (context, currentRoute, onRouteTap) => _LegalSideNav(
        currentRoute: currentRoute,
        onRouteTap: onRouteTap,
      ),
      bottomNavBuilder:
          (context, currentRoute, menuOpen, onRouteTap, onMoreTap) =>
              AdminBottomNavSlot(
        child: _LegalBottomNav(
          currentRoute: currentRoute,
          onRouteTap: onRouteTap,
        ),
      ),
      floatingMenuBuilder: (context, open, currentRoute, onClose, onRouteTap) =>
          _LegalMenuOverlay(
        open: open,
        currentRoute: currentRoute,
        onClose: onClose,
        onRouteTap: onRouteTap,
      ),
      onRouteSelected: (context, route) => Navigator.pushNamed(context, route),
      child: child,
    );
  }
}

class _LegalTopBar extends StatelessWidget {
  final String screenId;
  final bool wide;
  final VoidCallback onMenuTap;

  const _LegalTopBar({
    required this.screenId,
    required this.wide,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final compact = !wide;
    return AdminTopBarFrame(
      compact: compact,
      child: Row(
        children: [
          _LegalIconButton(
            icon: wide ? Icons.arrow_back_rounded : Icons.menu_rounded,
            tooltip: wide ? 'Back' : 'Menu',
            onTap: wide ? () => navigateCoreBack(context) : onMenuTap,
          ),
          const SizedBox(width: 10),
          if (!compact) ...[
            Icon(Icons.gavel_outlined, color: colors.goldDark, size: 20),
            const SizedBox(width: 8),
            Text(
              'LEGAL',
              style: AppTextStyles.sectionHeaderStyle.copyWith(
                color: colors.textPrimary,
                fontSize: 13,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                gradient: colors.searchGradient,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: colors.goldDark, size: 19),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      compact
                          ? 'Search...'
                          : '$screenId - contracts, clauses, addendums, billing...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          ThemeToggleButton(size: compact ? 34 : 38),
          const SizedBox(width: 10),
          _LegalIconButton(
            icon: Icons.logout_rounded,
            tooltip: 'Logout',
            onTap: () => logoutToLogin(context),
          ),
          if (!compact) ...[
            const SizedBox(width: 10),
            _LegalIconButton(
              icon: Icons.notifications_none_rounded,
              tooltip: 'Notifications',
              onTap: () =>
                  Navigator.pushNamed(context, CoreRoutes.notifications),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegalIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _LegalIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          width: 38,
          height: 38,
          radius: 19,
          child: Icon(icon, color: colors.icon, size: 20),
        ),
      ),
    );
  }
}

class _LegalSideNav extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onRouteTap;

  const _LegalSideNav({
    required this.currentRoute,
    required this.onRouteTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 276,
      margin: const EdgeInsets.fromLTRB(14, 14, 0, 14),
      child: GlassContainer(
        radius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.gavel_outlined, color: colors.goldDark, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'LEGAL DESK',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sectionHeaderStyle.copyWith(
                      color: colors.textPrimary,
                      fontSize: 17,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'Queue, templates, addendums, history and billing.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: legalMenuEntries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = legalMenuEntries[index];
                  return _LegalNavTile(
                    item: item,
                    active: item.route == currentRoute,
                    onTap: () => onRouteTap(item.route),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalNavTile extends StatelessWidget {
  final LegalMenuEntry item;
  final bool active;
  final VoidCallback onTap;

  const _LegalNavTile({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          gradient:
              active ? colors.activeChipGradient : colors.inactiveChipGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? colors.goldMid : colors.border),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              color: active ? colors.goldDark : colors.iconMuted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardLabel.copyWith(
                  color: active ? colors.textPrimary : colors.textSecondary,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalBottomNav extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onRouteTap;

  const _LegalBottomNav({
    required this.currentRoute,
    required this.onRouteTap,
  });

  @override
  Widget build(BuildContext context) {
    return CineBottomNav(
      currentIndex: _currentIndex(currentRoute),
      destinations: _bottomDestinations,
      compactCenter: true,
      onTap: (index) => onRouteTap(LegalPartnerRoutes.primaryNav[index]),
    );
  }

  int _currentIndex(String route) {
    final index = LegalPartnerRoutes.primaryNav.indexOf(route);
    return index == -1 ? 0 : index;
  }
}

class _LegalMenuOverlay extends StatelessWidget {
  final bool open;
  final String currentRoute;
  final VoidCallback onClose;
  final ValueChanged<String> onRouteTap;

  const _LegalMenuOverlay({
    required this.open,
    required this.currentRoute,
    required this.onClose,
    required this.onRouteTap,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingPortalMenuOverlay(
      open: open,
      currentRoute: currentRoute,
      items: [
        for (final item in legalMenuEntries)
          FloatingPortalMenuItem(
            route: item.route,
            label: item.label,
            icon: item.icon,
          ),
      ],
      statusTitle: 'Legal Desk',
      statusSubtitle: 'Review queue operational',
      statusIcon: Icons.gavel_outlined,
      onClose: onClose,
      onRouteTap: onRouteTap,
    );
  }
}
