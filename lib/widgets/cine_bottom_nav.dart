import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Floating rounded bottom navigation bar with an elevated center Create button.
class CineBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const CineBottomNav({super.key, this.currentIndex = 1, this.onTap});

  @override
  Widget build(BuildContext context) {
    return PremiumBottomNavBar(currentIndex: currentIndex, onTap: onTap);
  }
}

class PremiumBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const PremiumBottomNavBar({
    super.key,
    this.currentIndex = 1,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 700;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final totalHeight = (wide ? 156.0 : 132.0) + bottomInset;
    final navHeight = (wide ? 126.0 : 108.0) + bottomInset;
    final createSize = wide ? 118.0 : 82.0;

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
                        left: wide ? 50 : 22,
                        right: wide ? 50 : 22,
                        top: wide ? 32 : 26,
                        child: Row(
                          children: [
                            Flexible(
                              child: BottomNavItem(
                                icon: Icons.home_outlined,
                                label: 'Home',
                                active: currentIndex == 0,
                                onTap: () => onTap?.call(0),
                                wide: wide,
                              ),
                            ),
                            Flexible(
                              child: BottomNavItem(
                                icon: Icons.search_rounded,
                                label: 'Discover',
                                active: currentIndex == 1,
                                onTap: () => onTap?.call(1),
                                wide: wide,
                              ),
                            ),
                            SizedBox(width: wide ? 160 : 92),
                            Flexible(
                              child: BottomNavItem(
                                icon: Icons.work_outline_rounded,
                                label: 'Bookings',
                                active: currentIndex == 3,
                                onTap: () => onTap?.call(3),
                                wide: wide,
                              ),
                            ),
                            Flexible(
                              child: BottomNavItem(
                                icon: Icons.person_outline_rounded,
                                label: 'Profile',
                                active: currentIndex == 4,
                                onTap: () => onTap?.call(4),
                                wide: wide,
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
            child: CenterCreateButton(
              active: currentIndex == 2,
              size: createSize,
              wide: wide,
              onTap: () => onTap?.call(2),
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

  const BottomNavItem({
    super.key,
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = active ? colors.goldDark : colors.textTertiary;
    final iconSize = wide ? 42.0 : 29.0;
    final labelSize = wide ? 22.0 : 14.5;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: wide ? 76 : 46,
            height: wide ? 52 : 34,
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
          SizedBox(height: wide ? 10 : 7),
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
          SizedBox(height: wide ? 12 : 7),
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

class CenterCreateButton extends StatelessWidget {
  final bool active;
  final double size;
  final bool wide;
  final VoidCallback? onTap;

  const CenterCreateButton({
    super.key,
    this.active = false,
    required this.size,
    required this.wide,
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
              Icons.add_rounded,
              color: colors.isLight ? colors.icon : colors.textPrimary,
              size: wide ? 60 : 42,
            ),
          ),
          SizedBox(height: wide ? 16 : 9),
          Text(
            'Create',
            style: AppTextStyles.caption.copyWith(
              color: active ? colors.goldDark : colors.textTertiary,
              fontSize: wide ? 22 : 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
