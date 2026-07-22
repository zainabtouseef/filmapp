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
import '../routes/insurance_partner_routes.dart';

typedef InsuranceMenuEntry = ({
  String route,
  String screenId,
  String label,
  IconData icon,
});

const insuranceMenuEntries = <InsuranceMenuEntry>[
  (
    route: InsurancePartnerRoutes.home,
    screenId: 'IN-01',
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
  ),
  (
    route: InsurancePartnerRoutes.records,
    screenId: 'IN-02',
    label: 'Policies',
    icon: Icons.policy_outlined,
  ),
  (
    route: InsurancePartnerRoutes.claims,
    screenId: 'IN-03',
    label: 'Claims',
    icon: Icons.assignment_late_outlined,
  ),
  (
    route: InsurancePartnerRoutes.safety,
    screenId: 'IN-04',
    label: 'Safety Checks',
    icon: Icons.fact_check_outlined,
  ),
  (
    route: InsurancePartnerRoutes.incidents,
    screenId: 'IN-05',
    label: 'Incidents',
    icon: Icons.warning_amber_outlined,
  ),
];

const _bottomDestinations = [
  CineBottomNavDestination(label: 'Dash', icon: Icons.dashboard_outlined),
  CineBottomNavDestination(label: 'Policies', icon: Icons.policy_outlined),
  CineBottomNavDestination(
      label: 'Claims', icon: Icons.assignment_late_outlined),
  CineBottomNavDestination(label: 'Safety', icon: Icons.fact_check_outlined),
  CineBottomNavDestination(
      label: 'Incidents', icon: Icons.warning_amber_outlined),
];

class InsurancePartnerShell extends StatelessWidget {
  final String routeName;
  final String title;
  final String screenId;
  final Widget child;

  const InsurancePartnerShell({
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
      topBarBuilder: (context, wide, onMenuTap) => _InsuranceTopBar(
        screenId: screenId,
        wide: wide,
        onMenuTap: onMenuTap,
      ),
      sideNavBuilder: (context, currentRoute, onRouteTap) => _InsuranceSideNav(
        currentRoute: currentRoute,
        onRouteTap: onRouteTap,
      ),
      bottomNavBuilder:
          (context, currentRoute, menuOpen, onRouteTap, onMoreTap) =>
              AdminBottomNavSlot(
        child: _InsuranceBottomNav(
          currentRoute: currentRoute,
          onRouteTap: onRouteTap,
        ),
      ),
      floatingMenuBuilder: (context, open, currentRoute, onClose, onRouteTap) =>
          _InsuranceMenuOverlay(
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

class _InsuranceTopBar extends StatelessWidget {
  final String screenId;
  final bool wide;
  final VoidCallback onMenuTap;

  const _InsuranceTopBar({
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
          _InsuranceIconButton(
            icon: wide ? Icons.arrow_back_rounded : Icons.menu_rounded,
            tooltip: wide ? 'Back' : 'Menu',
            onTap: wide ? () => navigateCoreBack(context) : onMenuTap,
          ),
          const SizedBox(width: 10),
          if (!compact) ...[
            Icon(
              Icons.health_and_safety_outlined,
              color: colors.goldDark,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'INSURANCE',
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
                          : '$screenId - policies, claims, permits, incidents...',
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
          _InsuranceIconButton(
            icon: Icons.logout_rounded,
            tooltip: 'Logout',
            onTap: () => logoutToLogin(context),
          ),
          if (!compact) ...[
            const SizedBox(width: 10),
            _InsuranceIconButton(
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

class _InsuranceIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _InsuranceIconButton({
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

class _InsuranceSideNav extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onRouteTap;

  const _InsuranceSideNav({
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
                Icon(
                  Icons.health_and_safety_outlined,
                  color: colors.goldDark,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SAFETY DESK',
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
              'Policies, claims, safety checks and incident evidence.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: insuranceMenuEntries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = insuranceMenuEntries[index];
                  return _InsuranceNavTile(
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

class _InsuranceNavTile extends StatelessWidget {
  final InsuranceMenuEntry item;
  final bool active;
  final VoidCallback onTap;

  const _InsuranceNavTile({
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

class _InsuranceBottomNav extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onRouteTap;

  const _InsuranceBottomNav({
    required this.currentRoute,
    required this.onRouteTap,
  });

  @override
  Widget build(BuildContext context) {
    return CineBottomNav(
      currentIndex: _currentIndex(currentRoute),
      destinations: _bottomDestinations,
      compactCenter: true,
      onTap: (index) => onRouteTap(InsurancePartnerRoutes.primaryNav[index]),
    );
  }

  int _currentIndex(String route) {
    final index = InsurancePartnerRoutes.primaryNav.indexOf(route);
    return index == -1 ? 0 : index;
  }
}

class _InsuranceMenuOverlay extends StatelessWidget {
  final bool open;
  final String currentRoute;
  final VoidCallback onClose;
  final ValueChanged<String> onRouteTap;

  const _InsuranceMenuOverlay({
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
        for (final item in insuranceMenuEntries)
          FloatingPortalMenuItem(
            route: item.route,
            label: item.label,
            icon: item.icon,
          ),
      ],
      statusTitle: 'Insurance',
      statusSubtitle: 'Safety desk operational',
      statusIcon: Icons.health_and_safety_outlined,
      onClose: onClose,
      onRouteTap: onRouteTap,
    );
  }
}
