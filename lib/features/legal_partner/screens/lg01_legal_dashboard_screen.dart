import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_widgets.dart';
import '../../../core/contracts/contract_models.dart' as contract_models;
import '../../../core/contracts/contracts_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../data/legal_partner_demo_data.dart';
import '../routes/legal_partner_routes.dart';
import '../widgets/legal_partner_components.dart';

class LG01LegalDashboardScreen extends StatefulWidget {
  const LG01LegalDashboardScreen({super.key});

  @override
  State<LG01LegalDashboardScreen> createState() =>
      _LG01LegalDashboardScreenState();
}

class _LG01LegalDashboardScreenState extends State<LG01LegalDashboardScreen> {
  Future<List<contract_models.LegalReviewDto>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final contracts = ContractsScope.maybeOf(context);
    if (contracts != null) _future ??= contracts.legalReviews(force: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_future != null) {
      return FutureBuilder<List<contract_models.LegalReviewDto>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CoreEmptyState(
              icon: Icons.hourglass_top_rounded,
              title: 'Loading legal queue',
              message: 'Fetching review requests from CineConnect.',
            );
          }
          final rows = snapshot.data ?? const [];
          if (!snapshot.hasError && rows.isNotEmpty) {
            return _LiveLegalDashboard(rows: rows);
          }
          return _DemoLegalDashboard();
        },
      );
    }
    return _DemoLegalDashboard();
  }
}

class _LiveLegalDashboard extends StatelessWidget {
  final List<contract_models.LegalReviewDto> rows;

  const _LiveLegalDashboard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final request = rows.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PersonalDashboardKpiStrip(),
        const SizedBox(height: 12),
        MetricActionRail(
          items: [
            MetricActionItem(
              icon: Icons.rule_folder_outlined,
              value: '${rows.length}',
              title: 'Live reviews',
              subtitle: 'Queue',
              accentColor: colors.goldDark,
            ),
            MetricActionItem(
              icon: Icons.priority_high_outlined,
              value: rows.where((row) => row.risk == 'high').length.toString(),
              title: 'High risk',
              subtitle: 'Open',
              accentColor: colors.danger,
            ),
            MetricActionItem(
              icon: Icons.verified_outlined,
              value: rows
                  .where((row) => row.status == 'approved')
                  .length
                  .toString(),
              title: 'Approved',
              subtitle: 'All time',
              accentColor: colors.success,
            ),
          ],
        ),
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
                  imageUrl: '',
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
                    StatusBadge(
                      label: request.status.toUpperCase(),
                      tone: _toneFor(request.status),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  '${request.requestedBy.displayName} • ${request.risk} risk',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                MetricActionRail(
                  items: [
                    MetricActionItem(
                      icon: Icons.timer_outlined,
                      value: request.slaLabel,
                      title: 'SLA',
                      subtitle: 'Current',
                      accentColor: colors.goldDark,
                    ),
                    MetricActionItem(
                      icon: Icons.person_outline_rounded,
                      value: request.assignedLegal?.displayName ?? 'Unassigned',
                      title: 'Lawyer',
                      subtitle: 'Current',
                      accentColor: colors.goldDark,
                    ),
                    MetricActionItem(
                      icon: Icons.comment_outlined,
                      value: '${request.risks.length}',
                      title: 'Risks',
                      subtitle: 'Current',
                      accentColor: colors.goldDark,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CorePrimaryButton(
                  icon: Icons.article_outlined,
                  label: 'Open review',
                  compact: true,
                  onTap: () => Navigator.pushNamed(
                    context,
                    LegalPartnerRoutes.contractReview,
                    arguments: request.publicId,
                  ),
                ),
              ],
            ),
          ),
          right: LegalSectionCard(
            title: 'Action required',
            icon: Icons.notifications_active_outlined,
            child: Column(
              children: [
                for (final row in rows.take(5))
                  LegalInfoRow(
                    icon: Icons.gavel_outlined,
                    label: row.status,
                    value: '${row.title} • ${row.slaLabel}',
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  CoreStatusTone _toneFor(String status) {
    return switch (status) {
      'approved' => CoreStatusTone.success,
      'changes_requested' || 'rejected' => CoreStatusTone.danger,
      _ => CoreStatusTone.warning,
    };
  }
}

class _DemoLegalDashboard extends StatelessWidget {
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
            const PersonalDashboardKpiStrip(),
            const SizedBox(height: 12),
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
