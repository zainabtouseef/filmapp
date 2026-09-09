import 'package:flutter/material.dart';

import '../../../core/core_ui/core_back_navigation.dart';
import '../../../core/core_ui/core_logout.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/tour/tour_controller.dart';
import '../../../core/tour/tour_preferences_store.dart';
import '../../../core/tour/tour_target.dart';
import '../../../shared/layout/admin_bottom_nav.dart';
import '../../../shared/layout/admin_screen_scaffold.dart';
import '../../../shared/layout/admin_top_bar.dart';
import '../../../shared/layout/floating_portal_menu.dart';
import '../../../shared/widgets/app_header.dart' show ThemeToggleButton;
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../routes/brand_sponsor_routes.dart';
import 'brand_sponsor_live.dart';
import 'brand_tour_steps.dart';

void startBrandTour(BuildContext context) {
  TourScope.of(context).start(
    brandTourSteps,
    tourId: brandTourId,
    replaceRoutes: true,
    onFinished: () => const TourPreferencesStore().markSeen(brandTourId),
  );
}

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
    label: 'Overview',
    icon: Icons.dashboard_outlined,
  ),
  (
    route: BrandSponsorRoutes.projects,
    screenId: 'BR-08',
    label: 'Projects',
    icon: Icons.movie_creation_outlined,
  ),
  (
    route: BrandSponsorRoutes.marketplace,
    screenId: 'BR-09',
    label: 'Discover',
    icon: Icons.manage_search_outlined,
  ),
  (
    route: BrandSponsorRoutes.shortlists,
    screenId: 'BR-10',
    label: 'Shortlists',
    icon: Icons.favorite_border_rounded,
  ),
  (
    route: BrandSponsorRoutes.bookings,
    screenId: 'BR-11',
    label: 'Requests & Bookings',
    icon: Icons.send_time_extension_outlined,
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
    label: 'Opportunities',
    icon: Icons.campaign_outlined,
  ),
  (
    route: BrandSponsorRoutes.applications,
    screenId: 'BR-04',
    label: 'Applications',
    icon: Icons.move_to_inbox_outlined,
  ),
  (
    route: BrandSponsorRoutes.negotiation,
    screenId: 'BR-05',
    label: 'Terms & Deals',
    icon: Icons.handshake_outlined,
  ),
  (
    route: BrandSponsorRoutes.tracker,
    screenId: 'BR-06',
    label: 'Campaign Delivery',
    icon: Icons.fact_check_outlined,
  ),
  (
    route: BrandSponsorRoutes.payments,
    screenId: 'BR-07',
    label: 'Finance & Records',
    icon: Icons.account_balance_wallet_outlined,
  ),
];

const _brandBottomDestinations = [
  CineBottomNavDestination(
    label: 'Home',
    icon: Icons.home_outlined,
    route: BrandSponsorRoutes.home,
  ),
  CineBottomNavDestination(
    label: 'Projects',
    icon: Icons.movie_outlined,
    route: BrandSponsorRoutes.projects,
  ),
  CineBottomNavDestination(
    label: 'Discover',
    icon: Icons.search_rounded,
    route: BrandSponsorRoutes.marketplace,
  ),
  CineBottomNavDestination(
    label: 'Requests',
    icon: Icons.send_outlined,
    route: BrandSponsorRoutes.bookings,
  ),
  CineBottomNavDestination(
    label: 'More',
    icon: Icons.menu_rounded,
    route: BrandSponsorRoutes.shortlists,
  ),
];

const _brandBottomRoutes = [
  BrandSponsorRoutes.home,
  BrandSponsorRoutes.projects,
  BrandSponsorRoutes.marketplace,
  BrandSponsorRoutes.bookings,
];

