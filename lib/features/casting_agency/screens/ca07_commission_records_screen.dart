import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../data/casting_agency_demo_data.dart';
import '../models/casting_agency_models.dart';
import '../widgets/casting_agency_components.dart';

class CA07CommissionRecordsScreen extends StatefulWidget {
  const CA07CommissionRecordsScreen({super.key});

  @override
  State<CA07CommissionRecordsScreen> createState() =>
      _CA07CommissionRecordsScreenState();
}

class _CA07CommissionRecordsScreenState
    extends State<CA07CommissionRecordsScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final store = CastingAgencyDemoStore.instance;
    final rows = _rows(store).toList();
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MetricActionRail(
              items: [
                MetricActionItem(
                  value: 'PKR 3.4M',
                  icon: Icons.verified_outlined,
                  title: 'Verified',
                  subtitle: 'Current',
                  accentColor: agencyToneColor(context, AgencyTone.green),
                ),
                MetricActionItem(
                  value: 'PKR 241K',
                  icon: Icons.pending_actions_outlined,
                  title: 'Pending',
                  subtitle: 'Current',
                  accentColor: agencyToneColor(context, AgencyTone.gold),
                ),
                MetricActionItem(
                  value: '${store.commissionPercent}%',
                  icon: Icons.percent_outlined,
                  title: 'Commission',
                  subtitle: 'Current',
                  accentColor: agencyToneColor(context, AgencyTone.blue),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AgencyTwoColumn(
              left: AgencySectionCard(
                title: 'Commission ledger',
                icon: Icons.table_rows_outlined,
                selected: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final filter in [
                            'All',
                            'Pending',
                            'Paid',
                            'Issue',
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: CoreChip(
                                label: filter,
                                selected: _filter == filter,
                                onTap: () {
                                  setState(() => _filter = filter);
                                  agencySnack(
                                    context,
                                    '$filter commission filter applied',
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (rows.isEmpty)
                      CoreEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No commission records',
                        message: 'Try another payment status.',
                        actionLabel: 'Clear',
                        onAction: () => setState(() => _filter = 'All'),
                      )
                    else
                      for (final row in rows)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _CommissionRow(
                            item: row,
                            status: store.commissionStatus(row),
                            onVerify: () {
                              store.verifyCommission(row.id);
                              agencySnack(context, 'Commission verified');
                            },
                            onIssue: () => _confirmIssue(context, store, row),
                            onReceipt: () => Navigator.pushNamed(
                              context,
                              CoreRoutes.ledger,
                            ),
                          ),
                        ),
                  ],
                ),
              ),
              right: Column(
                children: [
                  AgencySectionCard(
                    title: 'Commission settings',
                    icon: Icons.tune_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AgencyInfoRow(
                          icon: Icons.business_center_outlined,
                          label: 'Default split',
                          value: '${store.commissionPercent}%',
                        ),
                        Slider(
                          value: store.commissionPercent.toDouble(),
                          min: 5,
                          max: 25,
                          divisions: 20,
                          activeColor: context.appColors.goldMid,
                          onChanged: (value) =>
                              store.updateCommissionPercent(value.round()),
                        ),
                        CorePrimaryButton(
                          icon: Icons.save_outlined,
                          label: 'Save split',
                          compact: true,
                          onTap: () => agencySnack(
                            context,
                            'Commission split saved',
                          ),
                        ),
                        const SizedBox(height: 8),
                        CoreSecondaryButton(
                          icon: Icons.receipt_long_outlined,
                          label: 'Open receipts',
                          compact: true,
                          onTap: () => Navigator.pushNamed(
                            context,
                            CoreRoutes.ledger,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AgencySectionCard(
                    title: 'Payment timeline',
                    icon: Icons.account_tree_outlined,
                    child: Column(
                      children: const [
                        _TimelineRow(
                          label: 'Booking secured',
                          value: 'Record',
                          status: AgencyStatus.booked,
                        ),
                        _TimelineRow(
                          label: 'Agency invoice',
                          value: 'Generated',
                          status: AgencyStatus.paymentPending,
                        ),
                        _TimelineRow(
                          label: 'Payment verification',
                          value: 'Admin queue',
                          status: AgencyStatus.reviewing,
                        ),
                        _TimelineRow(
                          label: 'Receipt issued',
                          value: 'Paid',
                          status: AgencyStatus.paid,
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

  Iterable<AgencyCommissionItem> _rows(CastingAgencyDemoStore store) {
    return CastingAgencyDemoData.commission.where((item) {
      final status = store.commissionStatus(item);
      return switch (_filter) {
        'Pending' => status == AgencyStatus.paymentPending,
        'Paid' => status == AgencyStatus.paid,
        'Issue' => status == AgencyStatus.disputed,
        _ => true,
      };
    });
  }

  void _confirmIssue(
    BuildContext context,
    CastingAgencyDemoStore store,
    AgencyCommissionItem item,
  ) {
    showAgencySheet(
      context,
      title: 'Flag commission',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Flag ${item.project} for admin payment review?',
            style: AppTextStyles.body.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.close_rounded,
                  label: 'Cancel',
                  onTap: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.report_problem_outlined,
                  label: 'Flag',
                  onTap: () {
                    store.flagCommission(item.id);
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      CoreRoutes.report,
                      arguments: 'Agency commission issue',
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommissionRow extends StatelessWidget {
  final AgencyCommissionItem item;
  final AgencyStatus status;
  final VoidCallback onVerify;
  final VoidCallback onIssue;
  final VoidCallback onReceipt;

  const _CommissionRow({
    required this.item,
    required this.status,
    required this.onVerify,
    required this.onIssue,
    required this.onReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 16,
      padding: const EdgeInsets.all(11),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.project,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.talentName} - ${item.gross} - ${item.commission}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AgencyStatusChip(status: status),
          IconButton(
            tooltip: 'Verify',
            visualDensity: VisualDensity.compact,
            onPressed: onVerify,
            icon: Icon(Icons.verified_outlined, color: colors.success),
          ),
          IconButton(
            tooltip: 'Receipt',
            visualDensity: VisualDensity.compact,
            onPressed: onReceipt,
            icon: Icon(Icons.receipt_long_outlined, color: colors.goldDark),
          ),
          IconButton(
            tooltip: 'Issue',
            visualDensity: VisualDensity.compact,
            onPressed: onIssue,
            icon: Icon(Icons.report_problem_outlined, color: colors.iconMuted),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final String value;
  final AgencyStatus status;

  const _TimelineRow({
    required this.label,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = agencyStatusColor(context, status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardLabel.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.smallMeta.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
