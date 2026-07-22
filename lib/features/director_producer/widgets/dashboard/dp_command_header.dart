import 'package:flutter/material.dart';

import '../../../../core/core_ui/core_routes.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/director_producer_demo_data.dart';
import '../../routes/director_producer_routes.dart';
import '../dp_glass_card.dart';
import '../dp_holographic_button.dart';
import 'dp_dashboard_insights.dart';

/// Compact command header replacing the generic centered "Dashboard"
/// title — greeting, one-line business summary, a real cross-entity
/// search, and the primary create action.
class DPCommandHeader extends StatefulWidget {
  const DPCommandHeader({super.key});

  @override
  State<DPCommandHeader> createState() => _DPCommandHeaderState();
}

class _DPCommandHeaderState extends State<DPCommandHeader> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final activeProjects = DirectorProducerDemoData.projects
        .where((p) => p.status != 'Closed')
        .length;
    final actionCount = dpPriorityItems().length;
    final hits = _query.trim().isEmpty ? const <_SearchHit>[] : _search(_query);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        return DPGlassCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flex(
                direction: compact ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: compact
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: compact ? 0 : 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_greeting, Producer',
                          style: AppTextStyles.cardTitle.copyWith(
                            color: colors.textPrimary,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          actionCount == 0
                              ? '$activeProjects active productions • everything is caught up.'
                              : '$activeProjects active productions • $actionCount need your attention today.',
                          style: AppTextStyles.smallMeta.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: compact ? 0 : 14, height: compact ? 12 : 0),
                  Row(
                    mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
                    children: [
                      _IconAction(
                        icon: Icons.notifications_none_rounded,
                        tooltip: 'Notifications',
                        onTap: () => Navigator.pushNamed(
                          context,
                          CoreRoutes.notifications,
                        ),
                      ),
                      const SizedBox(width: 8),
                      DPHolographicButton(
                        label: 'New Project',
                        icon: Icons.add_rounded,
                        onTap: () => Navigator.pushNamed(
                          context,
                          DirectorProducerRoutes.createProject,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  gradient: colors.searchGradient,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded,
                        color: colors.goldDark, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: (value) => setState(() => _query = value),
                        style: AppTextStyles.label
                            .copyWith(color: colors.textPrimary),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText:
                              'Search projects, talent, contracts, payments…',
                          hintStyle: AppTextStyles.smallMeta
                              .copyWith(color: colors.textSecondary),
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() {
                          _controller.clear();
                          _query = '';
                        }),
                        child: Icon(Icons.close_rounded,
                            color: colors.iconMuted, size: 18),
                      ),
                  ],
                ),
              ),
              if (hits.isNotEmpty) ...[
                const SizedBox(height: 10),
                for (final hit in hits) _SearchHitTile(hit: hit),
              ] else if (_query.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'No matches for "$_query".',
                  style: AppTextStyles.smallMeta
                      .copyWith(color: colors.textSecondary),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  List<_SearchHit> _search(String rawQuery) {
    final query = rawQuery.toLowerCase();
    bool has(String value) => value.toLowerCase().contains(query);
    final hits = <_SearchHit>[];

    for (final project in DirectorProducerDemoData.projects) {
      if (has(project.title) || has(project.city) || has(project.type)) {
        hits.add(_SearchHit(
          icon: Icons.movie_creation_outlined,
          title: project.title,
          subtitle: '${project.type} • ${project.city}',
          route: DirectorProducerRoutes.projectDetail,
          argument: project.id,
        ));
      }
    }
    for (final candidate in DirectorProducerDemoData.candidates) {
      if (has(candidate.name) ||
          has(candidate.category) ||
          has(candidate.city)) {
        hits.add(_SearchHit(
          icon: Icons.person_search_outlined,
          title: candidate.name,
          subtitle: '${candidate.category} • ${candidate.city}',
          route: DirectorProducerRoutes.profile,
          argument: candidate.id,
        ));
      }
    }
    for (final contract in DirectorProducerDemoData.contracts) {
      if (has(contract.title) ||
          has(contract.project) ||
          has(contract.candidate)) {
        hits.add(_SearchHit(
          icon: Icons.article_outlined,
          title: contract.title,
          subtitle: '${contract.project} • ${contract.candidate}',
          route: DirectorProducerRoutes.contracts,
        ));
      }
    }
    for (final payment in DirectorProducerDemoData.payments) {
      if (has(payment.stakeholder) || has(payment.booking)) {
        hits.add(_SearchHit(
          icon: Icons.payments_outlined,
          title: payment.stakeholder,
          subtitle: '${payment.booking} • PKR ${payment.amount}',
          route: DirectorProducerRoutes.payments,
        ));
      }
    }
    for (final booking in DirectorProducerDemoData.bookings) {
      if (has(booking.candidate) || has(booking.requirement)) {
        hits.add(_SearchHit(
          icon: Icons.handshake_outlined,
          title: booking.candidate,
          subtitle: '${booking.requirement} • ${booking.stage}',
          route: DirectorProducerRoutes.bargaining,
        ));
      }
    }
    return hits.take(8).toList();
  }
}

class _SearchHit {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Object? argument;

  const _SearchHit({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    this.argument,
  });
}

class _SearchHitTile extends StatelessWidget {
  final _SearchHit hit;

  const _SearchHitTile({required this.hit});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          Navigator.pushNamed(context, hit.route, arguments: hit.argument),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: colors.surface.withValues(alpha: colors.isLight ? 0.6 : 0.18),
          border: Border.all(color: colors.borderMuted),
        ),
        child: Row(
          children: [
            Icon(hit.icon, size: 16, color: colors.goldDark),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hit.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardLabel
                        .copyWith(color: colors.textPrimary),
                  ),
                  Text(
                    hit.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption
                        .copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: colors.iconMuted),
          ],
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.surface.withValues(alpha: colors.isLight ? 0.7 : 0.2),
            border: Border.all(color: colors.border),
          ),
          child: Icon(icon, color: colors.icon, size: 19),
        ),
      ),
    );
  }
}
