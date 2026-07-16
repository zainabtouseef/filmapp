import 'package:flutter/material.dart';

import '../../../core/core_ui/core_logout.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/layout/floating_portal_menu.dart';
import '../../../shared/widgets/app_header.dart' show ThemeToggleButton;
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/cinematic_backdrop.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/location_owner_demo_data.dart';
import '../routes/location_owner_routes.dart';
import 'location_owner_components.dart';

typedef LocationOwnerMenuEntry = ({
  String route,
  String screenId,
  String label,
  IconData icon,
});

const _locationBottomDestinations = [
  CineBottomNavDestination(label: 'Home', icon: Icons.home_outlined),
  CineBottomNavDestination(
      label: 'Properties', icon: Icons.location_city_outlined),
  CineBottomNavDestination(label: 'Requests', icon: Icons.inbox_outlined),
  CineBottomNavDestination(
      label: 'Calendar', icon: Icons.calendar_month_outlined),
  CineBottomNavDestination(
      label: 'Earnings', icon: Icons.account_balance_wallet_outlined),
];

const _locationMenuEntries = <LocationOwnerMenuEntry>[
  (
    route: LocationOwnerRoutes.home,
    screenId: 'LO-01',
    label: 'Owner Dashboard',
    icon: Icons.dashboard_outlined,
  ),
  (
    route: LocationOwnerRoutes.listing,
    screenId: 'LO-02',
    label: 'Location Listing',
    icon: Icons.add_location_alt_outlined,
  ),
  (
    route: LocationOwnerRoutes.calendar,
    screenId: 'LO-03',
    label: 'Availability Calendar',
    icon: Icons.calendar_month_outlined,
  ),
  (
    route: LocationOwnerRoutes.pricing,
    screenId: 'LO-04',
    label: 'Pricing & Deposit',
    icon: Icons.price_change_outlined,
  ),
  (
    route: LocationOwnerRoutes.rules,
    screenId: 'LO-05',
    label: 'Rules & Restrictions',
    icon: Icons.rule_folder_outlined,
  ),
  (
    route: LocationOwnerRoutes.requests,
    screenId: 'LO-06',
    label: 'Booking Requests',
    icon: Icons.move_to_inbox_outlined,
  ),
  (
    route: LocationOwnerRoutes.checkIn,
    screenId: 'LO-07',
    label: 'Check-In Inspection',
    icon: Icons.fact_check_outlined,
  ),
  (
    route: LocationOwnerRoutes.checkOut,
    screenId: 'LO-08',
    label: 'Check-Out Claim',
    icon: Icons.verified_user_outlined,
  ),
  (
    route: LocationOwnerRoutes.earnings,
    screenId: 'LO-09',
    label: 'Earnings & Deposits',
    icon: Icons.payments_outlined,
  ),
  (
    route: LocationOwnerRoutes.performance,
    screenId: 'LO-10',
    label: 'Property Performance',
    icon: Icons.analytics_outlined,
  ),
];

const _bottomIndexOverrides = {
  LocationOwnerRoutes.pricing: 1,
  LocationOwnerRoutes.rules: 1,
  LocationOwnerRoutes.performance: 1,
  LocationOwnerRoutes.checkIn: 2,
  LocationOwnerRoutes.checkOut: 2,
};

class LocationOwnerShell extends StatefulWidget {
  final String routeName;
  final String title;
  final String screenId;
  final Widget child;

  const LocationOwnerShell({
    super.key,
    required this.routeName,
    required this.title,
    required this.screenId,
    required this.child,
  });

  @override
  State<LocationOwnerShell> createState() => _LocationOwnerShellState();
}

class _LocationOwnerShellState extends State<LocationOwnerShell> {
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
    final horizontal = width >= AppBreakpoints.tablet ? 28.0 : 14.0;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: CinematicBackdrop()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontal, 10, horizontal, 0),
                  child: _LocationTopBar(
                    title: widget.title,
                    screenId: widget.screenId,
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
                  destinations: _locationBottomDestinations,
                  onTap: (index) {
                    final target = LocationOwnerRoutes.primaryNav[index];
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
              for (final item in _locationMenuEntries)
                FloatingPortalMenuItem(
                  route: item.route,
                  label: item.label,
                  icon: item.icon,
                ),
            ],
            statusTitle: 'Location Owner',
            statusSubtitle: 'Property portal operational',
            statusIcon: Icons.location_city_outlined,
            onClose: _closeMenu,
            onRouteTap: _selectMenuRoute,
          ),
        ],
      ),
    );
  }

  int _bottomIndex(String route) {
    final override = _bottomIndexOverrides[route];
    if (override != null) return override;
    final index = LocationOwnerRoutes.primaryNav.indexOf(route);
    return index == -1 ? 0 : index;
  }
}

class _LocationTopBar extends StatelessWidget {
  final String title;
  final String screenId;
  final VoidCallback onMenuTap;

  const _LocationTopBar({
    required this.title,
    required this.screenId,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final store = LocationOwnerDemoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return SizedBox(
          height: 60,
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
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _showPropertySwitcher(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              '$screenId - ${store.activeProperty.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.smallMeta.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(
                            Icons.expand_more_rounded,
                            color: colors.goldDark,
                            size: 18,
                          ),
                        ],
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
                onTap: () =>
                    Navigator.pushNamed(context, CoreRoutes.notifications),
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
      },
    );
  }

  void _showPropertySwitcher(BuildContext context) {
    final colors = context.appColors;
    final store = LocationOwnerDemoStore.instance;
    showLocationSheet(
      context,
      title: 'Active property',
      child: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final property in LocationOwnerDemoData.properties)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      store.setActiveProperty(property.id);
                      Navigator.pop(context);
                      locationSnack(context, '${property.name} selected');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: colors.inactiveChipGradient,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: property.id == store.activePropertyId
                              ? colors.goldMid
                              : colors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_city_outlined,
                            color: property.id == store.activePropertyId
                                ? colors.goldDark
                                : colors.iconMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  property.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.cardLabel.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${property.type} - ${property.publicAddress}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.smallMeta.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusChip(
                            label: property.id == store.activePropertyId
                                ? 'ACTIVE'
                                : property.rating.toStringAsFixed(1),
                            color: property.id == store.activePropertyId
                                ? colors.goldMid
                                : colors.infoBlue,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
