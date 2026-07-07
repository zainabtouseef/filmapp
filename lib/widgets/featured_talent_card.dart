import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/talent.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// The large premium featured-talent card.
class FeaturedTalentCard extends StatelessWidget {
  final Talent talent;

  const FeaturedTalentCard({super.key, required this.talent});

  static const double _radius = 28;
  static const double _borderWidth = 1.2;

  @override
  Widget build(BuildContext context) {
    if (context.appColors.isLight) {
      return _LightFeaturedTalentCard(talent: talent);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final fallbackWidth = MediaQuery.sizeOf(context).width - 32;
        final cardWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : fallbackWidth;
        final compact = cardWidth < 390;
        final innerRadius = (_radius - _borderWidth).clamp(0, _radius);

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            boxShadow: const [
              BoxShadow(
                color: Color(0xAA000000),
                blurRadius: 34,
                spreadRadius: -10,
                offset: Offset(0, 18),
              ),
              BoxShadow(
                color: Color(0x40C88A1E),
                blurRadius: 26,
                spreadRadius: -8,
                offset: Offset(0, 8),
              ),
              BoxShadow(
                color: Color(0x24F4C76A),
                blurRadius: 18,
                spreadRadius: -10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: _TalentPalette.goldStrokeGradient,
              ),
              child: Padding(
                padding: const EdgeInsets.all(_borderWidth),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(innerRadius.toDouble()),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Stack(
                      children: [
                        const Positioned.fill(child: _CardBackgroundLayer()),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _TopArea(talent: talent, cardWidth: cardWidth),
                            TrustBadgesStrip(compact: compact),
                            _ActionButtons(compact: compact),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LightFeaturedTalentCard extends StatelessWidget {
  final Talent talent;

  const _LightFeaturedTalentCard({required this.talent});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fallbackWidth = MediaQuery.sizeOf(context).width - 32;
        final cardWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : fallbackWidth;
        final wide = cardWidth >= 720;
        final compact = cardWidth < 390;
        final portraitWidth = (cardWidth * (wide ? 0.49 : 0.47))
            .clamp(cardWidth * 0.38, cardWidth * 0.52)
            .toDouble();

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: colors.cardGradient,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.22),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: colors.goldGlow.withValues(alpha: 0.18),
                blurRadius: 20,
                spreadRadius: -8,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: portraitWidth,
                      child: _LightFeaturedPortrait(
                        talent: talent,
                        compact: compact,
                        wide: wide,
                      ),
                    ),
                    Expanded(
                      child: _LightFeaturedDetails(
                        talent: talent,
                        cardWidth: cardWidth,
                        infoWidth: cardWidth - portraitWidth,
                      ),
                    ),
                  ],
                ),
              ),
              _LightTrustBadgesStrip(compact: compact),
              _LightActionButtons(compact: compact),
            ],
          ),
        );
      },
    );
  }
}

class _LightFeaturedPortrait extends StatelessWidget {
  final Talent talent;
  final bool compact;
  final bool wide;

