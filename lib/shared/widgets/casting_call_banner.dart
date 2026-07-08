import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';

/// "Looking for the perfect match?" casting-call promo banner.
class CastingCallBanner extends StatelessWidget {
  final double horizontalPadding;

  const CastingCallBanner({super.key, this.horizontalPadding = 16});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 700;
    final height = wide ? 110.0 : 104.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: height,
            padding: EdgeInsets.symmetric(
              horizontal: wide ? 28 : 18,
              vertical: wide ? 18 : 16,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: colors.cardGradient,
              border: Border.all(
                color: colors.border,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(
                    alpha: colors.isLight ? 0.23 : 0.45,
                  ),
                  blurRadius: 22,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                _CastingIcon(size: wide ? 66 : 54),
                SizedBox(width: wide ? 28 : 14),
                Expanded(child: _CastingCopy(wide: wide)),
                SizedBox(width: wide ? 22 : 12),
                GoldOutlinedButton(
                  label: 'Create Casting Call',
                  height: wide ? 54 : 48,
                  compact: !wide,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CastingIcon extends StatelessWidget {
  final double size;

  const _CastingIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.isLight ? colors.surface : const Color(0x16000000),
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(
          color: colors.goldMid.withValues(alpha: 0.78),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.goldGlow,
            blurRadius: 14,
            spreadRadius: -3,
          ),
        ],
      ),
      child: Icon(
        Icons.movie_creation_outlined,
        color: colors.goldDark,
        size: size * 0.58,
      ),
    );
  }
}

class _CastingCopy extends StatelessWidget {
  final bool wide;

  const _CastingCopy({required this.wide});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Looking for the perfect match?',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.heading.copyWith(
            color: colors.textPrimary,
            fontSize: wide ? 24 : 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            shadows: colors.isLight
                ? null
                : const [
                    Shadow(color: Color(0xD0000000), blurRadius: 8),
                  ],
          ),
        ),
        SizedBox(height: wide ? 8 : 6),
        Text(
          'Post your casting call and get responses.',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMuted.copyWith(
            color: colors.textSecondary,
            fontSize: wide ? 16 : 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class GoldOutlinedButton extends StatelessWidget {
  final String label;
  final double height;
  final bool compact;
  final VoidCallback? onTap;

  const GoldOutlinedButton({
    super.key,
    required this.label,
    this.height = 52,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24),
        constraints: BoxConstraints(maxWidth: compact ? 174 : 280),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          gradient: colors.glassGradient,
          border: Border.all(
            color: colors.goldMid.withValues(alpha: 0.92),
            width: 1.15,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.goldGlow,
              blurRadius: 16,
              spreadRadius: -4,
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                style: AppTextStyles.label.copyWith(
                  color: colors.goldDark,
                  fontSize: compact ? 15 : 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(width: compact ? 10 : 14),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.goldDark,
                size: compact ? 22 : 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
