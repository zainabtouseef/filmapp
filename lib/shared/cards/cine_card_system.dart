import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_durations.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../formatters/cine_format.dart';
import '../layout/portal_reference_design.dart';

enum CardVariant { standard, compact, hero, section, soft, alert, media }

enum CardDensity { compact, standard, comfortable }

enum CineTone { neutral, positive, warning, critical, information, premium }

enum SectionTreatment { open, soft, elevated }

Color cineToneColor(BuildContext context, CineTone tone) {
  final colors = context.appColors;
  return switch (tone) {
    CineTone.neutral => colors.textSecondary,
    CineTone.positive => colors.success,
    CineTone.warning => colors.warning,
    CineTone.critical => colors.danger,
    CineTone.information => colors.infoBlue,
    CineTone.premium => colors.goldMid,
  };
}

CineTone cineToneFromColor(BuildContext context, Color color) {
  final colors = context.appColors;
  if (color == colors.success) return CineTone.positive;
  if (color == colors.danger) return CineTone.critical;
  if (color == colors.warning) return CineTone.warning;
  if (color == colors.infoBlue || color == colors.infoPurple) {
    return CineTone.information;
  }
  if (color == colors.goldMid || color == colors.goldDark) {
    return CineTone.premium;
  }
  return CineTone.neutral;
}

class CardShell extends StatefulWidget {
  final Widget child;
  final CardVariant variant;
  final CardDensity density;
  final CineTone tone;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool selected;
  final bool accentEdge;
  final double? radius;
  final double? minHeight;

  const CardShell({
    super.key,
    required this.child,
    this.variant = CardVariant.standard,
    this.density = CardDensity.standard,
    this.tone = CineTone.neutral,
    this.padding,
    this.onTap,
    this.semanticLabel,
    this.selected = false,
    this.accentEdge = false,
    this.radius,
    this.minHeight,
  });

  @override
  State<CardShell> createState() => _CardShellState();
}

