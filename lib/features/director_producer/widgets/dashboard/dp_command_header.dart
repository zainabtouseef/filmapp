import 'package:flutter/material.dart';

import '../../../../core/director/director_dashboard_models.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/tour/tour_target.dart';
import '../../../../shared/formatters/cine_format.dart';
import '../../routes/director_producer_routes.dart';
import '../dp_glass_card.dart';
import '../dp_holographic_button.dart';

/// The dashboard's command header: a cinematic hero card carrying the
/// day's greeting, committed budget, and primary actions. Search and
/// logout already live in the shell's own top bar, so this doesn't
/// repeat them.
class DPCommandHeader extends StatelessWidget {
  final DirectorDashboardSummary summary;

  const DPCommandHeader({super.key, required this.summary});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return _HeroCard(
      greeting: '$_greeting, Producer',
      activeProjects: summary.activeProjects,
      actionCount: summary.attentionCount,
      committedBudget: summary.committedBudgetMinor ~/ 100,
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String greeting;
  final int activeProjects;
  final int actionCount;
  final int committedBudget;

  const _HeroCard({
    required this.greeting,
    required this.activeProjects,
    required this.actionCount,
    required this.committedBudget,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final heroInk = colors.isLight ? colors.goldDark : colors.goldLight;
    final budgetInk = colors.isLight
        ? Color.lerp(colors.goldDark, colors.textPrimary, 0.22)!
        : colors.goldLight;
    return DPGlassCard(
      accentColor: colors.goldDark,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FoilLine(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 9, 16, 0),
            child: Row(
              children: [
                for (var i = 0; i < 14; i++)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(right: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      color: colors.borderMuted,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      AppTextStyles.heroSerifHeadline.copyWith(color: heroInk),
                ),
                const SizedBox(height: 3),
                Text(
                  actionCount == 0
                      ? '$activeProjects active productions · everything is caught up'
                      : '$activeProjects active productions · $actionCount need your attention',
                  style: AppTextStyles.smallMeta
                      .copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: Container(height: 1, color: colors.borderMuted),
                ),
                const SizedBox(height: 10),
                Text(
                  'COMMITTED BUDGET',
                  style: AppTextStyles.micro.copyWith(
                    color: colors.goldDark,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  CineFormat.currency(committedBudget, compact: true),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      AppTextStyles.heroSerifNumber.copyWith(color: budgetInk),
                ),
                const SizedBox(height: 12),
                TourTarget(
                  id: 'dp.newProject',
                  child: DPHolographicButton(
                    label: 'New Project',
                    icon: Icons.add_rounded,
                    onTap: () => Navigator.pushNamed(
                      context,
                      DirectorProducerRoutes.createProject,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A continuously-sliding gold/sage/violet gradient line — the "foil"
/// motif from the source design, built from two back-to-back copies of
/// the same stop sequence so the loop has no visible seam.
class _FoilLine extends StatefulWidget {
  const _FoilLine();

  @override
  State<_FoilLine> createState() => _FoilLineState();
}

class _FoilLineState extends State<_FoilLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final stops = [
      colors.goldMid,
      colors.success,
      colors.infoPurple,
      colors.goldMid,
    ];
    return SizedBox(
      height: 3,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return ClipRect(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Transform.translate(
                offset: Offset(-_controller.value * width, 0),
                child: Container(
                  width: width * 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [...stops, ...stops]),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
