import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';

/// The underlined tab row used to filter the talent carousel
/// (Available this week / Rising Stars / Top Rated / New Talents).
class TalentTabsBar extends StatelessWidget {
  final List<String> tabs;
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final double horizontalPadding;

  const TalentTabsBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    this.onTap,
    this.horizontalPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final wide = MediaQuery.sizeOf(context).width >= 700;

    return SizedBox(
      height: wide ? 70 : 54,
      child: Stack(
        children: [
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            bottom: 0,
            child: Container(
              height: 1,
              color: colors.border.withValues(alpha: 0.76),
            ),
          ),
          ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            itemCount: tabs.length,
            separatorBuilder: (_, __) => SizedBox(width: wide ? 100 : 44),
            itemBuilder: (context, index) {
              return _TalentTab(
                label: tabs[index],
                active: index == currentIndex,
                wide: wide,
                onTap: () => onTap?.call(index),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TalentTab extends StatelessWidget {
  final String label;
  final bool active;
  final bool wide;
  final VoidCallback? onTap;

  const _TalentTab({
    required this.label,
    required this.active,
    required this.wide,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final underlineWidth = wide ? 320.0 : 174.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            style: AppTextStyles.label.copyWith(
              color: active ? colors.goldDark : colors.textSecondary,
              fontSize: wide ? 30 : 19,
              fontWeight: active ? FontWeight.w900 : FontWeight.w700,
              letterSpacing: 0,
              shadows: active
                  ? [
                      Shadow(color: colors.goldGlow, blurRadius: 10),
                    ]
                  : null,
            ),
          ),
          SizedBox(height: wide ? 18 : 13),
          if (active)
            SizedBox(
              width: underlineWidth,
              height: wide ? 5 : 4,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: wide ? 10 : 8,
                    top: wide ? 1.5 : 1,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: wide ? 2.8 : 2.4,
                      decoration: BoxDecoration(
                        gradient: colors.goldGradient,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: colors.goldGlow,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: wide ? 9 : 7,
                      height: wide ? 9 : 7,
                      decoration: BoxDecoration(
                        color: colors.goldDark,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: colors.goldGlow, blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(height: wide ? 5 : 4),
        ],
      ),
    );
  }
}