const _brandBottomIndexOverrides = {
  BrandSponsorRoutes.profile: 4,
  BrandSponsorRoutes.shortlists: 4,
  BrandSponsorRoutes.composer: 4,
  BrandSponsorRoutes.applications: 4,
  BrandSponsorRoutes.negotiation: 4,
  BrandSponsorRoutes.tracker: 4,
  BrandSponsorRoutes.payments: 4,
};

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
    final showMobileDemo =
        MediaQuery.sizeOf(context).width < AppBreakpoints.laptop;
    return AdminScreenScaffold(
      title: title,
      currentRoute: routeName,
      showHeading: false,
      topBarBuilder: (context, wide, onMenuTap) => _BrandWorkspaceTopBar(
        wide: wide,
        onMenuTap: onMenuTap,
      ),
      sideNavBuilder: (context, currentRoute, onRouteTap) =>
          _BrandWorkspaceSidebar(
        currentRoute: currentRoute,
        onRouteTap: onRouteTap,
      ),
      bottomNavBuilder:
          (context, currentRoute, menuOpen, onRouteTap, onMoreTap) =>
              AdminBottomNavSlot(
        child: _BrandWorkspaceBottomNav(
          currentRoute: currentRoute,
          menuOpen: menuOpen,
          onRouteTap: onRouteTap,
          onMoreTap: onMoreTap,
        ),
      ),
      floatingMenuBuilder: (context, open, currentRoute, onClose, onRouteTap) =>
          FloatingPortalMenuOverlay(
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
        statusTitle: 'Brand Workspace',
        statusSubtitle: 'Opportunities, deals, delivery and finance',
        statusIcon: Icons.campaign_outlined,
        onClose: onClose,
        onRouteTap: onRouteTap,
        isRouteActive: _brandRouteActive,
      ),
      onRouteSelected: (context, route) => Navigator.pushNamed(context, route),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _BrandRouteHeading(title: title, route: routeName),
              ),
              if (showMobileDemo) ...[
                const SizedBox(width: 10),
                _BrandDemoLauncher(onTap: () => startBrandTour(context)),
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _BrandDemoLauncher extends StatelessWidget {
  final VoidCallback onTap;

  const _BrandDemoLauncher({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: 'Play one complete project story',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('brand-demo-launcher'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              gradient: colors.goldGradient,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.goldMid),
              boxShadow: [
                BoxShadow(
                  color: colors.goldGlow,
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.play_circle_outline_rounded,
                  color: colors.onGold,
                  size: 19,
                ),
                const SizedBox(width: 7),
                Text(
                  'Project demo',
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.onGold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandRouteHeading extends StatelessWidget {
  final String title;
  final String route;

  const _BrandRouteHeading({required this.title, required this.route});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _eyebrow,
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
                fontSize: compact ? 27 : 30,
              ),
            ),
          ],
        );
        final badge = StatusChip(
          label: 'Brand Sponsor',
          icon: Icons.verified_outlined,
          color: colors.goldMid,
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 10),
              badge,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 12),
            badge,
          ],
        );
      },
    );
  }

  String get _eyebrow {
    return switch (route) {
      BrandSponsorRoutes.home => 'Brand workspace · overview',
      BrandSponsorRoutes.projects => 'Campaign planning · production scope',
      BrandSponsorRoutes.marketplace => 'Talent · crew · locations · equipment',
      BrandSponsorRoutes.shortlists => 'Project picks · comparison · selection',
      BrandSponsorRoutes.bookings => 'Requests · responses · confirmations',
      BrandSponsorRoutes.profile => 'Identity · organization trust',
      BrandSponsorRoutes.composer => 'Campaign brief · opportunity publishing',
      BrandSponsorRoutes.applications => 'Proposals · audience · selection',
      BrandSponsorRoutes.negotiation => 'Scope · rights · payment terms',
      BrandSponsorRoutes.tracker => 'Proof · revisions · verified metrics',
      BrandSponsorRoutes.payments => 'Schedules · ledger · receipts',
      _ => 'Brand sponsor workspace',
    };
  }
}

class _BrandWorkspaceTopBar extends StatelessWidget {
  final bool wide;
  final VoidCallback onMenuTap;

