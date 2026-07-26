import 'package:flutter/material.dart';

import '../../../core/core_ui/core_back_navigation.dart';
import '../../../core/core_ui/core_logout.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
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
import '../routes/location_owner_routes.dart';
import 'location_owner_components.dart';
import 'location_owner_live.dart';

typedef LocationOwnerMenuEntry = ({
  String route,
  String screenId,
  String label,
  IconData icon,
});

const _locationBottomDestinations = [
  CineBottomNavDestination(label: 'Home', icon: Icons.home_outlined),
  CineBottomNavDestination(label: 'Requests', icon: Icons.inbox_outlined),
  CineBottomNavDestination(
    label: 'Calendar',
    icon: Icons.calendar_month_outlined,
  ),
  CineBottomNavDestination(
    label: 'Earnings',
    icon: Icons.account_balance_wallet_outlined,
  ),
  CineBottomNavDestination(label: 'More', icon: Icons.menu_rounded),
];

const _locationBottomRoutes = [
  LocationOwnerRoutes.home,
  LocationOwnerRoutes.requests,
  LocationOwnerRoutes.calendar,
  LocationOwnerRoutes.earnings,
];

const _locationMenuEntries = <LocationOwnerMenuEntry>[
  (
    route: LocationOwnerRoutes.home,
    screenId: 'LO-01',
    label: 'Overview',
    icon: Icons.dashboard_outlined,
  ),
  (
    route: LocationOwnerRoutes.listing,
    screenId: 'LO-02',
    label: 'Properties',
    icon: Icons.location_city_outlined,
  ),
  (
    route: LocationOwnerRoutes.calendar,
    screenId: 'LO-03',
    label: 'Calendar',
    icon: Icons.calendar_month_outlined,
  ),
  (
    route: LocationOwnerRoutes.pricing,
    screenId: 'LO-04',
    label: 'Rates & Deposits',
    icon: Icons.price_change_outlined,
  ),
  (
    route: LocationOwnerRoutes.rules,
    screenId: 'LO-05',
    label: 'Property Rules',
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
    label: 'Check-In',
    icon: Icons.fact_check_outlined,
  ),
  (
    route: LocationOwnerRoutes.checkOut,
    screenId: 'LO-08',
    label: 'Check-Out & Claims',
    icon: Icons.verified_user_outlined,
  ),
  (
    route: LocationOwnerRoutes.earnings,
    screenId: 'LO-09',
    label: 'Earnings',
    icon: Icons.payments_outlined,
  ),
  (
    route: LocationOwnerRoutes.performance,
    screenId: 'LO-10',
    label: 'Property Insights',
    icon: Icons.analytics_outlined,
  ),
  (
    route: LocationOwnerRoutes.profile,
    screenId: 'LO-11',
    label: 'Owner Profile',
    icon: Icons.badge_outlined,
  ),
  (
    route: LocationOwnerRoutes.portfolio,
    screenId: 'LO-12',
    label: 'Portfolio',
    icon: Icons.photo_library_outlined,
  ),
  (
    route: LocationOwnerRoutes.opportunities,
    screenId: 'LO-13',
    label: 'Opportunities',
    icon: Icons.explore_outlined,
  ),
];

const _locationBottomIndexOverrides = {
  LocationOwnerRoutes.listing: 4,
  LocationOwnerRoutes.pricing: 4,
  LocationOwnerRoutes.rules: 4,
  LocationOwnerRoutes.checkIn: 4,
  LocationOwnerRoutes.checkOut: 4,
  LocationOwnerRoutes.performance: 4,
  LocationOwnerRoutes.profile: 4,
  LocationOwnerRoutes.portfolio: 4,
  LocationOwnerRoutes.opportunities: 4,
};

class LocationOwnerShell extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return _LocationWorkspaceScaffold(
      routeName: routeName,
      title: title,
      child: child,
    );
  }
}

class _LocationWorkspaceScaffold extends StatefulWidget {
  final String routeName;
  final String title;
  final Widget child;

  const _LocationWorkspaceScaffold({
    required this.routeName,
    required this.title,
    required this.child,
  });

  @override
  State<_LocationWorkspaceScaffold> createState() =>
      _LocationWorkspaceScaffoldState();
}

