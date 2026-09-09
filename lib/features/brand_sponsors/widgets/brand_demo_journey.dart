import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/projects/project_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/tour/tour_target.dart';
import '../routes/brand_sponsor_routes.dart';
import 'brand_sponsor_live.dart';

const brandDemoProjectId = 'DEMO-BRAND-PRJ-001';
const brandDemoProjectTitle = 'Nova Cola Winter Stories';

bool isBrandDemoAccount(AuthController? auth) {
  return auth?.user?.email.toLowerCase() ==
      'brand01@demo.cine.nalexustechnologies.com';
}

Project? selectBrandDemoProject(Iterable<Project> projects) {
  final rows = projects.toList();
  for (final project in rows) {
    if (project.publicId == brandDemoProjectId) return project;
  }
  for (final project in rows) {
    if (project.title == brandDemoProjectTitle) return project;
  }
  for (final project in rows) {
    if (project.status == 'active') return project;
  }
  return rows.isEmpty ? null : rows.first;
}

class BrandDemoJourneyCard extends StatelessWidget {
  final Project project;
  final int shortlistCount;
  final int requestCount;
  final int confirmedCount;
  final VoidCallback onPlay;

  const BrandDemoJourneyCard({
    super.key,
    required this.project,
    required this.shortlistCount,
    required this.requestCount,
    required this.confirmedCount,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final stages = [
      _JourneyStage(
        number: '01',
        title: 'Project registered',
        detail:
            '${readableBrandStatus(project.projectType)} · ${project.city?.name ?? 'City set'}',
        icon: Icons.movie_creation_outlined,
        route: BrandSponsorRoutes.projects,
        complete: project.title.trim().isNotEmpty,
      ),
      _JourneyStage(
        number: '02',
        title: 'Production brief',
        detail: '${project.requirementCount} connected requirements',
        icon: Icons.checklist_rounded,
        route: BrandSponsorRoutes.projects,
        complete: project.requirementCount >= 5,
      ),
      _JourneyStage(
        number: '03',
        title: 'Talent & vendors',
        detail: 'Actor · model · crew · location · equipment',
        icon: Icons.travel_explore_outlined,
        route: BrandSponsorRoutes.marketplace,
        complete: shortlistCount > 0,
      ),
      _JourneyStage(
        number: '04',
        title: 'Project shortlist',
        detail: '$shortlistCount candidates compared in one board',
        icon: Icons.favorite_outline_rounded,
        route: BrandSponsorRoutes.shortlists,
        complete: shortlistCount >= 5,
      ),
      _JourneyStage(
        number: '05',
        title: 'Requests & terms',
        detail: '$requestCount live requests with chat and offers',
        icon: Icons.send_time_extension_outlined,
        route: BrandSponsorRoutes.bookings,
        complete: requestCount > 0,
      ),
      _JourneyStage(
        number: '06',
        title: 'Team secured',
        detail: '$confirmedCount accepted or secured bookings',
        icon: Icons.verified_outlined,
        route: BrandSponsorRoutes.bookings,
        complete: confirmedCount > 0,
      ),
    ];

    return TourTarget(
      id: 'brand:demo:journey',
      child: Container(
        key: const ValueKey('brand-demo-project-journey'),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: colors.goldMid.withValues(alpha: 0.58)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.goldDark.withValues(alpha: colors.isLight ? 0.18 : 0.30),
              colors.surface,
              colors.infoBlue.withValues(alpha: colors.isLight ? 0.08 : 0.16),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: colors.goldGlow,
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;
                final copy = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ONE PROJECT · COMPLETE LIVE FLOW',
                      style: AppTextStyles.micro.copyWith(
                        color: colors.goldDark,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      project.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heroSerifNumber.copyWith(
                        color: colors.textPrimary,
                        fontSize: compact ? 28 : 35,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Follow one campaign from registration and production requirements to discovery, shortlisting, negotiation and a secured shoot team. Every number below is loaded from the backend.',
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                );
                final play = FilledButton.icon(
                  key: const ValueKey('brand-demo-journey-play'),
                  onPressed: onPlay,
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: const Text('Play project story'),
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [copy, const SizedBox(height: 14), play],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: copy),
                    const SizedBox(width: 18),
                    play,
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1080
                    ? 6
                    : constraints.maxWidth >= 680
                        ? 3
                        : 1;
                final width =
                    (constraints.maxWidth - (columns - 1) * 10) / columns;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final stage in stages)
                      SizedBox(
                        width: width,
                        child: _JourneyStageTile(stage: stage),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyStage {
  final String number;
  final String title;
  final String detail;
  final IconData icon;
  final String route;
  final bool complete;

  const _JourneyStage({
    required this.number,
    required this.title,
    required this.detail,
    required this.icon,
    required this.route,
    required this.complete,
  });
}

class _JourneyStageTile extends StatelessWidget {
  final _JourneyStage stage;

  const _JourneyStageTile({required this.stage});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: colors.surface.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, stage.route),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 132),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: stage.complete
                  ? colors.success.withValues(alpha: 0.42)
                  : colors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(stage.icon, color: colors.goldDark, size: 20),
                  const Spacer(),
                  Text(
                    stage.number,
                    style: AppTextStyles.micro.copyWith(
                      color: colors.textTertiary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Text(
                stage.title,
                style: AppTextStyles.cardLabel.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stage.detail,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: colors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
