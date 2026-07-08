import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import 'glass_card.dart';

/// The CineConnect search bar: glass pill with search icon, hint
/// text, and a trailing gold filter button.
class PremiumSearchBar extends StatelessWidget {
  final double horizontalPadding;
  final String placeholder;

  const PremiumSearchBar({
    super.key,
    required this.horizontalPadding,
    this.placeholder = 'Search actors, models, directors...',
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final width = MediaQuery.sizeOf(context).width;
    final tablet = width >= 700;
    final height = tablet ? 76.0 : 64.0;
    final radius = tablet ? 32.0 : 29.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: GlassContainer(
        width: double.infinity,
        height: height,
        radius: radius,
        blur: 22,
        padding: EdgeInsets.zero,
        gradient: colors.searchGradient,
        borderColor: colors.border,
        borderWidth: 1.2,
        shadows: [
          BoxShadow(
            color:
                colors.shadow.withValues(alpha: colors.isLight ? 0.42 : 0.55),
            blurRadius: colors.isLight ? 26 : 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color:
                colors.goldGlow.withValues(alpha: colors.isLight ? 0.38 : 0.5),
            blurRadius: 18,
            offset: const Offset(8, -4),
          ),
        ],
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white
                          .withValues(alpha: colors.isLight ? 0.18 : 0.07),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.52],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 18,
              width: tablet ? 132 : 86,
              height: 1.1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.goldLight.withValues(alpha: 0),
                      colors.goldLight
                          .withValues(alpha: colors.isLight ? 0.28 : 0.54),
                      colors.goldLight.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                tablet ? 28 : 18,
                0,
                tablet ? 12 : 8,
                0,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: tablet ? 38 : 32,
                    color: colors.iconMuted,
                  ),
                  SizedBox(width: tablet ? 18 : 14),
                  Expanded(
                    child: Text(
                      placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMuted.copyWith(
                        color: colors.textSecondary,
                        fontSize: tablet ? 24 : 19,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  SizedBox(width: tablet ? 16 : 10),
                  GoldIconButton(
                    icon: Icons.tune_rounded,
                    size: tablet ? 58 : 48,
                    iconSize: tablet ? 32 : 26,
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

class GoldIconButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final VoidCallback? onTap;

  const GoldIconButton({
    super.key,
    required this.icon,
    this.size = 48,
    this.iconSize = 25,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: colors.glassGradient,
          borderRadius: BorderRadius.circular(size * 0.36),
          border: Border.all(
            color: colors.goldMid.withValues(alpha: 0.72),
            width: 1.05,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.goldGlow,
              blurRadius: 18,
              spreadRadius: -4,
            ),
            BoxShadow(
              color:
                  colors.shadow.withValues(alpha: colors.isLight ? 0.26 : 0.55),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Icon(icon, color: colors.goldMid, size: iconSize),
      ),
    );
  }
}
