import 'package:flutter/widgets.dart';

import 'tour_controller.dart';

/// Wraps any widget so a spotlight tour can highlight it by [id].
///
/// Registers its render bounds with the nearest [TourScope] while mounted.
/// If the tour is currently waiting on this exact target, tapping it
/// (through the spotlight's cutout) both performs the widget's real action
/// and advances the tour — observed via a raw [Listener] rather than a
/// [GestureDetector], since a second `TapGestureRecognizer` wrapping an
/// already-interactive child competes with the child's own in the same
/// gesture arena and only one of them ends up firing; a `Listener` sees
/// every pointer event without entering that competition at all.
class TourTarget extends StatefulWidget {
  final String id;
  final Widget child;

  const TourTarget({super.key, required this.id, required this.child});

  @override
  State<TourTarget> createState() => _TourTargetState();
}

class _TourTargetState extends State<TourTarget> {
  final GlobalKey _renderKey = GlobalKey();
  TourController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = TourScope.maybeOf(context);
    if (!identical(controller, _controller)) {
      _controller?.unregisterTarget(widget.id, _renderKey);
      _controller = controller;
      _controller?.registerTarget(widget.id, _renderKey);
    }
  }

  @override
  void didUpdateWidget(covariant TourTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _controller?.unregisterTarget(oldWidget.id, _renderKey);
      _controller?.registerTarget(widget.id, _renderKey);
    }
  }

  @override
  void dispose() {
    _controller?.unregisterTarget(widget.id, _renderKey);
    super.dispose();
  }

  void _handlePointerUp(PointerUpEvent event) {
    final controller = _controller;
    if (controller == null || !controller.isActive) return;
    if (controller.currentStep?.targetId == widget.id) {
      controller.next();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerUp: _handlePointerUp,
      child: KeyedSubtree(key: _renderKey, child: widget.child),
    );
  }
}
