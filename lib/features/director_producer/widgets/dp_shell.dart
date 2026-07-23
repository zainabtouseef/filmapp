import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
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
import '../routes/director_producer_routes.dart';
import 'dp_layout_helpers.dart';
import 'dp_status_chip.dart';

class DPShell extends StatelessWidget {
  final String title;
  final String currentRoute;
  final Widget child;
  final bool showHeading;
  final AdminFloatingActionBuilder? floatingActionBuilder;

  const DPShell({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.child,
    this.showHeading = true,
    this.floatingActionBuilder,
  });

  static const navItems = [
    DpNavItem(
      label: 'Console',
      icon: Icons.dashboard_customize_rounded,
      route: DirectorProducerRoutes.console,
    ),
    DpNavItem(
      label: 'Projects',
      icon: Icons.movie_creation_outlined,
      route: DirectorProducerRoutes.projects,
    ),
    DpNavItem(
      label: 'Discover',
      icon: Icons.manage_search_rounded,
      route: DirectorProducerRoutes.marketplace,
    ),
    DpNavItem(
      label: 'Shortlist',
      icon: Icons.view_kanban_outlined,
      route: DirectorProducerRoutes.shortlist,
    ),
    DpNavItem(
      label: 'Bargaining',
      icon: Icons.handshake_outlined,
      route: DirectorProducerRoutes.bargaining,
    ),
    DpNavItem(
      label: 'Contracts',
      icon: Icons.article_outlined,
      route: DirectorProducerRoutes.contracts,
    ),
    DpNavItem(
      label: 'Payments',
      icon: Icons.payments_outlined,
      route: DirectorProducerRoutes.payments,
    ),
    DpNavItem(
      label: 'Schedule',
      icon: Icons.calendar_month_outlined,
      route: DirectorProducerRoutes.schedule,
    ),
    DpNavItem(
      label: 'Accounts',
      icon: Icons.account_balance_wallet_outlined,
      route: DirectorProducerRoutes.accounts,
    ),
    DpNavItem(
      label: 'Room',
      icon: Icons.forum_outlined,
      route: DirectorProducerRoutes.room,
    ),
    DpNavItem(
      label: 'Reports',
      icon: Icons.file_download_outlined,
      route: DirectorProducerRoutes.reports,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final routedChild = showHeading
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DPRouteHeading(title: title, route: currentRoute),
              const SizedBox(height: 14),
              child,
            ],
          )
        : child;
    return AdminScreenScaffold(
      title: title,
      currentRoute: currentRoute,
      showHeading: false,
      floatingActionBuilder: floatingActionBuilder,
      topBarBuilder: (context, wide, onMenuTap) => _DPTopBar(
        wide: wide,
        onMenuTap: onMenuTap,
      ),
      sideNavBuilder: (context, currentRoute, onRouteTap) => _DPSidebar(
        currentRoute: currentRoute,
        onRouteTap: onRouteTap,
      ),
      bottomNavBuilder:
          (context, currentRoute, menuOpen, onRouteTap, onMoreTap) =>
              AdminBottomNavSlot(
        child: _DPBottomNav(
          currentRoute: currentRoute,
          menuOpen: menuOpen,
          onRouteTap: onRouteTap,
          onMoreTap: onMoreTap,
        ),
      ),
      floatingMenuBuilder: (context, open, currentRoute, onClose, onRouteTap) =>
          _DPMenuOverlay(
        open: open,
        currentRoute: currentRoute,
        onClose: onClose,
        onRouteTap: onRouteTap,
      ),
      onRouteSelected: (context, route) => Navigator.pushNamed(context, route),
      child: routedChild,
    );
  }
}

class _DPRouteHeading extends StatelessWidget {
  final String title;
  final String route;

  const _DPRouteHeading({required this.title, required this.route});

  @override
  Widget build(BuildContext context) {
    return DPPageHeader(
      eyebrow: _eyebrow,
      title: title,
    );
  }