  const _LightFeaturedPortrait({
    required this.talent,
    required this.compact,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Stack(
      fit: StackFit.expand,
      children: [
        PortraitImage(asset: talent.imageAsset),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: 0.58),
                  Colors.white,
                ],
                stops: const [0.0, 0.55, 0.86, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.5),
                  Colors.white.withValues(alpha: 0.9),
                ],
                stops: const [0.0, 0.56, 0.82, 1.0],
              ),
            ),
          ),
        ),
        if (talent.available)
          Positioned(
            top: wide ? 34 : 22,
            left: wide ? 36 : (compact ? 16 : 24),
            child: _LightAvailableBadge(compact: compact),
          ),
        Positioned(
          left: wide ? 38 : (compact ? 16 : 24),
          right: compact ? 12 : 18,
          bottom: wide ? 34 : 24,
          child: _LightShowreelButton(compact: compact, wide: wide),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: wide ? 70 : 42,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, colors.card],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LightShowreelButton extends StatelessWidget {
  final bool compact;
  final bool wide;

  const _LightShowreelButton({required this.compact, required this.wide});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final playSize = wide ? 74.0 : (compact ? 48.0 : 56.0);

    return Row(
      children: [
        Container(
          width: playSize,
          height: playSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.76),
            border: Border.all(color: Colors.white, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.24),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.play_arrow_rounded,
            color: colors.textPrimary,
            size: wide ? 42 : 32,
          ),
        ),
        SizedBox(width: wide ? 18 : 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Play Showreel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(
                  color: colors.textPrimary,
                  fontSize: wide ? 18 : 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '5:24',
                style: AppTextStyles.caption.copyWith(
                  fontSize: wide ? 15 : 12.5,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LightFeaturedDetails extends StatelessWidget {
  final Talent talent;
  final double infoWidth;
  final double cardWidth;

  const _LightFeaturedDetails({
    required this.talent,
    required this.infoWidth,
    required this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final compact = infoWidth < 215;
    final wide = cardWidth >= 720;
    final hPad = wide ? 34.0 : (compact ? 12.0 : 20.0);
    final topPad = wide ? 34.0 : (compact ? 20.0 : 24.0);
    final nameSize = _scale(cardWidth, compact ? 28 : 31, 52, 340, 920);

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, topPad, hPad, wide ? 22 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _LightVerifiedTalentBadge(compact: compact),
          ),
          SizedBox(height: wide ? 46 : (compact ? 30 : 36)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    talent.name,
                    maxLines: 1,
                    style: AppTextStyles.heading.copyWith(
                      color: colors.textPrimary,
                      fontSize: nameSize,
                      fontWeight: FontWeight.w800,
                      height: 1.02,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
              if (talent.verified) ...[
                SizedBox(width: wide ? 16 : 9),
                _VerifiedCheck(size: wide ? 34 : 23),
              ],
            ],
          ),
          SizedBox(height: wide ? 12 : 8),
          Text(
            talent.role,
            maxLines: compact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMuted.copyWith(
              color: colors.textSecondary,
              fontSize: _scale(cardWidth, compact ? 14 : 15, 18, 340, 920),
              height: 1.28,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: wide ? 28 : 22),
          Wrap(
            spacing: wide ? 16 : 10,
            runSpacing: 10,
            children: talent.tags
                .map(
                  (tag) => _LightPillChip(
                    label: tag,
                    fontSize:
                        _scale(cardWidth, compact ? 12.5 : 13.5, 16, 340, 920),
                    compact: compact,
                  ),
                )
                .toList(),
          ),
          SizedBox(height: wide ? 40 : 30),
          _LightGoldPrice(
            amount: talent.ratePerDay,
            fontSize: _scale(cardWidth, compact ? 29 : 32, 40, 340, 920),
          ),
          SizedBox(height: wide ? 20 : 11),
          Wrap(
            spacing: wide ? 22 : 14,
            runSpacing: 9,
            children: [
              _LightTalentInfoRow(
                icon: Icons.sell_outlined,
                label: 'Negotiable',
                iconColor: colors.goldDark,
              ),
              _LightTalentInfoRow(
                icon: Icons.bolt_rounded,
                label: 'Responds in 2h',
                iconColor: colors.goldMid,
              ),
            ],
          ),
          SizedBox(height: wide ? 22 : 16),
          _LightRatingBookingRow(
            rating: talent.rating,
            reviews: talent.reviews,
            bookings: talent.bookings,
            compact: compact,
            wide: wide,
          ),
          SizedBox(height: wide ? 26 : 18),
          _LightPortfolioThumbnails(
            imageAsset: talent.imageAsset,
            infoWidth: infoWidth,
            wide: wide,
          ),
        ],
      ),
    );
  }
}

class _LightGoldPrice extends StatelessWidget {
  final int amount;
  final double fontSize;

  const _LightGoldPrice({required this.amount, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return FittedBox(
      alignment: Alignment.centerLeft,
      fit: BoxFit.scaleDown,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'Rs ${_formatCurrency(amount)}'),
            TextSpan(
              text: ' / day',
              style: TextStyle(
                fontSize: fontSize * 0.66,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        maxLines: 1,
        style: AppTextStyles.price.copyWith(
          color: colors.goldDark,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          height: 1,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _LightRatingBookingRow extends StatelessWidget {
  final double rating;
  final int reviews;
  final int bookings;
  final bool compact;
  final bool wide;

  const _LightRatingBookingRow({
    required this.rating,
    required this.reviews,
    required this.bookings,
    required this.compact,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fontSize = wide ? 16.5 : (compact ? 13.0 : 14.0);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: wide ? 8 : 5,
      runSpacing: 8,
      children: [
        Icon(Icons.star_rounded, size: wide ? 27 : 20, color: colors.goldMid),
        Text(
          rating.toStringAsFixed(1),
          style: AppTextStyles.label.copyWith(
            color: colors.textPrimary,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          '($reviews reviews)',
          style: AppTextStyles.caption.copyWith(
            color: colors.textSecondary,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          ' · ',
          style: AppTextStyles.caption.copyWith(
            color: colors.textTertiary,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          '$bookings bookings',
          style: AppTextStyles.caption.copyWith(
            color: colors.textSecondary,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LightPortfolioThumbnails extends StatelessWidget {
  final String imageAsset;
  final double infoWidth;
  final bool wide;

  const _LightPortfolioThumbnails({
    required this.imageAsset,
    required this.infoWidth,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    final thumbSize = wide ? 58.0 : (infoWidth < 220 ? 36.0 : 44.0);
    final gap = wide ? 12.0 : 6.0;
    final maxItemsPerRow = infoWidth < 220 ? 3 : 4;

    return SizedBox(
      height: thumbSize,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : infoWidth;
          final itemWidth = thumbSize + gap;
          final count = availableWidth < (itemWidth * 4) ? maxItemsPerRow : 4;
          final children = <Widget>[];

          for (var i = 0; i < count; i++) {
            if (i > 0) {
              children.add(SizedBox(width: gap));
            }
            children.add(
              _LightThumbnailBox(
                asset: imageAsset,
                size: thumbSize,
                play: i == 0,
                child: i == count - 1 && count < 4
                    ? _LightMorePhotos(size: thumbSize)
                    : null,
              ),
            );
          }

          return Row(mainAxisSize: MainAxisSize.min, children: children);
        },
      ),
    );
  }
}

class _LightMorePhotos extends StatelessWidget {
  final double size;

  const _LightMorePhotos({required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+12',
                style: AppTextStyles.label.copyWith(
                  color: colors.textPrimary,
                  fontSize: size * 0.32,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Photos',
                style: AppTextStyles.micro.copyWith(
                  color: colors.goldDark,
                  fontSize: size * 0.18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LightTrustBadgesStrip extends StatelessWidget {
  final bool compact;

  const _LightTrustBadgesStrip({required this.compact});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final margin = compact ? 14.0 : 22.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(margin, compact ? 12 : 16, margin, 0),
      child: Container(
        height: compact ? 78 : 74,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Row(
          children: [
            _LightTrustBadgeItem(
              icon: Icons.shield_outlined,
              firstLine: 'Escrow',
              secondLine: 'Protected',
              color: colors.success,
            ),
            _LightTrustDivider(color: colors.border),
            _LightTrustBadgeItem(
              icon: Icons.description_outlined,
              firstLine: 'Contract',
              secondLine: 'Ready',
              color: colors.infoBlue,
            ),
            _LightTrustDivider(color: colors.border),
            _LightTrustBadgeItem(
              icon: Icons.lock_outline_rounded,
              firstLine: 'Secure',
              secondLine: 'Payments',
              color: colors.infoPurple,
            ),
            _LightTrustDivider(color: colors.border),
            _LightTrustBadgeItem(
              icon: Icons.verified_outlined,
              firstLine: 'Super Admin',
              secondLine: 'Verified',
              color: colors.goldDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _LightActionButtons extends StatelessWidget {
  final bool compact;

  const _LightActionButtons({required this.compact});

  @override
  Widget build(BuildContext context) {
    final margin = compact ? 14.0 : 22.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(margin, compact ? 18 : 22, margin, 22),
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: DarkOutlineButton(
              icon: Icons.bookmark_border_rounded,
              label: 'Add to Shortlist',
              compact: compact,
            ),
          ),
          SizedBox(width: compact ? 14 : 16),
          Expanded(
            flex: 12,
            child: GoldGradientButton(
              icon: Icons.near_me_outlined,
              label: 'Request Booking',
              compact: compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _LightAvailableBadge extends StatelessWidget {
  final bool compact;

  const _LightAvailableBadge({required this.compact});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 11 : 13,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: colors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.success.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusDot(color: colors.success),
          const SizedBox(width: 8),
          Text(
            'AVAILABLE',
            style: AppTextStyles.micro.copyWith(
              color: const Color(0xFF14975A),
              fontSize: compact ? 10.5 : 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _LightVerifiedTalentBadge extends StatelessWidget {
  final bool compact;

  const _LightVerifiedTalentBadge({required this.compact});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: compact ? 17 : 22,
            color: colors.goldDark,
          ),
          SizedBox(width: compact ? 7 : 10),
          Text(
            'VERIFIED TALENT',
            style: AppTextStyles.micro.copyWith(
              color: colors.goldDark,
              fontSize: compact ? 11 : 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _LightPillChip extends StatelessWidget {
  final String label;
  final double fontSize;
  final bool compact;

  const _LightPillChip({
    required this.label,
    required this.fontSize,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 13 : 16,
        vertical: compact ? 8 : 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: AppTextStyles.label.copyWith(
          color: colors.textPrimary,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _LightTalentInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _LightTalentInfoRow({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 7),
        Text(
          label,
          maxLines: 1,
          style: AppTextStyles.caption.copyWith(
            color: colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _LightThumbnailBox extends StatelessWidget {
  final String asset;
  final double size;
  final bool play;
  final Widget? child;

  const _LightThumbnailBox({
    required this.asset,
    required this.size,
    this.play = false,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size >= 56 ? 12 : 9),
        border: Border.all(
          color: play ? colors.goldLight : colors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (child == null) PortraitImage(asset: asset),
          if (child != null) child!,
          if (play) ...[
            const ColoredBox(color: Color(0x33000000)),
            Center(
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: size * 0.55,
                shadows: const [
                  Shadow(color: Colors.black, blurRadius: 8),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LightTrustBadgeItem extends StatelessWidget {
  final IconData icon;
  final String firstLine;
  final String secondLine;
  final Color color;

  const _LightTrustBadgeItem({
    required this.icon,
    required this.firstLine,
    required this.secondLine,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 94;
          final text = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                narrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Text(
                firstLine,
                maxLines: 1,
                style: AppTextStyles.micro.copyWith(
                  color: colors.textPrimary,
                  fontSize: narrow ? 10.5 : 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                  height: 1.1,
                ),
              ),
              Text(
                secondLine,
                maxLines: 1,
                style: AppTextStyles.micro.copyWith(
                  color: colors.textPrimary,
                  fontSize: narrow ? 10.5 : 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                  height: 1.1,
                ),
              ),
            ],
          );

          if (narrow) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22, color: color),
                  const SizedBox(height: 6),
                  FittedBox(fit: BoxFit.scaleDown, child: text),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 26, color: color),
                const SizedBox(width: 10),
                Flexible(child: text),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LightTrustDivider extends StatelessWidget {
  final Color color;

  const _LightTrustDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: color);
  }
}

class _TopArea extends StatelessWidget {
  final Talent talent;
  final double cardWidth;

  const _TopArea({required this.talent, required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    final wide = cardWidth >= 720;
    final minPortraitWidth = cardWidth < 360 ? 142.0 : 154.0;
    final maxPortraitWidth = cardWidth * 0.52;
    final effectiveMinPortraitWidth = minPortraitWidth > maxPortraitWidth
        ? maxPortraitWidth
        : minPortraitWidth;
    final portraitWidth = (cardWidth * (wide ? 0.49 : 0.47))
        .clamp(effectiveMinPortraitWidth, maxPortraitWidth)
        .toDouble();
    final infoWidth = (cardWidth - portraitWidth).clamp(0.0, cardWidth);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: portraitWidth,
            child: _TalentPortrait(
              talent: talent,
              compact: cardWidth < 390,
              wide: wide,
            ),
          ),
          Expanded(
            child: _TalentDetails(
              talent: talent,
              infoWidth: infoWidth.toDouble(),
              cardWidth: cardWidth,
            ),
          ),
        ],
      ),
    );
  }
}

class _TalentPortrait extends StatelessWidget {
  final Talent talent;
  final bool compact;
  final bool wide;

  const _TalentPortrait({
    required this.talent,
    required this.compact,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PortraitImage(asset: talent.imageAsset),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  Color(0x00000000),
                  Color(0xB005080B),
                  Color(0xF505080B),
                ],
                stops: [0.0, 0.58, 0.86, 1.0],
              ),
            ),
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
                  Color(0x12000000),
                  Color(0x72000000),
                  Color(0xDD050607),
                ],
                stops: [0.0, 0.48, 0.76, 1.0],
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.28, -0.02),
                radius: 0.9,
                colors: [
                  Color(0x00000000),
                  Color(0x18000000),
                  Color(0x88000000),
                ],
                stops: [0.0, 0.58, 1.0],
              ),
            ),
          ),
        ),
        if (talent.available)
          Positioned(
            top: wide ? 34 : 26,
            left: wide ? 36 : (compact ? 18 : 24),
            child: AvailableBadge(compact: compact),
          ),
        Positioned(
          left: wide ? 38 : (compact ? 18 : 24),
          right: compact ? 12 : 18,
          bottom: wide ? 34 : 24,
          child: _ShowreelButton(compact: compact, wide: wide),
        ),
      ],
    );
  }
}

class _ShowreelButton extends StatelessWidget {
  final bool compact;
  final bool wide;

  const _ShowreelButton({required this.compact, required this.wide});

  @override
  Widget build(BuildContext context) {
    final playSize = wide ? 74.0 : (compact ? 48.0 : 56.0);

    return Row(
      children: [
        Container(
          width: playSize,
          height: playSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x421E2428), Color(0x98050709)],
            ),
            border: Border.all(
              color: _TalentPalette.goldLight.withValues(alpha: 0.9),
              width: 1.3,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
              BoxShadow(color: Color(0x33C88A1E), blurRadius: 20),
            ],
          ),
          child: Icon(
            Icons.play_arrow_rounded,
            color: _TalentPalette.cream,
            size: wide ? 42 : 32,
          ),
        ),
        SizedBox(width: wide ? 18 : 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Play Showreel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(
                  color: _TalentPalette.whiteText,
                  fontSize: wide ? 18 : 15,
                  fontWeight: FontWeight.w800,
                  shadows: const [
                    Shadow(color: Colors.black, blurRadius: 12),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '5:24',
                style: AppTextStyles.caption.copyWith(
                  fontSize: wide ? 15 : 12.5,
                  color: _TalentPalette.mutedText,
                  fontWeight: FontWeight.w700,
                  shadows: const [
                    Shadow(color: Colors.black, blurRadius: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TalentDetails extends StatelessWidget {
  final Talent talent;
  final double infoWidth;
  final double cardWidth;

  const _TalentDetails({
    required this.talent,
    required this.infoWidth,
    required this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    final compact = infoWidth < 215;
    final wide = cardWidth >= 720;
    final hPad = wide ? 34.0 : (compact ? 14.0 : 20.0);
    final topPad = wide ? 34.0 : (compact ? 20.0 : 24.0);
    final bottomPad = wide ? 22.0 : 18.0;
    final nameSize = _scale(cardWidth, compact ? 28 : 31, 52, 340, 920);
    final subtitleSize = _scale(cardWidth, compact ? 14 : 15, 18, 340, 920);
    final chipFontSize = _scale(cardWidth, compact ? 12.5 : 13.5, 16, 340, 920);
    final detailGap = wide ? 20.0 : 11.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, topPad, hPad, bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: VerifiedTalentBadge(compact: compact),
          ),
          SizedBox(height: wide ? 46 : (compact ? 30 : 36)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    talent.name,
                    maxLines: 1,
                    style: AppTextStyles.heading.copyWith(
                      color: _TalentPalette.whiteText,
                      fontSize: nameSize,
                      fontWeight: FontWeight.w800,
                      height: 1.02,
                      letterSpacing: 0,
                      shadows: const [
                        Shadow(color: Color(0xB0000000), blurRadius: 12),
                      ],
                    ),
                  ),
                ),
              ),
              if (talent.verified) ...[
                SizedBox(width: wide ? 16 : 9),
                _VerifiedCheck(size: wide ? 34 : 23),
              ],
            ],
          ),
          SizedBox(height: wide ? 12 : 8),
          Text(
            talent.role,
            maxLines: compact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMuted.copyWith(
              color: _TalentPalette.mutedText,
              fontSize: subtitleSize,
              height: 1.28,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: wide ? 28 : 22),
          Wrap(
            spacing: wide ? 16 : 10,
            runSpacing: 10,
            children: talent.tags
                .map(
                  (tag) => GlassPillChip(
                    label: tag,
                    fontSize: chipFontSize,
                    compact: compact,
                  ),
                )
                .toList(),
          ),
          SizedBox(height: wide ? 40 : 30),
          _GoldPrice(
            amount: talent.ratePerDay,
            fontSize: _scale(cardWidth, compact ? 29 : 32, 40, 340, 920),
          ),
          SizedBox(height: detailGap),
          Wrap(
            spacing: wide ? 22 : 14,
            runSpacing: 9,
            children: const [
              TalentInfoRow(
                icon: Icons.sell_outlined,
                label: 'Negotiable',
                iconColor: _TalentPalette.goldDark,
              ),
              TalentInfoRow(
                icon: Icons.bolt_rounded,
                label: 'Responds in 2h',
                iconColor: _TalentPalette.goldLight,
              ),
            ],
          ),
          SizedBox(height: wide ? 22 : 16),
          _RatingBookingRow(
            rating: talent.rating,
            reviews: talent.reviews,
            bookings: talent.bookings,
            compact: compact,
            wide: wide,
          ),
          SizedBox(height: wide ? 26 : 18),
          _PortfolioThumbnails(
            imageAsset: talent.imageAsset,
            infoWidth: infoWidth,
            wide: wide,
          ),
        ],
      ),
    );
  }
}

class _GoldPrice extends StatelessWidget {
  final int amount;
  final double fontSize;

  const _GoldPrice({required this.amount, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) =>
          _TalentPalette.goldButtonGradient.createShader(bounds),
      child: FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.scaleDown,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Rs ${_formatCurrency(amount)}'),
              TextSpan(
                text: ' / day',
                style: TextStyle(
                  fontSize: fontSize * 0.66,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          maxLines: 1,
          style: AppTextStyles.price.copyWith(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _RatingBookingRow extends StatelessWidget {
  final double rating;
  final int reviews;
  final int bookings;
  final bool compact;
  final bool wide;

  const _RatingBookingRow({
    required this.rating,
    required this.reviews,
    required this.bookings,
    required this.compact,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = wide ? 16.5 : (compact ? 13.0 : 14.0);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: wide ? 8 : 5,
      runSpacing: 8,
      children: [
        Icon(
          Icons.star_rounded,
          size: wide ? 27 : 20,
          color: _TalentPalette.goldLight,
          shadows: const [
            Shadow(color: Color(0x66C88A1E), blurRadius: 9),
          ],
        ),
        Text(
          rating.toStringAsFixed(1),
          style: AppTextStyles.label.copyWith(
            color: _TalentPalette.whiteText,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          '($reviews reviews)',
          style: AppTextStyles.caption.copyWith(
            color: _TalentPalette.mutedText,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          ' · ',
          style: AppTextStyles.caption.copyWith(
            color: _TalentPalette.textDim,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          '$bookings bookings',
          style: AppTextStyles.caption.copyWith(
            color: _TalentPalette.mutedText,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PortfolioThumbnails extends StatelessWidget {
  final String imageAsset;
  final double infoWidth;
  final bool wide;

  const _PortfolioThumbnails({
    required this.imageAsset,
    required this.infoWidth,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    final thumbSize = wide ? 58.0 : (infoWidth < 220 ? 40.0 : 48.0);
    final gap = wide ? 12.0 : 7.0;

    return SizedBox(
      height: thumbSize,
      child: Row(
        children: [
          ThumbnailBox(asset: imageAsset, size: thumbSize, play: true),
          SizedBox(width: gap),
          ThumbnailBox(asset: imageAsset, size: thumbSize),
          SizedBox(width: gap),
          ThumbnailBox(asset: imageAsset, size: thumbSize),
          SizedBox(width: gap),
          ThumbnailBox(
            asset: imageAsset,
            size: thumbSize,
            child: _MorePhotos(size: thumbSize),
          ),
        ],
      ),
    );
  }
}

class _MorePhotos extends StatelessWidget {
  final double size;

  const _MorePhotos({required this.size});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x7A10161D),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '+12',
                  style: AppTextStyles.label.copyWith(
                    color: _TalentPalette.whiteText,
                    fontSize: size * 0.32,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Photos',
                  style: AppTextStyles.micro.copyWith(
                    color: _TalentPalette.goldLight,
                    fontSize: size * 0.18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                    height: 1,
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

class TrustBadgesStrip extends StatelessWidget {
  final bool compact;

  const TrustBadgesStrip({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final margin = compact ? 14.0 : 22.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(margin, compact ? 12 : 16, margin, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: compact ? 78 : 74,
            decoration: BoxDecoration(
              color: const Color(0xA10A0F13),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF23282C), width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 18,
                  offset: Offset(0, 9),
                ),
                BoxShadow(
                  color: Color(0x16000000),
                  blurRadius: 2,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: const [
                TrustBadgeItem(
                  icon: Icons.shield_outlined,
                  firstLine: 'Escrow',
                  secondLine: 'Protected',
                  color: _TalentPalette.green,
                ),
                _TrustDivider(),
                TrustBadgeItem(
                  icon: Icons.description_outlined,
                  firstLine: 'Contract',
                  secondLine: 'Ready',
                  color: _TalentPalette.blue,
                ),
                _TrustDivider(),
                TrustBadgeItem(
                  icon: Icons.lock_outline_rounded,
                  firstLine: 'Secure',
                  secondLine: 'Payments',
                  color: _TalentPalette.purple,
                ),
                _TrustDivider(),
                TrustBadgeItem(
                  icon: Icons.verified_outlined,
                  firstLine: 'Super Admin',
                  secondLine: 'Verified',
                  color: _TalentPalette.goldLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustDivider extends StatelessWidget {
  const _TrustDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: const Color(0x321C252C),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final bool compact;

  const _ActionButtons({required this.compact});

  @override
  Widget build(BuildContext context) {
    final margin = compact ? 14.0 : 22.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(margin, compact ? 18 : 22, margin, 22),
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: DarkOutlineButton(
              icon: Icons.bookmark_border_rounded,
              label: 'Add to Shortlist',
              compact: compact,
            ),
          ),
          SizedBox(width: compact ? 14 : 16),
          Expanded(
            flex: 12,
            child: GoldGradientButton(
              icon: Icons.near_me_outlined,
              label: 'Request Booking',
              compact: compact,
            ),
          ),
        ],
      ),
    );
  }
}

class GlassPillChip extends StatelessWidget {
  final String label;
  final double? fontSize;
  final bool compact;

  const GlassPillChip({
    super.key,
    required this.label,
    this.fontSize,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 13 : 16,
            vertical: compact ? 8 : 9,
          ),
          decoration: BoxDecoration(
            color: const Color(0x6112171D),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _TalentPalette.borderGrey, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3A000000),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
              BoxShadow(
                color: Color(0x12FFFFFF),
                blurRadius: 1,
                offset: Offset(0, -1),
              ),
            ],
          ),
          child: Text(
            label,
            maxLines: 1,
            style: AppTextStyles.label.copyWith(
              color: _TalentPalette.whiteText,
              fontSize: fontSize ?? 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class AvailableBadge extends StatelessWidget {
  final bool compact;

  const AvailableBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 11 : 13,
            vertical: compact ? 7 : 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xA00D251C),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0x2539E697), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x62000000),
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
              BoxShadow(color: Color(0x1A20D37A), blurRadius: 14),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _StatusDot(color: _TalentPalette.green),
              const SizedBox(width: 8),
              Text(
                'AVAILABLE',
                style: AppTextStyles.micro.copyWith(
                  color: _TalentPalette.green,
                  fontSize: compact ? 10.5 : 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VerifiedTalentBadge extends StatelessWidget {
  final bool compact;

  const VerifiedTalentBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: compact ? 17 : 22,
            color: _TalentPalette.goldLight,
          ),
          SizedBox(width: compact ? 7 : 10),
          Text(
            'VERIFIED TALENT',
            style: AppTextStyles.micro.copyWith(
              color: _TalentPalette.goldLight,
              fontSize: compact ? 11 : 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class TalentInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const TalentInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 7),
        Text(
          label,
          maxLines: 1,
          style: AppTextStyles.caption.copyWith(
            color: _TalentPalette.mutedText,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class ThumbnailBox extends StatelessWidget {
  final String asset;
  final double size;
  final bool play;
  final Widget? child;

  const ThumbnailBox({
    super.key,
    required this.asset,
    required this.size,
    this.play = false,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0x6310151B),
        borderRadius: BorderRadius.circular(size >= 56 ? 12 : 9),
        border: Border.all(
          color: play
              ? _TalentPalette.goldLight.withValues(alpha: 0.7)
              : const Color(0xFF2B3035),
          width: 1,
        ),
        boxShadow: [
          if (play) const BoxShadow(color: Color(0x22C88A1E), blurRadius: 12),
          const BoxShadow(
            color: Color(0x44000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (child == null) PortraitImage(asset: asset),
          if (child != null) child!,
          if (play) ...[
            const ColoredBox(color: Color(0x44000000)),
            Center(
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: size * 0.55,
                shadows: const [
                  Shadow(color: Colors.black, blurRadius: 8),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TrustBadgeItem extends StatelessWidget {
  final IconData icon;
  final String firstLine;
  final String secondLine;
  final Color color;

  const TrustBadgeItem({
    super.key,
    required this.icon,
    required this.firstLine,
    required this.secondLine,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 94;

          if (narrow) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22, color: color),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _TrustText(
                      firstLine: firstLine,
                      secondLine: secondLine,
                      fontSize: 10.5,
                      align: TextAlign.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 26, color: color),
                const SizedBox(width: 10),
                Flexible(
                  child: _TrustText(
                    firstLine: firstLine,
                    secondLine: secondLine,
                    fontSize: 13.5,
                    align: TextAlign.left,
                    crossAxisAlignment: CrossAxisAlignment.start,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TrustText extends StatelessWidget {
  final String firstLine;
  final String secondLine;
  final double fontSize;
  final TextAlign align;
  final CrossAxisAlignment crossAxisAlignment;

  const _TrustText({
    required this.firstLine,
    required this.secondLine,
    required this.fontSize,
    required this.align,
    required this.crossAxisAlignment,
  });

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.micro.copyWith(
      color: _TalentPalette.whiteText,
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
      height: 1.05,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(firstLine, maxLines: 1, textAlign: align, style: style),
        Text(secondLine, maxLines: 1, textAlign: align, style: style),
      ],
    );
  }
}

class GoldGradientButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool compact;
  final VoidCallback? onTap;

  const GoldGradientButton({
    super.key,
    required this.icon,
    required this.label,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return _PressableButton(
      onTap: onTap,
      height: compact ? 58 : 64,
      radius: 20,
      decoration: BoxDecoration(
        gradient: colors.goldGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.goldLight.withValues(alpha: 0.95),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                colors.goldGlow.withValues(alpha: colors.isLight ? 0.62 : 0.78),
            blurRadius: 22,
            spreadRadius: -6,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: colors.goldLight
                .withValues(alpha: colors.isLight ? 0.22 : 0.28),
            blurRadius: 12,
            spreadRadius: -8,
          ),
        ],
      ),
      child: _ButtonContent(
        icon: icon,
        label: label,
        color: colors.onGold,
        compact: compact,
      ),
    );
  }
}

class DarkOutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool compact;
  final VoidCallback? onTap;

  const DarkOutlineButton({
    super.key,
    required this.icon,
    required this.label,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return _PressableButton(
      onTap: onTap,
      height: compact ? 58 : 64,
      radius: 20,
      decoration: BoxDecoration(
        gradient: colors.glassGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border, width: 1.1),
        boxShadow: [
          BoxShadow(
            color:
                colors.shadow.withValues(alpha: colors.isLight ? 0.18 : 0.48),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: _ButtonContent(
        icon: icon,
        label: label,
        color: colors.textPrimary,
        compact: compact,
      ),
    );
  }
}

class _PressableButton extends StatelessWidget {
  final double height;
  final double radius;
  final BoxDecoration decoration;
  final Widget child;
  final VoidCallback? onTap;

  const _PressableButton({
    required this.height,
    required this.radius,
    required this.decoration,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Ink(
            height: height,
            decoration: decoration,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool compact;

  const _ButtonContent({
    required this.icon,
    required this.label,
    required this.color,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: compact ? 22 : 25),
              SizedBox(width: compact ? 9 : 12),
              Text(
                label,
                maxLines: 1,
                style: AppTextStyles.label.copyWith(
                  color: color,
                  fontSize: compact ? 15 : 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerifiedCheck extends StatelessWidget {
  final double size;

  const _VerifiedCheck({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: _TalentPalette.green,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Color(0x5530D987), blurRadius: 12),
          BoxShadow(color: Color(0x66000000), blurRadius: 8),
        ],
      ),
      child: Icon(
        Icons.check_rounded,
        size: size * 0.62,
        color: Colors.white,
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;

  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 9),
        ],
      ),
    );
  }
}

class _CardBackgroundLayer extends StatelessWidget {
  const _CardBackgroundLayer();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: const [
        DecoratedBox(
          decoration: BoxDecoration(gradient: _TalentPalette.cardGradient),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.92, -0.92),
              radius: 1.05,
              colors: [
                Color(0x26F4C76A),
                Color(0x120B0F12),
                Color(0x00000000),
              ],
              stops: [0.0, 0.38, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.72, 1.04),
              radius: 1.08,
              colors: [
                Color(0x24284A64),
                Color(0x10080D11),
                Color(0x00000000),
              ],
              stops: [0.0, 0.42, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x12FFFFFF),
                Color(0x00000000),
                Color(0x52000000),
              ],
              stops: [0.0, 0.34, 1.0],
            ),
          ),
        ),
        CustomPaint(painter: _CinematicTexturePainter()),
      ],
    );
  }
}

class _CinematicTexturePainter extends CustomPainter {
  const _CinematicTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0x09FFFFFF)
      ..strokeWidth = 0.7;

    for (var i = -6; i < 18; i++) {
      final start = Offset(size.width * (i / 16), 0);
      final end = Offset(size.width * ((i + 7) / 16), size.height);
      canvas.drawLine(start, end, linePaint);
    }

    final dotPaint = Paint()..color = const Color(0x08F4C76A);
    for (var i = 0; i < 90; i++) {
      final x = ((i * 73) % 997) / 997 * size.width;
      final y = ((i * 149) % 991) / 991 * size.height;
      canvas.drawCircle(Offset(x, y), i.isEven ? 0.55 : 0.35, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TalentPalette {
  const _TalentPalette._();

  static const Color backgroundBlack = Color(0xFF050607);
  static const Color cardBlack = Color(0xFF0B0F12);
  static const Color cardGlass = Color(0xCC101418);
  static const Color goldLight = Color(0xFFF4C76A);
  static const Color goldDark = Color(0xFFC88A1E);
  static const Color mutedText = Color(0xFFAAA39A);
  static const Color whiteText = Color(0xFFF7F3EA);
  static const Color cream = Color(0xFFFFE7A3);
  static const Color borderGrey = Color(0xFF2A2D30);
  static const Color green = Color(0xFF20D37A);
  static const Color blue = Color(0xFF5AA9FF);
  static const Color purple = Color(0xFFC078FF);
  static const Color textDim = Color(0xFF756F68);

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF07090B),
      cardBlack,
      cardGlass,
      backgroundBlack,
    ],
    stops: [0.0, 0.42, 0.72, 1.0],
  );

  static const LinearGradient goldStrokeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      goldLight,
      Color(0xAAC88A1E),
      Color(0x342A2D30),
      goldDark,
    ],
    stops: [0.0, 0.24, 0.58, 1.0],
  );

  static const LinearGradient goldButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      goldLight,
      Color(0xFFE2A52E),
      goldDark,
    ],
    stops: [0.0, 0.5, 1.0],
  );
}

double _scale(
  double width,
  double min,
  double max,
  double lower,
  double upper,
) {
  final t = ((width - lower) / (upper - lower)).clamp(0.0, 1.0);
  return min + (max - min) * t;
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
