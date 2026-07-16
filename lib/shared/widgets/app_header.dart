import 'package:flutter/material.dart';

import '../../core/core_ui/core_back_navigation.dart';
import '../../core/core_ui/core_logout.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/theme_controller.dart';
import 'glass_card.dart';

/// The CineConnect brand header: logo + tagline, theme toggle,
/// notification bell, and user avatar.
class CineConnectHeader extends StatelessWidget {
  final double horizontalPadding;
  final Widget avatar;
  final bool showBack;

  const CineConnectHeader({
    super.key,
    required this.horizontalPadding,
    required this.avatar,
    this.showBack = true,
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
          if (showBack) ...[
            _HeaderBackButton(size: tablet ? 42 : 34),
            SizedBox(width: tablet ? 18 : 12),
          ],
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
                SizedBox(width: tablet ? 18 : 12),
                _HeaderLogoutButton(size: tablet ? 42 : 34),
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

class _HeaderBackButton extends StatelessWidget {
  final double size;

  const _HeaderBackButton({required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: () => navigateCoreBack(context),
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
          Icons.arrow_back_rounded,
          color: colors.icon,
          size: size * 0.56,
        ),
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

class _HeaderLogoutButton extends StatelessWidget {
  final double size;

  const _HeaderLogoutButton({required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Tooltip(
      message: 'Logout',
      child: GestureDetector(
        onTap: () => logoutToLogin(context),
        child: GlassContainer(
          width: size,
          height: size,
          radius: size / 2,
          blur: 14,
          borderColor: colors.border,
          gradient: colors.glassGradient,
          shadows: [
            BoxShadow(
              color:
                  colors.shadow.withValues(alpha: colors.isLight ? 0.45 : 0.5),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
          child: Icon(
            Icons.logout_rounded,
            color: colors.icon,
            size: size * 0.54,
          ),
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
