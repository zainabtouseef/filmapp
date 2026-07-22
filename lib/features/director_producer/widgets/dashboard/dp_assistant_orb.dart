import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../routes/director_producer_routes.dart';

class _OrbAction {
  final IconData icon;
  final String label;
  final String subtitle;
  final String route;
  final Object? argument;

  const _OrbAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.route,
    this.argument,
  });
}

const _orbActions = [
  _OrbAction(
    icon: Icons.payments_outlined,
    label: 'Payments due',
    subtitle: 'Jump to milestones awaiting proof or verification',
    route: DirectorProducerRoutes.payments,
  ),
  _OrbAction(
    icon: Icons.draw_outlined,
    label: 'Contracts pending signature',
    subtitle: 'Review agreements waiting on a signature',
    route: DirectorProducerRoutes.contracts,
  ),
  _OrbAction(
    icon: Icons.manage_search_rounded,
    label: 'Find talent',
    subtitle: 'Open the marketplace scoped to Talent',
    route: DirectorProducerRoutes.marketplace,
    argument: {'category': 'Talent'},
  ),
  _OrbAction(
    icon: Icons.today_outlined,
    label: "Today's schedule",
    subtitle: 'See production events across every project',
    route: DirectorProducerRoutes.schedule,
  ),
  _OrbAction(
    icon: Icons.forum_outlined,
    label: 'Open production room',
    subtitle: 'Catch up on team chat and shared files',
    route: DirectorProducerRoutes.room,
  ),
];

/// The Smart Assistant Orb — a persistent floating control that expands
/// into a short list of real quick actions. There's no NLP backend in
/// this app, so it deliberately does not pretend to be a chat assistant;
/// every entry navigates somewhere real rather than faking a response.
class DPAssistantOrb extends StatefulWidget {
  final double bottomInset;

  const DPAssistantOrb({super.key, required this.bottomInset});

  @override
  State<DPAssistantOrb> createState() => _DPAssistantOrbState();
}

class _DPAssistantOrbState extends State<DPAssistantOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2, milliseconds: 200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openActions(BuildContext context) {
    final colors = context.appColors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: colors.holographicGradient,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 17),
                ),
                const SizedBox(width: 10),
                Text(
                  'Quick actions',
                  style: AppTextStyles.cardTitle
                      .copyWith(color: colors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final action in _orbActions)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.pushNamed(
                    context,
                    action.route,
                    arguments: action.argument,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      Icon(action.icon, size: 18, color: colors.goldDark),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              action.label,
                              style: AppTextStyles.cardLabel
                                  .copyWith(color: colors.textPrimary),
                            ),
                            Text(
                              action.subtitle,
                              style: AppTextStyles.caption
                                  .copyWith(color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: colors.iconMuted),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Positioned(
      right: 18,
      bottom: widget.bottomInset,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final glow = 0.22 + _controller.value * 0.14;
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.holographicTeal.withValues(alpha: glow),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: child,
          );
        },
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _openActions(context),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: colors.holographicGradient,
                border: Border.all(
                  color: colors.isLight
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.14),
                  width: 1.4,
                ),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