class _CardShellState extends State<CardShell> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  EdgeInsetsGeometry get _padding =>
      widget.padding ??
      switch (widget.density) {
        CardDensity.compact => const EdgeInsets.all(AppSpacing.md),
        CardDensity.standard => const EdgeInsets.all(AppSpacing.lg),
        CardDensity.comfortable => const EdgeInsets.all(AppSpacing.xxl),
      };

  double get _radius =>
      widget.radius ??
      switch (widget.variant) {
        CardVariant.compact => AppRadius.md,
        CardVariant.hero => AppRadius.xl,
        CardVariant.section => AppRadius.xxl,
        _ => AppRadius.lg,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final route = ModalRoute.of(context)?.settings.name;
    final referenceRoute = PortalReferenceDesign.usesReference(route);
    final bodyLayout = PortalReferenceDesign.layoutForRoute(route);
    final openSection = referenceRoute && widget.variant == CardVariant.section;
    final compactStructure = bodyLayout == PortalBodyLayout.list ||
        bodyLayout == PortalBodyLayout.timeline ||
        bodyLayout == PortalBodyLayout.splitView;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final tone = cineToneColor(context, widget.tone);
    final interactive = widget.onTap != null;
    final elevated = _hovered && (interactive || referenceRoute);
    final surface = switch (widget.variant) {
      CardVariant.soft => colors.softSurface,
      CardVariant.media => colors.surface,
      _ => colors.elevatedSurface,
    };
    final layoutRadius = switch (bodyLayout) {
      PortalBodyLayout.editorial || PortalBodyLayout.analytics => 16.0,
      PortalBodyLayout.list || PortalBodyLayout.timeline => 12.0,
      PortalBodyLayout.calendar => 18.0,
      PortalBodyLayout.kanban || PortalBodyLayout.splitView => 14.0,
      PortalBodyLayout.gallery || PortalBodyLayout.horizontalRail => 20.0,
    };
    final resolvedRadius = referenceRoute
        ? switch (widget.variant) {
            CardVariant.compact => compactStructure ? 10.0 : 14.0,
            CardVariant.hero => layoutRadius + 4,
            CardVariant.section => layoutRadius,
            CardVariant.alert => 12.0,
            CardVariant.media =>
              bodyLayout == PortalBodyLayout.gallery ? 18.0 : layoutRadius,
            _ => widget.radius == null
                ? layoutRadius
                : widget.radius!.clamp(10.0, layoutRadius + 2),
          }
        : _radius;
    final tintedSurface = Color.lerp(
      surface,
      tone,
      colors.isLight
          ? (widget.accentEdge ? .05 : .024)
          : (widget.accentEdge ? .13 : .075),
    )!;
    final borderColor = _focused
        ? colors.focusRing
        : widget.selected
            ? tone.withValues(alpha: 0.72)
            : elevated
                ? Color.lerp(colors.border, tone, referenceRoute ? .32 : .2)!
                : referenceRoute && widget.accentEdge
                    ? Color.lerp(colors.border, tone, .18)!
                    : openSection
                        ? colors.borderMuted
                        : colors.border;
    final accentDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(4),
      gradient: referenceRoute
          ? LinearGradient(
              begin: bodyLayout == PortalBodyLayout.kanban
                  ? Alignment.centerLeft
                  : Alignment.topCenter,
              end: bodyLayout == PortalBodyLayout.kanban
                  ? Alignment.centerRight
                  : Alignment.bottomCenter,
              colors: [
                tone.withValues(alpha: .48),
                tone,
                tone.withValues(alpha: .62),
              ],
            )
          : null,
      color: referenceRoute ? null : tone,
      boxShadow: referenceRoute
          ? [
              BoxShadow(
                color: tone.withValues(alpha: .18),
                blurRadius: 7,
              ),
            ]
          : null,
    );

    final content = AnimatedScale(
      scale: _pressed
          ? (referenceRoute ? 1.009 : 1.018)
          : (elevated ? (referenceRoute ? 1.004 : 1.01) : 1),
      duration: reduceMotion ? Duration.zero : AppDurations.press,
      curve: AppDurations.standardCurve,
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : AppDurations.hover,
        curve: AppDurations.standardCurve,
        constraints: BoxConstraints(minHeight: widget.minHeight ?? 0),
        transform: Matrix4.translationValues(
          0,
          elevated ? -2 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: referenceRoute ? null : surface,
          gradient: referenceRoute
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(
                      surface,
                      colors.surfaceHighlight,
                      colors.isLight ? (openSection ? .11 : .16) : .075,
                    )!,
                    openSection
                        ? Color.lerp(
                            surface,
                            tone,
                            colors.isLight ? .02 : .07,
                          )!
                        : tintedSurface,
                    Color.lerp(
                      surface,
                      colors.softSurface,
                      openSection ? .38 : .15,
                    )!,
                  ],
                  stops: const [0, .48, 1],
                )
              : null,
          borderRadius: BorderRadius.circular(resolvedRadius),
          border: Border.all(
            color: borderColor,
            width: _focused || widget.selected
                ? 1.5
                : referenceRoute
                    ? (openSection ? .8 : 1)
                    : 1,
          ),
          boxShadow: [
            if (!openSection)
              BoxShadow(
                color: Colors.white.withValues(
                  alpha: colors.isLight ? (referenceRoute ? .32 : 0) : .035,
                ),
                offset: const Offset(0, 1),
              ),
            BoxShadow(
              color: colors.shadow.withValues(
                alpha: colors.isLight
                    ? (elevated ? .11 : (openSection ? .035 : .065))
                    : (elevated ? .3 : (openSection ? .14 : .22)),
              ),
              blurRadius: elevated ? 22 : (openSection ? 14 : 18),
              spreadRadius: elevated ? -9 : -10,
              offset: Offset(0, elevated ? 9 : 6),
            ),
            if (referenceRoute && (widget.selected || elevated))
              BoxShadow(
                color: tone.withValues(alpha: colors.isLight ? .09 : .14),
                blurRadius: 22,
                spreadRadius: -11,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(resolvedRadius - 1),
          child: Stack(
            children: [
              if (referenceRoute)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(.88, -1.1),
                          radius: 1.1,
                          colors: [
                            tone.withValues(
                              alpha: colors.isLight
                                  ? (openSection ? .03 : .055)
                                  : (openSection ? .05 : .08),
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  canRequestFocus: interactive,
                  focusColor: colors.focusRing.withValues(alpha: 0.08),
                  hoverColor: tone.withValues(alpha: 0.025),
                  splashColor: tone.withValues(alpha: 0.08),
                  onHover: (value) => setState(() => _hovered = value),
                  onFocusChange: (value) => setState(() => _focused = value),
                  onHighlightChanged: (value) =>
                      setState(() => _pressed = value),
                  child: Padding(padding: _padding, child: widget.child),
                ),
              ),
              if (widget.accentEdge && bodyLayout != PortalBodyLayout.kanban)
                Positioned(
                  left: 0,
                  top: referenceRoute ? 8 : 12,
                  bottom: referenceRoute ? 8 : 12,
                  child: Container(
                    width: referenceRoute ? 4 : 3,
                    decoration: accentDecoration,
                  ),
                ),
              if (widget.accentEdge && bodyLayout == PortalBodyLayout.kanban)
                Positioned(
                  left: referenceRoute ? 8 : 12,
                  right: referenceRoute ? 8 : 12,
                  top: 0,
                  child: Container(
                    height: referenceRoute ? 4 : 3,
                    decoration: accentDecoration,
                  ),
                ),
              if (referenceRoute && !openSection)
                Positioned(
                  left: 20,
                  right: 20,
                  top: 0,
                  child: Container(
                    height: 1,
                    color: colors.surfaceHighlight.withValues(
                      alpha: colors.isLight ? .72 : .1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: interactive,
      label: widget.semanticLabel,
      child: referenceRoute
          ? Listener(
              onPointerDown: (_) => setState(() => _pressed = true),
              onPointerUp: (_) => setState(() => _pressed = false),
              onPointerCancel: (_) => setState(() => _pressed = false),
              child: MouseRegion(
                onEnter: (_) => setState(() => _hovered = true),
                onExit: (_) => setState(() {
                  _hovered = false;
                  _pressed = false;
                }),
                child: content,
              ),
            )
          : content,
    );
  }
}

class Surface extends StatelessWidget {
  final Widget child;
  final CardVariant variant;
  final CardDensity density;
  final EdgeInsetsGeometry? padding;

  const Surface({
    super.key,
    required this.child,
    this.variant = CardVariant.standard,
    this.density = CardDensity.standard,
    this.padding,
  });

  @override
  Widget build(BuildContext context) => CardShell(
        variant: variant,
        density: density,
        padding: padding,
        child: child,
      );
}

class CardHeader extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  const CardHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.micro.copyWith(
                    color: colors.textTertiary,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardTitle.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}

class CardBody extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const CardBody({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.only(top: AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) => Padding(padding: padding, child: child);
}

class CardFooter extends StatelessWidget {
  final Widget child;

  const CardFooter({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: child,
      );
}

class IconBadge extends StatelessWidget {
  final IconData icon;
  final CineTone tone;
  final bool compact;

  const IconBadge({
    super.key,
    required this.icon,
    this.tone = CineTone.neutral,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = cineToneColor(context, tone);
    final size = compact ? 32.0 : 38.0;
    final referenceRoute = PortalReferenceDesign.usesReference(
      ModalRoute.of(context)?.settings.name,
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: referenceRoute
            ? null
            : Color.lerp(
                colors.elevatedSurface,
                color,
                colors.isLight ? 0.055 : 0.11,
              ),
        gradient: referenceRoute
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(colors.elevatedSurface, color, .08)!,
                  Color.lerp(
                    colors.elevatedSurface,
                    color,
                    colors.isLight ? .16 : .24,
                  )!,
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(referenceRoute ? 13 : AppRadius.sm),
        border: Border.all(
          color: color.withValues(
            alpha: referenceRoute
                ? (colors.isLight ? .3 : .42)
                : (colors.isLight ? .18 : .26),
          ),
        ),
        boxShadow: referenceRoute
            ? [
                BoxShadow(
                  color: color.withValues(alpha: colors.isLight ? .08 : .14),
                  blurRadius: 12,
                  spreadRadius: -5,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Icon(icon, color: color, size: compact ? 17 : 20),
    );
  }
}

class CineStatusBadge extends StatelessWidget {
  final String label;
  final CineTone tone;
  final IconData? icon;
  final bool showDot;
  final Color? colorOverride;

  const CineStatusBadge({
    super.key,
    required this.label,
    this.tone = CineTone.neutral,
    this.icon,
    this.showDot = true,
    this.colorOverride,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = colorOverride ?? cineToneColor(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Color.lerp(
          colors.elevatedSurface,
          color,
          colors.isLight ? 0.055 : 0.12,
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: color.withValues(alpha: colors.isLight ? 0.2 : 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, color: color, size: 13)
          else if (showDot)
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          if (icon != null || showDot) const SizedBox(width: 6),
          Flexible(
            child: Text(
              CineFormat.normalizeCurrency(label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.smallMeta.copyWith(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small numeric-count pill — e.g. the modules-grid card's "12 open"
/// indicator. Distinct from [CineStatusBadge], which pairs an icon/dot
/// with a text label rather than a bare count.
class CountBadge extends StatelessWidget {
  final int count;
  final CineTone tone;
  final Color? colorOverride;

  const CountBadge({
    super.key,
    required this.count,
    this.tone = CineTone.premium,
    this.colorOverride,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = colorOverride ?? cineToneColor(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Color.lerp(
          colors.elevatedSurface,
          color,
          colors.isLight ? 0.055 : 0.12,
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$count',
        style: AppTextStyles.smallMeta.copyWith(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class MetricValue extends StatelessWidget {
  final String value;
  final bool hero;
  final bool compact;
  final Color? color;

  const MetricValue({
    super.key,
    required this.value,
    this.hero = false,
    this.compact = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final display = CineFormat.normalizeCurrency(value);
    final style = AppTextStyles.metricNumber.copyWith(
      color: color ?? colors.textPrimary,
      fontSize: hero
          ? 32
          : compact
              ? 21
              : (display.length > 12 ? 21 : 26),
    );

    if (!compact) {
      return Text(
        display,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        width: constraints.hasBoundedWidth ? constraints.maxWidth : null,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(display, maxLines: 1, softWrap: false, style: style),
        ),
      ),
    );
  }
}

class TrendIndicator extends StatelessWidget {
  final String label;
  final CineTone tone;
  final IconData? icon;

  const TrendIndicator({
    super.key,
    required this.label,
    this.tone = CineTone.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = cineToneColor(context, tone);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon ?? Icons.trending_up_rounded, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class MetadataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const MetadataRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.iconMuted),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
        if (value != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            CineFormat.normalizeCurrency(value!),
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class SegmentedProgress extends StatelessWidget {
  final List<double> values;
  final List<CineTone>? tones;
  final double height;

  const SegmentedProgress({
    super.key,
    required this.values,
    this.tones,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final safeValues = values.where((value) => value > 0).toList();
    if (safeValues.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: colors.borderMuted,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (var index = 0; index < safeValues.length; index++)
              Expanded(
                flex:
                    (safeValues[index] * 1000).round().clamp(1, 100000).toInt(),
                child: ColoredBox(
                  color: cineToneColor(
                    context,
                    tones?[index % tones!.length] ??
                        const [
                          CineTone.premium,
                          CineTone.information,
                          CineTone.positive,
                          CineTone.neutral,
                        ][index % 4],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ProgressRing extends StatelessWidget {
  final double value;
  final CineTone tone;
  final double size;

  const ProgressRing({
    super.key,
    required this.value,
    this.tone = CineTone.premium,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final normalized = value.clamp(0.0, 1.0);
    return Semantics(
      label: '${(normalized * 100).round()} percent complete',
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: normalized,
              strokeWidth: 5,
              backgroundColor: colors.borderMuted,
              color: cineToneColor(context, tone),
            ),
            Text(
              '${(normalized * 100).round()}%',
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompactMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? contextLabel;
  final String? trend;
  final CineTone tone;
  final VoidCallback? onTap;

  const CompactMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.contextLabel,
    this.trend,
    this.tone = CineTone.neutral,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final referenceRoute = PortalReferenceDesign.usesReference(
      ModalRoute.of(context)?.settings.name,
    );
    return CardShell(
      variant: CardVariant.compact,
      density: CardDensity.compact,
      tone: tone,
      accentEdge: referenceRoute,
      onTap: onTap,
      semanticLabel: '$label, $value',
      minHeight: referenceRoute ? 92 : 104,
      child: referenceRoute
          ? Row(
              children: [
                IconBadge(icon: icon, tone: tone),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.micro.copyWith(
                          color: cineToneColor(context, tone),
                          fontWeight: FontWeight.w800,
                          letterSpacing: .85,
                        ),
                      ),
                      const SizedBox(height: 5),
                      MetricValue(value: value, compact: true),
                      if (contextLabel != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          contextLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.smallMeta.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trend != null)
                  TrendIndicator(label: trend!, tone: tone)
                else if (onTap != null)
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: colors.iconMuted,
                  ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconBadge(icon: icon, tone: tone, compact: true),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardLabel.copyWith(
                          color: colors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: MetricValue(value: value, compact: true)),
                    if (trend != null)
                      Flexible(
                        child: TrendIndicator(
                          label: trend!,
                          tone: tone,
                          icon: tone == CineTone.critical
                              ? Icons.trending_down_rounded
                              : null,
                        ),
                      ),
                  ],
                ),
                if (contextLabel != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    contextLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.smallMeta.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class HeroMetricCard extends StatelessWidget {
  final String eyebrow;
  final String value;
  final String? unit;
  final String contextLabel;
  final String? trend;
  final String timeframe;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? chart;

  const HeroMetricCard({
    super.key,
    required this.eyebrow,
    required this.value,
    required this.contextLabel,
    required this.timeframe,
    this.unit,
    this.trend,
    this.actionLabel,
    this.onAction,
    this.chart,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CardShell(
      variant: CardVariant.hero,
      tone: CineTone.premium,
      accentEdge: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: AppTextStyles.micro.copyWith(
              color: colors.textTertiary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: MetricValue(value: value, hero: true)),
              if (unit != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit!,
                    style: AppTextStyles.smallMeta.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            contextLabel,
            style: AppTextStyles.body.copyWith(color: colors.textSecondary),
          ),
          if (chart != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(height: 44, child: chart),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (trend != null) ...[
                TrendIndicator(label: trend!, tone: CineTone.positive),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  timeframe,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ),
              if (actionLabel != null)
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ),
        ],
      ),
    );
  }
}

class MetricStripItem {
  final IconData icon;
  final String label;
  final String value;
  final String? contextLabel;
  final String? trend;
  final CineTone tone;
  final VoidCallback? onTap;

  const MetricStripItem({
    required this.icon,
    required this.label,
    required this.value,
    this.contextLabel,
    this.trend,
    this.tone = CineTone.neutral,
    this.onTap,
  });
}

class MetricStrip extends StatelessWidget {
  final List<MetricStripItem> items;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  const MetricStrip({
    super.key,
    required this.items,
    this.title,
    this.actionLabel,
    this.onAction,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (items.isEmpty) return const SizedBox.shrink();
    return CardShell(
      variant: CardVariant.section,
      density: CardDensity.compact,
      radius: AppRadius.md,
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    title!,
                    style: AppTextStyles.cardTitle.copyWith(
                      color: colors.textPrimary,
                      fontSize: compact ? 15 : 16,
                    ),
                  ),
                ),
                if (actionLabel != null)
                  TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = _columnCount(constraints.maxWidth);
              final rowCount = (items.length / columns).ceil();
              return Column(
                children: [
                  for (var row = 0; row < rowCount; row++)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: colors.borderMuted),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var column = 0;
                              column < columns &&
                                  row * columns + column < items.length;
                              column++)
                            Expanded(
                              child: _MetricStripCell(
                                item: items[row * columns + column],
                                showDivider: column > 0,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  int _columnCount(double width) {
    final maxColumns = width >= 1160
        ? 4
        : width >= 780
            ? 4
            : width >= 560
                ? 3
                : width >= 320
                    ? 2
                    : 1;
    if (items.length == 6 && maxColumns == 4) return 3;
    return maxColumns.clamp(1, items.length);
  }
}

class _MetricStripCell extends StatelessWidget {
  final MetricStripItem item;
  final bool showDivider;

  const _MetricStripCell({required this.item, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(left: BorderSide(color: colors.borderMuted))
            : null,
      ),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: EdgeInsets.only(
            left: showDivider ? AppSpacing.md : 2,
            right: AppSpacing.md,
            top: 11,
            bottom: 10,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 16,
                      color: cineToneColor(context, item.tone),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.smallMeta.copyWith(
                          color: colors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                MetricValue(value: item.value, compact: true),
                if (item.trend != null || item.contextLabel != null) ...[
                  const SizedBox(height: 5),
                  if (item.trend != null)
                    TrendIndicator(label: item.trend!, tone: item.tone)
                  else
                    Text(
                      item.contextLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuickActionItem {
  final IconData icon;
  final String title;
  final String? description;
  final CineTone tone;
  final VoidCallback? onTap;

  const QuickActionItem({
    required this.icon,
    required this.title,
    this.description,
    this.tone = CineTone.neutral,
    this.onTap,
  });
}

class QuickActionCard extends StatelessWidget {
  final QuickActionItem item;
  final bool primary;
  final int descriptionMaxLines;

  const QuickActionCard({
    super.key,
    required this.item,
    this.primary = false,
    this.descriptionMaxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tone = primary ? CineTone.premium : item.tone;
    final referenceRoute = PortalReferenceDesign.usesReference(
      ModalRoute.of(context)?.settings.name,
    );
    return CardShell(
      variant: primary ? CardVariant.hero : CardVariant.compact,
      density: CardDensity.compact,
      tone: tone,
      onTap: item.onTap,
      semanticLabel: item.title,
      accentEdge: primary || referenceRoute,
      minHeight: referenceRoute ? 78 : 104,
      child: referenceRoute
          ? Row(
              children: [
                IconBadge(icon: item.icon, tone: tone),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle.copyWith(
                          color: colors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      if (item.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.description!,
                          maxLines: descriptionMaxLines,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.smallMeta.copyWith(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: cineToneColor(context, tone),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBadge(icon: item.icon, tone: tone, compact: true),
                const SizedBox(height: AppSpacing.md),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: colors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                if (item.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    maxLines: descriptionMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.smallMeta.copyWith(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class QuickActionRail extends StatelessWidget {
  final List<QuickActionItem> items;

  const QuickActionRail({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth >= 1200
                ? 6
                : constraints.maxWidth >= 820
                    ? 4
                    : constraints.maxWidth >= 560
                        ? 3
                        : 2)
            .clamp(1, items.length)
            .toInt();
        final width =
            (constraints.maxWidth - ((columns - 1) * AppSpacing.md)) / columns;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (var index = 0; index < items.length; index++)
              SizedBox(
                width: width,
                child: QuickActionCard(
                  item: items[index],
                  primary: index == 0,
                ),
              ),
          ],
        );
      },
    );
  }
}

class StatusCard extends StatelessWidget {
  final String title;
  final String status;
  final String metadata;
  final String nextStep;
  final CineTone tone;
  final IconData icon;
  final String? amount;
  final VoidCallback? onTap;

  const StatusCard({
    super.key,
    required this.title,
    required this.status,
    required this.metadata,
    required this.nextStep,
    required this.icon,
    this.tone = CineTone.neutral,
    this.amount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CardShell(
      density: CardDensity.compact,
      tone: tone,
      accentEdge: true,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            title: title,
            subtitle: metadata,
            leading: IconBadge(icon: icon, tone: tone, compact: true),
            trailing: CineStatusBadge(label: status, tone: tone),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  nextStep,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              if (amount != null) ...[
                const SizedBox(width: AppSpacing.md),
                Text(
                  CineFormat.normalizeCurrency(amount!),
                  style: AppTextStyles.metricNumberCompact.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class PriorityActionCard extends StatelessWidget {
  final String title;
  final String metadata;
  final String priority;
  final IconData icon;
  final CineTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onTap;
  final Widget? trailing;

  const PriorityActionCard({
    super.key,
    required this.title,
    required this.metadata,
    required this.priority,
    required this.icon,
    this.tone = CineTone.warning,
    this.actionLabel,
    this.onAction,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final referenceRoute = PortalReferenceDesign.usesReference(
      ModalRoute.of(context)?.settings.name,
    );
    return CardShell(
      variant: CardVariant.alert,
      density: CardDensity.compact,
      tone: tone,
      accentEdge: true,
      minHeight: referenceRoute ? 72 : null,
      onTap: actionLabel == null ? onTap : null,
      child: Row(
        children: [
          IconBadge(icon: icon, tone: tone, compact: true),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: colors.textPrimary,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metadata,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          trailing ??
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CineStatusBadge(label: priority, tone: tone),
                  if (actionLabel != null) ...[
                    const SizedBox(height: 4),
                    TextButton(
                        onPressed: onAction ?? onTap,
                        child: Text(actionLabel!)),
                  ],
                ],
              ),
        ],
      ),
    );
  }
}

class FinancialSummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final String period;
  final String status;
  final CineTone tone;
  final double? progress;
  final String? actionLabel;
  final VoidCallback? onAction;

  const FinancialSummaryCard({
    super.key,
    required this.label,
    required this.amount,
    required this.period,
    required this.status,
    this.tone = CineTone.neutral,
    this.progress,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CardShell(
      density: CardDensity.standard,
      tone: tone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              CineStatusBadge(label: status, tone: tone),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          MetricValue(value: amount),
          const SizedBox(height: 6),
          Text(
            period,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textTertiary,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.md),
            SegmentedProgress(
              values: [progress!.clamp(0, 1), 1 - progress!.clamp(0, 1)],
              tones: [tone, CineTone.neutral],
            ),
          ],
          if (actionLabel != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ),
        ],
      ),
    );
  }
}

class ProgressCard extends StatelessWidget {
  final String title;
  final String progressLabel;
  final String remaining;
  final String nextMilestone;
  final double progress;
  final CineTone tone;
  final VoidCallback? onTap;

  const ProgressCard({
    super.key,
    required this.title,
    required this.progressLabel,
    required this.remaining,
    required this.nextMilestone,
    required this.progress,
    this.tone = CineTone.premium,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CardShell(
      onTap: onTap,
      child: Row(
        children: [
          ProgressRing(value: progress, tone: tone),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  progressLabel,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SegmentedProgress(
                  values: [progress.clamp(0, 1), 1 - progress.clamp(0, 1)],
                  tones: [tone, CineTone.neutral],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$remaining · Next: $nextMilestone',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EntityPreviewCard extends StatelessWidget {
  final Widget? media;
  final String title;
  final String subtitle;
  final String status;
  final CineTone tone;
  final List<Widget> metadata;
  final Widget? trailing;
  final VoidCallback? onTap;

  const EntityPreviewCard({
    super.key,
    this.media,
    required this.title,
    required this.subtitle,
    required this.status,
    this.tone = CineTone.neutral,
    this.metadata = const [],
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CardShell(
      variant: media == null ? CardVariant.standard : CardVariant.media,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (media != null) media!,
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardHeader(
                  title: title,
                  subtitle: subtitle,
                  trailing:
                      trailing ?? CineStatusBadge(label: status, tone: tone),
                ),
                if (metadata.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    children: metadata,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  final String title;
  final String type;
  final String stage;
  final String nextMilestone;
  final double progress;
  final CineTone tone;
  final Widget? thumbnail;
  final VoidCallback? onTap;

  const ProjectCard({
    super.key,
    required this.title,
    required this.type,
    required this.stage,
    required this.nextMilestone,
    required this.progress,
    this.tone = CineTone.premium,
    this.thumbnail,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => EntityPreviewCard(
        media: thumbnail,
        title: title,
        subtitle: type,
        status: stage,
        tone: tone,
        onTap: onTap,
        metadata: [
          SizedBox(
            width: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedProgress(
                  values: [progress.clamp(0, 1), 1 - progress.clamp(0, 1)],
                  tones: [tone, CineTone.neutral],
                ),
                const SizedBox(height: 6),
                Text('Next: $nextMilestone', maxLines: 1),
              ],
            ),
          ),
        ],
      );
}

class BookingCard extends StatelessWidget {
  final String title;
  final String project;
  final String schedule;
  final String location;
  final String status;
  final String? amount;
  final CineTone tone;
  final VoidCallback? onTap;

  const BookingCard({
    super.key,
    required this.title,
    required this.project,
    required this.schedule,
    required this.location,
    required this.status,
    this.amount,
    this.tone = CineTone.information,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => StatusCard(
        title: title,
        status: status,
        metadata: '$project · $schedule',
        nextStep: location,
        icon: Icons.event_available_outlined,
        amount: amount,
        tone: tone,
        onTap: onTap,
      );
}

class DealCard extends StatelessWidget {
  final String counterparty;
  final String project;
  final String stage;
  final String amount;
  final String expiry;
  final CineTone tone;
  final VoidCallback? onTap;

  const DealCard({
    super.key,
    required this.counterparty,
    required this.project,
    required this.stage,
    required this.amount,
    required this.expiry,
    this.tone = CineTone.premium,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => StatusCard(
        title: counterparty,
        status: stage,
        metadata: project,
        nextStep: expiry,
        icon: Icons.handshake_outlined,
        amount: amount,
        tone: tone,
        onTap: onTap,
      );
}

class ContractCard extends StatelessWidget {
  final String title;
  final String parties;
  final String signatureStatus;
  final String deadline;
  final String? value;
  final CineTone tone;
  final VoidCallback? onTap;

  const ContractCard({
    super.key,
    required this.title,
    required this.parties,
    required this.signatureStatus,
    required this.deadline,
    this.value,
    this.tone = CineTone.warning,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => StatusCard(
        title: title,
        status: signatureStatus,
        metadata: parties,
        nextStep: deadline,
        icon: Icons.draw_outlined,
        amount: value,
        tone: tone,
        onTap: onTap,
      );
}

class TransactionCard extends StatelessWidget {
  final String party;
  final String type;
  final String project;
  final String amount;
  final String date;
  final String status;
  final CineTone tone;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.party,
    required this.type,
    required this.project,
    required this.amount,
    required this.date,
    required this.status,
    this.tone = CineTone.neutral,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => StatusCard(
        title: party,
        status: status,
        metadata: '$type · $project',
        nextStep: date,
        icon: Icons.receipt_long_outlined,
        amount: amount,
        tone: tone,
        onTap: onTap,
      );
}

class ActivityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String metadata;
  final String time;
  final CineTone tone;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.icon,
    required this.title,
    required this.metadata,
    required this.time,
    this.tone = CineTone.information,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => PriorityActionCard(
        title: title,
        metadata: metadata,
        priority: time,
        icon: icon,
        tone: tone,
        onTap: onTap,
      );
}

class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CardShell(
      variant: CardVariant.soft,
      density: CardDensity.standard,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconBadge(icon: icon, tone: CineTone.premium),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.cardTitle.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMuted.copyWith(height: 1.4),
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AlertCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final CineTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  const AlertCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.tone = CineTone.information,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CardShell(
      variant: CardVariant.alert,
      density: CardDensity.compact,
      tone: tone,
      accentEdge: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: icon, tone: tone, compact: true),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                    height: 1.35,
                  ),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(onPressed: onAction, child: Text(actionLabel!)),
                ],
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              tooltip: 'Dismiss',
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
        ],
      ),
    );
  }
}

class ChartCard extends StatelessWidget {
  final String title;
  final String summary;
  final String value;
  final String timeframe;
  final Widget chart;
  final Widget? legend;
  final VoidCallback? onOpen;
  final VoidCallback? onExport;

  const ChartCard({
    super.key,
    required this.title,
    required this.summary,
    required this.value,
    required this.timeframe,
    required this.chart,
    this.legend,
    this.onOpen,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CardShell(
      variant: CardVariant.section,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            title: title,
            subtitle: summary,
            trailing: CineStatusBadge(
              label: timeframe,
              tone: CineTone.neutral,
              showDot: false,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          MetricValue(value: value),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            label: '$title chart. $summary',
            image: true,
            child: chart,
          ),
          if (legend != null) ...[
            const SizedBox(height: AppSpacing.md),
            legend!,
          ],
          if (onOpen != null || onExport != null) ...[
            Divider(color: colors.borderMuted, height: AppSpacing.xxl),
            ActionRow(
              primary: onOpen == null
                  ? null
                  : TextButton(onPressed: onOpen, child: const Text('Details')),
              secondary: onExport == null
                  ? null
                  : IconButton(
                      tooltip: 'Export',
                      onPressed: onExport,
                      icon: const Icon(Icons.download_outlined),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class RecommendationCard extends StatelessWidget {
  final Widget? media;
  final String title;
  final String subtitle;
  final String reason;
  final String status;
  final VoidCallback? onTap;
  final VoidCallback? onSave;

  const RecommendationCard({
    super.key,
    this.media,
    required this.title,
    required this.subtitle,
    required this.reason,
    required this.status,
    this.onTap,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return EntityPreviewCard(
      media: media,
      title: title,
      subtitle: subtitle,
      status: status,
      tone: CineTone.premium,
      onTap: onTap,
      trailing: IconButton(
        tooltip: 'Save',
        onPressed: onSave,
        icon: const Icon(Icons.bookmark_border_rounded),
      ),
      metadata: [
        CineStatusBadge(
          label: reason,
          tone: CineTone.information,
          icon: Icons.auto_awesome_outlined,
          showDot: false,
        ),
      ],
    );
  }
}

class EntityAvatar extends StatelessWidget {
  final ImageProvider<Object>? image;
  final String label;
  final double size;
  final bool twoLetterInitials;

  const EntityAvatar({
    super.key,
    this.image,
    required this.label,
    this.size = 36,
    this.twoLetterInitials = false,
  });

  String get _initials {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return '?';
    if (!twoLetterInitials) return trimmed[0].toUpperCase();
    final words = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final letters = words.take(2).map((w) => w[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      label: label,
      image: true,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: colors.mutedSurface,
        backgroundImage: image,
        child: image == null
            ? Text(
                _initials,
                style: AppTextStyles.label.copyWith(color: colors.textPrimary),
              )
            : null,
      ),
    );
  }
}

class AvatarStack extends StatelessWidget {
  final List<Widget> avatars;
  final double avatarSize;

  const AvatarStack({
    super.key,
    required this.avatars,
    this.avatarSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    final visible = avatars.take(4).toList();
    return SizedBox(
      width: visible.isEmpty
          ? 0
          : avatarSize + ((visible.length - 1) * avatarSize * 0.62),
      height: avatarSize,
      child: Stack(
        children: [
          for (var index = 0; index < visible.length; index++)
            Positioned(left: index * avatarSize * 0.62, child: visible[index]),
        ],
      ),
    );
  }
}

class ActionRow extends StatelessWidget {
  final Widget? primary;
  final Widget? secondary;
  final Widget? menu;

  const ActionRow({
    super.key,
    this.primary,
    this.secondary,
    this.menu,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (secondary != null) secondary!,
        if (secondary != null && primary != null)
          const SizedBox(width: AppSpacing.sm),
        if (primary != null) primary!,
        if (menu != null) ...[
          const SizedBox(width: AppSpacing.sm),
          menu!,
        ],
      ],
    );
  }
}

class CardMenuItem<T> {
  final T value;
  final String label;
  final IconData icon;

  const CardMenuItem({
    required this.value,
    required this.label,
    required this.icon,
  });
}

class CardMenu<T> extends StatelessWidget {
  final List<CardMenuItem<T>> items;
  final ValueChanged<T> onSelected;

  const CardMenu({
    super.key,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: 'More actions',
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final item in items)
          PopupMenuItem<T>(
            value: item.value,
            child: Row(
              children: [
                Icon(item.icon, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(item.label),
              ],
            ),
          ),
      ],
      icon: const Icon(Icons.more_horiz_rounded),
    );
  }
}

class SectionContainer extends StatelessWidget {
  final String title;
  final Widget child;
  final String? description;
  final Widget? leading;
  final Widget? action;
  final SectionTreatment treatment;
  final CardDensity density;

  const SectionContainer({
    super.key,
    required this.title,
    required this.child,
    this.description,
    this.leading,
    this.action,
    this.treatment = SectionTreatment.open,
    this.density = CardDensity.standard,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final referenceRoute = PortalReferenceDesign.usesReference(
      ModalRoute.of(context)?.settings.name,
    );
    final sectionTone = _sectionTone(title);
    final resolvedLeading = leading ??
        (referenceRoute
            ? IconBadge(
                icon: _sectionIcon(title),
                tone: sectionTone,
              )
            : null);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resolvedLeading != null) ...[
              resolvedLeading,
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: referenceRoute
                        ? AppTextStyles.heroSerifHeadline.copyWith(
                            color: colors.textPrimary,
                            fontSize: 23,
                            fontWeight: FontWeight.w600,
                            height: 1.05,
                          )
                        : AppTextStyles.sectionTitle.copyWith(
                            color: colors.textPrimary,
                          ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: AppSpacing.sm),
              action!,
            ],
          ],
        ),
        if (referenceRoute) ...[
          const SizedBox(height: AppSpacing.md),
          Divider(color: colors.borderMuted, height: 1),
          const SizedBox(height: AppSpacing.md),
        ] else
          const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
    final resolvedContent = referenceRoute
        ? DefaultTextStyle.merge(
            style: AppTextStyles.body.copyWith(color: colors.textPrimary),
            child: content,
          )
        : content;
    final section = switch (treatment) {
      SectionTreatment.open when referenceRoute => CardShell(
          variant: CardVariant.section,
          density: density,
          radius: 22,
          accentEdge: true,
          tone: sectionTone,
          child: resolvedContent,
        ),
      SectionTreatment.open => resolvedContent,
      SectionTreatment.soft => CardShell(
          variant: CardVariant.soft,
          density: density,
          radius: referenceRoute ? 22 : null,
          child: resolvedContent,
        ),
      SectionTreatment.elevated => CardShell(
          variant: CardVariant.section,
          density: density,
          radius: referenceRoute ? 22 : null,
          accentEdge: referenceRoute,
          tone: referenceRoute ? sectionTone : CineTone.neutral,
          child: resolvedContent,
        ),
    };
    return section;
  }
}

CineTone _sectionTone(String title) {
  final value = title.toLowerCase();
  if (value.contains('risk') ||
      value.contains('incident') ||
      value.contains('dispute') ||
      value.contains('rejected')) {
    return CineTone.critical;
  }
  if (value.contains('payment') ||
      value.contains('earning') ||
      value.contains('finance') ||
      value.contains('contract') ||
      value.contains('due')) {
    return CineTone.warning;
  }
  if (value.contains('approved') ||
      value.contains('complete') ||
      value.contains('available') ||
      value.contains('verified')) {
    return CineTone.positive;
  }
  if (value.contains('schedule') ||
      value.contains('calendar') ||
      value.contains('message') ||
      value.contains('review') ||
      value.contains('history')) {
    return CineTone.information;
  }
  return CineTone.premium;
}

IconData _sectionIcon(String title) {
  final value = title.toLowerCase();
  if (value.contains('payment') ||
      value.contains('earning') ||
      value.contains('finance') ||
      value.contains('billing')) {
    return Icons.account_balance_wallet_outlined;
  }
  if (value.contains('contract') || value.contains('agreement')) {
    return Icons.draw_outlined;
  }
  if (value.contains('schedule') ||
      value.contains('calendar') ||
      value.contains('availability')) {
    return Icons.calendar_month_outlined;
  }
  if (value.contains('profile') || value.contains('talent')) {
    return Icons.person_search_outlined;
  }
  if (value.contains('message') || value.contains('room')) {
    return Icons.forum_outlined;
  }
  if (value.contains('review') ||
      value.contains('rating') ||
      value.contains('reputation')) {
    return Icons.workspace_premium_outlined;
  }
  if (value.contains('risk') ||
      value.contains('incident') ||
      value.contains('safety')) {
    return Icons.health_and_safety_outlined;
  }
  if (value.contains('report') ||
      value.contains('analytics') ||
      value.contains('performance')) {
    return Icons.insights_outlined;
  }
  if (value.contains('project') || value.contains('production')) {
    return Icons.movie_creation_outlined;
  }
  return Icons.auto_awesome_outlined;
}

class SkeletonCard extends StatefulWidget {
  final double height;
  final CardDensity density;

  const SkeletonCard({
    super.key,
    this.height = 128,
    this.density = CardDensity.standard,
  });

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class SkeletonSurface extends StatelessWidget {
  final double height;
  final CardDensity density;

  const SkeletonSurface({
    super.key,
    this.height = 128,
    this.density = CardDensity.standard,
  });

  @override
  Widget build(BuildContext context) => SkeletonCard(
        height: height,
        density: density,
      );
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.shimmer,
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
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return CardShell(
      density: widget.density,
      child: SizedBox(
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final position = reduceMotion ? 0.4 : _controller.value;
            return ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment(-1.6 + (position * 3.2), 0),
                end: Alignment(-0.6 + (position * 3.2), 0),
                colors: [
                  colors.borderMuted,
                  colors.surfaceHighlight,
                  colors.borderMuted,
                ],
              ).createShader(bounds),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Keep the placeholder lines inside compact skeletons.
                  // Several responsive loading states intentionally use
                  // 48-58px rows, so fixed desktop-sized lines overflowed.
                  final height = constraints.maxHeight;
                  final titleHeight = height < 72 ? height * 0.18 : 12.0;
                  final gapHeight = height < 72 ? height * 0.12 : AppSpacing.lg;
                  final headlineHeight = height < 72 ? height * 0.30 : 28.0;
                  final footerHeight = height < 72 ? height * 0.12 : 9.0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 132,
                        height: titleHeight,
                        color: colors.borderMuted,
                      ),
                      SizedBox(height: gapHeight),
                      Container(
                        width: 210,
                        height: headlineHeight,
                        color: colors.borderMuted,
                      ),
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        height: footerHeight,
                        color: colors.borderMuted,
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
