import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/app_breakpoints.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import 'tour_controller.dart';
import 'tour_models.dart';

/// Global spotlight-tour visual layer. Mount once near the app root (see
/// `main.dart`'s `MaterialApp.builder`) — it renders nothing while no tour
/// is active, and otherwise paints a dark scrim with a glowing cutout
/// around the current step's target, a tooltip card, and a bottom pill
/// with step controls.
///
/// The scrim/glow/pill deliberately use fixed dark-theme colors regardless
/// of the app's own light/dark mode (matching the source design), since
/// they're translucent tour "chrome" sitting on top of the app rather than
/// opaque app content.
class SpotlightOverlay extends StatefulWidget {
  const SpotlightOverlay({super.key});

  @override
  State<SpotlightOverlay> createState() => _SpotlightOverlayState();
}

class _SpotlightOverlayState extends State<SpotlightOverlay>
    with TickerProviderStateMixin {
  TourController? _controller;
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;
  Duration _stepChangedAt = Duration.zero;
  String? _lastStepId;

  Rect? _displayRect;
  double _pulsePhase = 0;
  double _tooltipProgress = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = TourScope.maybeOf(context);
    if (!identical(controller, _controller)) {
      _controller?.removeListener(_onTourChanged);
      _controller = controller;
      _controller?.addListener(_onTourChanged);
      _onTourChanged();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTourChanged);
    _ticker?.dispose();
    super.dispose();
  }

  void _onTourChanged() {
    final controller = _controller;
    final active = controller?.isActive ?? false;
    if (active) {
      final ticker = _ticker ??= createTicker(_onTick);
      if (!ticker.isTicking) {
        _lastElapsed = Duration.zero;
        ticker.start();
      }
    } else {
      _ticker?.stop();
      _displayRect = null;
      _lastStepId = null;
      if (mounted) setState(() {});
    }

    final step = controller?.currentStep;
    if (step != null && step.id != _lastStepId) {
      _lastStepId = step.id;
      _stepChangedAt = _lastElapsed;
    }
  }

  void _onTick(Duration elapsed) {
    final controller = _controller;
    if (controller == null || !controller.isActive) {
      _ticker?.stop();
      return;
    }
    final dtSeconds = (elapsed - _lastElapsed).inMicroseconds /
        Duration.microsecondsPerSecond;
    _lastElapsed = elapsed;

    final step = controller.currentStep!;
    final measured = controller.rectFor(step.targetId);
    if (measured == null) {
      _displayRect = null;
    } else if (_displayRect == null) {
      _displayRect = measured;
    } else {
      // Exponential smoothing: glides toward the target every frame rather
      // than running a discrete per-step animation, so it stays correct
      // whether the change is a new tour step or just the page scrolling.
      const speed = 16.0;
      final t = (1 - math.exp(-speed * dtSeconds)).clamp(0.0, 1.0);
      _displayRect = Rect.lerp(_displayRect, measured, t);
    }

    _pulsePhase = (elapsed.inMilliseconds % 1600) / 1600;
    final sinceStep = (elapsed - _stepChangedAt).inMilliseconds / 220.0;
    _tooltipProgress = sinceStep.clamp(0.0, 1.0);

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final active = controller?.isActive ?? false;
    return IgnorePointer(
      ignoring: !active,
      child: !active
          ? const SizedBox.shrink()
          : _SpotlightContent(
              controller: controller!,
              rect: _displayRect,
              pulsePhase: _pulsePhase,
              tooltipProgress: _tooltipProgress,
            ),
    );
  }
}

// Fixed dark "tour chrome" palette — deliberately independent of the app's
// light/dark theme (see class doc on [SpotlightOverlay]).
const _pillBackground = Color(0xD416181D);
const _chromeGold = Color(0xFFE0AB45);
const _chromeGoldDeep = Color(0xFFC88A1E);
const _chromeOnGold = Color(0xFF201404);

class _SpotlightContent extends StatelessWidget {
  final TourController controller;
  final Rect? rect;
  final double pulsePhase;
  final double tooltipProgress;

  const _SpotlightContent({
    required this.controller,
    required this.rect,
    required this.pulsePhase,
    required this.tooltipProgress,
  });

  @override
  Widget build(BuildContext context) {
    final step = controller.currentStep;
    if (step == null) return const SizedBox.shrink();
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final mobile = context.isMobileWidth;

    final highlightRect = rect?.inflate(mobile ? 8 : 10);

    return Stack(
      children: [
        // CustomPaint hit-tests as opaque across its full bounds by default
        // (a CustomPainter with no hitTest override reports "hit" for any
        // position), which would silently swallow every tap — including
        // ones meant to fall through the cutout. IgnorePointer keeps this
        // layer purely visual; the `_TapBlocker`s below do the real,
        // cutout-aware hit testing.
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _SpotlightPainter(
                rect: highlightRect,
                radius: mobile ? 14 : 16,
                pulse: (math.sin(pulsePhase * 2 * math.pi) + 1) / 2,
              ),
            ),
          ),
        ),
        ..._buildTapBlockers(highlightRect, size),
        _Tooltip(
          step: step,
          rect: highlightRect,
          screenSize: size,
          bottomInset: bottomInset,
          progress: tooltipProgress,
          mobile: mobile,
        ),
        _BottomPill(
          controller: controller,
          bottomInset: bottomInset,
          mobile: mobile,
        ),
      ],
    );
  }

  /// Absorbs taps everywhere except the highlighted cutout, so the rest of
  /// the app can't be interacted with mid-tour — but the real widget under
  /// the spotlight stays fully tappable (the hole is simply not covered).
  List<Widget> _buildTapBlockers(Rect? highlight, Size size) {
    Widget blocker(Rect area) {
      if (area.width <= 0 || area.height <= 0) return const SizedBox.shrink();
      return Positioned.fromRect(
        rect: area,
        child: const _TapBlocker(),
      );
    }

    if (highlight == null) {
      return [blocker(Offset.zero & size)];
    }
    final r = Rect.fromLTRB(
      highlight.left.clamp(0.0, size.width),
      highlight.top.clamp(0.0, size.height),
      highlight.right.clamp(0.0, size.width),
      highlight.bottom.clamp(0.0, size.height),
    );
    return [
      blocker(Rect.fromLTRB(0, 0, size.width, r.top)),
      blocker(Rect.fromLTRB(0, r.bottom, size.width, size.height)),
      blocker(Rect.fromLTRB(0, r.top, r.left, r.bottom)),
      blocker(Rect.fromLTRB(r.right, r.top, size.width, r.bottom)),
    ];
  }
}

