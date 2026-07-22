import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_color_scheme.dart';

/// The persistent branding half of the auth split layout — an ambient,
/// theme-aware continuation of the splash screen's final wordmark card,
/// used on onboarding / role-selection / sign-in / sign-up so the brand
/// moment doesn't just vanish once the intro animation finishes.
class BrandPanel extends StatefulWidget {
  const BrandPanel({super.key});

  @override
  State<BrandPanel> createState() => _BrandPanelState();
}

class _BrandPanelState extends State<BrandPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Offset> _dust;

  static const _icons = [
    Icons.videocam_outlined,
    Icons.movie_creation_outlined,
    Icons.description_outlined,
    Icons.mic_none_outlined,
    Icons.wb_incandescent_outlined,
    Icons.location_on_outlined,
    Icons.groups_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _dust = List.generate(16, (i) {
      final r = math.Random(i * 53 + 7);
      return Offset(r.nextDouble(), r.nextDouble());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ColoredBox(
      color: colors.background,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final shimmer = ((t * 1.6) % 1.0);
          return LayoutBuilder(
            builder: (context, c) {
              final ring = math.min(c.maxWidth, c.maxHeight) * 0.36;
              return Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _AmbientDustPainter(
                        dust: _dust, t: t, color: colors.goldMid),
                  ),
                  for (var i = 0; i < _icons.length; i++)
                    Transform.translate(
                      offset: Offset(
                        math.cos(-math.pi / 2 +
                                i * 2 * math.pi / _icons.length) *
                            ring,
                        math.sin(-math.pi / 2 +
                                    i * 2 * math.pi / _icons.length) *
                                ring +
                            math.sin(t * 2 * math.pi + i) * 4,
                      ),
                      child: Opacity(
                        opacity: 0.35,
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: colors.goldMid.withValues(alpha: 0.6)),
                          ),
                          child:
                              Icon(_icons[i], size: 17, color: colors.goldDark),
                        ),
                      ),
                    ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          blendMode: BlendMode.srcATop,
                          shaderCallback: (bounds) {
                            const band = 0.18;
                            final pos = -band + (1 + band * 2) * shimmer;
                            return LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.5),
                                Colors.transparent,
                              ],
                              stops: [
                                (pos - band).clamp(0.0, 1.0),
                                pos.clamp(0.0, 1.0),
                                (pos + band).clamp(0.0, 1.0),
                              ],
                            ).createShader(bounds);
                          },
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 4.5,
                              ),
                              children: [
                                TextSpan(
                                    text: 'CINE',
                                    style:
                                        TextStyle(color: colors.textPrimary)),
                                TextSpan(
                                    text: 'CONNECT',
                                    style: TextStyle(color: colors.goldDark)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'CAST.  CONNECT.  CREATE.',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _AmbientDustPainter extends CustomPainter {
  final List<Offset> dust;
  final double t;
  final Color color;

  _AmbientDustPainter(
      {required this.dust, required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.28);
    for (var i = 0; i < dust.length; i++) {
      final seed = dust[i];
      final dx = (seed.dx * size.width +
              math.sin((t * 2 * math.pi) + seed.dy * 6) * 14) %
          size.width;
      final dy = (seed.dy * size.height +
              math.cos((t * 2 * math.pi) + seed.dx * 6) * 14) %
          size.height;
      canvas.drawCircle(Offset(dx, dy), 1.4 + seed.dx, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientDustPainter oldDelegate) => true;
}
