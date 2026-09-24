import 'package:flutter/material.dart';

/// Staggers its children's entrance (fade + slide-up), each starting
/// slightly after the previous — the cinematic "cascade in" motion used
/// across the dashboard-kit's widget grids.
class PortalStaggeredReveal extends StatefulWidget {
  final List<Widget> children;
  final Axis direction;
  final double spacing;
  final double runSpacing;

  const PortalStaggeredReveal({
    super.key,
    required this.children,
    this.direction = Axis.horizontal,
    this.spacing = 14,
    this.runSpacing = 14,
  });

  @override
  State<PortalStaggeredReveal> createState() => _PortalStaggeredRevealState();
}

class _PortalStaggeredRevealState extends State<PortalStaggeredReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final count = widget.children.length.clamp(1, 8);
    return Wrap(
      spacing: widget.spacing,
      runSpacing: widget.runSpacing,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          if (reduceMotion)
            widget.children[i]
          else
            _RevealItem(
              controller: _controller,
              start: (i / count) * 0.5,
              child: widget.children[i],
            ),
      ],
    );
  }
}

class _RevealItem extends StatelessWidget {
  final AnimationController controller;
  final double start;
  final Widget child;

  const _RevealItem({
    required this.controller,
    required this.start,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: controller,
      curve: Interval(
        start.clamp(0.0, 1.0),
        (start + 0.5).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, (1 - curved.value) * 24),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
