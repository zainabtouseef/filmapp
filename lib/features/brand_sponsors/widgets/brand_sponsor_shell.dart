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
import '../routes/brand_sponsor_routes.dart';

typedef BrandSponsorMenuEntry = ({
  String route,
  String screenId,
  String label,
  IconData icon,
});

const brandSponsorMenuEntries = <BrandSponsorMenuEntry>[
  (
    route: BrandSponsorRoutes.home,
    screenId: 'BR-01',
    label: 'Brand Dashboard',
    icon: Icons.dashboard_outlined,
  ),
  (
    route: BrandSponsorRoutes.profile,
    screenId: 'BR-02',
    label: 'Brand Profile',
    icon: Icons.business_center_outlined,
  ),
  (
    route: BrandSponsorRoutes.composer,
    screenId: 'BR-03',
    label: 'Opportunity Composer',
    icon: Icons.campaign_outlined,
  ),
  (
    route: BrandSponsorRoutes.applications,
    screenId: 'BR-04',
    label: 'Applications Inbox',
    icon: Icons.inbox_outlined,
  ),
  (
    route: BrandSponsorRoutes.negotiation,
    screenId: 'BR-05',
    label: 'Negotiation & Terms',
    icon: Icons.handshake_outlined,
  ),
  (
    route: BrandSponsorRoutes.tracker,
    screenId: 'BR-06',
    label: 'Campaign Tracker',
    icon: Icons.track_changes_outlined,
  ),
  (
    route: BrandSponsorRoutes.payments,
    screenId: 'BR-07',
    label: 'Payments & Records',
    icon: Icons.payments_outlined,
  ),
];

const _bottomDestinations = [
  CineBottomNavDestination(label: 'Dashboard', icon: Icons.dashboard_outlined),
  CineBottomNavDestination(
      label: 'Opportunities', icon: Icons.campaign_outlined),
  CineBottomNavDestination(label: 'Applications', icon: Icons.inbox_outlined),
  CineBottomNavDestination(
      label: 'Campaigns', icon: Icons.track_changes_outlined),
  CineBottomNavDestination(label: 'Payments', icon: Icons.payments_outlined),
];

class BrandSponsorShell extends StatelessWidget {
  final String routeName;
  final String title;
  final String screenId;
  final Widget child;

  const BrandSponsorShell({
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
      topBarBuilder: (context, wide, onMenuTap) => _BrandTopBar(
        screenId: screenId,
        wide: wide,
        onMenuTap: onMenuTap,
      ),
      sideNavBuilder: (context, currentRoute, onRouteTap) => _BrandSideNav(
        currentRoute: currentRoute,
        onRouteTap: onRouteTap,
      ),
      bottomNavBuilder:
          (context, currentRoute, menuOpen, onRouteTap, onMoreTap) =>
              AdminBottomNavSlot(
        child: _BrandBottomNav(
          currentRoute: currentRoute,
          onRouteTap: onRouteTap,
        ),
      ),
      floatingMenuBuilder: (context, open, currentRoute, onClose, onRouteTap) =>
          _BrandMenuOverlay(
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

class _BrandTopBar extends StatelessWidget {
  final String screenId;
  final bool wide;
  final VoidCallback onMenuTap;

  const _BrandTopBar({
    required this.screenId,
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
          _BrandIconButton(
            icon: wide ? Icons.arrow_back_rounded : Icons.menu_rounded,
            tooltip: wide ? 'Back' : 'Menu',
            onTap: wide ? () => navigateCoreBack(context) : onMenuTap,
          ),
          const SizedBox(width: 10),
          if (!compact) ...[
            Icon(Icons.campaign_outlined, color: colors.goldDark, size: 20),
            const SizedBox(width: 8),
            Text(
              'BRANDS',
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
                          : '$screenId - campaigns, applications, payments...',
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
          _BrandIconButton(
            icon: Icons.logout_rounded,
            tooltip: 'Logout',
            onTap: () => logoutToLogin(context),
          ),
          if (!compact) ...[
            const SizedBox(width: 10),
            _BrandIconButton(
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

class _BrandIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _BrandIconButton({
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

class _BrandSideNav extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onRouteTap;

  const _BrandSideNav({
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
                Icon(Icons.campaign_outlined, color: colors.goldDark, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SPONSORS',
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
              'Opportunities, applications, campaigns, payments and profile.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: brandSponsorMenuEntries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = brandSponsorMenuEntries[index];
                  return _BrandNavTile(
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

class _BrandNavTile extends StatelessWidget {
  final BrandSponsorMenuEntry item;
  final bool active;
  final VoidCallback onTap;

  const _BrandNavTile({
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

class _BrandBottomNav extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onRouteTap;

  const _BrandBottomNav({
    required this.currentRoute,
    required this.onRouteTap,
  });

  @override
  Widget build(BuildContext context) {
    return CineBottomNav(
      currentIndex: _currentIndex(currentRoute),
      destinations: _bottomDestinations,
      compactCenter: true,
      onTap: (index) => onRouteTap(BrandSponsorRoutes.primaryNav[index]),
    );
  }

  int _currentIndex(String route) {
    if (route == BrandSponsorRoutes.negotiation) return 2;
    if (route == BrandSponsorRoutes.profile) return 0;
    final index = BrandSponsorRoutes.primaryNav.indexOf(route);
    return index == -1 ? 0 : index;
  }
}

class _BrandMenuOverlay extends StatelessWidget {
  final bool open;
  final String currentRoute;
  final VoidCallback onClose;
  final ValueChanged<String> onRouteTap;

  const _BrandMenuOverlay({
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
        for (final item in brandSponsorMenuEntries)
          FloatingPortalMenuItem(
            route: item.route,
            label: item.label,
            icon: item.icon,
          ),
      ],
      statusTitle: 'Brand Sponsor',
      statusSubtitle: 'Campaign portal operational',
      statusIcon: Icons.campaign_outlined,
      onClose: onClose,
      onRouteTap: onRouteTap,
    );
  }
}
