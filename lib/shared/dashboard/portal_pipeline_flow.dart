import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';

/// One real stage in a [PortalPipelineFlow] — e.g. "Negotiating" with a
/// real count of items currently in that stage.
class PortalPipelineStage {
  final String value;
  final String label;
  final String? sublabel;
  final Color color;

  const PortalPipelineStage({
    required this.value,
    required this.label,
    this.sublabel,
    required this.color,
  });
}

/// A horizontal multi-stage flow visualization — connected stage badges
/// with a travelling animated dot along the connecting line, for a real
/// deals/bookings/requests pipeline. Reduced motion freezes the dot.
class PortalPipelineFlow extends StatefulWidget {
  final List<PortalPipelineStage> stages;

  const PortalPipelineFlow({super.key, required this.stages});

  @override
  State<PortalPipelineFlow> createState() => _PortalPipelineFlowState();
}

class _PortalPipelineFlowState extends State<PortalPipelineFlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
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
    if (widget.stages.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          height: 78,
          width: width,
          child: Stack(
            children: [
              Positioned(
                left: width / (widget.stages.length * 2),
                right: width / (widget.stages.length * 2),
                top: 15,
                child: Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: [
                        for (final stage in widget.stages)
                          stage.color.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: width / (widget.stages.length * 2) - 5,
                right: width / (widget.stages.length * 2) - 5,
                top: 10,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _TravelingDotPainter(
                        progress: _controller.value,
                        color: colors.goldMid,
                      ),
                      size: const Size(double.infinity, 10),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  for (final stage in widget.stages)
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colors.card,
                              shape: BoxShape.circle,
                              border: Border.all(color: stage.color, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.card,
                                  blurRadius: 0,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: stage.color.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Text(
                              stage.value,
                              style: AppTextStyles.micro.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            stage.label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                          if (stage.sublabel != null)
                            Text(
                              stage.sublabel!,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.micro.copyWith(
                                color: colors.textTertiary,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TravelingDotPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _TravelingDotPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width * progress;
    final paint = Paint()..color = color;
    canvas.drawCircle(Offset(x, size.height / 2), 4, paint);
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(x, size.height / 2), 6, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _TravelingDotPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
