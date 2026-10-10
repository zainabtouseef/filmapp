import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_durations.dart';
import '../../../core/theme/app_text_styles.dart';

class DPHolographicButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool secondary;

  const DPHolographicButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.secondary = false,
  });

  @override
  State<DPHolographicButton> createState() => _DPHolographicButtonState();
}

class _DPHolographicButtonState extends State<DPHolographicButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final enabled = widget.onTap != null;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final active = enabled && (_hovered || _focused);
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
        onExit: enabled
            ? (_) => setState(() {
                  _hovered = false;
                  _pressed = false;
                })
            : null,
        child: Focus(
          onFocusChange:
              enabled ? (value) => setState(() => _focused = value) : null,
          child: AnimatedScale(
            scale: _pressed ? 0.975 : (active ? 1.025 : 1),
            duration: reduceMotion ? Duration.zero : AppDurations.hover,
            curve: AppDurations.standardCurve,
            child: AnimatedContainer(
              duration: reduceMotion ? Duration.zero : AppDurations.hover,
              curve: AppDurations.standardCurve,
              transform: Matrix4.translationValues(0, active ? -2 : 0, 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: colors.goldGlow.withValues(
                      alpha: !enabled
                          ? 0
                          : active
                              ? 0.24
                              : widget.secondary
                                  ? 0.04
                                  : 0.16,
                    ),
                    blurRadius: active ? 26 : 18,
                    offset: Offset(0, active ? 11 : 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: widget.onTap,
                  onHighlightChanged: enabled
                      ? (value) => setState(() => _pressed = value)
                      : null,
                  focusColor: colors.focusRing.withValues(alpha: 0.1),
                  hoverColor: colors.goldGlow.withValues(alpha: 0.05),
                  splashColor: colors.goldGlow.withValues(alpha: 0.12),
                  child: AnimatedContainer(
                    duration: reduceMotion ? Duration.zero : AppDurations.hover,
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: widget.secondary
                          ? colors.glassGradient
                          : colors.goldGradient,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _focused
                            ? colors.focusRing
                            : active
                                ? colors.goldMid.withValues(alpha: 0.9)
                                : widget.secondary
                                    ? colors.border
                                    : colors.goldMid,
                        width: _focused ? 1.5 : 1,
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final text = Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.statusText.copyWith(
                            color: widget.secondary
                                ? colors.textPrimary
                                : colors.onGold,
                          ),
                        );
                        final iconWidget = AnimatedScale(
                          scale: active ? 1.08 : 1,
                          duration:
                              reduceMotion ? Duration.zero : AppDurations.hover,
                          child: Icon(
                            widget.icon,
                            color: widget.secondary
                                ? colors.textPrimary
                                : colors.onGold,
                            size: 17,
                          ),
                        );
                        if (!constraints.hasBoundedWidth) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              iconWidget,
                              const SizedBox(width: 7),
                              text,
                            ],
                          );
                        }
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            iconWidget,
                            const SizedBox(width: 7),
                            Flexible(child: text),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