class _TapBlocker extends StatelessWidget {
  const _TapBlocker();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? rect;
  final double radius;
  final double pulse;

  const _SpotlightPainter({
    required this.rect,
    required this.radius,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final screenRect = Offset.zero & size;
    final scrimPaint = Paint()..color = Colors.black.withValues(alpha: 0.6);
    final r = rect;
    if (r == null) {
      canvas.drawRect(screenRect, scrimPaint);
      return;
    }

    final rrect = RRect.fromRectAndRadius(r, Radius.circular(radius));
    final scrimPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(screenRect),
      Path()..addRRect(rrect),
    );
    canvas.drawPath(scrimPath, scrimPaint);

    final glowAlpha = 0.32 + 0.28 * pulse;
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = _chromeGold.withValues(alpha: glowAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = _chromeGold.withValues(alpha: 0.75 + 0.25 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.rect != rect || oldDelegate.pulse != pulse;
  }
}

class _Tooltip extends StatelessWidget {
  final TourStep step;
  final Rect? rect;
  final Size screenSize;
  final double bottomInset;
  final double progress;
  final bool mobile;

  const _Tooltip({
    required this.step,
    required this.rect,
    required this.screenSize,
    required this.bottomInset,
    required this.progress,
    required this.mobile,
  });

  @override
  Widget build(BuildContext context) {
    const margin = 16.0;
    const gap = 14.0;
    final pillReserve = 92.0 + bottomInset;
    final width =
        mobile ? math.min(360.0, screenSize.width - margin * 2) : 340.0;
    const estimatedHeight = 150.0;

    double left;
    double top;
    final r = rect;
    if (r == null) {
      left = (screenSize.width - width) / 2;
      top = (screenSize.height - pillReserve - estimatedHeight) / 2;
    } else {
      left = (r.center.dx - width / 2).clamp(
        margin,
        math.max(margin, screenSize.width - width - margin),
      );
      final spaceBelow = screenSize.height - pillReserve - r.bottom - gap;
      final spaceAbove = r.top - gap;
      top = (spaceBelow >= estimatedHeight || spaceBelow >= spaceAbove)
          ? r.bottom + gap
          : math.max(margin, r.top - gap - estimatedHeight);
      top = top.clamp(
        margin,
        math.max(margin, screenSize.height - pillReserve - estimatedHeight),
      );
    }

    final opacity = Curves.easeOutCubic.transform(progress);
    return Positioned(
      left: left,
      top: top,
      width: width,
      child: IgnorePointer(
        ignoring: opacity < 0.99,
        child: Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, (1 - opacity) * 10),
            child: _TooltipCard(step: step),
          ),
        ),
      ),
    );
  }
}

class _TooltipCard extends StatelessWidget {
  final TourStep step;

  const _TooltipCard({required this.step});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xD62A303B), Color(0xBC0D1118)],
            ),
            borderRadius: radius,
            border: Border.all(color: _chromeGold, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.48),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_chromeGold, _chromeGoldDeep],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  step.badge,
                  style: AppTextStyles.micro.copyWith(
                    color: _chromeOnGold,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                step.title,
                style: AppTextStyles.cardTitle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                step.description,
                style: AppTextStyles.smallMeta.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomPill extends StatelessWidget {
  final TourController controller;
  final double bottomInset;
  final bool mobile;

  const _BottomPill({
    required this.controller,
    required this.bottomInset,
    required this.mobile,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.pill);
    final pill = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          constraints: BoxConstraints(maxWidth: mobile ? double.infinity : 380),
          decoration: BoxDecoration(
            color: _pillBackground,
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: mobile ? MainAxisSize.max : MainAxisSize.min,
            children: [
              _PillIconButton(
                icon: Icons.close_rounded,
                tooltip: 'Skip tour',
                onTap: controller.skip,
              ),
              _PillIconButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Back',
                onTap: controller.isFirstStep ? null : controller.back,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Center(
                  child: Text(
                    '${controller.currentIndex + 1} / ${controller.stepCount}',
                    style: AppTextStyles.smallMeta.copyWith(
                      color: _chromeGold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _PillActionButton(
                label: controller.isLastStep ? 'Done' : 'Next',
                onTap: controller.next,
              ),
            ],
          ),
        ),
      ),
    );

    return Positioned(
      left: mobile ? 16 : 0,
      right: mobile ? 16 : 0,
      bottom: 20 + bottomInset,
      child: mobile ? pill : Center(child: pill),
    );
  }
}

class _PillIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _PillIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        splashFactory: InkRipple.splashFactory,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: enabled ? 0.82 : 0.28),
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _PillActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PillActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      splashFactory: InkRipple.splashFactory,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_chromeGold, _chromeGoldDeep],
          ),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: AppTextStyles.smallMeta.copyWith(
            color: _chromeOnGold,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
