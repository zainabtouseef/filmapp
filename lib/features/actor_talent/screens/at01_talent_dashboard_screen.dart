import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/actor_talent_demo_data.dart';
import '../models/actor_talent_models.dart';
import '../routes/actor_talent_routes.dart';
import '../widgets/actor_talent_components.dart';

/// AT-01 Talent Dashboard
class AT01TalentDashboardScreen extends StatelessWidget {
  const AT01TalentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ActorTalentDemoStore.instance,
      builder: (context, _) {
        final store = ActorTalentDemoStore.instance;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ActorSectionCard(
              title: 'Command Snapshot',
              icon: Icons.auto_awesome_outlined,
              actionText: 'Profile',
              onActionTap: () =>
                  Navigator.pushNamed(context, ActorTalentRoutes.profile),
              selected: store.profileCompleteness < 80,
              child: ActorTwoColumn(
                left: _IdentityCard(store: store),
                right: ActorProgressMeter(value: store.profileCompleteness),
              ),
            ),
            const SizedBox(height: 12),
            const PersonalDashboardKpiStrip(),
            const SizedBox(height: 12),
            ActorKpiRail(metrics: ActorTalentDemoData.metrics),
            const SizedBox(height: 12),
            ActorTwoColumn(
              left: _PendingWork(store: store),
              right: _DashboardSideRail(store: store),
            ),
          ],
        );
      },
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final ActorTalentDemoStore store;

  const _IdentityCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        SizedBox(
          width: 82,
          child: ActorMediaFrame(
            imageUrl: ActorTalentDemoData.profileImage,
            title: store.profileStageName,
            badge: 'Verified',
            fallbackIcon: Icons.person_outline_rounded,
            aspectRatio: 1,
            compact: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                store.profileStageName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sectionHeading.copyWith(
                  color: colors.textPrimary,
                  fontSize: 19,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${store.profileCity} - ${store.profileLanguages}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.smallMeta.copyWith(
                  color: colors.textSecondary,
                  height: 1.28,
                ),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  ActorStatusLabel(label: store.agency),
                  ActorStatusLabel(
                    label: store.profileSubmittedForReview
                        ? 'Review queued'
                        : 'Draft profile',
                    tone: store.profileSubmittedForReview
                        ? ActorTone.green
                        : ActorTone.gold,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PendingWork extends StatelessWidget {
  final ActorTalentDemoStore store;

  const _PendingWork({required this.store});

  @override
  Widget build(BuildContext context) {
    return ActorSectionCard(
      title: 'Action Required',
      icon: Icons.priority_high_rounded,
      actionText: 'Inbox',
      onActionTap: () =>
          Navigator.pushNamed(context, ActorTalentRoutes.opportunities),
      child: store.activeTasks.isEmpty
          ? const _NoActivityCard()
          : ActorTaskRail(tasks: store.activeTasks),
    );
  }
}

class _DashboardSideRail extends StatelessWidget {
  final ActorTalentDemoStore store;

  const _DashboardSideRail({required this.store});

  @override
  Widget build(BuildContext context) {
    final first = ActorTalentDemoData.opportunities.first;
    final status = store.opportunityStatus(first);
    return Column(
      children: [
        ActorSectionCard(
          title: 'Primary Match',
          icon: Icons.local_activity_outlined,
          actionText: 'Open',
          onActionTap: () => Navigator.pushNamed(
            context,
            ActorTalentRoutes.offerDetail,
            arguments: first.id,
          ),
          child: Column(
            children: [
              ActorMediaFrame(
                imageUrl: first.imageUrl,
                title: first.projectTitle,
                badge: first.expiry,
                fallbackIcon: Icons.movie_filter_outlined,
              ),
              const SizedBox(height: 10),
              ActorInfoRow(
                icon: Icons.badge_outlined,
                label: first.role,
                value: first.fee,
              ),
              ActorInfoRow(
                icon: Icons.verified_outlined,
                label: 'Status',
                value: ActorTalentDemoData.statusLabel(status),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ActorSectionCard(
          title: 'Rating Snapshot',
          icon: Icons.stars_outlined,
          actionText: 'Reviews',
          onActionTap: () =>
              Navigator.pushNamed(context, ActorTalentRoutes.reputation),
          child: const Column(
            children: [
              ActorInfoRow(
                icon: Icons.schedule_rounded,
                label: 'Response time',
                value: '1h 12m',
              ),
              ActorInfoRow(
                icon: Icons.groups_2_outlined,
                label: 'Repeat booking',
                value: '68%',
              ),
              ActorInfoRow(
                icon: Icons.workspace_premium_outlined,
                label: 'Trust badges',
                value: '5 earned',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoActivityCard extends StatelessWidget {
  const _NoActivityCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        'No urgent work. Your healthy state is active.',
        style: AppTextStyles.cardLabel.copyWith(color: colors.success),
      ),
    );
  }
}

class ActorStatusLabel extends StatelessWidget {
  final String label;
  final ActorTone tone;

  const ActorStatusLabel({
    super.key,
    required this.label,
    this.tone = ActorTone.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(label),
      labelStyle: AppTextStyles.micro.copyWith(
        color: actorToneColor(context, tone),
        letterSpacing: 0,
        fontWeight: FontWeight.w900,
      ),
      backgroundColor: actorToneColor(context, tone).withValues(alpha: 0.12),
      side: BorderSide(
        color: actorToneColor(context, tone).withValues(alpha: 0.3),
      ),
    );
  }
}
