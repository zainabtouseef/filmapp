import 'package:flutter/material.dart';

import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';
import '../core_routes.dart';
import '../widgets/core_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  final _slides = const [
    _OnboardingSlide(
      icon: Icons.verified_user_outlined,
      title: 'Find Verified Industry Professionals',
      description:
          'Discover actors, models, locations, crew, media teams and production services in one trusted place.',
    ),
    _OnboardingSlide(
      icon: Icons.swap_horiz_rounded,
      title: 'Negotiate with Clarity',
      description:
          'Send structured offers, receive counteroffers, ask questions and lock final terms without scattered chats.',
    ),
    _OnboardingSlide(
      icon: Icons.draw_outlined,
      title: 'Sign Digital Contracts',
      description:
          'Convert approved terms into clean agreements with version history, signatures and secure records.',
    ),
    _OnboardingSlide(
      icon: Icons.admin_panel_settings_outlined,
      title: 'Payments Verified by Company',
      description:
          'Upload payment proof, track milestones and close bookings only after verification.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Leads with sign-in — the app has no anonymous browsing, so returning
  // users should land straight on "Welcome Back"; "Create an account" on
  // that screen is the fallback path for anyone without one yet.
  void _goSignIn() {
    Navigator.pushNamed(context, CoreRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return CoreScreenScaffold(
      scrollable: false,
      showGlobalControls: false,
      showBackdrop: false,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: CoreBrandMark()),
              TextButton(
                onPressed: _goSignIn,
                child: Text(
                  'Skip',
                  style: AppTextStyles.label.copyWith(color: colors.goldDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) =>
                  _OnboardingCard(slide: _slides[index]),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (dot) {
              final active = dot == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: active ? 28 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: active ? colors.goldGradient : null,
                  color: active ? null : colors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          CorePrimaryButton(
            icon: _index == _slides.length - 1
                ? Icons.rocket_launch_outlined
                : Icons.arrow_forward_rounded,
            label: _index == _slides.length - 1 ? 'Get Started' : 'Next',
            onTap: () {
              if (_index == _slides.length - 1) {
                _goSignIn();
              } else {
                _controller.nextPage(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _OnboardingCard extends StatelessWidget {
  final _OnboardingSlide slide;

  const _OnboardingCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 360 || size.height < 820;
    final visualOuter = compact ? 104.0 : 132.0;
    final visualInner = compact ? 66.0 : 82.0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: CoreGlassCard(
          padding: EdgeInsets.fromLTRB(
            compact ? 18 : 24,
            compact ? 22 : 30,
            compact ? 18 : 24,
            compact ? 22 : 30,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: visualOuter,
                height: visualOuter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colors.goldGlow.withValues(alpha: 0.72),
                      colors.goldGlow.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: visualInner,
                    height: visualInner,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: colors.goldGradient,
                    ),
                    child: Icon(
                      slide.icon,
                      color: colors.onGold,
                      size: compact ? 32 : 40,
                    ),
                  ),
                ),
              ),
              SizedBox(height: compact ? 18 : 26),
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: colors.textPrimary,
                  fontSize: compact ? 19 : 21,
                  height: 1.15,
                ),
              ),
              SizedBox(height: compact ? 8 : 10),
              Text(
                slide.description,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMuted.copyWith(
                  color: colors.textSecondary,
                  height: compact ? 1.35 : 1.45,
                  fontSize: compact ? 13 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
