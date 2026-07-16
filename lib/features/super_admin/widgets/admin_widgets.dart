import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/core_ui/core_back_navigation.dart';
import '../../../core/core_ui/core_logout.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart' as shared_metric;
import '../../../shared/layout/admin_bottom_nav.dart';
import '../../../shared/layout/admin_screen_scaffold.dart';
import '../../../shared/layout/admin_section_header.dart' as shared_layout;
import '../../../shared/layout/admin_top_bar.dart';
import '../../../shared/sections/admin_filter_bar.dart' as shared_filters;
import '../../../shared/sections/admin_quick_actions_section.dart'
    as shared_sections;
import '../../../shared/widgets/premium_data_table.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/app_header.dart' show ThemeToggleButton;
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/glass_card.dart';
import '../mock_data/admin_mock_data.dart';
import '../models/admin_models.dart';
import '../routes/super_admin_routes.dart';

class AdminShell extends StatefulWidget {
  final String currentRoute;
  final String title;
  final String subtitle;
  final Widget child;

  const AdminShell({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  @override
  Widget build(BuildContext context) {
    return AdminScreenScaffold(
      title: widget.title,
      currentRoute: widget.currentRoute,
      topBarBuilder: (context, wide, onMenuTap) => AdminTopBar(
        title: widget.title,
        onNavTap: wide ? null : onMenuTap,
      ),
      sideNavBuilder: (context, currentRoute, onRouteTap) => AdminSidebar(
        currentRoute: currentRoute,
        onRouteTap: onRouteTap,
      ),
      bottomNavBuilder:
          (context, currentRoute, menuOpen, onRouteTap, onMoreTap) =>
              AdminBottomNavSlot(
        child: AdminBottomNav(
          currentRoute: currentRoute,
          menuOpen: menuOpen,
          onRouteTap: onRouteTap,
          onMoreTap: onMoreTap,
        ),
      ),
      floatingMenuBuilder: (context, open, currentRoute, onClose, onRouteTap) =>
          AdminFloatingMenuOverlay(
        open: open,
        currentRoute: currentRoute,
        onClose: onClose,
        onRouteTap: onRouteTap,
      ),
      onRouteSelected: _go,
      child: widget.child,
    );
  }

  void _go(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }
}

class AdminSidebar extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onRouteTap;

  const AdminSidebar({
    super.key,
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
            const _AdminBrand(),
            const SizedBox(height: 18),
            AdminStatusBadge(
              label: 'Super Admin Control Room',
              icon: Icons.security_rounded,
              tone: AdminDecisionTone.warning,
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView.separated(
                itemCount: AdminMockData.navItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = AdminMockData.navItems[index];
                  final active = _isRouteActive(currentRoute, item.route);
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
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.label.copyWith(
                                color: active
                                    ? colors.textPrimary
                                    : colors.textSecondary,
                                fontWeight:
                                    active ? FontWeight.w900 : FontWeight.w700,
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
            const SizedBox(height: 12),
            AdminActionButton(
              icon: Icons.logout_rounded,
              label: 'Logout',
              secondary: true,
              onTap: () => logoutToLogin(context),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminTopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onNavTap;

  const AdminTopBar({
    super.key,
    required this.title,
    this.onNavTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 620;
    return AdminTopBarFrame(
      compact: compact,
      child: Row(
        children: [
          AdminIconButton(
            icon: onNavTap == null
                ? Icons.arrow_back_rounded
                : Icons.menu_rounded,
            tooltip: onNavTap == null ? 'Back' : 'Menu',
            onTap: onNavTap ?? () => navigateCoreBack(context),
          ),
          SizedBox(width: compact ? 8 : 12),
          if (!compact) ...[
            const _AdminBrand(compact: true),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: AdminCommandButton(
              label: compact
                  ? 'Search admin...'
                  : 'Search bookings, users, contracts, payments...',
              onTap: () => showAdminCommandSheet(context),
            ),
          ),
          SizedBox(width: compact ? 8 : 12),
          ThemeToggleButton(size: compact ? 34 : 38),
          SizedBox(width: compact ? 8 : 10),
          AdminIconButton(
            icon: Icons.logout_rounded,
            tooltip: 'Logout',
            onTap: () => logoutToLogin(context),
          ),
          if (!compact) ...[
            const SizedBox(width: 10),
            AdminIconButton(
              icon: Icons.notifications_none_rounded,
              tooltip: 'Notifications',
              onTap: () =>
                  Navigator.pushNamed(context, CoreRoutes.notifications),
            ),
            const SizedBox(width: 10),
          ],
          if (width >= 720) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AdminMockData.adminName,
                  style: AppTextStyles.label.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const AdminStatusBadge(
                  label: 'Super Admin',
                  tone: AdminDecisionTone.warning,
                ),
              ],
            ),
            const SizedBox(width: 10),
          ],
          if (!compact) ...[
            AdminIconButton(
              icon: Icons.account_circle_outlined,
              tooltip: 'Profile menu',
              onTap: () => showCoreSnack(context, 'Profile menu simulated'),
            ),
          ],
        ],
      ),
    );
  }
}

class AdminBottomNav extends StatelessWidget {
  final String currentRoute;
  final bool menuOpen;
  final ValueChanged<String> onRouteTap;
  final VoidCallback onMoreTap;

  const AdminBottomNav({
    super.key,
    required this.currentRoute,
    required this.menuOpen,
    required this.onRouteTap,
    required this.onMoreTap,
  });

  static const _destinations = [
    CineBottomNavDestination(
      label: 'Home',
      icon: Icons.home_outlined,
    ),
    CineBottomNavDestination(
      label: 'Review',
      icon: Icons.verified_user_outlined,
    ),
    CineBottomNavDestination(
      label: 'Pay',
      icon: Icons.payments_outlined,
    ),
    CineBottomNavDestination(
      label: 'Disputes',
      icon: Icons.gpp_maybe_outlined,
    ),
    CineBottomNavDestination(
      label: 'More',
      icon: Icons.menu_rounded,
    ),
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
            onRouteTap(SuperAdminRoutes.dashboard);
            return;
          case 1:
            onRouteTap(SuperAdminRoutes.reviewHub);
            return;
          case 2:
            onRouteTap(SuperAdminRoutes.payments);
            return;
          case 3:
            onRouteTap(SuperAdminRoutes.disputes);
            return;
          case 4:
            onMoreTap();
            return;
        }
      },
    );
  }

  int get _currentIndex {
    if (menuOpen) return 4;
    if (_isRouteActive(currentRoute, SuperAdminRoutes.dashboard)) return 0;
    if (_isRouteActive(currentRoute, SuperAdminRoutes.reviewHub)) return 1;
    if (_isRouteActive(currentRoute, SuperAdminRoutes.payments)) return 2;
    if (_isRouteActive(currentRoute, SuperAdminRoutes.disputes)) return 3;
    return 4;
  }
}

class AdminFloatingMenuOverlay extends StatelessWidget {
  final bool open;
  final String currentRoute;
  final VoidCallback onClose;
  final ValueChanged<String> onRouteTap;

  const AdminFloatingMenuOverlay({
    super.key,
    required this.open,
    required this.currentRoute,
    required this.onClose,
    required this.onRouteTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return IgnorePointer(
      ignoring: !open,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final panelWidth =
              (constraints.maxWidth * 0.54).clamp(214.0, 314.0).toDouble();
          // This overlay only renders when the bottom nav (not the side
          // nav) is showing, so mirror PremiumBottomNavBar's own 700px
          // "wide" breakpoint to size the gap around its real height.
          final navBarWide = constraints.maxWidth >= 700;
          final bottomGap = ((navBarWide ? 156 : 112) +
                  MediaQuery.paddingOf(context).bottom +
                  14)
              .toDouble();
          final panelHeight = (constraints.maxHeight - bottomGap - 14)
              .clamp(0.0, 1400.0)
              .toDouble();
          return Stack(
            children: [
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: open ? 1 : 0,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  child: GestureDetector(
                    onTap: onClose,
                    behavior: HitTestBehavior.opaque,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        color: Colors.black.withValues(
                          alpha: colors.isLight ? 0.08 : 0.22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                top: 14,
                child: AnimatedSlide(
                  offset: open ? Offset.zero : const Offset(-1.1, 0),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: open ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: SizedBox(
                      width: panelWidth,
                      height: panelHeight,
                      child: _AdminFloatingMenuPanel(
                        open: open,
                        currentRoute: currentRoute,
                        onClose: onClose,
                        onRouteTap: onRouteTap,
                      ),
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

class _AdminFloatingMenuPanel extends StatelessWidget {
  final bool open;
  final String currentRoute;
  final VoidCallback onClose;
  final ValueChanged<String> onRouteTap;

  const _AdminFloatingMenuPanel({
    required this.open,
    required this.currentRoute,
    required this.onClose,
    required this.onRouteTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassContainer(
      radius: 34,
      padding: EdgeInsets.zero,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors.isLight
            ? [
                colors.surface.withValues(alpha: 0.9),
                colors.softSurface.withValues(alpha: 0.78),
                colors.surface.withValues(alpha: 0.86),
              ]
            : [
                colors.surface.withValues(alpha: 0.58),
                colors.softSurface.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.18),
              ],
      ),
      borderColor: colors.textPrimary.withValues(alpha: 0.12),
      borderWidth: 0.75,
      blur: 40,
      shadows: [
        BoxShadow(
          color: colors.shadow.withValues(alpha: colors.isLight ? 0.16 : 0.62),
          blurRadius: 40,
          offset: const Offset(0, 24),
        ),
        BoxShadow(
          color: colors.goldGlow.withValues(alpha: 0.025),
          blurRadius: 28,
          offset: const Offset(28, 12),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = constraints.maxWidth - 26;

          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Column(
              children: [
                SizedBox(
                  height: 46,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: 4,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 70,
                            height: 5,
                            decoration: BoxDecoration(
                              color: colors.textPrimary.withValues(alpha: 0.24),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: AnimatedScale(
                          scale: open ? 1 : 0.82,
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutBack,
                          child: GestureDetector(
                            onTap: onClose,
                            child: GlassContainer(
                              width: 40,
                              height: 40,
                              radius: 20,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colors.textPrimary.withValues(alpha: 0.06),
                                  colors.surface.withValues(alpha: 0.02),
                                ],
                              ),
                              borderColor:
                                  colors.textPrimary.withValues(alpha: 0.16),
                              borderWidth: 0.75,
                              blur: 28,
                              shadows: [
                                BoxShadow(
                                  color: colors.textPrimary
                                      .withValues(alpha: 0.08),
                                  blurRadius: 18,
                                ),
                              ],
                              child: Icon(
                                Icons.close_rounded,
                                color: colors.textPrimary,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: AdminMockData.navItems.asMap().entries.map(
                        (entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final active =
                              _isRouteActive(currentRoute, item.route);
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == AdminMockData.navItems.length - 1
                                  ? 0
                                  : 8,
                            ),
                            child: SizedBox(
                              width: contentWidth,
                              child: _FloatingAdminMenuCard(
                                item: item,
                                active: active,
                                open: open,
                                index: index,
                                onTap: () => onRouteTap(item.route),
                              ),
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _SuperAdminStatusCard(open: open),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FloatingAdminMenuCard extends StatefulWidget {
  final AdminNavItem item;
  final bool active;
  final bool open;
  final int index;
  final VoidCallback onTap;

  const _FloatingAdminMenuCard({
    required this.item,
    required this.active,
    required this.open,
    required this.index,
    required this.onTap,
  });

  @override
  State<_FloatingAdminMenuCard> createState() => _FloatingAdminMenuCardState();
}

class _FloatingAdminMenuCardState extends State<_FloatingAdminMenuCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final glowColor = widget.active ? colors.goldLight : colors.goldGlow;
    const itemHeight = 48.0;
    const iconSize = 40.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: widget.open ? 0 : 1, end: widget.open ? 1 : 0),
      duration: Duration(milliseconds: 300 + widget.index * 36),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(-26 * (1 - value), 8 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          child: SizedBox(
            height: itemHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: GlassContainer(
                    radius: itemHeight / 2,
                    padding: const EdgeInsets.only(
                      left: iconSize + 22,
                      right: 12,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.active
                          ? [
                              colors.goldGlow.withValues(alpha: 0.035),
                              colors.surface.withValues(alpha: 0.3),
                              colors.goldGlow.withValues(alpha: 0.008),
                            ]
                          : [
                              colors.surface.withValues(
                                  alpha: colors.isLight ? 0.54 : 0.24),
                              colors.softSurface.withValues(
                                  alpha: colors.isLight ? 0.38 : 0.12),
                              colors.textPrimary.withValues(
                                  alpha: colors.isLight ? 0.025 : 0.015),
                            ],
                    ),
                    borderColor: widget.active
                        ? colors.goldLight.withValues(alpha: 0.16)
                        : colors.textPrimary.withValues(alpha: 0.1),
                    borderWidth: 0.75,
                    blur: 30,
                    shadows: [
                      BoxShadow(
                        color: glowColor.withValues(
                          alpha: widget.active ? 0.07 : 0.025,
                        ),
                        blurRadius: widget.active ? 18 : 12,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: widget.active
                              ? colors.goldLight.withValues(alpha: 0.9)
                              : colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: (itemHeight - iconSize) / 2,
                  child: Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colors.textPrimary.withValues(
                            alpha: colors.isLight ? 0.32 : 0.1,
                          ),
                          colors.surface.withValues(alpha: 0.42),
                          colors.goldGlow.withValues(alpha: 0.008),
                        ],
                      ),
                      border: Border.all(
                        color: widget.active
                            ? colors.goldLight.withValues(alpha: 0.24)
                            : colors.textPrimary.withValues(alpha: 0.1),
                        width: 0.85,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.goldGlow.withValues(
                            alpha: widget.active ? 0.14 : 0.02,
                          ),
                          blurRadius: widget.active ? 16 : 10,
                          spreadRadius: widget.active ? 0 : -2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        widget.item.icon,
                        color: colors.textPrimary,
                        size: 22,
                      ),
                    ),
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

class _SuperAdminStatusCard extends StatelessWidget {
  final bool open;

  const _SuperAdminStatusCard({required this.open});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: open ? 0 : 1, end: open ? 1 : 0),
      duration: const Duration(milliseconds: 440),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(-18 * (1 - value), 8 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GlassContainer(
        width: double.infinity,
        height: 62,
        radius: 17,
        padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.textPrimary.withValues(alpha: colors.isLight ? 0.08 : 0.045),
            colors.surface.withValues(alpha: colors.isLight ? 0.48 : 0.2),
            colors.goldGlow.withValues(alpha: 0.012),
          ],
        ),
        borderColor: colors.textPrimary.withValues(alpha: 0.11),
        borderWidth: 0.75,
        blur: 30,
        shadows: [
          BoxShadow(
            color: colors.goldGlow.withValues(alpha: 0.025),
            blurRadius: 14,
            offset: const Offset(0, 12),
          ),
        ],
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.goldLight.withValues(alpha: 0.36),
                    colors.surface.withValues(alpha: 0.34),
                    colors.textPrimary.withValues(alpha: 0.04),
                  ],
                ),
                border: Border.all(
                  color: colors.goldLight.withValues(alpha: 0.14),
                  width: 0.85,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.goldGlow.withValues(alpha: 0.08),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: colors.onGold,
                size: 28,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Super Admin Control',
                      maxLines: 1,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'All systems operational',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: colors.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.success,
                boxShadow: [
                  BoxShadow(
                    color: colors.success.withValues(alpha: 0.8),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminBreadcrumbs extends StatelessWidget {
  final String title;
  final String subtitle;

  const AdminBreadcrumbs({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return shared_layout.AdminScreenHeading(title: title);
  }
}

class DashboardSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;
  final Color? iconColor;
  final Color? actionColor;

  const DashboardSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.actionText,
    this.onActionTap,
    this.iconColor,
    this.actionColor,
  });

  @override
  Widget build(BuildContext context) {
    return shared_layout.AdminSectionHeader(
      icon: icon,
      title: title,
      actionText: actionText,
      onActionTap: onActionTap,
      iconColor: iconColor,
      actionColor: actionColor,
    );
  }
}

class AdminSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool selected;

  const AdminSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSectionCard(
      padding: padding,
      selected: selected,
      child: child,
    );
  }
}

class DashboardMetricCards extends StatelessWidget {
  final ValueChanged<String>? onRouteTap;

  const DashboardMetricCards({
    super.key,
    this.onRouteTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final cards = [
      shared_metric.MetricActionItem(
        icon: Icons.verified_user_outlined,
        value: '42',
        title: 'Verifications',
        subtitle: '+9 today',
        accentColor: colors.infoBlue,
        onTap: () => onRouteTap?.call(SuperAdminRoutes.verifications),
      ),
      shared_metric.MetricActionItem(
        icon: Icons.payments_outlined,
        value: '18',
        title: 'Payments',
        subtitle: 'PKR 4.2M',
        accentColor: colors.infoPurple,
        onTap: () => onRouteTap?.call(SuperAdminRoutes.payments),
      ),
      shared_metric.MetricActionItem(
        icon: Icons.gpp_maybe_outlined,
        value: '7',
        title: 'Disputes',
        subtitle: '+2 today',
        accentColor: colors.danger,
        onTap: () => onRouteTap?.call(SuperAdminRoutes.disputes),
      ),
      shared_metric.MetricActionItem(
        icon: Icons.groups_rounded,
        value: '126',
        title: 'Active Negotiations',
        subtitle: '+15 today',
        accentColor: colors.infoBlue,
        onTap: () => onRouteTap?.call(SuperAdminRoutes.bookingsMonitor),
      ),
      shared_metric.MetricActionItem(
        icon: Icons.fact_check_outlined,
        value: 'Open',
        title: 'Reviews',
        subtitle: 'Review hub',
        accentColor: colors.goldMid,
        onTap: () => onRouteTap?.call(SuperAdminRoutes.reviewHub),
      ),
      shared_metric.MetricActionItem(
        icon: Icons.payments_outlined,
        value: 'Verify',
        title: 'Payments',
        subtitle: 'Queue',
        accentColor: colors.infoPurple,
        onTap: () => onRouteTap?.call(SuperAdminRoutes.paymentQueue),
      ),
      shared_metric.MetricActionItem(
        icon: Icons.gpp_maybe_outlined,
        value: 'Open',
        title: 'Disputes',
        subtitle: 'Cases',
        accentColor: colors.infoBlue,
        onTap: () => onRouteTap?.call(SuperAdminRoutes.disputes),
      ),
      shared_metric.MetricActionItem(
        icon: Icons.calendar_month_outlined,
        value: 'View',
        title: 'Bookings',
        subtitle: 'Monitor',
        accentColor: colors.success,
        onTap: () => onRouteTap?.call(SuperAdminRoutes.bookingsMonitor),
      ),
      shared_metric.MetricActionItem(
        icon: Icons.manage_search_outlined,
        value: 'Open',
        title: 'Audit Logs',
        subtitle: 'System trail',
        accentColor: colors.goldMid,
        onTap: () => onRouteTap?.call(SuperAdminRoutes.auditLogs),
      ),
      shared_metric.MetricActionItem(
        icon: Icons.analytics_outlined,
        value: 'Run',
        title: 'Analytics',
        subtitle: 'Live insights',
        accentColor: colors.infoBlue,
        onTap: () => onRouteTap?.call(SuperAdminRoutes.analytics),
      ),
    ];

    return shared_sections.AdminQuickActionsSection(items: cards);
  }
}

class AdminStatusBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AdminDecisionTone tone;

  const AdminStatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.tone = AdminDecisionTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(context, tone);
    return StatusChip(
      label: label,
      icon: icon,
      color: color,
    );
  }
}

class AdminRiskBadge extends StatelessWidget {
  final String label;
  final AdminRiskTone risk;

  const AdminRiskBadge({
    super.key,
    required this.label,
    required this.risk,
  });

  @override
  Widget build(BuildContext context) {
    final tone = switch (risk) {
      AdminRiskTone.low => AdminDecisionTone.success,
      AdminRiskTone.medium => AdminDecisionTone.warning,
      AdminRiskTone.high => AdminDecisionTone.danger,
      AdminRiskTone.critical => AdminDecisionTone.danger,
    };
    return AdminStatusBadge(
      label: label,
      icon: risk == AdminRiskTone.low
          ? Icons.check_circle_outline
          : Icons.warning_amber_rounded,
      tone: tone,
    );
  }
}

class AdminSlaBadge extends StatelessWidget {
  final String age;

  const AdminSlaBadge({super.key, required this.age});

  @override
  Widget build(BuildContext context) {
    final danger =
        age.contains('24') || age.contains('2d') || age.contains('27');
    return AdminStatusBadge(
      label: age,
      icon: Icons.timer_outlined,
      tone: danger ? AdminDecisionTone.danger : AdminDecisionTone.warning,
    );
  }
}

class AdminFilterBar extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  const AdminFilterBar({
    super.key,
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return shared_filters.AdminCompactFilterBar(
      filters: filters,
      selected: selected,
      onSelected: onSelected,
    );
  }
}

class AdminDataTable extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;
  final List<VoidCallback?>? rowActions;

  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.rowActions,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumDataTable(
      columns: columns,
      rows: rows,
      rowActions: rowActions,
    );
  }
}

class AdminActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool secondary;

  const AdminActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: secondary ? colors.glassGradient : colors.goldGradient,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: secondary ? colors.border : colors.goldLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: secondary ? colors.textPrimary : colors.onGold,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(
                  color: secondary ? colors.textPrimary : colors.onGold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const AdminIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
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

class AdminCommandButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const AdminCommandButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: colors.searchGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: colors.goldDark, size: 20),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            AdminStatusBadge(
              label: 'CMD K',
              tone: AdminDecisionTone.neutral,
            ),
          ],
        ),
      ),
    );
  }
}

class AdminNavPill extends StatelessWidget {
  final AdminNavItem item;
  final bool active;
  final VoidCallback onTap;

  const AdminNavPill({
    super.key,
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CoreChip(
      label: item.label,
      icon: item.icon,
      selected: active,
      onTap: onTap,
    );
  }
}

class AdminActionFeedItem extends StatelessWidget {
  final AdminFeedItem item;
  final bool resolved;
  final VoidCallback onResolve;

  const AdminActionFeedItem({
    super.key,
    required this.item,
    required this.resolved,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AnimatedOpacity(
      opacity: resolved ? 0.46 : 1,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: colors.inactiveChipGradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            AdminRiskBadge(label: item.priority, risk: item.risk),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTextStyles.label.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${item.category} - ${item.age} - Assigned to ${item.assignedTo}',
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AdminActionButton(
              icon: resolved ? Icons.check_circle_outline : Icons.done_rounded,
              label: resolved ? 'Resolved' : 'Resolve',
              secondary: true,
              onTap: onResolve,
            ),
          ],
        ),
      ),
    );
  }
}

class AdminTimeline extends StatelessWidget {
  final List<String> items;

  const AdminTimeline({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == 0 ? colors.goldMid : colors.border,
                  ),
                ),
                if (index != items.length - 1)
                  Container(width: 1, height: 42, color: colors.border),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Text(
                  item,
                  style: AppTextStyles.caption.copyWith(
                    color: colors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class AdminEvidenceViewer extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> details;

  const AdminEvidenceViewer({
    super.key,
    required this.title,
    required this.icon,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: colors.isLight ? 0.72 : 0.32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.goldMid.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                  border:
                      Border.all(color: colors.goldMid.withValues(alpha: 0.24)),
                ),
                child: Icon(icon, color: colors.goldDark, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle
                      .copyWith(color: colors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: details
                .map(
                  (detail) => AdminStatusBadge(
                    label: detail,
                    tone: AdminDecisionTone.info,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class AdminProofViewer extends StatelessWidget {
  final String title;
  final List<String> ocrLines;

  const AdminProofViewer({
    super.key,
    required this.title,
    required this.ocrLines,
  });

  @override
  Widget build(BuildContext context) {
    return AdminEvidenceViewer(
      title: title,
      icon: Icons.receipt_long_outlined,
      details: ocrLines,
    );
  }
}

class AdminChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<double> values;
  final bool bars;

  const AdminChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.values,
    this.bars = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.label.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 150,
            child:
                bars ? _BarChart(values: values) : _LineChart(values: values),
          ),
        ],
      ),
    );
  }
}

class AdminPermissionMatrix extends StatelessWidget {
  final List<String> roles;
  final List<String> permissions;
  final Set<String> enabled;
  final ValueChanged<String> onToggle;

  const AdminPermissionMatrix({
    super.key,
    required this.roles,
    required this.permissions,
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AdminSurface(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _matrixCell(context, 'Role', width: 150, header: true),
                ...permissions.map(
                    (p) => _matrixCell(context, p, width: 120, header: true)),
              ],
            ),
            ...roles.map(
              (role) => Row(
                children: [
                  _matrixCell(context, role, width: 150),
                  ...permissions.map((permission) {
                    final key = '$role|$permission';
                    final protected =
                        role == 'Super Admin' && enabled.contains(key);
                    return SizedBox(
                      width: 120,
                      height: 54,
                      child: Center(
                        child: IconButton(
                          tooltip: protected ? 'Protected' : permission,
                          onPressed: protected ? null : () => onToggle(key),
                          icon: Icon(
                            protected
                                ? Icons.lock_outline
                                : enabled.contains(key)
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                            color: protected
                                ? colors.goldDark
                                : enabled.contains(key)
                                    ? colors.success
                                    : colors.iconMuted,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _matrixCell(
    BuildContext context,
    String text, {
    required double width,
    bool header = false,
  }) {
    final colors = context.appColors;
    return Container(
      width: width,
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: colors.borderMuted),
          bottom: BorderSide(color: colors.borderMuted),
        ),
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption.copyWith(
          color: header ? colors.goldDark : colors.textPrimary,
          fontWeight: header ? FontWeight.w900 : FontWeight.w700,
        ),
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const AdminEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return CoreEmptyState(icon: icon, title: title, message: message);
  }
}

class AdminUserMiniCard extends StatelessWidget {
  final String name;
  final String detail;
  final String badge;
  final VoidCallback? onTap;

  const AdminUserMiniCard({
    super.key,
    required this.name,
    required this.detail,
    required this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final content = Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colors.goldMid.withValues(alpha: 0.16),
            child: Icon(Icons.person_outline, color: colors.goldDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.label.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: AppTextStyles.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AdminStatusBadge(label: badge, tone: AdminDecisionTone.info),
        ],
      ),
    );
    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}

class AdminSectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final IconData icon;

  const AdminSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.icon = Icons.auto_awesome_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardSectionHeader(
      icon: icon,
      title: title,
      actionText: action,
      onActionTap: onAction,
    );
  }
}

class AdminMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final AdminDecisionTone tone;

  const AdminMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tone = AdminDecisionTone.info,
  });

  shared_metric.MetricActionItem toActionItem(BuildContext context) {
    return shared_metric.MetricActionItem(
      icon: icon,
      value: value,
      title: label,
      subtitle: _toneLabel(tone),
      accentColor: _toneColor(context, tone),
    );
  }

  @override
  Widget build(BuildContext context) {
    return shared_metric.MetricActionCard(item: toActionItem(context));
  }
}

String _toneLabel(AdminDecisionTone tone) {
  return switch (tone) {
    AdminDecisionTone.success => 'CLEARED',
    AdminDecisionTone.warning => 'REVIEW',
    AdminDecisionTone.danger => 'URGENT',
    AdminDecisionTone.info => 'ACTIVE',
    AdminDecisionTone.neutral => 'TRACKING',
  };
}

class AdminDetailDrawer extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const AdminDetailDrawer({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
          decoration: BoxDecoration(
            gradient: colors.cardGradient,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.sectionHeaderStyle.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showAdminDecisionDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  VoidCallback? onConfirm,
}) {
  final colors = context.appColors;
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        title,
        style: AppTextStyles.sectionHeaderStyle.copyWith(
          color: colors.textPrimary,
        ),
      ),
      content: Text(
        message,
        style: AppTextStyles.cardLabel.copyWith(color: colors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm?.call();
          },
          child: Text(action),
        ),
      ],
    ),
  );
}

void showAdminCommandSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AdminDetailDrawer(
      title: 'Global Command Search',
      children: [
        CoreTextField(
          controller: TextEditingController(),
          label: 'Search bookings, users, contracts, payments...',
          icon: Icons.search_rounded,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AdminMockData.navItems
              .take(10)
              .map(
                (item) => AdminNavPill(
                  item: item,
                  active: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, item.route);
                  },
                ),
              )
              .toList(),
        ),
      ],
    ),
  );
}

Color _toneColor(BuildContext context, AdminDecisionTone tone) {
  final colors = context.appColors;
  return switch (tone) {
    AdminDecisionTone.success => colors.success,
    AdminDecisionTone.warning => colors.goldMid,
    AdminDecisionTone.info => colors.infoBlue,
    AdminDecisionTone.danger => colors.danger,
    AdminDecisionTone.neutral => colors.textSecondary,
  };
}

bool _isRouteActive(String currentRoute, String itemRoute) {
  if (currentRoute == itemRoute) return true;
  if (itemRoute == SuperAdminRoutes.reviewHub &&
      {
        SuperAdminRoutes.reviewHubPeople,
        SuperAdminRoutes.reviewHubListings,
        SuperAdminRoutes.reviewHubContent,
        SuperAdminRoutes.verifications,
        SuperAdminRoutes.verificationDetail,
        SuperAdminRoutes.contentModeration,
        SuperAdminRoutes.listingsModeration,
      }.contains(currentRoute)) {
    return true;
  }
  if (currentRoute == SuperAdminRoutes.verificationDetail) {
    return itemRoute == SuperAdminRoutes.verifications;
  }
  if (itemRoute == SuperAdminRoutes.payments &&
      {
        SuperAdminRoutes.paymentQueue,
        SuperAdminRoutes.paymentReview,
        SuperAdminRoutes.paymentLedger,
        SuperAdminRoutes.paymentRevenue,
        SuperAdminRoutes.fees,
      }.contains(currentRoute)) {
    return true;
  }
  if (currentRoute == SuperAdminRoutes.disputeCase) {
    return itemRoute == SuperAdminRoutes.disputes;
  }
  if (currentRoute == SuperAdminRoutes.bookingDetail) {
    return itemRoute == SuperAdminRoutes.bookingsMonitor;
  }
  if (currentRoute == SuperAdminRoutes.contractTemplateDetail) {
    return itemRoute == SuperAdminRoutes.contractTemplates;
  }
  if (currentRoute == SuperAdminRoutes.support ||
      currentRoute == SuperAdminRoutes.adminRoles) {
    return itemRoute == SuperAdminRoutes.users;
  }
  return false;
}

class _AdminBrand extends StatelessWidget {
  final bool compact;

  const _AdminBrand({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final size = compact ? 15.5 : 19.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'CINE',
                style: AppTextStyles.brand.copyWith(
                  color: colors.textPrimary,
                  fontSize: size,
                  letterSpacing: compact ? 2.6 : 4.0,
                  fontWeight: FontWeight.w900,
                ),
              ),
              TextSpan(
                text: 'CONNECT',
                style: AppTextStyles.brand.copyWith(
                  color: colors.goldMid,
                  fontSize: size,
                  letterSpacing: compact ? 2.1 : 3.3,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 8),
          Text(
            'TRUST. MONEY. SAFETY.',
            style: AppTextStyles.micro.copyWith(
              color: colors.textSecondary,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<double> values;

  const _BarChart({required this.values});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: values
          .map(
            (value) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FractionallySizedBox(
                  heightFactor: (value / maxValue).clamp(0.08, 1),
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: colors.goldGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _LineChart extends StatelessWidget {
  final List<double> values;

  const _LineChart({required this.values});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LinePainter(context.appColors, values),
      child: const SizedBox.expand(),
    );
  }
}

class _LinePainter extends CustomPainter {
  final CineThemeColors colors;
  final List<double> values;

  const _LinePainter(this.colors, this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i == 0 ? 0.0 : size.width * i / (values.length - 1);
      final y = size.height - (values[i] / maxValue * size.height * 0.86);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = colors.goldMid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colors.goldGlow.withValues(alpha: 0.46),
          colors.goldGlow.withValues(alpha: 0.02),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) =>
      oldDelegate.colors != colors || oldDelegate.values != values;
}