  const _BrandWorkspaceTopBar({
    required this.wide,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final compact = !wide;
    final veryCompact = MediaQuery.sizeOf(context).width < 380;
    final canGoBack = Navigator.canPop(context);
    return AdminTopBarFrame(
      compact: compact,
      child: Row(
        children: [
          _BrandTopIcon(
            icon: canGoBack ? Icons.arrow_back_rounded : Icons.menu_rounded,
            tooltip: canGoBack ? 'Back' : 'Menu',
            onTap: canGoBack ? () => navigateCoreBack(context) : onMenuTap,
          ),
          SizedBox(width: veryCompact ? 6 : 10),
          if (veryCompact)
            Icon(
              Icons.movie_filter_outlined,
              color: context.appColors.goldDark,
              size: 22,
            )
          else
            _BrandLockup(compact: compact),
          SizedBox(width: veryCompact ? 6 : (compact ? 8 : 16)),
          Expanded(
            child: _BrandSearchPill(
              compact: compact,
              onTap: () => Navigator.pushNamed(
                context,
                BrandSponsorRoutes.marketplace,
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (wide) ...[
            _BrandTopIcon(
              icon: Icons.explore_outlined,
              tooltip: 'Play one complete project story',
              onTap: () => startBrandTour(context),
            ),
            const SizedBox(width: 10),
          ],
          TourTarget(
            id: 'brand:notifications',
            child: _BrandNotificationButton(
              onTap: () =>
                  Navigator.pushNamed(context, CoreRoutes.notifications),
            ),
          ),
          const SizedBox(width: 10),
          TourTarget(
            id: 'nav:${BrandSponsorRoutes.profile}',
            child: _BrandProfileButton(
              onTap: () => Navigator.pushNamed(
                context,
                BrandSponsorRoutes.profile,
              ),
            ),
          ),
          SizedBox(width: compact ? 8 : 10),
          ThemeToggleButton(size: compact ? 34 : 38),
          if (wide) ...[
            const SizedBox(width: 10),
            _BrandTopIcon(
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

class _BrandLockup extends StatelessWidget {
  final bool compact;

  const _BrandLockup({required this.compact});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: compact ? 78 : 166,
        maxWidth: compact ? 88 : 190,
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
                fontSize: compact ? 14.5 : 22,
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
            'Brand Workspace',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: colors.textSecondary,
              fontSize: compact ? 9.5 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandSearchPill extends StatelessWidget {
  final bool compact;
  final VoidCallback onTap;

  const _BrandSearchPill({
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: 'Search applications',
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
                  compact
                      ? 'Search...'
                      : 'Search applications and campaigns...',
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

class _BrandTopIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _BrandTopIcon({
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

class _BrandNotificationButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BrandNotificationButton({required this.onTap});

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

class _BrandProfileButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BrandProfileButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: 'Brand profile',
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.softSurface,
            border: Border.all(color: colors.border),
          ),
          child: Icon(
            Icons.business_center_outlined,
            color: colors.goldDark,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _BrandWorkspaceSidebar extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onRouteTap;

  const _BrandWorkspaceSidebar({
    required this.currentRoute,
    required this.onRouteTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final specialist = SpecialistScope.maybeOf(context);
    return Container(
      width: 276,
      margin: const EdgeInsets.fromLTRB(14, 14, 0, 14),
      child: GlassContainer(
        radius: 24,
        padding: const EdgeInsets.all(16),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            if (specialist != null) specialist,
          ]),
          builder: (context, _) {
            final profile = specialist?.cachedBrandProfile;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BRAND SPONSOR',
                  style: AppTextStyles.sectionHeaderStyle.copyWith(
                    color: colors.textPrimary,
                    fontSize: 18,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Campaign operations portal',
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _BrandIdentityCard(
                  profile: profile,
                  onTap: () => onRouteTap(BrandSponsorRoutes.profile),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    itemCount: brandSponsorMenuEntries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = brandSponsorMenuEntries[index];
                      final active =
                          _brandRouteActive(currentRoute, item.route);
                      return TourTarget(
                        id: 'nav:${item.route}',
                        child: InkWell(
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
                                  color: active
                                      ? colors.goldDark
                                      : colors.iconMuted,
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
                                      fontWeight: active
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? colors.goldMid
                                        : colors.iconMuted
                                            .withValues(alpha: 0.45),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BrandIdentityCard extends StatelessWidget {
  final BrandProfileDto? profile;
  final VoidCallback onTap;

  const _BrandIdentityCard({
    required this.profile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final name = profile?.name ?? 'Create brand profile';
    final category = profile?.category ?? 'Identity required';
    final status = profile?.trustStatus ?? 'Pending';
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: colors.softSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.goldMid.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.campaign_outlined,
                color: colors.goldDark,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$category · ${readableBrandStatus(status)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.smallMeta.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.iconMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandWorkspaceBottomNav extends StatelessWidget {
  final String currentRoute;
  final bool menuOpen;
  final ValueChanged<String> onRouteTap;
  final VoidCallback onMoreTap;

  const _BrandWorkspaceBottomNav({
    required this.currentRoute,
    required this.menuOpen,
    required this.onRouteTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return CineBottomNav(
      currentIndex: _currentIndex,
      destinations: _brandBottomDestinations,
      compactCenter: true,
      onTap: (index) {
        if (index == _brandBottomDestinations.length - 1) {
          onMoreTap();
          return;
        }
        onRouteTap(_brandBottomRoutes[index]);
      },
    );
  }

  int get _currentIndex {
    if (menuOpen) return _brandBottomDestinations.length - 1;
    final override = _brandBottomIndexOverrides[currentRoute];
    if (override != null) return override;
    final index = _brandBottomRoutes.indexOf(currentRoute);
    return index >= 0 ? index : _brandBottomDestinations.length - 1;
  }
}

bool _brandRouteActive(String currentRoute, String route) {
  if (route == BrandSponsorRoutes.home) return currentRoute == route;
  return currentRoute == route || currentRoute.startsWith('$route/');
}