  String get _eyebrow {
    return switch (route) {
      DirectorProducerRoutes.requirements => 'Project brief · requirements',
      DirectorProducerRoutes.filters => 'Discovery controls · saved view',
      DirectorProducerRoutes.profile => 'Verified profile · booking ready',
      DirectorProducerRoutes.shortlist => 'Shortlists · saved talent',
      DirectorProducerRoutes.bookingRequest => 'Booking composer · live terms',
      DirectorProducerRoutes.negotiationThread =>
        'Offer thread · counter terms',
      DirectorProducerRoutes.contracts => 'Agreements · signatures',
      DirectorProducerRoutes.payments => 'Ledger · proofs',
      DirectorProducerRoutes.schedule => 'Calendar · call sheets',
      DirectorProducerRoutes.accounts => 'Budgets · committed cost',
      DirectorProducerRoutes.room => 'Team room · decisions',
      DirectorProducerRoutes.reports => 'Exports · analytics',
      _ => 'Producer Console',
    };
  }
}

class _DPTopBar extends StatelessWidget {
  final bool wide;
  final VoidCallback onMenuTap;

  const _DPTopBar({
    required this.wide,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final compact = !wide;
    final canGoBack = wide || Navigator.canPop(context);
    return AdminTopBarFrame(
      compact: compact,
      child: Row(
        children: [
          _DPTopIcon(
            icon: canGoBack ? Icons.arrow_back_rounded : Icons.menu_rounded,
            tooltip: canGoBack ? 'Back' : 'Menu',
            onTap: canGoBack ? () => navigateCoreBack(context) : onMenuTap,
          ),
          const SizedBox(width: 10),
          _DPBrandLockup(compact: compact),
          SizedBox(width: compact ? 8 : 16),
          Expanded(child: _DPSearchPill(compact: compact)),
          const SizedBox(width: 10),
          if (wide) ...[
            _DPNotificationIcon(
              hasUnread: true,
              onTap: () =>
                  Navigator.pushNamed(context, CoreRoutes.notifications),
            ),
            const SizedBox(width: 10),
          ],
          _DPAvatarButton(
            onTap: () => Navigator.pushNamed(context, CoreRoutes.profileRoles),
          ),
          SizedBox(width: compact ? 8 : 10),
          ThemeToggleButton(size: compact ? 34 : 38),
          if (wide) ...[
            const SizedBox(width: 10),
            _DPTopIcon(
              icon: Icons.logout_rounded,
              tooltip: 'Logout',
              onTap: () => logoutToLogin(context),
            ),
            const SizedBox(width: 10),
            const DPStatusChip(
              label: 'Producer',
              tone: DpTone.warning,
              icon: Icons.workspace_premium_outlined,
            ),
          ],
        ],
      ),
    );
  }
}

class _DPBrandLockup extends StatelessWidget {
  final bool compact;

