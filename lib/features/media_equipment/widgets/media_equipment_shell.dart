import 'package:flutter/material.dart';

import '../../../core/core_ui/core_back_navigation.dart';
import '../../../core/core_ui/core_logout.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/operations/operations_controller.dart';
import '../../../core/operations/operations_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/layout/admin_bottom_nav.dart';
import '../../../shared/layout/admin_screen_scaffold.dart';
import '../../../shared/layout/admin_top_bar.dart';
import '../../../shared/layout/floating_portal_menu.dart';
import '../../../shared/widgets/app_header.dart' show ThemeToggleButton;
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../routes/media_equipment_routes.dart';

typedef MediaEquipmentMenuEntry = ({
  String route,
  String screenId,
  String label,
  IconData icon,
});

const mediaEquipmentMenuEntries = <MediaEquipmentMenuEntry>[
  (
    route: MediaEquipmentRoutes.home,
    screenId: 'ME-01',
    label: 'Overview',
    icon: Icons.dashboard_outlined,
  ),
  (
    route: MediaEquipmentRoutes.profile,
    screenId: 'ME-02',
    label: 'Provider Profile',
    icon: Icons.storefront_outlined,
  ),
  (
    route: MediaEquipmentRoutes.inventory,
    screenId: 'ME-03',
    label: 'Inventory',
    icon: Icons.videocam_outlined,
  ),
  (
    route: MediaEquipmentRoutes.packages,
    screenId: 'ME-04',
    label: 'Rental Packages',
    icon: Icons.inventory_2_outlined,
  ),
  (
    route: MediaEquipmentRoutes.availability,
    screenId: 'ME-05',
    label: 'Availability',
    icon: Icons.calendar_month_outlined,
  ),
  (
    route: MediaEquipmentRoutes.terms,
    screenId: 'ME-06',
    label: 'Rates & Terms',
    icon: Icons.rule_folder_outlined,
  ),
  (
    route: MediaEquipmentRoutes.requests,
    screenId: 'ME-07',
    label: 'Booking Requests',
    icon: Icons.move_to_inbox_outlined,
  ),
  (
    route: MediaEquipmentRoutes.handover,
    screenId: 'ME-08',
    label: 'Handover',
    icon: Icons.qr_code_scanner_rounded,
  ),
  (
    route: MediaEquipmentRoutes.returns,
    screenId: 'ME-09',
    label: 'Returns & Claims',
    icon: Icons.assignment_return_outlined,
  ),
  (
    route: MediaEquipmentRoutes.earnings,
    screenId: 'ME-10',
    label: 'Earnings & Ratings',
    icon: Icons.account_balance_wallet_outlined,
  ),
];

const _bottomDestinations = [
  CineBottomNavDestination(label: 'Home', icon: Icons.home_outlined),
  CineBottomNavDestination(label: 'Inventory', icon: Icons.videocam_outlined),
  CineBottomNavDestination(label: 'Requests', icon: Icons.inbox_outlined),
  CineBottomNavDestination(
    label: 'Calendar',
    icon: Icons.calendar_month_outlined,
  ),
  CineBottomNavDestination(label: 'More', icon: Icons.menu_rounded),
];

const _bottomRoutes = [
  MediaEquipmentRoutes.home,
  MediaEquipmentRoutes.inventory,
  MediaEquipmentRoutes.requests,
  MediaEquipmentRoutes.availability,
];

const _bottomIndexOverrides = {
  MediaEquipmentRoutes.profile: 4,
  MediaEquipmentRoutes.packages: 4,
  MediaEquipmentRoutes.terms: 4,
  MediaEquipmentRoutes.handover: 4,
  MediaEquipmentRoutes.returns: 4,
  MediaEquipmentRoutes.earnings: 4,
};

class MediaEquipmentShell extends StatefulWidget {
  final String routeName;
  final String title;
  final String screenId;
  final Widget child;

  const MediaEquipmentShell({
    super.key,
    required this.routeName,
    required this.title,
    required this.screenId,
    required this.child,
  });

  @override
  State<MediaEquipmentShell> createState() => _MediaEquipmentShellState();
}

