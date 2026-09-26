import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_durations.dart';
import '../../core/theme/app_text_styles.dart';

/// A shared CineConnect filter/tab rail.
///
/// The gold selection light moves between items, the selected item is kept in
/// view, and semantics expose the state even when motion is disabled.
class CineAnimatedFilterRail<T> extends StatefulWidget {
  final List<T> values;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T value) labelFor;
  final IconData? Function(T value)? iconFor;
  final Color? railColor;
  final Color? selectedColor;
  final Color? selectedTextColor;
  final Color? textColor;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final double gap;
  final double itemHeight;
  final bool showSelectionDot;

  const CineAnimatedFilterRail({
    super.key,
    required this.values,
    required this.selected,
    required this.onSelected,
    required this.labelFor,
    this.iconFor,
    this.railColor,
    this.selectedColor,
    this.selectedTextColor,
    this.textColor,
    this.borderColor,
    this.padding = const EdgeInsets.all(4),
    this.gap = 4,
    this.itemHeight = 44,
    this.showSelectionDot = true,
  });

  @override
  State<CineAnimatedFilterRail<T>> createState() =>
      _CineAnimatedFilterRailState<T>();
}

class _CineAnimatedFilterRailState<T> extends State<CineAnimatedFilterRail<T>> {
  final _scrollController = ScrollController();
  final _railKey = GlobalKey();
  late List<GlobalKey> _itemKeys;
  Rect? _indicatorRect;
  double _viewportWidth = 0;

  @override
  void initState() {
    super.initState();
    _itemKeys = List.generate(widget.values.length, (_) => GlobalKey());
    _scheduleIndicatorUpdate();
  }

  @override
  void didUpdateWidget(covariant CineAnimatedFilterRail<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.values.length != widget.values.length ||
        !_sameValues(oldWidget.values, widget.values)) {
      _itemKeys = List.generate(widget.values.length, (_) => GlobalKey());
    }
    _scheduleIndicatorUpdate();
  }

  bool _sameValues(List<T> left, List<T> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }

  void _scheduleIndicatorUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateIndicator());
  }

  void _updateIndicator() {
    if (!mounted || widget.values.isEmpty) return;
    final selectedIndex = widget.values.indexOf(widget.selected);
    if (selectedIndex < 0 || selectedIndex >= _itemKeys.length) return;
    final railBox = _railKey.currentContext?.findRenderObject() as RenderBox?;
    final itemBox = _itemKeys[selectedIndex].currentContext?.findRenderObject()
        as RenderBox?;
    if (railBox == null ||
        itemBox == null ||
        !railBox.hasSize ||
        !itemBox.hasSize) {
      return;
    }
    final origin = itemBox.localToGlobal(Offset.zero, ancestor: railBox);
    final nextRect = origin & itemBox.size;
    if (_indicatorRect != nextRect) {
      setState(() => _indicatorRect = nextRect);
    }
    if (_scrollController.hasClients && _viewportWidth > 0) {
      final target = (nextRect.center.dx - _viewportWidth / 2)
          .clamp(0.0, _scrollController.position.maxScrollExtent)
          .toDouble();
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reduceMotion) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: AppDurations.tab,
          curve: AppDurations.standardCurve,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final selectedColor = widget.selectedColor ?? colors.goldMid;
    final selectedTextColor = widget.selectedTextColor ?? colors.onGold;
    final textColor = widget.textColor ?? colors.textSecondary;
    final borderColor = widget.borderColor ?? colors.border;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportWidth = constraints.maxWidth;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: widget.railColor ??
                colors.surface.withValues(alpha: colors.isLight ? 0.58 : 0.24),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: widget.padding,
            child: Stack(
              key: _railKey,
              children: [
                if (_indicatorRect case final rect?)
                  AnimatedPositioned(
                    duration: reduceMotion ? Duration.zero : AppDurations.tab,
                    curve: AppDurations.standardCurve,
                    left: rect.left,
                    top: rect.top,
                    width: rect.width,
                    height: rect.height,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: selectedColor,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: selectedColor.withValues(alpha: 0.86),
                          ),
                          boxShadow: reduceMotion
                              ? null
                              : [
                                  BoxShadow(
                                    color:
                                        selectedColor.withValues(alpha: 0.28),
                                    blurRadius: 16,
                                    spreadRadius: -3,
                                  ),
                                ],
                        ),
                      ),
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0;
                        index < widget.values.length;
                        index++) ...[
                      if (index > 0) SizedBox(width: widget.gap),
                      _FilterItem<T>(
                        key: _itemKeys[index],
                        value: widget.values[index],
                        label: widget.labelFor(widget.values[index]),
                        icon: widget.iconFor?.call(widget.values[index]),
                        selected: widget.values[index] == widget.selected,
                        selectedTextColor: selectedTextColor,
                        textColor: textColor,
                        height: widget.itemHeight,
                        showSelectionDot: widget.showSelectionDot,
                        onTap: () {
                          widget.onSelected(widget.values[index]);
                          _scheduleIndicatorUpdate();
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FilterItem<T> extends StatefulWidget {
  final T value;
  final String label;
  final IconData? icon;
  final bool selected;
  final Color selectedTextColor;
  final Color textColor;
  final double height;
  final bool showSelectionDot;
  final VoidCallback onTap;

  const _FilterItem({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedTextColor,
    required this.textColor,
    required this.height,
    required this.showSelectionDot,
    required this.onTap,
  });

  @override
  State<_FilterItem<T>> createState() => _FilterItemState<T>();
}

class _FilterItemState<T> extends State<_FilterItem<T>> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final foreground =
        widget.selected ? widget.selectedTextColor : widget.textColor;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed && !reduceMotion ? 0.98 : 1,
          duration: reduceMotion ? Duration.zero : AppDurations.press,
          curve: AppDurations.standardCurve,
          child: Container(
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            alignment: Alignment.center,
            child: AnimatedDefaultTextStyle(
              duration: reduceMotion ? Duration.zero : AppDurations.tab,
              curve: AppDurations.standardCurve,
              style: AppTextStyles.caption.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 17, color: foreground),
                    const SizedBox(width: 7),
                  ] else if (widget.showSelectionDot) ...[
                    AnimatedContainer(
                      duration: reduceMotion ? Duration.zero : AppDurations.tab,
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: foreground,
                      ),
                    ),
                    const SizedBox(width: 7),
                  ],
                  Text(widget.label, maxLines: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
