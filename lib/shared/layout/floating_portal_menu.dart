import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/glass_card.dart';

class FloatingPortalMenuItem {
  final String route;
  final String label;
  final IconData icon;

  const FloatingPortalMenuItem({
    required this.route,
    required this.label,
    required this.icon,
  });
}

class FloatingPortalMenuOverlay extends StatelessWidget {
  final bool open;
  final String currentRoute;
  final List<FloatingPortalMenuItem> items;
  final String statusTitle;
  final String statusSubtitle;
  final IconData statusIcon;
  final VoidCallback onClose;
  final ValueChanged<String> onRouteTap;
  final bool Function(String currentRoute, String itemRoute)? isRouteActive;

  const FloatingPortalMenuOverlay({
    super.key,
    required this.open,
    required this.currentRoute,
    required this.items,
    required this.statusTitle,
    required this.statusSubtitle,
    required this.statusIcon,
    required this.onClose,
    required this.onRouteTap,
    this.isRouteActive,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return IgnorePointer(
      ignoring: !open,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final panelWidth =
              (constraints.maxWidth * 0.54).clamp(214.0, 314.0).toDouble();
          final navBarWide = constraints.maxWidth >= 700;
          final bottomGap = ((navBarWide ? 156 : 112) +
                  MediaQuery.paddingOf(context).bottom +
                  14)
              .toDouble();
          final panelHeight = (constraints.maxHeight - bottomGap - 14)
              .clamp(0.0, 1400.0)
              .toDouble();
          return Stack(
            children: [
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: open ? 1 : 0,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  child: GestureDetector(
                    onTap: onClose,
                    behavior: HitTestBehavior.opaque,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        color: Colors.black.withValues(
                          alpha: colors.isLight ? 0.08 : 0.22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                top: 14,
                child: AnimatedSlide(
                  offset: open ? Offset.zero : const Offset(-1.1, 0),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: open ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: SizedBox(
                      width: panelWidth,
                      height: panelHeight,
                      child: _FloatingPortalMenuPanel(
                        open: open,
                        currentRoute: currentRoute,
                        items: items,
                        statusTitle: statusTitle,
                        statusSubtitle: statusSubtitle,
                        statusIcon: statusIcon,
                        onClose: onClose,
                        onRouteTap: onRouteTap,
                        isRouteActive: isRouteActive,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FloatingPortalMenuPanel extends StatelessWidget {
  final bool open;
  final String currentRoute;
  final List<FloatingPortalMenuItem> items;
  final String statusTitle;
  final String statusSubtitle;
  final IconData statusIcon;
  final VoidCallback onClose;
  final ValueChanged<String> onRouteTap;
  final bool Function(String currentRoute, String itemRoute)? isRouteActive;

  const _FloatingPortalMenuPanel({
    required this.open,
    required this.currentRoute,
    required this.items,
    required this.statusTitle,
    required this.statusSubtitle,
    required this.statusIcon,
    required this.onClose,
    required this.onRouteTap,
    required this.isRouteActive,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassContainer(
      radius: 34,
      padding: EdgeInsets.zero,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors.isLight
            ? [
                colors.surface.withValues(alpha: 0.9),
                colors.softSurface.withValues(alpha: 0.78),
                colors.surface.withValues(alpha: 0.86),
              ]
            : [
                colors.surface.withValues(alpha: 0.58),
                colors.softSurface.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.18),
              ],
      ),
      borderColor: colors.textPrimary.withValues(alpha: 0.12),
      borderWidth: 0.75,
      blur: 40,
      shadows: [
        BoxShadow(
          color: colors.shadow.withValues(alpha: colors.isLight ? 0.16 : 0.62),
          blurRadius: 40,
          offset: const Offset(0, 24),
        ),
        BoxShadow(
          color: colors.goldGlow.withValues(alpha: 0.025),
          blurRadius: 28,
          offset: const Offset(28, 12),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = constraints.maxWidth - 26;
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Column(
              children: [
                SizedBox(
                  height: 46,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: 4,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 70,
                            height: 5,
                            decoration: BoxDecoration(
                              color: colors.textPrimary.withValues(alpha: 0.24),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: AnimatedScale(
                          scale: open ? 1 : 0.82,
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutBack,
                          child: GestureDetector(
                            onTap: onClose,
                            child: GlassContainer(
                              width: 40,
                              height: 40,
                              radius: 20,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colors.textPrimary.withValues(alpha: 0.06),
                                  colors.surface.withValues(alpha: 0.02),
                                ],
                              ),
                              borderColor:
                                  colors.textPrimary.withValues(alpha: 0.16),
                              borderWidth: 0.75,
                              blur: 28,
                              shadows: [
                                BoxShadow(
                                  color: colors.textPrimary
                                      .withValues(alpha: 0.08),
                                  blurRadius: 18,
                                ),
                              ],
                              child: Icon(
                                Icons.close_rounded,
                                color: colors.textPrimary,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final active = isRouteActive?.call(
                              currentRoute,
                              item.route,
                            ) ??
                            currentRoute == item.route;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == items.length - 1 ? 0 : 8,
                          ),
                          child: SizedBox(
                            width: contentWidth,
                            child: _FloatingPortalMenuCard(
                              item: item,
                              active: active,
                              open: open,
                              index: index,
                              onTap: () => onRouteTap(item.route),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _FloatingPortalStatusCard(
                  open: open,
                  title: statusTitle,
                  subtitle: statusSubtitle,
                  icon: statusIcon,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FloatingPortalMenuCard extends StatefulWidget {
  final FloatingPortalMenuItem item;
  final bool active;
  final bool open;
  final int index;
  final VoidCallback onTap;

  const _FloatingPortalMenuCard({
    required this.item,
    required this.active,
    required this.open,
    required this.index,
    required this.onTap,
  });

  @override
  State<_FloatingPortalMenuCard> createState() =>
      _FloatingPortalMenuCardState();
}

class _FloatingPortalMenuCardState extends State<_FloatingPortalMenuCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final glowColor = widget.active ? colors.goldLight : colors.goldGlow;
    const itemHeight = 48.0;
    const iconSize = 40.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: widget.open ? 0 : 1, end: widget.open ? 1 : 0),
      duration: Duration(milliseconds: 300 + widget.index * 36),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(-26 * (1 - value), 8 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          child: SizedBox(
            height: itemHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: GlassContainer(
                    radius: itemHeight / 2,
                    padding: const EdgeInsets.only(
                      left: iconSize + 22,
                      right: 12,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.active
                          ? [
                              colors.goldGlow.withValues(alpha: 0.035),
                              colors.surface.withValues(alpha: 0.3),
                              colors.goldGlow.withValues(alpha: 0.008),
                            ]
                          : [
                              colors.surface.withValues(
                                alpha: colors.isLight ? 0.54 : 0.24,
                              ),
                              colors.softSurface.withValues(
                                alpha: colors.isLight ? 0.38 : 0.12,
                              ),
                              colors.textPrimary.withValues(
                                alpha: colors.isLight ? 0.025 : 0.015,
                              ),
                            ],
                    ),
                    borderColor: widget.active
                        ? colors.goldLight.withValues(alpha: 0.16)
                        : colors.textPrimary.withValues(alpha: 0.1),
                    borderWidth: 0.75,
                    blur: 30,
                    shadows: [
                      BoxShadow(
                        color: glowColor.withValues(
                          alpha: widget.active ? 0.07 : 0.025,
                        ),
                        blurRadius: widget.active ? 18 : 12,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: widget.active
                              ? colors.goldLight.withValues(alpha: 0.9)
                              : colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: (itemHeight - iconSize) / 2,
                  child: Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colors.textPrimary.withValues(
                            alpha: colors.isLight ? 0.32 : 0.1,
                          ),
                          colors.surface.withValues(alpha: 0.42),
                          colors.goldGlow.withValues(alpha: 0.008),
                        ],
                      ),
                      border: Border.all(
                        color: widget.active
                            ? colors.goldLight.withValues(alpha: 0.24)
                            : colors.textPrimary.withValues(alpha: 0.1),
                        width: 0.85,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.goldGlow.withValues(
                            alpha: widget.active ? 0.14 : 0.02,
                          ),
                          blurRadius: widget.active ? 16 : 10,
                          spreadRadius: widget.active ? 0 : -2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        widget.item.icon,
                        color: colors.textPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingPortalStatusCard extends StatelessWidget {
  final bool open;
  final String title;
  final String subtitle;
  final IconData icon;

  const _FloatingPortalStatusCard({
    required this.open,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: open ? 0 : 1, end: open ? 1 : 0),
      duration: const Duration(milliseconds: 440),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(-18 * (1 - value), 8 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GlassContainer(
        width: double.infinity,
        height: 62,
        radius: 17,
        padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.textPrimary.withValues(alpha: colors.isLight ? 0.08 : 0.045),
            colors.surface.withValues(alpha: colors.isLight ? 0.48 : 0.2),
            colors.goldGlow.withValues(alpha: 0.012),
          ],
        ),
        borderColor: colors.textPrimary.withValues(alpha: 0.11),
        borderWidth: 0.75,
        blur: 30,
        shadows: [
          BoxShadow(
            color: colors.goldGlow.withValues(alpha: 0.025),
            blurRadius: 14,
            offset: const Offset(0, 12),
          ),
        ],
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.goldLight.withValues(alpha: 0.36),
                    colors.surface.withValues(alpha: 0.34),
                    colors.textPrimary.withValues(alpha: 0.04),
                  ],
                ),
                border: Border.all(
                  color: colors.goldLight.withValues(alpha: 0.14),
                  width: 0.85,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.goldGlow.withValues(alpha: 0.08),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: colors.onGold,
                size: 28,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      maxLines: 1,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: colors.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.success,
                boxShadow: [
                  BoxShadow(
                    color: colors.success.withValues(alpha: 0.8),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
