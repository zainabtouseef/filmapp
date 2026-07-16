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
import '../data/media_equipment_demo_data.dart';
import '../routes/media_equipment_routes.dart';
import 'media_equipment_components.dart';

typedef MediaEquipmentMenuEntry = ({
  String route,
  String screenId,
  String label,
  IconData icon,
});

const _mediaBottomDestinations = [
  CineBottomNavDestination(label: 'Home', icon: Icons.home_outlined),
  CineBottomNavDestination(label: 'Inventory', icon: Icons.videocam_outlined),
  CineBottomNavDestination(label: 'Requests', icon: Icons.inbox_outlined),
  CineBottomNavDestination(
      label: 'Schedule', icon: Icons.calendar_month_outlined),
  CineBottomNavDestination(
      label: 'Earnings', icon: Icons.account_balance_wallet_outlined),
];

const _mediaMenuEntries = <MediaEquipmentMenuEntry>[
  (
    route: MediaEquipmentRoutes.home,
    screenId: 'ME-01',
    label: 'Provider Dashboard',
    icon: Icons.dashboard_outlined,
  ),
  (
    route: MediaEquipmentRoutes.profile,
    screenId: 'ME-02',
    label: 'Provider Profile',
    icon: Icons.badge_outlined,
  ),
  (
    route: MediaEquipmentRoutes.inventory,
    screenId: 'ME-03',
    label: 'Inventory Manager',
    icon: Icons.videocam_outlined,
  ),
  (
    route: MediaEquipmentRoutes.packages,
    screenId: 'ME-04',
    label: 'Package Builder',
    icon: Icons.inventory_2_outlined,
  ),
  (
    route: MediaEquipmentRoutes.availability,
    screenId: 'ME-05',
    label: 'Availability Calendar',
    icon: Icons.calendar_month_outlined,
  ),
  (
    route: MediaEquipmentRoutes.terms,
    screenId: 'ME-06',
    label: 'Rate & Terms',
    icon: Icons.rule_folder_outlined,
  ),
  (
    route: MediaEquipmentRoutes.requests,
    screenId: 'ME-07',
    label: 'Requests & Negotiation',
    icon: Icons.move_to_inbox_outlined,
  ),
  (
    route: MediaEquipmentRoutes.handover,
    screenId: 'ME-08',
    label: 'Handover Checklist',
    icon: Icons.qr_code_scanner_rounded,
  ),
  (
    route: MediaEquipmentRoutes.returns,
    screenId: 'ME-09',
    label: 'Return Checklist',
    icon: Icons.assignment_return_outlined,
  ),
  (
    route: MediaEquipmentRoutes.earnings,
    screenId: 'ME-10',
    label: 'Earnings & Ratings',
    icon: Icons.payments_outlined,
  ),
];

const _bottomIndexOverrides = {
  MediaEquipmentRoutes.profile: 1,
  MediaEquipmentRoutes.packages: 1,
  MediaEquipmentRoutes.terms: 1,
  MediaEquipmentRoutes.handover: 2,
  MediaEquipmentRoutes.returns: 2,
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
                  child: _MediaTopBar(
                    title: widget.title,
                    screenId: widget.screenId,
                    onMenuTap: _openMenu,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        EdgeInsets.fromLTRB(horizontal, 14, horizontal, 18),
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
                  destinations: _mediaBottomDestinations,
                  onTap: (index) {
                    final target = MediaEquipmentRoutes.primaryNav[index];
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
              for (final item in _mediaMenuEntries)
                FloatingPortalMenuItem(
                  route: item.route,
                  label: item.label,
                  icon: item.icon,
                ),
            ],
            statusTitle: 'Media Equipment',
            statusSubtitle: 'Provider portal operational',
            statusIcon: Icons.videocam_outlined,
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
    final index = MediaEquipmentRoutes.primaryNav.indexOf(route);
    return index == -1 ? 0 : index;
  }
}

class _MediaTopBar extends StatelessWidget {
  final String title;
  final String screenId;
  final VoidCallback onMenuTap;

  const _MediaTopBar({
    required this.title,
    required this.screenId,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final store = MediaEquipmentDemoStore.instance;
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
                      onTap: () => _showInventorySwitcher(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              '$screenId - ${store.activeItem.modelName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.smallMeta.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(Icons.expand_more_rounded,
                              color: colors.goldDark, size: 18),
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

  void _showInventorySwitcher(BuildContext context) {
    final colors = context.appColors;
    final store = MediaEquipmentDemoStore.instance;
    showMediaSheet(
      context,
      title: 'Inventory context',
      child: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in store.inventory)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      store.setActiveItem(item.id);
                      Navigator.pop(context);
                      mediaSnack(context, '${item.modelName} selected');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: colors.inactiveChipGradient,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: item.id == store.activeItemId
                              ? colors.goldMid
                              : colors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.videocam_outlined,
                            color: item.id == store.activeItemId
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
                                  item.modelName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.cardLabel.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${item.category} - ${item.serial}',
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
                            label: item.available ? 'READY' : 'BOOKED',
                            color: item.available
                                ? colors.success
                                : colors.goldMid,
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
