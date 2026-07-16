import 'package:flutter/material.dart';

import '../../../core/core_ui/core_back_navigation.dart';
import '../../../core/core_ui/core_logout.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/layout/admin_bottom_nav.dart';
import '../../../shared/layout/admin_screen_scaffold.dart';
import '../../../shared/layout/admin_top_bar.dart';
import '../../../shared/layout/floating_portal_menu.dart';
import '../../../shared/widgets/app_header.dart' show ThemeToggleButton;
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/glass_card.dart';
import '../models/role_portal_models.dart';

class RolePortalShell extends StatelessWidget {
  final RolePortalSpec portal;
  final RolePortalScreenSpec screen;
  final Widget child;

  const RolePortalShell({
    super.key,
    required this.portal,
    required this.screen,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AdminScreenScaffold(
      title: screen.title,
      currentRoute: screen.route,
      topBarBuilder: (context, wide, onMenuTap) => _PortalTopBar(
        portal: portal,
        wide: wide,
        onMenuTap: onMenuTap,
      ),
      sideNavBuilder: (context, currentRoute, onRouteTap) => _PortalSideNav(
        portal: portal,
        currentRoute: currentRoute,
        onRouteTap: onRouteTap,
      ),
      bottomNavBuilder:
          (context, currentRoute, menuOpen, onRouteTap, onMoreTap) =>
              AdminBottomNavSlot(
        child: _PortalBottomNav(
          portal: portal,
          currentRoute: currentRoute,
          menuOpen: menuOpen,
          onRouteTap: onRouteTap,
          onMoreTap: onMoreTap,
        ),
      ),
      floatingMenuBuilder: (context, open, currentRoute, onClose, onRouteTap) =>
          _PortalMenuOverlay(
        portal: portal,
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

class _PortalTopBar extends StatelessWidget {
  final RolePortalSpec portal;
  final bool wide;
  final VoidCallback onMenuTap;

  const _PortalTopBar({
    required this.portal,
    required this.wide,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final compact = MediaQuery.sizeOf(context).width < 700;
    return AdminTopBarFrame(
      compact: compact,
      child: Row(
        children: [
          _PortalIconButton(
            icon: wide ? Icons.arrow_back_rounded : Icons.menu_rounded,
            tooltip: wide ? 'Back' : 'Menu',
            onTap: wide ? () => navigateCoreBack(context) : onMenuTap,
          ),
          const SizedBox(width: 10),
          if (!compact) ...[
            Icon(portal.icon, color: colors.goldDark, size: 20),
            const SizedBox(width: 8),
            Text(
              portal.shortLabel.toUpperCase(),
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
                          : 'Search bookings, records, contracts, people...',
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
          _PortalIconButton(
            icon: Icons.logout_rounded,
            tooltip: 'Logout',
            onTap: () => logoutToLogin(context),
          ),
          if (!compact) ...[
            const SizedBox(width: 10),
            _PortalIconButton(
              icon: Icons.notifications_none_rounded,
              tooltip: 'Notifications',
              onTap: () => Navigator.pushNamed(context, '/notifications'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PortalIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _PortalIconButton({
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

class _PortalSideNav extends StatelessWidget {
  final RolePortalSpec portal;
  final String currentRoute;
  final ValueChanged<String> onRouteTap;

  const _PortalSideNav({
    required this.portal,
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
                Icon(portal.icon, color: colors.goldDark, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    portal.shortLabel.toUpperCase(),
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
              portal.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: portal.navItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = portal.navItems[index];
                  final active = item.route == currentRoute;
                  return _PortalNavTile(
                    item: item,
                    active: active,
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

class _PortalNavTile extends StatelessWidget {
  final RolePortalNavItem item;
  final bool active;
  final VoidCallback onTap;

  const _PortalNavTile({
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

class _PortalBottomNav extends StatelessWidget {
  final RolePortalSpec portal;
  final String currentRoute;
  final bool menuOpen;
  final ValueChanged<String> onRouteTap;
  final VoidCallback onMoreTap;

  const _PortalBottomNav({
    required this.portal,
    required this.currentRoute,
    required this.menuOpen,
    required this.onRouteTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = portal.navItems.take(4).toList();
    while (navItems.length < 4) {
      navItems.add(portal.navItems.first);
    }
    final destinations = [
      CineBottomNavDestination(
          label: navItems[0].label, icon: navItems[0].icon),
      CineBottomNavDestination(
          label: navItems[1].label, icon: navItems[1].icon),
      CineBottomNavDestination(
          label: navItems[2].label, icon: navItems[2].icon),
      CineBottomNavDestination(
          label: navItems[3].label, icon: navItems[3].icon),
      const CineBottomNavDestination(label: 'More', icon: Icons.menu_rounded),
    ];
    return CineBottomNav(
      currentIndex: menuOpen ? 4 : _currentIndex(navItems),
      destinations: destinations,
      compactCenter: true,
      onTap: (index) {
        if (index >= 0 && index < 4) {
          onRouteTap(navItems[index].route);
          return;
        }
        onMoreTap();
      },
    );
  }

  int _currentIndex(List<RolePortalNavItem> navItems) {
    for (var index = 0; index < navItems.length; index++) {
      if (navItems[index].route == currentRoute) return index;
    }
    return 4;
  }
}

class _PortalMenuOverlay extends StatelessWidget {
  final RolePortalSpec portal;
  final bool open;
  final String currentRoute;
  final VoidCallback onClose;
  final ValueChanged<String> onRouteTap;

  const _PortalMenuOverlay({
    required this.portal,
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
        for (final item in portal.navItems)
          FloatingPortalMenuItem(
            route: item.route,
            label: item.label,
            icon: item.icon,
          ),
      ],
      statusTitle: portal.shortLabel,
      statusSubtitle: 'Portal systems operational',
      statusIcon: portal.icon,
      onClose: onClose,
      onRouteTap: onRouteTap,
    );
  }
}
