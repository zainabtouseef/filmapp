import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/cine_animated_gold_border.dart';
import '../widgets/cine_hover_zoom.dart';
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
class PortalHeroCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final compact = MediaQuery.sizeOf(context).width < 480;
    final showDecorativeChips = MediaQuery.sizeOf(context).width >= 900;

    return CineHoverZoom(
      child: CineAnimatedGoldBorder(
        radius: radius,
        child: Stack(
          children: [
            Container(
              decoration: AppTheme.heroCard(context, radius: radius),
              foregroundDecoration: BoxDecoration(
                gradient: colors.ambientGlow,
                borderRadius: BorderRadius.circular(radius),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 16 : 24,
                vertical: compact ? 18 : 22,
              ),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: PortalFloatingBubbles(count: 7),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: compact ? 50 : 84,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _InitialsBadge(initials: initials),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.sectionSerifHeading
                                        .copyWith(
                                      fontSize: compact ? 21 : 25,
                                      color: colors.textPrimary,
                                      height: 1.05,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _VerifiedPill(label: badgeLabel),
                                ],
                              ),
                            ),
                            if (showDecorativeChips) ...[
                              const SizedBox(width: 18),
                              Flexible(
                                child: _HeroDecorativeChips(
                                  stats: stats,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: colors.isLight
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(AppRadius.panel),
                        ),
                        child: Row(
                          children: [
                            for (final stat in stats)
                              Expanded(
                                child: Container(
                                  constraints: BoxConstraints(
                                    minHeight: compact ? 42 : 38,
                                  ),
                                  padding: EdgeInsets.only(
                                    left: compact ? 7 : 10,
                                    right: compact ? 3 : 0,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: colors.goldMid,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            stat.value,
                                            maxLines: 1,
                                            style: AppTextStyles.cardTitle
                                                .copyWith(
                                              fontSize: compact ? 16 : 18,
                                              color: colors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        stat.label,
                                        maxLines: compact ? 2 : 1,
                                        overflow: TextOverflow.fade,
                                        style: AppTextStyles.smallMeta.copyWith(
                                          color: colors.textSecondary,
                                          fontSize: compact ? 9.5 : 10.5,
                                          height: 1.05,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: onCta,
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.card,
                                foregroundColor: colors.textPrimary,
                                shape: const StadiumBorder(),
                                minimumSize: const Size.fromHeight(44),
                              ),
                              child: Text(ctaLabel),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _SecondaryIconButton(
                            icon: secondaryIcon,
                            onTap: onSecondary,
                          ),
                        ],
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

class _HeroDecorativeChips extends StatefulWidget {
  final List<PortalHeroStat> stats;

  const _HeroDecorativeChips({required this.stats});

  @override
  State<_HeroDecorativeChips> createState() => _HeroDecorativeChipsState();
}

class _HeroDecorativeChipsState extends State<_HeroDecorativeChips>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 8));
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
    final labels = widget.stats.take(3).map((stat) => stat.label).toList();
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 10,
      runSpacing: 8,
      children: [
        for (var index = 0; index < labels.length; index++)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final phase =
                  _controller.value * 2 * math.pi + index * (2 * math.pi / 3);
              final bob = math.sin(phase) * 3.5;
              return Transform.translate(
                offset: Offset(0, bob),
                child: Transform.rotate(
                  angle:
                      (index.isEven ? -0.025 : 0.025) + math.sin(phase) * 0.01,
                  child: child,
                ),
              );
            },
            child: _HeroDecorativeChip(
              label: labels[index],
              icon: switch (index) {
                0 => Icons.auto_awesome_outlined,
                1 => Icons.movie_filter_outlined,
                _ => Icons.bolt_rounded,
              },
            ),
          ),
      ],
    );
  }
}

class _HeroDecorativeChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _HeroDecorativeChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.card.withValues(alpha: 0.84),
            colors.infoBlue.withValues(alpha: colors.isLight ? 0.10 : 0.13),
            colors.infoPurple.withValues(alpha: colors.isLight ? 0.08 : 0.12),
            colors.goldLight.withValues(alpha: colors.isLight ? 0.17 : 0.13),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: Colors.white.withValues(alpha: colors.isLight ? 0.9 : 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: colors.isLight ? 0.11 : 0.3),
            blurRadius: 20,
            spreadRadius: -12,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.goldDark),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsBadge extends StatelessWidget {
  final String initials;

  const _InitialsBadge({required this.initials});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 50,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
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
          fontSize: 16,
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
      width: 44,
      height: 44,
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
