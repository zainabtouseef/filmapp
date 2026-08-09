import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/tour/tour_target.dart';

/// Floating rounded bottom navigation bar with an elevated center Create button.
class CineBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final List<CineBottomNavDestination> destinations;
  final bool compactCenter;

  const CineBottomNav({
    super.key,
    this.currentIndex = 1,
    this.onTap,
    this.destinations = _defaultBottomNavDestinations,
    this.compactCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumBottomNavBar(
      currentIndex: currentIndex,
      onTap: onTap,
      destinations: destinations,
      compactCenter: compactCenter,
    );
  }
}

class CineBottomNavDestination {
  final IconData icon;
  final String label;

  /// Optional route this destination navigates to. When set, the rendered
  /// item is wrapped in a `TourTarget(id: 'nav:<route>')` so a spotlight
  /// tour can highlight it — the same id convention used by the sidebar
  /// (`DPShell._DPSidebar` and friends) and `FloatingPortalMenuOverlay`,
  /// so one tour step lights up whichever of the three is on screen.
  final String? route;

  const CineBottomNavDestination({
    required this.icon,
    required this.label,
    this.route,
  });
}

Widget _tourWrap(String? route, Widget child) {
  if (route == null) return child;
  return TourTarget(id: 'nav:$route', child: child);
}

const _defaultBottomNavDestinations = [
  CineBottomNavDestination(
    icon: Icons.home_outlined,
    label: 'Home',
  ),
  CineBottomNavDestination(
    icon: Icons.search_rounded,
    label: 'Discover',
  ),
  CineBottomNavDestination(
    icon: Icons.add_rounded,
    label: 'Create',
  ),
  CineBottomNavDestination(
    icon: Icons.work_outline_rounded,
    label: 'Bookings',
  ),
  CineBottomNavDestination(
    icon: Icons.person_outline_rounded,
    label: 'Profile',
  ),
];

class PremiumBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final List<CineBottomNavDestination> destinations;
  final bool compactCenter;

  const PremiumBottomNavBar({
    super.key,
    this.currentIndex = 1,
    this.onTap,
    this.destinations = _defaultBottomNavDestinations,
    this.compactCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    assert(destinations.length == 5, 'Bottom navigation expects 5 items.');
    final colors = context.appColors;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 700;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final totalHeight =
        (wide ? 156.0 : (compactCenter ? 112.0 : 132.0)) + bottomInset;
    final navHeight =
        (wide ? 126.0 : (compactCenter ? 96.0 : 108.0)) + bottomInset;
    final createSize = wide ? 118.0 : (compactCenter ? 58.0 : 82.0);
    final sidePadding = wide ? 50.0 : (compactCenter ? 18.0 : 22.0);
    final itemTop = wide ? 32.0 : (compactCenter ? 23.0 : 26.0);
    final centerGap = wide ? 160.0 : (compactCenter ? 78.0 : 92.0);

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: navHeight,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: colors.navGradient,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    border: Border(
                      top: BorderSide(color: colors.border, width: 1.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withValues(
                          alpha: colors.isLight ? 0.24 : 0.65,
                        ),
                        blurRadius: 28,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: sidePadding,
                        right: sidePadding,
                        top: itemTop,
                        child: Row(
                          children: [
                            Expanded(
                              child: _tourWrap(
                                destinations[0].route,
                                BottomNavItem(
                                  icon: destinations[0].icon,
                                  label: destinations[0].label,
                                  active: currentIndex == 0,
                                  onTap: () => onTap?.call(0),
                                  wide: wide,
                                  dense: compactCenter,
                                ),
                              ),
                            ),
                            Expanded(
                              child: _tourWrap(
                                destinations[1].route,
                                BottomNavItem(
                                  icon: destinations[1].icon,
                                  label: destinations[1].label,
                                  active: currentIndex == 1,
                                  onTap: () => onTap?.call(1),
                                  wide: wide,
                                  dense: compactCenter,
                                ),
                              ),
                            ),
                            SizedBox(width: centerGap),
                            Expanded(
                              child: _tourWrap(
                                destinations[3].route,
                                BottomNavItem(
                                  icon: destinations[3].icon,
                                  label: destinations[3].label,
                                  active: currentIndex == 3,
                                  onTap: () => onTap?.call(3),
                                  wide: wide,
                                  dense: compactCenter,
                                ),
                              ),
                            ),
                            Expanded(
                              child: _tourWrap(
                                destinations[4].route,
                                BottomNavItem(
                                  icon: destinations[4].icon,
                                  label: destinations[4].label,
                                  active: currentIndex == 4,
                                  onTap: () => onTap?.call(4),
                                  wide: wide,
                                  dense: compactCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: bottomInset > 0 ? 9 : 12,
                        child: Center(
                          child: Container(
                            width: wide ? 410 : 132,
                            height: wide ? 8 : 5,
                            decoration: BoxDecoration(
                              color: colors.isLight
                                  ? Colors.black.withValues(alpha: 0.9)
                                  : Colors.white.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: _tourWrap(
              destinations[2].route,
              CenterNavButton(
                active: currentIndex == 2,
                size: createSize,
                wide: wide,
                icon: destinations[2].icon,
                label: destinations[2].label,
                compact: compactCenter,
                onTap: () => onTap?.call(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final bool wide;
  final bool dense;

  const BottomNavItem({
    super.key,
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
    this.wide = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = active ? colors.goldDark : colors.textTertiary;
    final iconSize = wide ? 42.0 : (dense ? 25.0 : 29.0);
    final baseLabelSize = wide ? 22.0 : (dense ? 13.0 : 14.5);
    final labelSize =
        !wide && label.length > 9 ? (dense ? 11.2 : 12.6) : baseLabelSize;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: wide ? 76 : (dense ? 42 : 46),
            height: wide ? 52 : (dense ? 30 : 34),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (active)
                  Container(
                    width: wide ? 66 : 42,
                    height: wide ? 48 : 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colors.goldLight.withValues(alpha: 0.24),
                          colors.goldDark.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.52, 1.0],
                      ),
                    ),
                  ),
                Icon(
                  icon,
                  color: color,
                  size: iconSize,
                  shadows: active
                      ? [
                          Shadow(color: colors.goldGlow, blurRadius: 12),
                        ]
                      : null,
                ),
              ],
            ),
          ),
          SizedBox(height: wide ? 10 : (dense ? 5 : 7)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontSize: labelSize,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: wide ? 12 : (dense ? 5 : 7)),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: active ? (wide ? 44 : 26) : 0,
            height: wide ? 3.5 : 2.8,
            decoration: BoxDecoration(
              gradient: colors.goldGradient,
              borderRadius: BorderRadius.circular(4),
              boxShadow: active
                  ? [
                      BoxShadow(color: colors.goldGlow, blurRadius: 10),
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class CenterNavButton extends StatelessWidget {
  final bool active;
  final double size;
  final bool wide;
  final IconData icon;
  final String label;
  final bool compact;
  final VoidCallback? onTap;

  const CenterNavButton({
    super.key,
    this.active = false,
    required this.size,
    required this.wide,
    required this.icon,
    required this.label,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: colors.glassGradient,
              border: Border.all(
                color: active ? colors.goldMid : colors.border,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow
                      .withValues(alpha: colors.isLight ? 0.22 : 0.8),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: colors.goldGlow.withValues(alpha: active ? 0.6 : 0.18),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: colors.isLight ? colors.icon : colors.textPrimary,
              size: wide ? 60 : (compact ? 29 : 42),
            ),
          ),
          SizedBox(height: wide ? 16 : (compact ? 5 : 9)),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: active ? colors.goldDark : colors.textTertiary,
              fontSize: wide ? 22 : (compact ? 13 : 15),
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
