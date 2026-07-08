import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/core_ui/core_back_navigation.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_header.dart' show ThemeToggleButton;
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/cinematic_backdrop.dart';
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
  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: CinematicBackdrop()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;
                return Row(
                  children: [
                    if (wide)
                      AdminSidebar(
                        currentRoute: widget.currentRoute,
                        onRouteTap: (route) => _go(context, route),
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          AdminTopBar(
                            title: widget.title,
                            onNavTap: wide ? null : _openMenu,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                            child: AdminBreadcrumbs(
                              title: widget.title,
                              subtitle: widget.subtitle,
                            ),
                          ),
                          Expanded(
                            child: Stack(
                              children: [
                                SingleChildScrollView(
                                  padding:
                                      const EdgeInsets.fromLTRB(18, 18, 18, 28),
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 1280),
                                    child: widget.child,
                                  ),
                                ),
                                if (!wide)
                                  AdminFloatingMenuOverlay(
                                    open: _menuOpen,
                                    currentRoute: widget.currentRoute,
                                    onClose: _closeMenu,
                                    onRouteTap: (route) => _go(context, route),
                                  ),
                              ],
                            ),
                          ),
                          if (!wide)
                            AdminBottomNav(
                              currentRoute: widget.currentRoute,
                              menuOpen: _menuOpen,
                              onRouteTap: (route) => _go(context, route),
                              onMoreTap: _openMenu,
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openMenu() {
    setState(() => _menuOpen = true);
  }

  void _closeMenu() {
    setState(() => _menuOpen = false);
  }

  void _go(BuildContext context, String route) {
    if (_menuOpen) _closeMenu();
    if (route == widget.currentRoute) return;
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
              onTap: () => Navigator.pushNamed(context, CoreRoutes.login),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 12 : 18, 12, compact ? 12 : 18, 0),
      child: GlassContainer(
        radius: compact ? 18 : 22,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 9 : 12,
        ),
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
              const SizedBox(width: 10),
              AdminIconButton(
                icon: Icons.logout_rounded,
                tooltip: 'Logout',
                onTap: () => Navigator.pushNamed(context, CoreRoutes.login),
              ),
            ],
          ],
        ),
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
            onRouteTap(SuperAdminRoutes.paymentQueue);
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
    if (_isRouteActive(currentRoute, SuperAdminRoutes.paymentQueue)) return 2;
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
              (constraints.maxWidth * 0.72).clamp(276.0, 344.0).toDouble();
          final panelHeight =
              (constraints.maxHeight - 20).clamp(0.0, 900.0).toDouble();
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
                          alpha: colors.isLight ? 0.12 : 0.32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                top: 10,
                bottom: 10,
                child: AnimatedSlide(
                  offset: open ? Offset.zero : const Offset(-1.1, 0),
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: open ? 1 : 0,
                    duration: const Duration(milliseconds: 260),
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
      radius: 28,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      borderColor: colors.border.withValues(alpha: 0.16),
      borderWidth: 0.8,
      blur: 28,
      shadows: [
        BoxShadow(
          color: colors.shadow.withValues(alpha: colors.isLight ? 0.2 : 0.72),
          blurRadius: 34,
          offset: const Offset(0, 18),
        ),
        BoxShadow(
          color: colors.goldGlow.withValues(alpha: 0.2),
          blurRadius: 38,
          offset: const Offset(18, -16),
        ),
      ],
      child: Column(
        children: [
          SizedBox(
            height: 42,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textPrimary.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedScale(
                    scale: open ? 1 : 0.82,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    child: GestureDetector(
                      onTap: onClose,
                      child: GlassContainer(
                        width: 42,
                        height: 42,
                        radius: 21,
                        borderColor: colors.border.withValues(alpha: 0.18),
                        child: Icon(
                          Icons.close_rounded,
                          color: colors.textPrimary,
                          size: 23,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = ((constraints.maxWidth - 10) / 2)
                    .clamp(96.0, 160.0)
                    .toDouble();
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: AdminMockData.navItems.asMap().entries.map(
                      (entry) {
                        final item = entry.value;
                        final active = _isRouteActive(currentRoute, item.route);
                        return SizedBox(
                          width: itemWidth,
                          child: _FloatingAdminMenuCard(
                            item: item,
                            active: active,
                            open: open,
                            index: entry.key,
                            onTap: () => onRouteTap(item.route),
                          ),
                        );
                      },
                    ).toList(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _SuperAdminStatusCard(open: open),
        ],
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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: widget.open ? 0 : 1, end: widget.open ? 1 : 0),
      duration: Duration(milliseconds: 250 + widget.index * 22),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 14),
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
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          child: GlassContainer(
            height: 86,
            radius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            gradient: widget.active
                ? colors.goldGradient
                : colors.inactiveChipGradient,
            borderColor: widget.active
                ? colors.goldLight.withValues(alpha: 0.36)
                : colors.border.withValues(alpha: 0.24),
            borderWidth: 0.8,
            shadows: [
              BoxShadow(
                color: widget.active
                    ? colors.goldGlow.withValues(alpha: 0.55)
                    : colors.shadow.withValues(alpha: 0.24),
                blurRadius: widget.active ? 24 : 18,
                offset: const Offset(0, 12),
              ),
            ],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.item.icon,
                  color: widget.active ? colors.onGold : colors.textPrimary,
                  size: 28,
                ),
                const SizedBox(height: 9),
                Text(
                  widget.item.label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: widget.active ? colors.onGold : colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
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
      duration: const Duration(milliseconds: 430),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 10),
            child: child,
          ),
        );
      },
      child: GlassContainer(
        radius: 18,
        padding: const EdgeInsets.all(12),
        borderColor: colors.goldMid.withValues(alpha: 0.2),
        shadows: [
          BoxShadow(
            color: colors.goldGlow.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: colors.goldGradient,
                boxShadow: [
                  BoxShadow(color: colors.goldGlow, blurRadius: 18),
                ],
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: colors.onGold,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Super Admin Control',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'All systems operational',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.success,
                          boxShadow: [
                            BoxShadow(color: colors.success, blurRadius: 8),
                          ],
                        ),
                      ),
                    ],
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
    final colors = context.appColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Super Admin / $title',
                style: AppTextStyles.caption.copyWith(
                  color: colors.goldDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heading.copyWith(
                        color: colors.textPrimary,
                        fontSize: 28,
                      ),
                    ),
                  ),
                  if (title == 'Review Hub') ...[
                    const SizedBox(width: 10),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.goldMid.withValues(alpha: 0.12),
                        border: Border.all(
                          color: colors.goldMid.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Icon(
                        Icons.verified_user_outlined,
                        color: colors.goldDark,
                        size: 19,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: AppTextStyles.bodyMuted.copyWith(
                  color: colors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        if (MediaQuery.sizeOf(context).width >= 760)
          AdminStatusBadge(
            label: 'Jul 8, 2026',
            icon: Icons.calendar_month_outlined,
            tone: AdminDecisionTone.neutral,
          ),
      ],
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
    final colors = context.appColors;
    return GlassContainer(
      radius: 22,
      padding: padding,
      borderColor: selected ? colors.goldMid : colors.border,
      shadows: [
        BoxShadow(
          color: colors.shadow.withValues(alpha: colors.isLight ? 0.12 : 0.38),
          blurRadius: 22,
          offset: const Offset(0, 12),
        ),
      ],
      child: child,
    );
  }
}

class AdminKpiCard extends StatelessWidget {
  final AdminKpi kpi;
  final VoidCallback onTap;

  const AdminKpiCard({
    super.key,
    required this.kpi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AdminSurface(
        selected: kpi.tone == AdminDecisionTone.danger,
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.goldMid.withValues(alpha: 0.13),
                  ),
                  child: Icon(kpi.icon, color: colors.goldDark, size: 21),
                ),
                const Spacer(),
                AdminStatusBadge(label: kpi.sla, tone: kpi.tone),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              kpi.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.sectionTitle.copyWith(
                color: colors.textPrimary,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              kpi.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              kpi.trend,
              style:
                  AppTextStyles.caption.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
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
    final colors = context.appColors;
    final color = _toneColor(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: colors.isLight ? 0.1 : 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.micro.copyWith(
                color: color,
                letterSpacing: 0,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters
            .map(
              (filter) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CoreChip(
                  label: filter,
                  selected: selected == filter,
                  onTap: () => onSelected(filter),
                ),
              ),
            )
            .toList(),
      ),
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
    final colors = context.appColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 36;
        final tableWidth = availableWidth > columns.length * 118
            ? availableWidth
            : columns.length * 118.0;

        return AdminSurface(
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: colors.border)),
                    ),
                    child: Row(
                      children: columns
                          .map(
                            (column) => Expanded(
                              child: Text(
                                column,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.micro.copyWith(
                                  color: colors.goldDark,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  ...rows.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;
                    return InkWell(
                      onTap: rowActions == null ? null : rowActions![index],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: colors.borderMuted),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: row
                              .map(
                                (cell) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: cell,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: colors.isLight ? 0.72 : 0.32),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 180,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.goldMid.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.goldMid.withValues(alpha: 0.24)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: colors.goldDark, size: 48),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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

  const AdminUserMiniCard({
    super.key,
    required this.name,
    required this.detail,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
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
  }
}

class AdminSectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const AdminSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.sectionTitle.copyWith(
              color: colors.textPrimary,
              fontSize: 22,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              action!,
              style: AppTextStyles.label.copyWith(color: colors.goldDark),
            ),
          ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = _toneColor(context, tone);
    return AdminSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sectionTitle.copyWith(
              color: colors.textPrimary,
              fontSize: 21,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
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
    return Container(
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
                style: AppTextStyles.sectionTitle.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
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
        style: AppTextStyles.sectionTitle.copyWith(color: colors.textPrimary),
      ),
      content: Text(
        message,
        style: AppTextStyles.bodyMuted.copyWith(color: colors.textSecondary),
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
    AdminDecisionTone.danger => colors.infoPurple,
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
  if (currentRoute == SuperAdminRoutes.paymentReview) {
    return itemRoute == SuperAdminRoutes.paymentQueue;
  }
  if (currentRoute == SuperAdminRoutes.disputeCase) {
    return itemRoute == SuperAdminRoutes.disputes;
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
