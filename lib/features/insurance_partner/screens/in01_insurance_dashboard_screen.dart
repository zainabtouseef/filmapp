import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_widgets.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/insurance/insurance_controller.dart';
import '../../../core/insurance/insurance_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../data/insurance_partner_demo_data.dart';
import '../routes/insurance_partner_routes.dart';
import '../widgets/insurance_partner_components.dart';

class IN01InsuranceDashboardScreen extends StatefulWidget {
  const IN01InsuranceDashboardScreen({super.key});

  @override
  State<IN01InsuranceDashboardScreen> createState() =>
      _IN01InsuranceDashboardScreenState();
}

class _IN01InsuranceDashboardScreenState
    extends State<IN01InsuranceDashboardScreen> {
  Future<InsuranceDashboardDto>? _dashboardFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final insurance = InsuranceScope.maybeOf(context);
    _dashboardFuture ??= insurance?.dashboard(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final store = InsurancePartnerDemoStore.instance;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final policy = store.primaryPolicy;
        final safety = store.primarySafety;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PersonalDashboardKpiStrip(),
            const SizedBox(height: 12),
            if (_dashboardFuture != null)
              FutureBuilder<InsuranceDashboardDto>(
                future: _dashboardFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: InlineNotice(
                        message: 'Loading live insurance dashboard...',
                        icon: Icons.hourglass_top_rounded,
                      ),
                    );
                  }
                  final live = snapshot.data;
                  if (live == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InlineNotice(
                      message:
                          'Live insurance: ${live.activePolicyCount}/${live.policyCount} active policies, ${live.openClaims} open claim(s).',
                      icon: Icons.cloud_done_outlined,
                      tone: CoreStatusTone.success,
                    ),
                  );
                },
              ),
            InsuranceKpiRail(metrics: InsurancePartnerDemoData.metrics),
            const SizedBox(height: 12),
            InsuranceTwoColumn(
              left: InsuranceSectionCard(
                title: 'High-risk booking',
                icon: Icons.health_and_safety_outlined,
                selected: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InsuranceMediaFrame(
                      imageUrl: policy.imageUrl,
                      title: policy.project,
                      badge: policy.booking,
                      fallbackIcon: Icons.policy_outlined,
                      aspectRatio: 16 / 8.5,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            policy.project,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.metricNumberCompact.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        InsuranceStatusChip(
                          status: store.policyStatus(policy),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${policy.insuredParty} - ${policy.coverage} - ${policy.risk}',
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
                          icon: Icons.calendar_month_outlined,
                          value: policy.validity,
                          title: 'Validity',
                          subtitle: 'Current',
                          accentColor: colors.goldDark,
                        ),
                        MetricActionItem(
                          icon: Icons.fact_check_outlined,
                          value: safety.dueDate,
                          title: 'Safety due',
                          subtitle: 'Current',
                          accentColor: colors.goldDark,
                        ),
                        MetricActionItem(
                          icon: Icons.history_outlined,
                          value: '${store.auditEvents}',
                          title: 'Audit events',
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
                            icon: Icons.policy_outlined,
                            label: 'Policies',
                            compact: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              InsurancePartnerRoutes.records,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CorePrimaryButton(
                            icon: Icons.fact_check_outlined,
                            label: 'Open safety',
                            compact: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              InsurancePartnerRoutes.safety,
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
                  InsuranceSectionCard(
                    title: 'Action required',
                    icon: Icons.notifications_active_outlined,
                    child: store.activeTasks.isEmpty
                        ? CoreEmptyState(
                            icon: Icons.check_circle_outline,
                            title: 'Safety queue clear',
                            message: 'No urgent policy or incident action.',
                            actionLabel: 'Open incidents',
                            onAction: () => Navigator.pushNamed(
                              context,
                              InsurancePartnerRoutes.incidents,
                            ),
                          )
                        : InsuranceTaskRail(tasks: store.activeTasks),
                  ),
                  const SizedBox(height: 12),
                  InsuranceSectionCard(
                    title: 'Operational health',
                    icon: Icons.analytics_outlined,
                    child: Column(
                      children: [
                        InsuranceInfoRow(
                          icon: Icons.policy_outlined,
                          label: 'Active policies',
                          value: '24 records',
                        ),
                        InsuranceInfoRow(
                          icon: Icons.assignment_late_outlined,
                          label: 'Open claims',
                          value: '6 claims',
                        ),
                        InsuranceInfoRow(
                          icon: Icons.warning_amber_outlined,
                          label: 'High-risk bookings',
                          value: '3 flagged',
                        ),
                        InsuranceInfoRow(
                          icon: Icons.fact_check_outlined,
                          label: 'Checks due',
                          value: '9 pending',
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
