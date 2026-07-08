import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';
import '../core_routes.dart';
import '../widgets/core_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  final bool hasValidToken = false;
  final bool isFirstLaunch = true;
  final bool forceUpdateRequired = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.86, end: 1).animate(_fade);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(_fade);
    Timer(const Duration(milliseconds: 2100), _routeNext);
  }

  void _routeNext() {
    if (!mounted) return;
    final route = forceUpdateRequired
        ? CoreRoutes.forceUpdate
        : hasValidToken
            ? CoreRoutes.dashboard
            : isFirstLaunch
                ? CoreRoutes.onboarding
                : CoreRoutes.login;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return CoreScreenScaffold(
      scrollable: false,
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Align(
                  alignment: Alignment(0.65, -0.28 + _controller.value * 0.08),
                  child: Container(
                    width: 240 + (_controller.value * 34),
                    height: 240 + (_controller.value * 34),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colors.goldGlow.withValues(alpha: 0.52),
                          colors.goldGlow.withValues(alpha: 0.16),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _scale,
                      child: Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: colors.goldGradient,
                          boxShadow: [
                            BoxShadow(
                              color: colors.goldGlow,
                              blurRadius: 36,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.movie_filter_rounded,
                          color: colors.onGold,
                          size: 52,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    const CoreBrandMark(large: true),
                    const SizedBox(height: 34),
                    Text(
                      'Preparing your production universe...',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMuted.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        width: 210,
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          color: colors.goldMid,
                          backgroundColor: colors.border,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Text(
              'v1.0.0',
              style: AppTextStyles.caption.copyWith(color: colors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}
