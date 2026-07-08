import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/talent.dart';
import 'portrait_image.dart';

/// Small portrait card used in the horizontal talent carousel.
class TalentCarouselCard extends StatelessWidget {
  final Talent talent;
  final bool active;

  const TalentCarouselCard({
    super.key,
    required this.talent,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return TalentMiniCard(talent: talent, isSelected: active);
  }
}

class TalentMiniCard extends StatelessWidget {
  final Talent talent;
  final bool isSelected;

  const TalentMiniCard({
    super.key,
    required this.talent,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 700;
    final cardWidth = wide ? 258.0 : 164.0;
    final cardHeight = wide ? 365.0 : 230.0;

    if (colors.isLight) {
      return _LightTalentMiniCard(
        talent: talent,
        isSelected: isSelected,
        width: cardWidth,
        height: cardHeight,
        wide: wide,
      );
    }

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(wide ? 22 : 20),
          border: Border.all(
            color: isSelected
                ? _LowerPalette.goldLight.withValues(alpha: 0.92)
                : _LowerPalette.glassBorder,
            width: isSelected ? 1.35 : 1,
          ),
          boxShadow: [
            const BoxShadow(
              color: Color(0x8C000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
            if (isSelected)
              const BoxShadow(
                color: Color(0x47C88A1E),
                blurRadius: 20,
                spreadRadius: 1,
              ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: isSelected ? 0.05 : 0.22),
                  BlendMode.darken,
                ),
                child: PortraitImage(asset: talent.imageAsset),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x08000000),
                      Color(0x16000000),
                      Color(0x72000000),
                      Color(0xEA050607),
                    ],
                    stops: [0.0, 0.42, 0.68, 1.0],
                  ),
                ),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, -0.22),
                    radius: 0.92,
                    colors: [
                      Color(0x00000000),
                      Color(0x1A000000),
                      Color(0x7A000000),
                    ],
                    stops: [0.0, 0.64, 1.0],
                  ),
                ),
              ),
            ),
            if (talent.available)
              Positioned(
                top: wide ? 24 : 14,
                right: wide ? 22 : 14,
                child: _OnlineDot(size: wide ? 20 : 15),
              ),
            Positioned(
              left: wide ? 24 : 14,
              right: wide ? 18 : 12,
              bottom: wide ? 22 : 16,
              child: _TalentMiniCardCopy(talent: talent, wide: wide),
            ),
          ],
        ),
      ),
    );
  }
}

class _LightTalentMiniCard extends StatelessWidget {
  final Talent talent;
  final bool isSelected;
  final double width;
  final double height;
  final bool wide;

  const _LightTalentMiniCard({
    required this.talent,
    required this.isSelected,
    required this.width,
    required this.height,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          gradient: colors.cardGradient,
          borderRadius: BorderRadius.circular(wide ? 22 : 18),
          border: Border.all(
            color: isSelected ? colors.goldLight : colors.border,
            width: isSelected ? 1.25 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
            if (isSelected)
              BoxShadow(
                color: colors.goldGlow,
                blurRadius: 18,
                spreadRadius: -4,
              ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: PortraitImage(asset: talent.imageAsset)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.72),
                      Colors.white.withValues(alpha: 0.98),
                    ],
                    stops: const [0.0, 0.48, 0.73, 1.0],
                  ),
                ),
              ),
            ),
            if (talent.available)
              Positioned(
                top: wide ? 24 : 14,
                right: wide ? 22 : 14,
                child: _OnlineDot(size: wide ? 20 : 15),
              ),
            Positioned(
              left: wide ? 24 : 14,
              right: wide ? 18 : 12,
              bottom: wide ? 22 : 16,
              child: _LightTalentMiniCardCopy(talent: talent, wide: wide),
            ),
          ],
        ),
      ),
    );
  }
}

class _LightTalentMiniCardCopy extends StatelessWidget {
  final Talent talent;
  final bool wide;

  const _LightTalentMiniCardCopy({required this.talent, required this.wide});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          talent.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.label.copyWith(
            color: colors.textPrimary,
            fontSize: wide ? 24 : 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: wide ? 12 : 8),
        Text(
          'Rs ${_formatCurrency(talent.ratePerDay)}/day',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(
            color: colors.textSecondary,
            fontSize: wide ? 21 : 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: wide ? 12 : 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: wide ? 27 : 18,
              color: colors.goldMid,
            ),
            SizedBox(width: wide ? 8 : 5),
            Text(
              talent.rating.toStringAsFixed(1),
              style: AppTextStyles.caption.copyWith(
                color: colors.textPrimary,
                fontSize: wide ? 21 : 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TalentMiniCardCopy extends StatelessWidget {
  final Talent talent;
  final bool wide;

  const _TalentMiniCardCopy({required this.talent, required this.wide});

  @override
  Widget build(BuildContext context) {
    final shadow = const [
      Shadow(color: Color(0xE0000000), blurRadius: 10),
      Shadow(color: Color(0xAA000000), blurRadius: 4),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          talent.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.label.copyWith(
            color: _LowerPalette.whiteText,
            fontSize: wide ? 24 : 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            shadows: shadow,
          ),
        ),
        SizedBox(height: wide ? 12 : 8),
        Text(
          'Rs ${_formatCurrency(talent.ratePerDay)}/day',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(
            color: _LowerPalette.mutedText,
            fontSize: wide ? 21 : 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            shadows: shadow,
          ),
        ),
        SizedBox(height: wide ? 12 : 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: wide ? 27 : 18,
              color: _LowerPalette.goldLight,
              shadows: const [
                Shadow(color: Color(0x80C88A1E), blurRadius: 8),
              ],
            ),
            SizedBox(width: wide ? 8 : 5),
            Text(
              talent.rating.toStringAsFixed(1),
              style: AppTextStyles.caption.copyWith(
                color: _LowerPalette.whiteText,
                fontSize: wide ? 21 : 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                shadows: shadow,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OnlineDot extends StatelessWidget {
  final double size;

  const _OnlineDot({required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.success,
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.isLight ? Colors.white : const Color(0xFF09100D),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
              color: colors.success.withValues(alpha: 0.5), blurRadius: 10),
        ],
      ),
    );
  }
}

class _LowerPalette {
  const _LowerPalette._();

  static const Color glassBorder = Color(0xFF252A2F);
  static const Color goldLight = Color(0xFFF4C76A);
  static const Color whiteText = Color(0xFFF7F3EA);
  static const Color mutedText = Color(0xFF9E9992);
}

String _formatCurrency(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
