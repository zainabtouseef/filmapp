import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';

class MetricActionItem {
  final IconData icon;
  final String value;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback? onTap;

  const MetricActionItem({
    required this.icon,
    required this.value,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.onTap,
  });
}

class MetricActionCard extends StatelessWidget {
  final MetricActionItem item;

  const MetricActionCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final light = colors.isLight;
    return GestureDetector(
      onTap: item.onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const radius = 20.0;
          const orbSize = 36.0;
          const iconSize = 17.0;
          const numberSize = 20.0;
          const labelSize = 11.5;
          const metaSize = 10.8;
          final cardGradient = light
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.surface.withValues(alpha: 0.96),
                    Color.lerp(colors.surface, item.accentColor, 0.045)!
                        .withValues(alpha: 0.94),
                    colors.softSurface.withValues(alpha: 0.9),
                  ],
                  stops: const [0.0, 0.58, 1.0],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(10, 14, 20, 0.62),
                    Color.fromRGBO(3, 5, 8, 0.94),
                    Color.fromRGBO(5, 7, 11, 0.88),
                  ],
                  stops: [0.0, 0.52, 1.0],
                );
          final borderColor = light
              ? Color.lerp(colors.border, item.accentColor, 0.22)!
              : colors.textPrimary.withValues(alpha: 0.095);
          final lowerWashAlpha = light ? 0.06 : 0.038;

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: light
                      ? colors.shadow.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.72),
                  blurRadius: light ? 18 : 30,
                  offset: Offset(0, light ? 10 : 20),
                ),
                BoxShadow(
                  color:
                      item.accentColor.withValues(alpha: light ? 0.11 : 0.055),
                  blurRadius: light ? 14 : 18,
                  spreadRadius: light ? -6 : -4,
                ),
                BoxShadow(
                  color:
                      item.accentColor.withValues(alpha: light ? 0.13 : 0.13),
                  blurRadius: light ? 24 : 34,
                  spreadRadius: light ? -16 : -18,
                  offset: Offset(0, light ? 16 : 28),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          gradient: cardGradient,
                          border: Border.all(
                            color: borderColor,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          gradient: RadialGradient(
                            center: const Alignment(0, -0.72),
                            radius: 0.9,
                            colors: [
                              item.accentColor
                                  .withValues(alpha: light ? 0.1 : 0.045),
                              item.accentColor
                                  .withValues(alpha: light ? 0.035 : 0.012),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.38, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 1,
                      right: 1,
                      bottom: 0,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(radius),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              item.accentColor.withValues(alpha: 0.68),
                              Colors.white.withValues(alpha: 0.24),
                              item.accentColor.withValues(alpha: 0.52),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.24, 0.5, 0.76, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: item.accentColor.withValues(alpha: 0.44),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: constraints.maxHeight * 0.22,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              item.accentColor
                                  .withValues(alpha: lowerWashAlpha),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _MetricOrb(
                              icon: item.icon,
                              size: orbSize,
                              iconSize: iconSize,
                              accentColor: item.accentColor,
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.metricNumber.copyWith(
                                    color: item.accentColor,
                                    fontSize: item.value.length > 4
                                        ? numberSize * 0.72
                                        : numberSize,
                                    fontWeight: FontWeight.w800,
                                    shadows: [
                                      Shadow(
                                        color: item.accentColor
                                            .withValues(alpha: 0.26),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.cardLabel.copyWith(
                                    color: colors.textPrimary,
                                    fontSize: labelSize,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.statusText.copyWith(
                                color: item.accentColor,
                                fontSize: metaSize,
                                shadows: [
                                  Shadow(
                                    color:
                                        item.accentColor.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MetricActionRail extends StatelessWidget {
  final List<MetricActionItem> items;

  const MetricActionRail({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 940;
        final cardWidth = wide ? 150.0 : 128.0;
        final cardHeight = wide ? 150.0 : 140.0;
        final gap = wide ? 12.0 : 10.0;

        return SizedBox(
          height: cardHeight + 8,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(width: gap),
            itemBuilder: (context, index) {
              return SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: MetricActionCard(item: items[index]),
              );
            },
          ),
        );
      },
    );
  }
}

class _MetricOrb extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final Color accentColor;

  const _MetricOrb({
    required this.icon,
    required this.size,
    required this.iconSize,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            accentColor.withValues(alpha: 0.1),
            colors.surface.withValues(alpha: 0.7),
            accentColor.withValues(alpha: 0.055),
          ],
          stops: const [0.0, 0.58, 1.0],
        ),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.24),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.18),
            blurRadius: 24,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 54,
            spreadRadius: -12,
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Center(
            child: Icon(
              icon,
              color: accentColor,
              size: iconSize,
              shadows: [
                Shadow(
                  color: accentColor.withValues(alpha: 0.42),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
