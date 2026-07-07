import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double radius;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;
  final double blur;

  const GlassContainer({
    super.key,
    required this.child,
    this.radius = 18,
    this.width,
    this.height,
    this.padding = EdgeInsets.zero,
    this.gradient,
    this.borderColor,
    this.borderWidth = 1.15,
    this.shadows,
    this.blur = 18,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            gradient: gradient ?? colors.glassGradient,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor ?? colors.border,
              width: borderWidth,
            ),
            boxShadow: shadows,
          ),
          child: child,
        ),
      ),
    );
  }
}

class CineConnectHeader extends StatelessWidget {
  final double horizontalPadding;
  final Widget avatar;

  const CineConnectHeader({
    super.key,
    required this.horizontalPadding,
    required this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final width = MediaQuery.sizeOf(context).width;
    final tablet = width >= 700;
    final logoSize = tablet ? 28.0 : 20.0;
    final taglineSize = tablet ? 12.5 : 10.5;
    final avatarSize = tablet ? 56.0 : 48.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        tablet ? 34 : 18,
        horizontalPadding,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: RichText(
                          maxLines: 1,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'CINE',
                                style: AppTextStyles.brand.copyWith(
                                  color: colors.textPrimary,
                                  fontSize: logoSize,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: tablet ? 6.2 : 4.2,
                                  height: 1,
                                ),
                              ),
                              TextSpan(
                                text: 'CONNECT',
                                style: AppTextStyles.brand.copyWith(
                                  color: colors.goldMid,
                                  fontSize: logoSize,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: tablet ? 5.4 : 3.6,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: tablet ? 12 : 9),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'CAST. CONNECT. CREATE.',
                    maxLines: 1,
                    style: AppTextStyles.tagline.copyWith(
                      color: colors.textSecondary,
                      fontSize: taglineSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: tablet ? 5.5 : 4.5,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: tablet ? 24 : 12),
          Padding(
            padding: EdgeInsets.only(top: tablet ? 2 : 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ThemeToggleButton(size: tablet ? 42 : 34),
                SizedBox(width: tablet ? 18 : 12),
                _NotificationBell(tablet: tablet),
                SizedBox(width: tablet ? 20 : 14),
                _GoldAvatar(size: avatarSize, child: avatar),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ThemeToggleButton extends StatelessWidget {
  final double size;

  const ThemeToggleButton({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final controller = ThemeControllerProvider.of(context);

    return GestureDetector(
      onTap: controller.toggleTheme,
      child: GlassContainer(
        width: size,
        height: size,
        radius: size / 2,
        blur: 14,
        borderColor: colors.border,
        gradient: colors.glassGradient,
        shadows: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: colors.isLight ? 0.45 : 0.5),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        child: Icon(
          controller.isDarkMode
              ? Icons.wb_sunny_outlined
              : Icons.dark_mode_outlined,
          color: colors.goldMid,
          size: size * 0.54,
        ),
      ),
    );
  }
}

class PremiumSearchBar extends StatelessWidget {
  final double horizontalPadding;
  final String placeholder;

  const PremiumSearchBar({
    super.key,
    required this.horizontalPadding,
    this.placeholder = 'Search actors, models, directors...',
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final width = MediaQuery.sizeOf(context).width;
    final tablet = width >= 700;
    final height = tablet ? 76.0 : 64.0;
    final radius = tablet ? 32.0 : 29.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: GlassContainer(
        width: double.infinity,
        height: height,
        radius: radius,
        blur: 22,
        padding: EdgeInsets.zero,
        gradient: colors.searchGradient,
        borderColor: colors.border,
        borderWidth: 1.2,
        shadows: [
          BoxShadow(
            color:
                colors.shadow.withValues(alpha: colors.isLight ? 0.42 : 0.55),
            blurRadius: colors.isLight ? 26 : 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color:
                colors.goldGlow.withValues(alpha: colors.isLight ? 0.38 : 0.5),
            blurRadius: 18,
            offset: const Offset(8, -4),
          ),
        ],
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white
                          .withValues(alpha: colors.isLight ? 0.18 : 0.07),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.52],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 18,
              width: tablet ? 132 : 86,
              height: 1.1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.goldLight.withValues(alpha: 0),
                      colors.goldLight
                          .withValues(alpha: colors.isLight ? 0.28 : 0.54),
                      colors.goldLight.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                tablet ? 28 : 18,
                0,
                tablet ? 12 : 8,
                0,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: tablet ? 38 : 32,
                    color: colors.iconMuted,
                  ),
                  SizedBox(width: tablet ? 18 : 14),
                  Expanded(
                    child: Text(
                      placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMuted.copyWith(
                        color: colors.textSecondary,
                        fontSize: tablet ? 24 : 19,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  SizedBox(width: tablet ? 16 : 10),
                  GoldIconButton(
                    icon: Icons.tune_rounded,
                    size: tablet ? 58 : 48,
                    iconSize: tablet ? 32 : 26,
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

class GoldIconButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final VoidCallback? onTap;

  const GoldIconButton({
    super.key,
    required this.icon,
    this.size = 48,
    this.iconSize = 25,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: colors.glassGradient,
          borderRadius: BorderRadius.circular(size * 0.36),
          border: Border.all(
            color: colors.goldMid.withValues(alpha: 0.72),
            width: 1.05,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.goldGlow,
              blurRadius: 18,
              spreadRadius: -4,
            ),
            BoxShadow(
              color:
                  colors.shadow.withValues(alpha: colors.isLight ? 0.26 : 0.55),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Icon(icon, color: colors.goldMid, size: iconSize),
      ),
    );
  }
}

/// Pill-shaped category chip (Actors / Models / Directors ...).
class CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tablet = MediaQuery.sizeOf(context).width >= 700;
    final height = tablet ? 56.0 : 48.0;
    final foreground = active ? colors.goldDark : colors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: height,
        padding: EdgeInsets.symmetric(horizontal: tablet ? 22 : 18),
        decoration: BoxDecoration(
          gradient:
              active ? colors.activeChipGradient : colors.inactiveChipGradient,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(
            color: active ? colors.goldMid : colors.border,
            width: active ? 1.25 : 1.05,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  colors.shadow.withValues(alpha: colors.isLight ? 0.18 : 0.55),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            if (active)
              BoxShadow(
                color: colors.goldGlow,
                blurRadius: 20,
                spreadRadius: -4,
              ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: tablet ? 22 : 19, color: foreground),
              SizedBox(width: tablet ? 10 : 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: foreground,
                    fontSize: tablet ? 17 : 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FilterChipBox extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool showChevron;
  final Widget? trailing;
  final VoidCallback? onTap;

  const FilterChipBox({
    super.key,
    this.icon,
    required this.label,
    this.showChevron = true,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tablet = MediaQuery.sizeOf(context).width >= 700;
    final height = tablet ? 56.0 : 50.0;

    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        height: height,
        radius: tablet ? 16 : 15,
        blur: 14,
        padding: EdgeInsets.symmetric(horizontal: tablet ? 22 : 16),
        gradient: colors.filterGradient,
        borderColor: colors.border,
        borderWidth: 1.05,
        shadows: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: colors.isLight ? 0.2 : 0.44),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: tablet ? 22 : 19, color: colors.icon),
              SizedBox(width: tablet ? 12 : 9),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(
                  color: colors.textPrimary,
                  fontSize: tablet ? 17 : 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: tablet ? 14 : 10),
              trailing!,
            ] else if (showChevron) ...[
              SizedBox(width: tablet ? 14 : 10),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: tablet ? 23 : 20,
                color: colors.iconMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class VerifiedToggleChip extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const VerifiedToggleChip({
    super.key,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChipBox(
      label: 'Verified only',
      showChevron: false,
      trailing: GoldSwitch(value: value, onChanged: onChanged),
      onTap: () => onChanged?.call(!value),
    );
  }
}

/// Backwards-compatible name for older dashboard code.
class FilterControl extends FilterChipBox {
  const FilterControl({
    super.key,
    super.icon,
    required super.label,
    super.showChevron,
    super.trailing,
    super.onTap,
  });
}

/// A small gold toggle switch used in "Verified only".
class GoldSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const GoldSwitch({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tablet = MediaQuery.sizeOf(context).width >= 700;

    return GestureDetector(
      onTap: () => onChanged?.call(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: tablet ? 52 : 46,
        height: tablet ? 28 : 25,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          gradient: value ? colors.goldGradient : null,
          color: value ? null : colors.softSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                value ? colors.goldMid.withValues(alpha: 0.72) : colors.border,
          ),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: colors.goldGlow,
                    blurRadius: 15,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: tablet ? 22 : 19,
          height: tablet ? 22 : 19,
          decoration: BoxDecoration(
            color: colors.isLight ? Colors.white : const Color(0xFFFFF1C5),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colors.shadow
                    .withValues(alpha: colors.isLight ? 0.2 : 0.45),
                blurRadius: 7,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small outlined tag chip (Drama Serial / TVC / Theatre).
class TagChip extends StatelessWidget {
  final String label;

  const TagChip(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GlassContainer(
      radius: 22,
      blur: 10,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      gradient: colors.inactiveChipGradient,
      borderColor: colors.border,
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final bool tablet;

  const _NotificationBell({required this.tablet});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      width: tablet ? 46 : 36,
      height: tablet ? 46 : 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.bottomLeft,
            child: Icon(
              Icons.notifications_none_rounded,
              size: tablet ? 40 : 33,
              color: colors.icon,
              shadows: colors.isLight
                  ? null
                  : const [Shadow(color: Colors.black, blurRadius: 10)],
            ),
          ),
          Positioned(
            top: tablet ? 6 : 3,
            right: tablet ? 5 : 1,
            child: Container(
              width: tablet ? 18 : 15,
              height: tablet ? 18 : 15,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: colors.goldGradient,
                shape: BoxShape.circle,
                border: Border.all(color: colors.background, width: 1.6),
                boxShadow: [
                  BoxShadow(color: colors.goldGlow, blurRadius: 10),
                ],
              ),
              child: Text(
                '3',
                style: AppTextStyles.micro.copyWith(
                  color: colors.onGold,
                  fontSize: tablet ? 9 : 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldAvatar extends StatelessWidget {
  final double size;
  final Widget child;

  const _GoldAvatar({required this.size, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: colors.goldGradient,
        boxShadow: [
          BoxShadow(
            color: colors.goldGlow,
            blurRadius: 16,
            spreadRadius: -4,
          ),
          BoxShadow(
            color:
                colors.shadow.withValues(alpha: colors.isLight ? 0.18 : 0.55),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(child: child),
    );
  }
}
