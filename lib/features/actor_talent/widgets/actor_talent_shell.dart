import 'package:flutter/material.dart';

import '../../../core/core_ui/core_logout.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/layout/floating_portal_menu.dart';
import '../../../shared/widgets/app_header.dart' show ThemeToggleButton;
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/cinematic_backdrop.dart';
import '../routes/actor_talent_routes.dart';

typedef ActorShellMenuEntry = ({
  String route,
  String screenId,
  String label,
  IconData icon,
});

const _actorBottomDestinations = [
  CineBottomNavDestination(
    label: 'Home',
    icon: Icons.home_outlined,
  ),
  CineBottomNavDestination(
    label: 'Opportunities',
    icon: Icons.local_activity_outlined,
  ),
  CineBottomNavDestination(
    label: 'Calendar',
    icon: Icons.calendar_month_outlined,
  ),
  CineBottomNavDestination(
    label: 'Earnings',
    icon: Icons.account_balance_wallet_outlined,
  ),
  CineBottomNavDestination(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
  ),
];

const _actorMenuEntries = <ActorShellMenuEntry>[
  (
    route: ActorTalentRoutes.dashboard,
    screenId: 'AT-01',
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
  ),
  (
    route: ActorTalentRoutes.profile,
    screenId: 'AT-02',
    label: 'Profile Builder',
    icon: Icons.badge_outlined,
  ),
  (
    route: ActorTalentRoutes.portfolio,
    screenId: 'AT-03',
    label: 'Portfolio',
    icon: Icons.video_library_outlined,
  ),
  (
    route: ActorTalentRoutes.calendar,
    screenId: 'AT-04',
    label: 'Calendar',
    icon: Icons.calendar_month_outlined,
  ),
  (
    route: ActorTalentRoutes.rates,
    screenId: 'AT-05',
    label: 'Rate Card',
    icon: Icons.price_change_outlined,
  ),
  (
    route: ActorTalentRoutes.opportunities,
    screenId: 'AT-06',
    label: 'Opportunities',
    icon: Icons.inbox_outlined,
  ),
  (
    route: ActorTalentRoutes.offerDetail,
    screenId: 'AT-07',
    label: 'Offer Detail',
    icon: Icons.description_outlined,
  ),
  (
    route: ActorTalentRoutes.counteroffer,
    screenId: 'AT-08',
    label: 'Counteroffer',
    icon: Icons.edit_note_outlined,
  ),
  (
    route: ActorTalentRoutes.contracts,
    screenId: 'AT-09',
    label: 'Contract Signing',
    icon: Icons.draw_outlined,
  ),
  (
    route: ActorTalentRoutes.earnings,
    screenId: 'AT-10',
    label: 'Earnings',
    icon: Icons.payments_outlined,
  ),
  (
    route: ActorTalentRoutes.reputation,
    screenId: 'AT-11',
    label: 'Reputation',
    icon: Icons.stars_outlined,
  ),
  (
    route: ActorTalentRoutes.safety,
    screenId: 'AT-12',
    label: 'Safety',
    icon: Icons.health_and_safety_outlined,
  ),
];

const _actorBottomIndexOverrides = {
  ActorTalentRoutes.offerDetail: 1,
  ActorTalentRoutes.counteroffer: 1,
  ActorTalentRoutes.contracts: 1,
  ActorTalentRoutes.rates: 4,
  ActorTalentRoutes.portfolio: 4,
  ActorTalentRoutes.reputation: 4,
  ActorTalentRoutes.safety: 4,
};

class ActorTalentShell extends StatefulWidget {
  final String routeName;
  final String title;
  final String screenId;
  final Widget child;
  final String portalLabel;
  final String menuTitle;
  final List<String> navRoutes;
  final List<CineBottomNavDestination> navDestinations;
  final List<ActorShellMenuEntry> menuEntries;
  final Map<String, int> bottomIndexOverrides;

  const ActorTalentShell({
    super.key,
    required this.routeName,
    required this.title,
    required this.screenId,
    required this.child,
    this.portalLabel = 'Actor / Talent Portal',
    this.menuTitle = 'Actor portal screens',
    this.navRoutes = ActorTalentRoutes.primaryNav,
    this.navDestinations = _actorBottomDestinations,
    this.menuEntries = _actorMenuEntries,
    this.bottomIndexOverrides = _actorBottomIndexOverrides,
  });

  @override
  State<ActorTalentShell> createState() => _ActorTalentShellState();
}

class _ActorTalentShellState extends State<ActorTalentShell> {
  bool _menuOpen = false;

  void _openMenu() {
    setState(() => _menuOpen = true);
  }

  void _closeMenu() {
    if (!_menuOpen) return;
    setState(() => _menuOpen = false);
  }

  void _selectMenuRoute(String route) {
    _closeMenu();
    if (route == widget.routeName) return;
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= 900 ? 28.0 : 14.0;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: CinematicBackdrop()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontal, 10, horizontal, 0),
                  child: _ActorTopBar(
                    title: widget.title,
                    screenId: widget.screenId,
                    portalLabel: widget.portalLabel,
                    onMenuTap: _openMenu,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      14,
                      horizontal,
                      18,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
                CineBottomNav(
                  currentIndex: _bottomIndex(widget.routeName),
                  compactCenter: true,
                  destinations: widget.navDestinations,
                  onTap: (index) {
                    final target = widget.navRoutes[index];
                    _closeMenu();
                    if (target == widget.routeName) return;
                    Navigator.pushNamed(context, target);
                  },
                ),
              ],
            ),
          ),
          FloatingPortalMenuOverlay(
            open: _menuOpen,
            currentRoute: widget.routeName,
            items: [
              for (final item in widget.menuEntries)
                FloatingPortalMenuItem(
                  route: item.route,
                  label: item.label,
                  icon: item.icon,
                ),
            ],
            statusTitle: widget.portalLabel,
            statusSubtitle: 'Portal systems operational',
            statusIcon: widget.navDestinations.isEmpty
                ? Icons.dashboard_outlined
                : widget.navDestinations.first.icon,
            onClose: _closeMenu,
            onRouteTap: _selectMenuRoute,
          ),
        ],
      ),
    );
  }

  int _bottomIndex(String route) {
    final override = widget.bottomIndexOverrides[route];
    if (override != null) return override;
    final index = widget.navRoutes.indexOf(route);
    return index == -1 ? 0 : index;
  }
}

class _ActorTopBar extends StatelessWidget {
  final String title;
  final String screenId;
  final String portalLabel;
  final VoidCallback onMenuTap;

  const _ActorTopBar({
    required this.title,
    required this.screenId,
    required this.portalLabel,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          CoreIconButton(
            icon: Icons.menu_rounded,
            tooltip: 'Portal menu',
            onTap: onMenuTap,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionHeading.copyWith(
                    color: colors.textPrimary,
                    fontSize: 18,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$screenId - $portalLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const ThemeToggleButton(size: 38),
          const SizedBox(width: 8),
          CoreIconButton(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notifications',
            onTap: () => Navigator.pushNamed(context, CoreRoutes.notifications),
          ),
          const SizedBox(width: 8),
          CoreIconButton(
            icon: Icons.logout_rounded,
            tooltip: 'Logout',
            onTap: () => logoutToLogin(context),
          ),
        ],
      ),
    );
  }
}
