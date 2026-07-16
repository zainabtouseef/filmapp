import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../data/legal_partner_demo_data.dart';
import '../routes/legal_partner_routes.dart';
import '../widgets/legal_partner_components.dart';

class LG01LegalDashboardScreen extends StatelessWidget {
  const LG01LegalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = LegalPartnerDemoStore.instance;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final request = store.primaryRequest;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LegalKpiRail(metrics: LegalPartnerDemoData.metrics),
            const SizedBox(height: 12),
            LegalTwoColumn(
              left: LegalSectionCard(
                title: 'Priority review',
                icon: Icons.priority_high_outlined,
                selected: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LegalMediaFrame(
                      imageUrl: request.imageUrl,
                      title: request.title,
                      badge: request.contractType,
                      fallbackIcon: Icons.article_outlined,
                      aspectRatio: 16 / 8.5,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            request.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.metricNumberCompact.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        LegalStatusChip(status: store.requestStatus(request)),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${request.owner} -> ${request.counterparty} - ${request.risk}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    MetricActionRail(
                      items: [
                        MetricActionItem(
                          icon: Icons.timer_outlined,
                          value: request.sla,
                          title: 'SLA',
                          subtitle: 'Current',
                          accentColor: colors.goldDark,
                        ),
                        MetricActionItem(
                          icon: Icons.person_outline_rounded,
                          value: request.assignedLawyer,
                          title: 'Lawyer',
                          subtitle: 'Current',
                          accentColor: colors.goldDark,
                        ),
                        MetricActionItem(
                          icon: Icons.comment_outlined,
                          value: '${store.annotationCount}',
                          title: 'Annotations',
                          subtitle: 'Current',
                          accentColor: colors.goldDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CoreSecondaryButton(
                            icon: Icons.library_books_outlined,
                            label: 'Templates',
                            compact: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              LegalPartnerRoutes.templateReview,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CorePrimaryButton(
                            icon: Icons.article_outlined,
                            label: 'Open review',
                            compact: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              LegalPartnerRoutes.contractReview,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              right: Column(
                children: [
                  LegalSectionCard(
                    title: 'Action required',
                    icon: Icons.notifications_active_outlined,
                    child: store.activeTasks.isEmpty
                        ? CoreEmptyState(
                            icon: Icons.check_circle_outline,
                            title: 'Queue clear',
                            message: 'No urgent legal action is pending.',
                            actionLabel: 'Open history',
                            onAction: () => Navigator.pushNamed(
                              context,
                              LegalPartnerRoutes.billing,
                            ),
                          )
                        : LegalTaskRail(tasks: store.activeTasks),
                  ),
                  const SizedBox(height: 12),
                  LegalSectionCard(
                    title: 'Queue health',
                    icon: Icons.analytics_outlined,
                    child: Column(
                      children: [
                        LegalInfoRow(
                          icon: Icons.warning_amber_outlined,
                          label: 'High risk',
                          value: '4 matters',
                        ),
                        LegalInfoRow(
                          icon: Icons.question_answer_outlined,
                          label: 'Clarifications',
                          value: '3 waiting',
                        ),
                        LegalInfoRow(
                          icon: Icons.verified_outlined,
                          label: 'Completed today',
                          value: '11 reviews',
                        ),
                        LegalInfoRow(
                          icon: Icons.history_outlined,
                          label: 'Audit events',
                          value: '${store.auditEvents}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