class _MediaEquipmentShellState extends State<MediaEquipmentShell> {
  OperationsController? _operations;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final operations = OperationsScope.maybeOf(context);
    if (operations == null || identical(operations, _operations)) return;
    _operations = operations;
    _loadWorkspace(operations);
  }

  Future<void> _loadWorkspace(OperationsController operations) async {
    try {
      await Future.wait([
        operations.equipmentProfile(force: true),
        operations.equipmentItems(force: true),
        operations.equipmentPackages(force: true),
        operations.equipmentTerms(force: true),
        operations.equipmentInspections(force: true),
      ]);
    } catch (_) {
      // Individual screens retain their preview state while offline.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScreenScaffold(
      title: widget.title,
      currentRoute: widget.routeName,
      showHeading: false,
      topBarBuilder: (context, wide, onMenuTap) => _EquipmentTopBar(
        wide: wide,
        onMenuTap: onMenuTap,
      ),
      sideNavBuilder: (context, currentRoute, onRouteTap) => _EquipmentSidebar(
        currentRoute: currentRoute,
        onRouteTap: onRouteTap,
      ),
      bottomNavBuilder:
          (context, currentRoute, menuOpen, onRouteTap, onMoreTap) =>
              AdminBottomNavSlot(
        child: _EquipmentBottomNav(
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
          for (final item in mediaEquipmentMenuEntries)
            FloatingPortalMenuItem(
              route: item.route,
              label: item.label,
              icon: item.icon,
            ),
        ],
        statusTitle: 'Equipment Workspace',
        statusSubtitle: 'Inventory, bookings, inspections and finance',
        statusIcon: Icons.videocam_outlined,
        onClose: onClose,
        onRouteTap: onRouteTap,
        isRouteActive: _equipmentRouteActive,
      ),
      onRouteSelected: (context, route) => Navigator.pushNamed(context, route),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EquipmentRouteHeading(
            title: widget.title,
            route: widget.routeName,
          ),
          const SizedBox(height: 14),
          widget.child,
        ],
      ),
    );
  }
}

class _EquipmentRouteHeading extends StatelessWidget {
  final String title;
  final String route;

  const _EquipmentRouteHeading({
    required this.title,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final heading = Column(
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
          label: 'Equipment Provider',
          icon: Icons.verified_outlined,
          color: colors.goldMid,
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [heading, const SizedBox(height: 10), badge],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: heading),
            const SizedBox(width: 12),
            badge,
          ],
        );
      },
    );
  }

  String get _eyebrow {
    return switch (route) {
      MediaEquipmentRoutes.home => 'Equipment workspace · operations',
      MediaEquipmentRoutes.profile => 'Business identity · marketplace trust',
      MediaEquipmentRoutes.inventory => 'Assets · condition · live pricing',
      MediaEquipmentRoutes.packages => 'Bundles · operators · publishing',
      MediaEquipmentRoutes.availability => 'Fleet schedule · holds · service',
      MediaEquipmentRoutes.terms => 'Rates · deposits · rental policy',
      MediaEquipmentRoutes.requests => 'Requests · negotiation · acceptance',
      MediaEquipmentRoutes.handover => 'Serials · accessories · signatures',
      MediaEquipmentRoutes.returns => 'Condition · evidence · damage claims',
      MediaEquipmentRoutes.earnings => 'Payouts · ledger · service quality',
      _ => 'Media equipment workspace',
    };
  }
}

class _EquipmentTopBar extends StatelessWidget {
  final bool wide;
  final VoidCallback onMenuTap;

