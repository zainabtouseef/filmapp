import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';

class CineV3BubbleField extends StatefulWidget {
  final int count;
  final double opacity;

  const CineV3BubbleField({
    super.key,
    this.count = 7,
    this.opacity = 1,
  });

  @override
  State<CineV3BubbleField> createState() => _CineV3BubbleFieldState();
}

class _CineV3BubbleFieldState extends State<CineV3BubbleField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _specs = <({double x, double y, double size, double phase})>[
    (x: .04, y: .18, size: 44, phase: .0),
    (x: .16, y: .66, size: 28, phase: .8),
    (x: .31, y: .10, size: 20, phase: 1.9),
    (x: .52, y: .62, size: 36, phase: 2.8),
    (x: .68, y: .14, size: 54, phase: 3.7),
    (x: .82, y: .56, size: 26, phase: 4.6),
    (x: .92, y: .20, size: 18, phase: 5.4),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final specs = _specs.take(widget.count.clamp(0, _specs.length).toInt());

    return IgnorePointer(
      child: Opacity(
        opacity: widget.opacity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final base = reduceMotion ? 0.0 : _controller.value * math.pi * 2;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final s in specs)
                      Positioned(
                        left: constraints.maxWidth * s.x,
                        top: constraints.maxHeight * s.y,
                        child: Transform.translate(
                          offset: Offset(
                            math.sin(base + s.phase) * 10,
                            math.cos(base * .78 + s.phase) * 13,
                          ),
                          child: Container(
                            width: s.size,
                            height: s.size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                center: const Alignment(-.38, -.42),
                                radius: .95,
                                colors: colors.isLight
                                    ? [
                                        Colors.white.withValues(alpha: .96),
                                        const Color(0xFFCEE9FB).withValues(alpha: .58),
                                        const Color(0xFFE1D8FA).withValues(alpha: .34),
                                        const Color(0xFFFFE5D2).withValues(alpha: .18),
                                        Colors.white.withValues(alpha: .02),
                                      ]
                                    : [
                                        Colors.white.withValues(alpha: .46),
                                        const Color(0xFFBBDDF6).withValues(alpha: .22),
                                        const Color(0xFFCABCF5).withValues(alpha: .14),
                                        const Color(0xFFFFCDB0).withValues(alpha: .08),
                                        Colors.white.withValues(alpha: .01),
                                      ],
                              ),
                              border: Border.all(
                                color: colors.isLight
                                    ? Colors.white.withValues(alpha: .78)
                                    : const Color(0xFFCEE7F8).withValues(alpha: .22),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.goldMid.withValues(alpha: .10),
                                  blurRadius: 14,
                                  spreadRadius: -5,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class CineV3LightSweep extends StatefulWidget {
  final Duration duration;
  final double opacity;

  const CineV3LightSweep({
    super.key,
    this.duration = const Duration(seconds: 9),
    this.opacity = .24,
  });

  @override
  State<CineV3LightSweep> createState() => _CineV3LightSweepState();
}

class _CineV3LightSweepState extends State<CineV3LightSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant CineV3LightSweep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return IgnorePointer(
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) => AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = reduceMotion ? .5 : Curves.easeInOut.transform(_controller.value);
              return Transform.translate(
                offset: Offset(-constraints.maxWidth * 1.15 + constraints.maxWidth * 2.3 * t, 0),
                child: Transform.rotate(
                  angle: -.18,
                  child: Container(
                    width: constraints.maxWidth * .28,
                    height: constraints.maxHeight * 1.7,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: widget.opacity),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class CineV3AtmosphericWash extends StatelessWidget {
  const CineV3AtmosphericWash({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors.isLight
                ? [
                    const Color(0xFFEAF5FC).withValues(alpha: .66),
                    Colors.transparent,
                    const Color(0xFFF0EBFD).withValues(alpha: .48),
                    const Color(0xFFF8EED5).withValues(alpha: .68),
                  ]
                : [
                    const Color(0xFF82BDE6).withValues(alpha: .08),
                    Colors.transparent,
                    const Color(0xFF9D8DE6).withValues(alpha: .07),
                    colors.goldMid.withValues(alpha: .07),
                  ],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class CineV3PageHero extends StatelessWidget {
  final String title;
  final String kicker;
  final String? subtitle;
  final List<Widget> actions;

  const CineV3PageHero({
    super.key,
    required this.title,
    this.kicker = 'CINECONNECT · LIVE WORKSPACE',
    this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: colors.isLight ? .18 : .42),
            blurRadius: 30,
            spreadRadius: -20,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: CineV3AtmosphericWash()),
          const Positioned.fill(child: CineV3BubbleField(count: 7, opacity: .9)),
          const Positioned.fill(child: CineV3LightSweep()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 14,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 220, maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.goldMid,
                              boxShadow: [BoxShadow(color: colors.goldGlow, blurRadius: 10, spreadRadius: 2)],
                            ),
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              kicker.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.micro.copyWith(
                                color: colors.goldDark,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.screenTitle.copyWith(
                          color: colors.textPrimary,
                          fontFamily: 'Georgia',
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          height: 1.02,
                        ),
                      ),
                      if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions.isNotEmpty)
                  Wrap(spacing: 8, runSpacing: 8, children: actions),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CineV3SlidingFilterBar extends StatefulWidget {
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onChanged;
  final Map<String, int>? counts;
  final EdgeInsetsGeometry padding;

  const CineV3SlidingFilterBar({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.counts,
    this.padding = const EdgeInsets.symmetric(vertical: 5),
  });

  @override
  State<CineV3SlidingFilterBar> createState() => _CineV3SlidingFilterBarState();
}

class _CineV3SlidingFilterBarState extends State<CineV3SlidingFilterBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheen;

  @override
  void initState() {
    super.initState();
    _sheen = AnimationController(vsync: this, duration: const Duration(milliseconds: 950))..repeat();
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  double _labelWidth(BuildContext context, String label) {
    final count = widget.counts?[label];
    final text = count == null ? label : '$label  $count';
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: AppTextStyles.smallMeta.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700),
      ),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();
    return painter.width + 28;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.labels.isEmpty) return const SizedBox.shrink();
    final colors = context.appColors;
    const gap = 7.0;
    final widths = [for (final label in widget.labels) _labelWidth(context, label)];
    final selectedIndex = widget.labels
        .indexOf(widget.selected)
        .clamp(0, widget.labels.length - 1)
        .toInt();
    final left = widths.take(selectedIndex).fold<double>(0, (v, e) => v + e + gap);
    final activeWidth = widths.isEmpty ? 0.0 : widths[selectedIndex];
    final totalWidth = widths.fold<double>(0, (v, e) => v + e) + math.max(0, widths.length - 1) * gap;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: widget.padding,
        child: SizedBox(
          width: totalWidth,
          height: 42,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: const Cubic(0.65, 0, 0.25, 1),
                left: left,
                top: 4,
                width: activeWidth,
                height: 34,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: colors.goldLight.withValues(alpha: .36),
                    boxShadow: [BoxShadow(color: colors.goldGlow, blurRadius: 20, spreadRadius: 2)],
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 420),
                curve: const Cubic(0.65, 0, 0.25, 1),
                left: left,
                top: 4,
                width: activeWidth,
                height: 34,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Stack(
                    children: [
                      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: colors.goldGradient))),
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _sheen,
                          builder: (context, _) => FractionalTranslation(
                            translation: Offset(-1.3 + _sheen.value * 2.6, 0),
                            child: Container(
                              width: activeWidth * .45,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withValues(alpha: .78), Colors.transparent]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 420),
                curve: const Cubic(0.65, 0, 0.25, 1),
                left: left,
                bottom: 0,
                width: activeWidth,
                height: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.goldMid,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [BoxShadow(color: colors.goldGlow, blurRadius: 10, spreadRadius: 2)],
                  ),
                ),
              ),
              Row(
                children: [
                  for (var index = 0; index < widget.labels.length; index++) ...[
                    SizedBox(
                      width: widths[index],
                      height: 42,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => widget.onChanged(widget.labels[index]),
                          child: Center(
                            child: Text(
                              widget.counts?[widget.labels[index]] == null
                                  ? widget.labels[index]
                                  : '${widget.labels[index]}  ${widget.counts![widget.labels[index]]}',
                              maxLines: 1,
                              style: AppTextStyles.smallMeta.copyWith(
                                color: index == selectedIndex ? colors.onGold : colors.textSecondary,
                                fontWeight: index == selectedIndex ? FontWeight.w900 : FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (index != widget.labels.length - 1) const SizedBox(width: gap),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CineV3NetflixZoom extends StatefulWidget {
  final Widget child;
  final double webScale;
  final double mobileScale;
  final bool enabled;

  const CineV3NetflixZoom({
    super.key,
    required this.child,
    this.webScale = 1.045,
    this.mobileScale = 1.02,
    this.enabled = true,
  });

  @override
  State<CineV3NetflixZoom> createState() => _CineV3NetflixZoomState();
}

class _CineV3NetflixZoomState extends State<CineV3NetflixZoom> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final target = !widget.enabled
        ? 1.0
        : kIsWeb
            ? (_hovered ? widget.webScale : 1.0)
            : (_pressed ? widget.mobileScale : 1.0);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: target,
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 360),
          curve: const Cubic(.2, .9, .25, 1),
          child: widget.child,
        ),
      ),
    );
  }
}