class _LocationWorkspaceScaffoldState
    extends State<_LocationWorkspaceScaffold> {
  OperationsController? _operations;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final operations = OperationsScope.maybeOf(context);
    if (operations == null || identical(operations, _operations)) return;
    _operations = operations;
    _loadProperties(operations);
  }

  Future<void> _loadProperties(OperationsController operations) async {
    try {
      final properties = await operations.locationProperties();
      if (properties.isEmpty) return;
      final store = LocationOwnerSelectionStore.instance;
      final selected = store.activePropertyId;
      if (selected == null ||
          !properties.any((property) => property.publicId == selected)) {
        store.setActiveProperty(properties.first.publicId);
      }
    } catch (_) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScreenScaffold(
      title: widget.title,
      currentRoute: widget.routeName,
      showHeading: false,
      topBarBuilder: (context, wide, onMenuTap) => _LocationWorkspaceTopBar(
        wide: wide,
        onMenuTap: onMenuTap,
      ),
      sideNavBuilder: (context, currentRoute, onRouteTap) =>
          _LocationWorkspaceSidebar(
        currentRoute: currentRoute,
        onRouteTap: onRouteTap,
      ),
      bottomNavBuilder:
          (context, currentRoute, menuOpen, onRouteTap, onMoreTap) =>
              AdminBottomNavSlot(
        child: _LocationWorkspaceBottomNav(
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
          for (final item in _locationMenuEntries)
            FloatingPortalMenuItem(
              route: item.route,
              label: item.label,
              icon: item.icon,
            ),
        ],
        statusTitle: 'Location Workspace',
        statusSubtitle: 'Properties, bookings, inspections and earnings',
        statusIcon: Icons.location_city_outlined,
        onClose: onClose,
        onRouteTap: onRouteTap,
        isRouteActive: _locationRouteActive,
      ),
      onRouteSelected: (context, route) => Navigator.pushNamed(context, route),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LocationRouteHeading(title: widget.title, route: widget.routeName),
          const SizedBox(height: 14),
          widget.child,
        ],
      ),
    );
  }
}

class _LocationRouteHeading extends StatelessWidget {
  final String title;
  final String route;

  const _LocationRouteHeading({required this.title, required this.route});

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
                  fontSize: 30,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        StatusChip(
          label: 'Location Owner',
          icon: Icons.verified_outlined,
          color: colors.goldMid,
        ),
      ],
    );
  }

  String get _eyebrow {
    return switch (route) {
      LocationOwnerRoutes.home => 'Location workspace · overview',
      LocationOwnerRoutes.listing => 'Property profile · discovery listing',
      LocationOwnerRoutes.calendar => 'Availability · booking conflicts',
      LocationOwnerRoutes.pricing => 'Rates · deposits · conditions',
      LocationOwnerRoutes.rules => 'Access · restrictions · production terms',
      LocationOwnerRoutes.requests => 'Requests · offers · negotiation',
      LocationOwnerRoutes.checkIn => 'Handover · condition evidence',
      LocationOwnerRoutes.checkOut => 'Return · damage claims · evidence',
      LocationOwnerRoutes.earnings => 'Payments · receipts · payout status',
      LocationOwnerRoutes.performance => 'Portfolio · booking health',
      LocationOwnerRoutes.profile => 'Public identity · bio · social links',
      LocationOwnerRoutes.portfolio => 'Photos · videos · edit anytime',
      LocationOwnerRoutes.opportunities => 'Open requests · applications',
      _ => 'Location owner workspace',
    };
  }
}

class _LocationWorkspaceTopBar extends StatelessWidget {
  final bool wide;
  final VoidCallback onMenuTap;