  const _EquipmentTopBar({
    required this.wide,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final compact = !wide;
    final canGoBack = Navigator.canPop(context);
    return AdminTopBarFrame(
      compact: compact,
      child: Row(
        children: [
          _TopIcon(
            icon: canGoBack ? Icons.arrow_back_rounded : Icons.menu_rounded,
            tooltip: canGoBack ? 'Back' : 'Menu',
            onTap: canGoBack ? () => navigateCoreBack(context) : onMenuTap,
          ),
          const SizedBox(width: 10),
          _EquipmentLockup(compact: compact),
          SizedBox(width: compact ? 8 : 16),
          if (wide)
            Expanded(
              child: _EquipmentSearch(
                onTap: () => Navigator.pushNamed(
                  context,
                  MediaEquipmentRoutes.inventory,
                ),
              ),
            )
          else
            const Spacer(),
          if (wide) ...[
            const SizedBox(width: 10),
            _TopIcon(
              icon: Icons.notifications_none_rounded,
              tooltip: 'Notifications',
              onTap: () => Navigator.pushNamed(
                context,
                CoreRoutes.notifications,
              ),
            ),
          ],
          SizedBox(width: compact ? 8 : 10),
          ThemeToggleButton(size: compact ? 34 : 38),
          SizedBox(width: compact ? 8 : 10),
          _TopIcon(
            icon: Icons.storefront_outlined,
            tooltip: 'Provider profile',
            onTap: () => Navigator.pushNamed(
              context,
              MediaEquipmentRoutes.profile,
            ),
          ),
          if (wide) ...[
            const SizedBox(width: 10),
            _TopIcon(
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

class _EquipmentLockup extends StatelessWidget {
  final bool compact;

  const _EquipmentLockup({required this.compact});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: compact ? 88 : 166,
        maxWidth: compact ? 108 : 190,
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
                fontSize: compact ? 16 : 22,
                fontWeight: FontWeight.w800,
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
            compact ? 'Equipment' : 'Equipment Workspace',
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

class _EquipmentSearch extends StatelessWidget {
  final VoidCallback onTap;

  const _EquipmentSearch({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: 'Search inventory',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            gradient: colors.searchGradient,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: colors.icon, size: 21),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Search inventory, packages and bookings...',
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
    );
  }
}

class _TopIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _TopIcon({
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

class _EquipmentSidebar extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onRouteTap;

  const _EquipmentSidebar({
    required this.currentRoute,
    required this.onRouteTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final operations = OperationsScope.maybeOf(context);
    return Container(
      width: 276,
      margin: const EdgeInsets.fromLTRB(14, 14, 0, 14),
      child: GlassContainer(
        radius: 24,
        padding: const EdgeInsets.all(16),
        child: AnimatedBuilder(
          animation: operations ?? Listenable.merge(const []),
          builder: (context, _) {
            final profile = operations?.cachedEquipmentProfile;
            final items = operations?.cachedEquipmentItems;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MEDIA / EQUIPMENT',
                  style: AppTextStyles.sectionHeaderStyle.copyWith(
                    color: colors.textPrimary,
                    fontSize: 18,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rental operations portal',
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _ProviderIdentity(
                  profile: profile,
                  inventoryCount: items?.length ?? 0,
                  onTap: () => onRouteTap(MediaEquipmentRoutes.profile),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    itemCount: mediaEquipmentMenuEntries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = mediaEquipmentMenuEntries[index];
                      final active =
                          _equipmentRouteActive(currentRoute, item.route);
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
                                color:
                                    active ? colors.goldDark : colors.iconMuted,
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

class _ProviderIdentity extends StatelessWidget {
  final EquipmentProfileDto? profile;
  final int inventoryCount;
  final VoidCallback onTap;

  const _ProviderIdentity({
    required this.profile,
    required this.inventoryCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
                color: colors.infoBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.videocam_outlined,
                color: colors.infoBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.name ?? 'Create provider profile',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$inventoryCount assets · ${_status(profile)}',
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

  String _status(EquipmentProfileDto? value) {
    if (value == null) return 'setup required';
    return value.verificationStatus.replaceAll('_', ' ');
  }
}

class _EquipmentBottomNav extends StatelessWidget {
  final String currentRoute;
  final bool menuOpen;
  final ValueChanged<String> onRouteTap;
  final VoidCallback onMoreTap;

  const _EquipmentBottomNav({
    required this.currentRoute,
    required this.menuOpen,
    required this.onRouteTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return CineBottomNav(
      currentIndex: _currentIndex,
      destinations: _bottomDestinations,
      compactCenter: true,
      onTap: (index) {
        if (index == _bottomDestinations.length - 1) {
          onMoreTap();
          return;
        }
        onRouteTap(_bottomRoutes[index]);
      },
    );
  }

  int get _currentIndex {
    if (menuOpen) return _bottomDestinations.length - 1;
    final override = _bottomIndexOverrides[currentRoute];
    if (override != null) return override;
    final index = _bottomRoutes.indexOf(currentRoute);
    return index >= 0 ? index : _bottomDestinations.length - 1;
  }
}

bool _equipmentRouteActive(String currentRoute, String route) {
  if (route == MediaEquipmentRoutes.home) return currentRoute == route;
  return currentRoute == route || currentRoute.startsWith('$route/');
}
