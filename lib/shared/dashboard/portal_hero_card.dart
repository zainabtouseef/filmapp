import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_durations.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import 'portal_floating_bubbles.dart';

/// A single stat shown in the hero card's translucent stat strip
/// (e.g. "20 · Productions").
class PortalHeroStat {
  final String value;
  final String label;

  const PortalHeroStat({required this.value, required this.label});
}

/// The dashboard-kit's shared hero card: a gold-gradient card with an
/// animated conic-gradient ring tracing its border, an avatar/initials
/// badge, name, a verified/status pill, a translucent stat strip, and a
/// primary CTA + secondary icon button.
///
/// This is the one hero-card treatment every portal dashboard should use —
/// it replaces portal-specific hero widgets like DP's foil-line
/// `DPCommandHeader` or the generic image-based `_AdminCommandHero`.
class PortalHeroCard extends StatefulWidget {
  final String initials;
  final String name;
  final String badgeLabel;
  final List<PortalHeroStat> stats;
  final String ctaLabel;
  final VoidCallback? onCta;
  final IconData secondaryIcon;
  final VoidCallback? onSecondary;
  final double radius;

  const PortalHeroCard({
    super.key,
    required this.initials,
    required this.name,
    required this.badgeLabel,
    required this.stats,
    required this.ctaLabel,
    this.onCta,
    this.secondaryIcon = Icons.chat_bubble_outline_rounded,
    this.onSecondary,
    this.radius = AppRadius.xl,
  });

  @override
  State<PortalHeroCard> createState() => _PortalHeroCardState();
}

class _PortalHeroCardState extends State<PortalHeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.heroRingRotation,
    );
    final reduceMotion = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (!reduceMotion) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: Stack(
        children: [
          Container(
            decoration: AppTheme.heroCard(context, radius: widget.radius),
            foregroundDecoration: BoxDecoration(
              gradient: colors.ambientGlow,
              borderRadius: BorderRadius.circular(widget.radius),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: PortalFloatingBubbles(count: 5),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _InitialsBadge(initials: widget.initials),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    AppTextStyles.sectionSerifHeading.copyWith(
                                  fontSize: 20,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 5),
                              _VerifiedPill(label: widget.badgeLabel),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: colors.isLight
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppRadius.panel),
                      ),
                      child: Row(
                        children: [
                          for (final stat in widget.stats)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.only(left: 10),
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: colors.goldMid,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      stat.value,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.cardTitle.copyWith(
                                        fontSize: 18,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      stat.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.smallMeta.copyWith(
                                        color: colors.textSecondary,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: widget.onCta,
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.card,
                              foregroundColor: colors.textPrimary,
                              shape: const StadiumBorder(),
                              minimumSize: const Size.fromHeight(42),
                            ),
                            child: Text(widget.ctaLabel),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _SecondaryIconButton(
                          icon: widget.secondaryIcon,
                          onTap: widget.onSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: reduceMotion
                  ? CustomPaint(
                      painter: _HeroRingPainter(
                        angle: 0,
                        gold: colors.goldMid,
                        radius: widget.radius,
                      ),
                    )
                  : AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => CustomPaint(
                        painter: _HeroRingPainter(
                          angle: _controller.value * 2 * math.pi,
                          gold: colors.goldMid,
                          radius: widget.radius,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Strokes the card's rounded-rect outline with a rotating sweep gradient —
/// only the gradient spins, the geometry stays fixed, so it reads as a
/// thin light tracing the border rather than the whole card rotating.
class _HeroRingPainter extends CustomPainter {
  final double angle;
  final Color gold;
  final double radius;

  const _HeroRingPainter({
    required this.angle,
    required this.gold,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect =
        RRect.fromRectAndRadius(rect.deflate(1), Radius.circular(radius));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = SweepGradient(
        colors: [
          gold.withValues(alpha: 0),
          gold.withValues(alpha: 0),
          gold.withValues(alpha: 0.9),
          Colors.white.withValues(alpha: 0.95),
          gold.withValues(alpha: 0.9),
          gold.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.52, 0.69, 0.78, 0.87, 1.0],
        transform: GradientRotation(angle),
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _HeroRingPainter oldDelegate) =>
      oldDelegate.angle != angle ||
      oldDelegate.gold != gold ||
      oldDelegate.radius != radius;
}

class _InitialsBadge extends StatelessWidget {
  final String initials;

  const _InitialsBadge({required this.initials});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: colors.isLight ? 0.1 : 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        initials,
        style: AppTextStyles.cardTitle.copyWith(
          fontSize: 15,
          color: colors.goldDark,
        ),
      ),
    );
  }
}

class _VerifiedPill extends StatelessWidget {
  final String label;

  const _VerifiedPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: colors.goldTint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 11, color: colors.goldDark),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.micro.copyWith(
              color: colors.goldDark,
              fontSize: 9.5,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _SecondaryIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: 42,
      height: 42,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 17, color: colors.textPrimary),
        style: IconButton.styleFrom(
          backgroundColor: colors.card,
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}