  const _LocationWorkspaceTopBar({
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
          _LocationTopIcon(
            icon: canGoBack ? Icons.arrow_back_rounded : Icons.menu_rounded,
            tooltip: canGoBack ? 'Back' : 'Menu',
            onTap: canGoBack ? () => navigateCoreBack(context) : onMenuTap,
          ),
          const SizedBox(width: 10),
          _LocationBrandLockup(compact: compact),
          SizedBox(width: compact ? 8 : 16),
          Expanded(
            child: _LocationSearchPill(
              compact: compact,
              onTap: () => Navigator.pushNamed(
                context,
                LocationOwnerRoutes.requests,
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (wide) ...[
            _LocationNotificationButton(
              onTap: () =>
                  Navigator.pushNamed(context, CoreRoutes.notifications),
            ),
            const SizedBox(width: 10),
          ],
          _LocationPropertyButton(
            onTap: () =>
                Navigator.pushNamed(context, LocationOwnerRoutes.listing),
          ),
          SizedBox(width: compact ? 8 : 10),
          ThemeToggleButton(size: compact ? 34 : 38),
          if (wide) ...[
            const SizedBox(width: 10),
            _LocationTopIcon(
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

class _LocationBrandLockup extends StatelessWidget {
  final bool compact;

  const _LocationBrandLockup({required this.compact});

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
            'Location Workspace',
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

class _LocationSearchPill extends StatelessWidget {
  final bool compact;
  final VoidCallback onTap;

  const _LocationSearchPill({
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: 'Search booking requests',
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
                  compact ? 'Search...' : 'Search requests and bookings...',
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

class _LocationTopIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _LocationTopIcon({
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

class _LocationNotificationButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LocationNotificationButton({required this.onTap});

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

class _LocationPropertyButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LocationPropertyButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: 'Properties',
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
            Icons.location_city_outlined,
            color: colors.goldDark,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _LocationWorkspaceSidebar extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onRouteTap;

  const _LocationWorkspaceSidebar({
    required this.currentRoute,
    required this.onRouteTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final operations = OperationsScope.maybeOf(context);
    final store = LocationOwnerSelectionStore.instance;
    return Container(
      width: 276,
      margin: const EdgeInsets.fromLTRB(14, 14, 0, 14),
      child: GlassContainer(
        radius: 24,
        padding: const EdgeInsets.all(16),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            store,
            if (operations != null) operations,
          ]),
          builder: (context, _) {
            final properties = operations?.cachedLocationProperties;
            final active = _activeLiveProperty(properties, store);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOCATION OWNER',
                  style: AppTextStyles.sectionHeaderStyle.copyWith(
                    color: colors.textPrimary,
                    fontSize: 18,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Property operations portal',
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _PropertySwitcherCard(
                  property: active,
                  onTap: () => _showPropertySwitcher(
                    context,
                    properties: properties,
                    store: store,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    itemCount: _locationMenuEntries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = _locationMenuEntries[index];
                      final selected =
                          _locationRouteActive(currentRoute, item.route);
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
                            gradient: selected
                                ? colors.activeChipGradient
                                : colors.inactiveChipGradient,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected ? colors.goldMid : colors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                color: selected
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
                                    color: selected
                                        ? colors.textPrimary
                                        : colors.textSecondary,
                                    fontWeight: selected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: selected
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

  void _showPropertySwitcher(
    BuildContext context, {
    required List<LocationPropertyDto>? properties,
    required LocationOwnerSelectionStore store,
  }) {
    showLocationSheet(
      context,
      title: 'Active property',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (properties != null && properties.isNotEmpty)
            for (final property in properties)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PropertySheetRow(
                  title: property.name,
                  subtitle: [
                    property.propertyType.replaceAll('_', ' '),
                    property.areaName,
                  ].where((value) => value.isNotEmpty).join(' · '),
                  status: property.status,
                  selected: property.publicId == store.activePropertyId,
                  onTap: () {
                    store.setActiveProperty(property.publicId);
                    Navigator.pop(context);
                  },
                ),
              )
          else
            CoreEmptyState(
              icon: Icons.add_location_alt_outlined,
              title: 'No properties yet',
              message: 'Create the first property profile for this account.',
              actionLabel: 'Create property',
              onAction: () {
                Navigator.pop(context);
                onRouteTap(LocationOwnerRoutes.listing);
              },
            ),
        ],
      ),
    );
  }
}

class _PropertySwitcherCard extends StatelessWidget {
  final LocationPropertyDto? property;
  final VoidCallback onTap;

  const _PropertySwitcherCard({
    required this.property,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final title = property?.name ?? 'Create property';
    final subtitle = property == null
        ? 'No backend property selected'
        : [
            property!.propertyType.replaceAll('_', ' '),
            property!.status,
          ].join(' · ');
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          gradient: colors.inactiveChipGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.apartment_outlined,
              color: colors.goldDark,
              size: 20,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.smallMeta.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.expand_more_rounded, color: colors.iconMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _PropertySheetRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final bool selected;
  final VoidCallback onTap;

  const _PropertySheetRow({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: colors.inactiveChipGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? colors.goldMid : colors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_city_outlined,
              color: selected ? colors.goldDark : colors.iconMuted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
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
              label: selected ? 'ACTIVE' : status.toUpperCase(),
              color: selected ? colors.goldMid : colors.infoBlue,
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationWorkspaceBottomNav extends StatelessWidget {
  final String currentRoute;
  final bool menuOpen;
  final ValueChanged<String> onRouteTap;
  final VoidCallback onMoreTap;

  const _LocationWorkspaceBottomNav({
    required this.currentRoute,
    required this.menuOpen,
    required this.onRouteTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return CineBottomNav(
      currentIndex: _currentIndex,
      destinations: _locationBottomDestinations,
      compactCenter: true,
      onTap: (index) {
        if (index == _locationBottomDestinations.length - 1) {
          onMoreTap();
          return;
        }
        onRouteTap(_locationBottomRoutes[index]);
      },
    );
  }

  int get _currentIndex {
    if (menuOpen) return _locationBottomDestinations.length - 1;
    final override = _locationBottomIndexOverrides[currentRoute];
    if (override != null) return override;
    final index = _locationBottomRoutes.indexOf(currentRoute);
    return index >= 0 ? index : _locationBottomDestinations.length - 1;
  }
}

LocationPropertyDto? _activeLiveProperty(
  List<LocationPropertyDto>? properties,
  LocationOwnerSelectionStore store,
) {
  if (properties == null || properties.isEmpty) return null;
  final selected = store.activePropertyId;
  for (final property in properties) {
    if (property.publicId == selected) return property;
  }
  return properties.first;
}

bool _locationRouteActive(String currentRoute, String route) {
  if (route == LocationOwnerRoutes.home) return currentRoute == route;
  return currentRoute == route || currentRoute.startsWith('$route/');
}
