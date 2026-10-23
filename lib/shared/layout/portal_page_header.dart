import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_durations.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/cine_animated_gold_border.dart';
import '../widgets/cine_hover_zoom.dart';

class PortalHeroStat {
  final String value;
  final String label;

  const PortalHeroStat(this.value, this.label);
}

/// Canonical page hero for every operational CineConnect screen.
///
/// It follows the Shortlist reference: compact editorial title, soft gold wash,
/// inline status metrics, restrained bubbles, and a responsive two-by-two stat
/// layout on phones. The same treatment is used by marketplace and dashboard
/// utility routes so portal typography and hero motion remain consistent.
class PortalPageHeader extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? trailing;
  final int titleMaxLines;
  final List<PortalHeroStat>? stats;

  const PortalPageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.trailing,
    this.titleMaxLines = 2,
    this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name;
    final colors = context.appColors;
    final resolvedStats = stats ?? _defaultStats(route, title);
    return CineHoverZoom(
      scale: 1.004,
      pressedScale: 1.01,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 560),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        ),
        child: CineAnimatedGoldBorder(
          radius: 24,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors.isLight
                    ? [
                        colors.elevatedSurface,
                        colors.goldSoft.withValues(alpha: .78),
                        colors.elevatedSurface,
                      ]
                    : [
                        colors.elevatedSurface,
                        Color.lerp(
                            colors.elevatedSurface, colors.goldMid, .045)!,
                        colors.elevatedSurface,
                      ],
                stops: const [0, .54, 1],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color:
                      colors.shadow.withValues(alpha: colors.isLight ? .1 : .3),
                  blurRadius: 30,
                  spreadRadius: -18,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Positioned(
                  right: 38,
                  top: -18,
                  child: _HeroBubble(size: 72, opacity: .16),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 620;
                      final titleBlock = _TitleBlock(
                        title: title,
                        eyebrow: eyebrow,
                        subtitle: subtitle,
                        titleMaxLines: titleMaxLines,
                        compact: compact,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (trailing == null || compact)
                            titleBlock
                          else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(child: titleBlock),
                                const SizedBox(width: 18),
                                Flexible(child: trailing!),
                              ],
                            ),
                          if (trailing != null && compact) ...[
                            const SizedBox(height: 12),
                            trailing!,
                          ],
                          const SizedBox(height: 16),
                          _HeroStatStrip(stats: resolvedStats),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static List<PortalHeroStat> _defaultStats(String? route, String title) {
    final key = '${route ?? ''} $title'.toLowerCase();
    if (_hasAny(key, const [
      'marketplace',
      'discover',
      'browse',
      'people and resources',
    ])) {
      return const [
        PortalHeroStat('LIVE', 'listings'),
        PortalHeroStat('VERIFIED', 'network'),
        PortalHeroStat('SMART', 'filters'),
        PortalHeroStat('SYNCED', 'server'),
      ];
    }
    if (_hasAny(key, const [
      'payment',
      'earning',
      'account',
      'billing',
      'commission',
      'rate',
      'pricing',
      'finance'
    ])) {
      return const [
        PortalHeroStat('LIVE', 'ledger'),
        PortalHeroStat('PKR', 'currency'),
        PortalHeroStat('SECURE', 'records'),
        PortalHeroStat('SYNCED', 'server'),
      ];
    }
    if (_hasAny(
        key, const ['calendar', 'schedule', 'availability', 'release'])) {
      return const [
        PortalHeroStat('TODAY', 'timeline'),
        PortalHeroStat('PKT', 'timezone'),
        PortalHeroStat('LIVE', 'status'),
        PortalHeroStat('SYNCED', 'calendar'),
      ];
    }
    if (_hasAny(key, const [
      'contract',
      'legal',
      'term',
      'rule',
      'safety',
      'insurance',
      'claim',
      'incident',
      'verification'
    ])) {
      return const [
        PortalHeroStat('LIVE', 'records'),
        PortalHeroStat('VERIFIED', 'workflow'),
        PortalHeroStat('SECURE', 'access'),
        PortalHeroStat('AUDITED', 'history'),
      ];
    }
    if (_hasAny(key, const ['profile', 'portfolio', 'media kit', 'showreel'])) {
      return const [
        PortalHeroStat('PUBLIC', 'view'),
        PortalHeroStat('EDITABLE', 'content'),
        PortalHeroStat('VERIFIED', 'identity'),
        PortalHeroStat('SYNCED', 'server'),
      ];
    }
    if (_hasAny(key, const [
      'shortlist',
      'roster',
      'candidate',
      'application',
      'audition'
    ])) {
      return const [
        PortalHeroStat('LIVE', 'workspace'),
        PortalHeroStat('SAVED', 'candidates'),
        PortalHeroStat('RANKED', 'comparison'),
        PortalHeroStat('SYNCED', 'server'),
      ];
    }
    if (_hasAny(key, const [
      'project',
      'campaign',
      'opportun',
      'booking',
      'request',
      'negotiation',
      'bargaining'
    ])) {
      return const [
        PortalHeroStat('LIVE', 'workflow'),
        PortalHeroStat('READY', 'actions'),
        PortalHeroStat('TRACKED', 'status'),
        PortalHeroStat('SYNCED', 'server'),
      ];
    }
    return const [
      PortalHeroStat('LIVE', 'workspace'),
      PortalHeroStat('READY', 'actions'),
      PortalHeroStat('SECURE', 'access'),
      PortalHeroStat('SYNCED', 'server'),
    ];
  }

  static bool _hasAny(String value, List<String> needles) =>
      needles.any(value.contains);
}