  const _DPBrandLockup({required this.compact});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: compact ? 96 : 166,
        maxWidth: compact ? 116 : 190,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: AppTextStyles.sectionHeaderStyle.copyWith(
                color: colors.textPrimary,
                fontSize: compact ? 17 : 22,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
              children: [
                const TextSpan(text: 'Cine'),
                TextSpan(
                  text: 'Connect',
                  style: TextStyle(color: colors.goldDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Producer Console',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: colors.textSecondary,
              fontSize: compact ? 10.5 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DPSearchPill extends StatelessWidget {
  final bool compact;

  const _DPSearchPill({required this.compact});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      height: compact ? 38 : 44,
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 13),
      decoration: BoxDecoration(
        gradient: colors.searchGradient,
        borderRadius: BorderRadius.circular(compact ? 15 : 18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded,
              color: colors.icon, size: compact ? 18 : 21),
          SizedBox(width: compact ? 7 : 9),
          Expanded(
            child: Text(
              compact ? 'Search...' : 'Search productions, talent...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
                fontSize: compact ? 12 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DPTopIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _DPTopIcon({
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

class _DPNotificationIcon extends StatelessWidget {
  final bool hasUnread;
  final VoidCallback onTap;

  const _DPNotificationIcon({required this.hasUnread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: 'Notifications',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(Icons.notifications_none_rounded,
                  color: colors.icon, size: 22),
              if (hasUnread)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: colors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DPAvatarButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DPAvatarButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: 'Profile',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.border),
          ),
          child: ClipOval(
            child: Image.asset(
              AppAssets.bilalAbbas,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: colors.softSurface,
                alignment: Alignment.center,
                child: Text(
                  'P',
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.goldDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DPSidebar extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onRouteTap;

  const _DPSidebar({
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
            Text(
              'DIRECTOR',
              style: AppTextStyles.sectionHeaderStyle.copyWith(
                color: colors.textPrimary,
                fontSize: 18,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Production command center',
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: DPShell.navItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = DPShell.navItems[index];
                  final active = _active(currentRoute, item.route);
                  return GestureDetector(
                    onTap: () => onRouteTap(item.route),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        gradient: active
                            ? colors.activeChipGradient
                            : colors.inactiveChipGradient,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: active ? colors.goldMid : colors.border,
                        ),
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
                                color: active
                                    ? colors.textPrimary
                                    : colors.textSecondary,
                                fontWeight:
                                    active ? FontWeight.w800 : FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _DPBottomNav extends StatelessWidget {
  final String currentRoute;
  final bool menuOpen;
  final ValueChanged<String> onRouteTap;
  final VoidCallback onMoreTap;

  const _DPBottomNav({
    required this.currentRoute,
    required this.menuOpen,
    required this.onRouteTap,
    required this.onMoreTap,
  });

  static const _destinations = [
    CineBottomNavDestination(label: 'Console', icon: Icons.home_outlined),
    CineBottomNavDestination(label: 'Productions', icon: Icons.movie_outlined),
    CineBottomNavDestination(label: 'Find', icon: Icons.search_rounded),
    CineBottomNavDestination(label: 'Deals', icon: Icons.handshake_outlined),
    CineBottomNavDestination(label: 'More', icon: Icons.menu_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return CineBottomNav(
      currentIndex: _currentIndex,
      destinations: _destinations,
      compactCenter: true,
      onTap: (index) {
        switch (index) {
          case 0:
            onRouteTap(DirectorProducerRoutes.home);
            return;
          case 1:
            onRouteTap(DirectorProducerRoutes.projects);
            return;
          case 2:
            onRouteTap(DirectorProducerRoutes.marketplace);
            return;
          case 3:
            onRouteTap(DirectorProducerRoutes.bargaining);
            return;
          default:
            onMoreTap();
        }
      },
    );
  }

  int get _currentIndex {
    if (menuOpen) return 4;
    if (_active(currentRoute, DirectorProducerRoutes.home)) return 0;
    if (_active(currentRoute, DirectorProducerRoutes.projects)) return 1;
    if (_active(currentRoute, DirectorProducerRoutes.marketplace)) return 2;
    if (_active(currentRoute, DirectorProducerRoutes.bargaining)) return 3;
    return 4;
  }
}

class _DPMenuOverlay extends StatelessWidget {
  final bool open;
  final String currentRoute;
  final VoidCallback onClose;
  final ValueChanged<String> onRouteTap;

  const _DPMenuOverlay({
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
        for (final item in DPShell.navItems)
          FloatingPortalMenuItem(
            route: item.route,
            label: item.label,
            icon: item.icon,
          ),
      ],
      statusTitle: 'Production Portal',
      statusSubtitle: 'Production command center',
      statusIcon: Icons.movie_filter_rounded,
      onClose: onClose,
      onRouteTap: onRouteTap,
      isRouteActive: _active,
    );
  }
}

bool _active(String currentRoute, String route) {
  if (route == DirectorProducerRoutes.home) {
    return currentRoute == route;
  }
  return currentRoute == route || currentRoute.startsWith(route);
}
