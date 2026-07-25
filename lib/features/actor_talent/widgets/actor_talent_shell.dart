import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/core_ui/core_back_navigation.dart';
import '../../../core/core_ui/core_logout.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/layout/admin_bottom_nav.dart';
import '../../../shared/layout/admin_screen_scaffold.dart';
import '../../../shared/layout/admin_top_bar.dart';
import '../../../shared/layout/floating_portal_menu.dart';
import '../../../shared/widgets/app_header.dart' show ThemeToggleButton;
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/cinematic_backdrop.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../routes/actor_talent_routes.dart';

typedef ActorShellMenuEntry = ({
  String route,
  String screenId,
  String label,
  IconData icon,
});

// Five primary destinations an actor reaches in one tap — mirrors the
// director/producer shell's bottom nav shape. Everything else (Auditions,
// Calendar, Rates, Contracts, Earnings, Reviews, Safety) lives one tap away
// in the "More" menu opened from the top-bar menu icon, not the bottom bar,
// so the bottom bar never needs a 6th "more" slot.
const _actorBottomDestinations = [
  CineBottomNavDestination(
    label: 'Home',
    icon: Icons.home_outlined,
  ),
  CineBottomNavDestination(
    label: 'Discover',
    icon: Icons.local_activity_outlined,
  ),
  CineBottomNavDestination(
    label: 'Applications',
    icon: Icons.assignment_outlined,
  ),
  CineBottomNavDestination(
    label: 'Bookings',
    icon: Icons.event_available_outlined,
  ),
  CineBottomNavDestination(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
  ),
];

// Secondary sections, reached from the top-bar menu icon rather than the
// bottom nav — kept out of the 5 primary taps so the everyday path (home,
// discover, applications, bookings, profile) never feels crowded.
const _actorMenuEntries = <ActorShellMenuEntry>[
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
    label: 'Rates',
    icon: Icons.price_change_outlined,
  ),
  (
    route: ActorTalentRoutes.auditions,
    screenId: 'AT-16',
    label: 'Auditions',
    icon: Icons.video_camera_front_outlined,
  ),
  (
    route: ActorTalentRoutes.contracts,
    screenId: 'AT-09',
    label: 'Contracts',
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
    label: 'Reviews',
    icon: Icons.stars_outlined,
  ),
  (
    route: ActorTalentRoutes.safety,
    screenId: 'AT-12',
    label: 'Safety & Support',
    icon: Icons.health_and_safety_outlined,
  ),
];

