import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../layout/admin_section_header.dart';
import '../widgets/queue_radar_painter.dart';

class QueueSnapshotItem {
  final IconData icon;
  final String title;
  final String count;
  final String status;
  final Color accentColor;

  const QueueSnapshotItem({
    required this.icon,
    required this.title,
    required this.count,
    required this.status,
    required this.accentColor,
  });
}

class AdminQueueSnapshotSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<QueueSnapshotItem> items;
  final String? actionText;
  final VoidCallback? onActionTap;

  const AdminQueueSnapshotSection({
    super.key,
    required this.title,
    required this.items,
    this.icon = Icons.layers_rounded,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final first = items.isNotEmpty ? items[0].accentColor : colors.success;
    final second = items.length > 1 ? items[1].accentColor : colors.infoPurple;
    final third = items.length > 2 ? items[2].accentColor : colors.goldMid;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = (width * 0.68).clamp(286.0, 560.0).toDouble();
        final scale = (height / 610).clamp(0.52, 1.0).toDouble();
        final radius = 32.0 * scale;
        final horizontalPadding = 44.0 * scale;
        final headerTop = 30.0 * scale;
        final headerHeight = 54.0 * scale;
        final bodyTop = headerTop + headerHeight + 8.0 * scale;
        final bodyBottom = 28.0 * scale;
        final radarWidth = width * 0.34;
        final listLeft = width * 0.345;
        final listRight = 30.0 * scale;

        // This is a deliberately dramatic, always-dark "featured analytics"
        // panel (radar visualization) — but the panel background must still
        // adapt per theme, or its always-light-text content becomes
        // illegible against a light page. See app_color_scheme.dart's
        // "always consume colors through context.appColors" rule.
        final light = colors.isLight;
        return Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: light ? 0.22 : 0.64),
                blurRadius: 34 * scale,
                offset: Offset(0, 20 * scale),
              ),
              BoxShadow(
                color: colors.infoBlue.withValues(alpha: 0.1),
                blurRadius: 38 * scale,
                spreadRadius: -8 * scale,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
                        gradient: light
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color.fromRGBO(28, 32, 38, 0.94),
                                  Color.fromRGBO(20, 24, 30, 0.96),
                                  Color.fromRGBO(16, 19, 24, 0.97),
                                ],
                                stops: [0.0, 0.52, 1.0],
                              )
                            : const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color.fromRGBO(18, 25, 28, 0.75),
                                  Color.fromRGBO(7, 11, 14, 0.88),
                                  Color.fromRGBO(4, 7, 10, 0.92),
                                ],
                                stops: [0.0, 0.52, 1.0],
                              ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
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
                          center: const Alignment(-0.72, -0.06),
                          radius: 0.7,
                          colors: [
                            colors.infoBlue.withValues(alpha: 0.14),
                            colors.goldGlow.withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.42, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.34),
                          ],
                          stops: const [0.56, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _QueueTexturePainter(
                        color: Colors.white.withValues(alpha: 0.026),
                      ),
                    ),
                  ),
                  Positioned(
                    left: horizontalPadding,
                    right: horizontalPadding,
                    top: headerTop,
                    height: headerHeight,
                    child: AdminSectionHeader(
                      icon: icon,
                      title: title,
                      actionText: actionText,
                      onActionTap: onActionTap,
                      iconColor: colors.goldLight,
                      actionColor: colors.goldLight,
                      titleColor: Colors.white,
                    ),
                  ),
                  Positioned(
                    left: 22 * scale,
                    top: bodyTop + 8 * scale,
                    width: radarWidth,
                    bottom: bodyBottom + 8 * scale,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.86,
                        child: CustomPaint(
                          painter: QueueRadarPainter(
                            green: first,
                            purple: second,
                            gold: third,
                            lineColor: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: listLeft,
                    right: listRight,
                    top: bodyTop,
                    bottom: bodyBottom,
                    child: Column(
                      children: [
                        for (var index = 0; index < items.length; index++) ...[
                          Expanded(
                            child: _QueueSnapshotRow(
                              item: items[index],
                              scale: scale,
                            ),
                          ),
                          if (index != items.length - 1)
                            Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QueueSnapshotRow extends StatelessWidget {
  final QueueSnapshotItem item;
  final double scale;

  const _QueueSnapshotRow({
    required this.item,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        _QueueIconOrb(
          icon: item.icon,
          accentColor: item.accentColor,
          size: 72 * scale,
          iconSize: 34 * scale,
        ),
        SizedBox(width: 22 * scale),
        Expanded(
          child: Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.cardLabel.copyWith(
              color: colors.textPrimary,
              fontSize: (23 * scale).clamp(12.0, 14.0).toDouble(),
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12 * scale),
        SizedBox(
          width: (142 * scale).clamp(66.0, 108.0).toDouble(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.count,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.smallMetricNumber.copyWith(
                  color: colors.textPrimary,
                  fontSize: (30 * scale).clamp(13.5, 16.5).toDouble(),
                ),
              ),
              SizedBox(height: 12 * scale),
              Text(
                item.status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.statusText.copyWith(
                  color: item.accentColor,
                  fontSize: (18 * scale).clamp(10.5, 12.0).toDouble(),
                  shadows: [
                    Shadow(
                      color: item.accentColor.withValues(alpha: 0.34),
                      blurRadius: 10,
                    ),
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

class _QueueIconOrb extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final double size;
  final double iconSize;

  const _QueueIconOrb({
    required this.icon,
    required this.accentColor,
    required this.size,
    required this.iconSize,
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
            accentColor.withValues(alpha: 0.22),
            colors.surface.withValues(alpha: 0.62),
            accentColor.withValues(alpha: 0.08),
          ],
          stops: const [0.0, 0.56, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.22),
            blurRadius: size * 0.48,
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Icon(
            icon,
            color: accentColor,
            size: iconSize,
            shadows: [
              Shadow(
                color: accentColor.withValues(alpha: 0.6),
                blurRadius: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueTexturePainter extends CustomPainter {
  final Color color;

  const _QueueTexturePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var y = 0.0; y < size.height; y += 18) {
      for (var x = (y % 36 == 0 ? 0.0 : 9.0); x < size.width; x += 36) {
        canvas.drawCircle(Offset(x, y), 0.75, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QueueTexturePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