class _TitleBlock extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final String? subtitle;
  final int titleMaxLines;
  final bool compact;

  const _TitleBlock({
    required this.title,
    required this.eyebrow,
    required this.subtitle,
    required this.titleMaxLines,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow case final value? when value.trim().isNotEmpty) ...[
          Text(
            value.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.micro.copyWith(
              color: colors.goldDark,
              fontSize: compact ? 10.5 : 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: compact ? 1.7 : 2.3,
            ),
          ),
          SizedBox(height: compact ? 5 : 7),
        ],
        Semantics(
          header: true,
          child: Text(
            title,
            maxLines: titleMaxLines,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.heroSerifHeadline.copyWith(
              color: colors.textPrimary,
              fontSize: compact ? 30 : 38,
              fontWeight: FontWeight.w600,
              height: 1.02,
              letterSpacing: -.45,
            ),
          ),
        ),
        if (subtitle case final value? when value.trim().isNotEmpty) ...[
          const SizedBox(height: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Text(
              value,
              maxLines: compact ? 3 : 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMuted.copyWith(
                color: colors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _HeroStatStrip extends StatelessWidget {
  final List<PortalHeroStat> stats;

  const _HeroStatStrip({required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 520 ? 2 : stats.length;
        final gap = 8.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final stat in stats)
              SizedBox(
                width: width,
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: colors.elevatedSurface.withValues(alpha: .72),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 30,
                        decoration: BoxDecoration(
                          color: colors.goldMid,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stat.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.smallMeta.copyWith(
                                color: colors.textPrimary,
                                fontSize: stat.value.length > 7 ? 12 : 14,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stat.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.micro.copyWith(
                                color: colors.textSecondary,
                                fontSize: 9.5,
                                letterSpacing: .25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HeroBubble extends StatelessWidget {
  final double size;
  final double opacity;

  const _HeroBubble({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final resolvedOpacity = colors.isLight ? opacity : opacity * .32;
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-.25, -.32),
            colors: [
              colors.surfaceHighlight.withValues(alpha: .9),
              colors.goldLight.withValues(alpha: resolvedOpacity),
              colors.goldMid.withValues(alpha: resolvedOpacity * .45),
            ],
          ),
          border:
              Border.all(color: colors.surfaceHighlight.withValues(alpha: .5)),
          boxShadow: [
            BoxShadow(
              color: colors.goldGlow.withValues(alpha: opacity),
              blurRadius: size * .4,
            ),
          ],
        ),
      ),
    );
  }
}

class PortalRouteEntrance extends StatefulWidget {
  final String route;
  final Widget child;

  const PortalRouteEntrance({
    super.key,
    required this.route,
    required this.child,
  });

  @override
  State<PortalRouteEntrance> createState() => _PortalRouteEntranceState();
}

class _PortalRouteEntranceState extends State<PortalRouteEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.pageEntrance,
    );
    _setAnimations();
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant PortalRouteEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route != widget.route) _controller.forward(from: 0);
  }

  void _setAnimations() {
    final curve =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _opacity = Tween(begin: 0.0, end: 1.0).animate(curve);
    _offset =
        Tween(begin: const Offset(0, .018), end: Offset.zero).animate(curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return widget.child;
    }
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