const _actorBottomIndexOverrides = {
  ActorTalentRoutes.offerDetail: 1,
  ActorTalentRoutes.counteroffer: 1,
  ActorTalentRoutes.roleDetail: 1,
  ActorTalentRoutes.applicationDetail: 2,
  ActorTalentRoutes.auditions: 2,
  ActorTalentRoutes.contracts: 4,
  ActorTalentRoutes.rates: 4,
  ActorTalentRoutes.portfolio: 4,
  ActorTalentRoutes.calendar: 4,
  ActorTalentRoutes.earnings: 4,
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
  final bool workspaceLayout;
  final String workspaceTitle;
  final String workspaceSectionLabel;
  final String workspaceBadgeLabel;
  final String workspaceStatusSubtitle;
  final String workspaceSearchHint;
  final String workspaceSearchRoute;
  final String workspaceProfileRoute;
  final IconData workspaceIcon;
  final String Function(String route)? workspaceEyebrow;

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
    this.workspaceLayout = false,
    this.workspaceTitle = 'Talent Workspace',
    this.workspaceSectionLabel = 'ACTOR / TALENT',
    this.workspaceBadgeLabel = 'Talent',
    this.workspaceStatusSubtitle = 'Profile, offers, bookings and earnings',
    this.workspaceSearchHint = 'Search offers and auditions...',
    this.workspaceSearchRoute = ActorTalentRoutes.opportunities,
    this.workspaceProfileRoute = ActorTalentRoutes.profile,
    this.workspaceIcon = Icons.theater_comedy_outlined,
    this.workspaceEyebrow,
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
    if (widget.workspaceLayout) {
      return _ActorWorkspaceScaffold(
        routeName: widget.routeName,
        title: widget.title,
        portalLabel: widget.portalLabel,
        navRoutes: widget.navRoutes,
        navDestinations: widget.navDestinations,
        menuEntries: widget.menuEntries,
        bottomIndexOverrides: widget.bottomIndexOverrides,
        workspaceTitle: widget.workspaceTitle,
        workspaceSectionLabel: widget.workspaceSectionLabel,
        workspaceBadgeLabel: widget.workspaceBadgeLabel,
        workspaceStatusSubtitle: widget.workspaceStatusSubtitle,
        workspaceSearchHint: widget.workspaceSearchHint,
        workspaceSearchRoute: widget.workspaceSearchRoute,
        workspaceProfileRoute: widget.workspaceProfileRoute,
        workspaceIcon: widget.workspaceIcon,
        workspaceEyebrow: widget.workspaceEyebrow,
        child: widget.child,
      );
    }
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

class _ActorWorkspaceScaffold extends StatelessWidget {
  final String routeName;
  final String title;
  final Widget child;
  final String portalLabel;
  final List<String> navRoutes;
  final List<CineBottomNavDestination> navDestinations;
  final List<ActorShellMenuEntry> menuEntries;
  final Map<String, int> bottomIndexOverrides;
  final String workspaceTitle;
  final String workspaceSectionLabel;
  final String workspaceBadgeLabel;
  final String workspaceStatusSubtitle;
  final String workspaceSearchHint;
  final String workspaceSearchRoute;
  final String workspaceProfileRoute;
  final IconData workspaceIcon;
  final String Function(String route)? workspaceEyebrow;

  const _ActorWorkspaceScaffold({
    required this.routeName,
    required this.title,
    required this.child,
    required this.portalLabel,
    required this.navRoutes,
    required this.navDestinations,
    required this.menuEntries,
    required this.bottomIndexOverrides,
    required this.workspaceTitle,
    required this.workspaceSectionLabel,
    required this.workspaceBadgeLabel,
    required this.workspaceStatusSubtitle,
    required this.workspaceSearchHint,
    required this.workspaceSearchRoute,
    required this.workspaceProfileRoute,
    required this.workspaceIcon,
    required this.workspaceEyebrow,
  });

  @override
  Widget build(BuildContext context) {
    return AdminScreenScaffold(
      title: title,
      currentRoute: routeName,
      showHeading: false,
      topBarBuilder: (context, wide, onMenuTap) => _ActorWorkspaceTopBar(
        wide: wide,
        onMenuTap: onMenuTap,
        workspaceTitle: workspaceTitle,
        searchHint: workspaceSearchHint,
        searchRoute: workspaceSearchRoute,
        profileRoute: workspaceProfileRoute,
      ),
      sideNavBuilder: (context, currentRoute, onRouteTap) =>
          _ActorWorkspaceSidebar(
        currentRoute: currentRoute,
        portalLabel: portalLabel,
        sectionLabel: workspaceSectionLabel,
        menuEntries: menuEntries,
        onRouteTap: onRouteTap,
      ),
      bottomNavBuilder:
          (context, currentRoute, menuOpen, onRouteTap, onMoreTap) =>
              AdminBottomNavSlot(
        child: _ActorWorkspaceBottomNav(
          currentRoute: currentRoute,
          menuOpen: menuOpen,
          navRoutes: navRoutes,
          navDestinations: navDestinations,
          bottomIndexOverrides: bottomIndexOverrides,
          onRouteTap: onRouteTap,
          onMoreTap: onMoreTap,
        ),
      ),
      floatingMenuBuilder: (context, open, currentRoute, onClose, onRouteTap) =>
          FloatingPortalMenuOverlay(
        open: open,
        currentRoute: currentRoute,
        items: [
          for (final item in menuEntries)
            FloatingPortalMenuItem(
              route: item.route,
              label: item.label,
              icon: item.icon,
            ),
        ],
        statusTitle: workspaceTitle,
        statusSubtitle: workspaceStatusSubtitle,
        statusIcon: workspaceIcon,
        onClose: onClose,
        onRouteTap: onRouteTap,
        isRouteActive: _actorRouteActive,
      ),
      onRouteSelected: (context, route) => Navigator.pushNamed(context, route),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActorRouteHeading(
            title: title,
            route: routeName,
            badgeLabel: workspaceBadgeLabel,
            icon: workspaceIcon,
            eyebrowBuilder: workspaceEyebrow,
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ActorRouteHeading extends StatelessWidget {
  final String title;
  final String route;
  final String badgeLabel;
  final IconData icon;
  final String Function(String route)? eyebrowBuilder;

  const _ActorRouteHeading({
    required this.title,
    required this.route,
    required this.badgeLabel,
    required this.icon,
    this.eyebrowBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrowBuilder?.call(route) ?? _eyebrow,
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.heroSerifNumber.copyWith(
                  color: colors.textPrimary,
                  fontSize: 30,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        StatusChip(
          label: badgeLabel,
          icon: icon,
          color: colors.goldMid,
        ),
      ],
    );
  }

  String get _eyebrow {
    return switch (route) {
      ActorTalentRoutes.dashboard => 'Talent workspace · overview',
      ActorTalentRoutes.profile => 'Public identity · casting profile',
      ActorTalentRoutes.portfolio => 'Media library · director-facing view',
      ActorTalentRoutes.calendar => 'Availability · booking conflicts',
      ActorTalentRoutes.rates => 'Rate guidance · negotiation baseline',
      ActorTalentRoutes.opportunities => 'Offers · auditions · casting calls',
      ActorTalentRoutes.roleDetail => 'Casting call · role brief',
      ActorTalentRoutes.applications => 'Submissions · status tracking',
      ActorTalentRoutes.applicationDetail => 'Application · next action',
      ActorTalentRoutes.auditions => 'Auditions · self-tapes · callbacks',
      ActorTalentRoutes.bookings => 'Confirmed work · schedule · messages',
      ActorTalentRoutes.offerDetail => 'Offer review · response due',
      ActorTalentRoutes.counteroffer => 'Negotiation · revised terms',
      ActorTalentRoutes.contracts => 'Agreements · signatures',
      ActorTalentRoutes.earnings => 'Payments · receipts · payout security',
      ActorTalentRoutes.reputation => 'Reviews · trust signals',
      ActorTalentRoutes.safety => 'Privacy · boundaries · support',
      _ => 'Actor / Talent workspace',
    };
  }
}

class _ActorWorkspaceTopBar extends StatelessWidget {
  final bool wide;
  final VoidCallback onMenuTap;
  final String workspaceTitle;
  final String searchHint;
  final String searchRoute;
  final String profileRoute;

  const _ActorWorkspaceTopBar({
    required this.wide,
    required this.onMenuTap,
    required this.workspaceTitle,
    required this.searchHint,
    required this.searchRoute,
    required this.profileRoute,
  });

  @override
  Widget build(BuildContext context) {
    final compact = !wide;
    final canGoBack = Navigator.canPop(context);
    return AdminTopBarFrame(
      compact: compact,
      child: Row(
        children: [
          _ActorTopIcon(
            icon: canGoBack ? Icons.arrow_back_rounded : Icons.menu_rounded,
            tooltip: canGoBack ? 'Back' : 'Menu',
            onTap: canGoBack ? () => navigateCoreBack(context) : onMenuTap,
          ),
          const SizedBox(width: 10),
          _ActorBrandLockup(
            compact: compact,
            workspaceTitle: workspaceTitle,
          ),
          SizedBox(width: compact ? 8 : 16),
          Expanded(
            child: _ActorSearchPill(
              compact: compact,
              hint: searchHint,
              onTap: () => Navigator.pushNamed(
                context,
                searchRoute,
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (wide) ...[
            _ActorNotificationButton(
              onTap: () => Navigator.pushNamed(
                context,
                CoreRoutes.notifications,
              ),
            ),
            const SizedBox(width: 10),
          ],
          _ActorAvatarButton(
            onTap: () => Navigator.pushNamed(
              context,
              profileRoute,
            ),
          ),
          SizedBox(width: compact ? 8 : 10),
          ThemeToggleButton(size: compact ? 34 : 38),
          if (wide) ...[
            const SizedBox(width: 10),
            _ActorTopIcon(
              icon: Icons.logout_rounded,
              tooltip: 'Logout',
              onTap: () => logoutToLogin(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActorBrandLockup extends StatelessWidget {
  final bool compact;
  final String workspaceTitle;

  const _ActorBrandLockup({
    required this.compact,
    required this.workspaceTitle,
  });

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
            workspaceTitle,
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

class _ActorSearchPill extends StatelessWidget {
  final bool compact;
  final String hint;
  final VoidCallback onTap;

  const _ActorSearchPill({
    required this.compact,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: 'Search opportunities',
      child: InkWell(
        borderRadius: BorderRadius.circular(compact ? 15 : 18),
        onTap: onTap,
        child: Container(
          height: compact ? 38 : 44,
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 13),
          decoration: BoxDecoration(
            gradient: colors.searchGradient,
            borderRadius: BorderRadius.circular(compact ? 15 : 18),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: colors.icon,
                size: compact ? 18 : 21,
              ),
              SizedBox(width: compact ? 7 : 9),
              Expanded(
                child: Text(
                  compact ? 'Search...' : hint,
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
        ),
      ),
    );
  }
}

class _ActorTopIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ActorTopIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
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

class _ActorNotificationButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ActorNotificationButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: 'Notifications',
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: colors.icon,
                size: 22,
              ),
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

class _ActorAvatarButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ActorAvatarButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: 'Talent profile',
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
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
              AppAssets.currentUserAvatar,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: colors.softSurface,
                alignment: Alignment.center,
                child: Text(
                  'T',
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

class _ActorWorkspaceSidebar extends StatelessWidget {
  final String currentRoute;
  final String portalLabel;
  final String sectionLabel;
  final List<ActorShellMenuEntry> menuEntries;
  final ValueChanged<String> onRouteTap;

  const _ActorWorkspaceSidebar({
    required this.currentRoute,
    required this.portalLabel,
    required this.sectionLabel,
    required this.menuEntries,
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
              sectionLabel,
              style: AppTextStyles.sectionHeaderStyle.copyWith(
                color: colors.textPrimary,
                fontSize: 18,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              portalLabel,
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: menuEntries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = menuEntries[index];
                  final active = _actorRouteActive(currentRoute, item.route);
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
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
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: active
                                  ? colors.goldMid
                                  : colors.iconMuted.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
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

class _ActorWorkspaceBottomNav extends StatelessWidget {
  final String currentRoute;
  final bool menuOpen;
  final List<String> navRoutes;
  final List<CineBottomNavDestination> navDestinations;
  final Map<String, int> bottomIndexOverrides;
  final ValueChanged<String> onRouteTap;
  final VoidCallback onMoreTap;

  const _ActorWorkspaceBottomNav({
    required this.currentRoute,
    required this.menuOpen,
    required this.navRoutes,
    required this.navDestinations,
    required this.bottomIndexOverrides,
    required this.onRouteTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return CineBottomNav(
      currentIndex: _currentIndex,
      destinations: navDestinations,
      compactCenter: true,
      onTap: (index) {
        if (index < navRoutes.length) onRouteTap(navRoutes[index]);
      },
    );
  }

  int get _currentIndex {
    final override = bottomIndexOverrides[currentRoute];
    if (override != null) return override;
    final index = navRoutes.indexOf(currentRoute);
    return index == -1 ? 0 : index;
  }
}

bool _actorRouteActive(String currentRoute, String route) {
  if (route == ActorTalentRoutes.dashboard) return currentRoute == route;
  return currentRoute == route || currentRoute.startsWith('$route/');
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
