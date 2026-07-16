import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../data/distribution_partner_demo_data.dart';
import '../models/distribution_partner_models.dart';
import '../widgets/distribution_partner_components.dart';

class DS04PerformanceReportingScreen extends StatefulWidget {
  const DS04PerformanceReportingScreen({super.key});

  @override
  State<DS04PerformanceReportingScreen> createState() =>
      _DS04PerformanceReportingScreenState();
}

class _DS04PerformanceReportingScreenState
    extends State<DS04PerformanceReportingScreen> {
  String _query = '';
  String _channel = 'All';

  @override
  Widget build(BuildContext context) {
    final store = DistributionPartnerDemoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final rows = _rows(store).toList();
        final ottCount = rows.where((row) => row.channel == 'OTT').length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DistributionSectionCard(
              title: 'Reporting command',
              icon: Icons.analytics_outlined,
              selected: true,
              child: Column(
                children: [
                  DistributionSearchField(
                    hintText: 'Search partner, territory, channel...',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final channel in [
                          'All',
                          'Cinema',
                          'OTT',
                          'Television',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CoreChip(
                              label: channel,
                              selected: _channel == channel,
                              onTap: () => setState(() => _channel = channel),
                            ),
                          ),
                        const SizedBox(width: 8),
                        CoreChip(
                          label: 'Submitted',
                          selected: store.reportFilter == 'Submitted',
                          icon: Icons.fact_check_outlined,
                          onTap: () => store.setReportFilter('Submitted'),
                        ),
                        const SizedBox(width: 8),
                        CoreChip(
                          label: 'Export',
                          icon: Icons.download_outlined,
                          onTap: () {
                            store.exportReports();
                            distributionSnack(
                              context,
                              'Performance report export prepared',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            DistributionTwoColumn(
              left: Column(
                children: [
                  DistributionSectionCard(
                    title: 'Performance analytics',
                    icon: Icons.stacked_bar_chart_outlined,
                    child: Column(
                      children: [
                        MetricActionRail(
                          items: [
                            MetricActionItem(
                              icon: Icons.analytics_outlined,
                              value: '${rows.length}',
                              title: 'Reports',
                              subtitle: 'Current',
                              accentColor: context.appColors.goldDark,
                            ),
                            MetricActionItem(
                              icon: Icons.live_tv_outlined,
                              value: '$ottCount',
                              title: 'OTT rows',
                              subtitle: 'Current',
                              accentColor: context.appColors.goldDark,
                            ),
                            MetricActionItem(
                              icon: Icons.download_outlined,
                              value: '${store.exportsPrepared}',
                              title: 'Exports',
                              subtitle: 'Current',
                              accentColor: context.appColors.goldDark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        for (final point
                            in DistributionPartnerDemoData.reportChart)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ChartBar(point: point),
                          ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            rows.isEmpty
                                ? 'No reporting rows match the selected filters.'
                                : 'Showing ${rows.length} partner report records across selected channels.',
                            style: AppTextStyles.smallMeta.copyWith(
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  DistributionSectionCard(
                    title: 'Report records',
                    icon: Icons.table_rows_outlined,
                    child: rows.isEmpty
                        ? CoreEmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No report records',
                            message: 'Clear filters or search another partner.',
                            actionLabel: 'Clear',
                            onAction: () {
                              setState(() {
                                _query = '';
                                _channel = 'All';
                              });
                              store.setReportFilter('All');
                            },
                          )
                        : Column(
                            children: [
                              for (final row in rows)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _ReportRow(
                                    row: row,
                                    status: store.reportStatus(row),
                                    onDetail: () => _showReport(context, row),
                                    onClose: () {
                                      store.closeReport(row.id);
                                      distributionSnack(
                                        context,
                                        'Report record closed',
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
              right: DistributionSectionCard(
                title: 'Revenue support',
                icon: Icons.receipt_long_outlined,
                child: Column(
                  children: [
                    DistributionInfoRow(
                      icon: Icons.payments_outlined,
                      label: 'Submitted revenue',
                      value: 'PKR 45M+',
                    ),
                    DistributionInfoRow(
                      icon: Icons.public_outlined,
                      label: 'Territories',
                      value: '4 active',
                    ),
                    DistributionInfoRow(
                      icon: Icons.visibility_outlined,
                      label: 'Audience reach',
                      value: '8.4M',
                    ),
                    DistributionInfoRow(
                      icon: Icons.history_outlined,
                      label: 'Audit events',
                      value: '${store.auditEvents}',
                    ),
                    const SizedBox(height: 10),
                    CoreSecondaryButton(
                      icon: Icons.download_outlined,
                      label: 'Prepare statement',
                      compact: true,
                      onTap: () {
                        store.exportReports();
                        distributionSnack(context, 'Statement prepared');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Iterable<DistributionReportRecord> _rows(
    DistributionPartnerDemoStore store,
  ) {
    final lower = _query.trim().toLowerCase();
    return DistributionPartnerDemoData.reports.where((row) {
      final matchesChannel = _channel == 'All' || row.channel == _channel;
      final matchesFilter = switch (store.reportFilter) {
        'Submitted' => store.reportStatus(row) == DistributionStatus.submitted,
        _ => true,
      };
      final haystack =
          '${row.partner} ${row.territory} ${row.channel} ${row.revenue}'
              .toLowerCase();
      return matchesChannel && matchesFilter && haystack.contains(lower);
    });
  }

  void _showReport(BuildContext context, DistributionReportRecord row) {
    final store = DistributionPartnerDemoStore.instance;
    showDistributionSheet(
      context,
      title: row.partner,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DistributionInfoRow(
            icon: Icons.public_outlined,
            label: 'Territory',
            value: row.territory,
          ),
          DistributionInfoRow(
            icon: Icons.live_tv_outlined,
            label: 'Channel',
            value: row.channel,
          ),
          DistributionInfoRow(
            icon: Icons.visibility_outlined,
            label: 'Audience',
            value: row.audience,
          ),
          DistributionInfoRow(
            icon: Icons.payments_outlined,
            label: 'Revenue',
            value: row.revenue,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.report_problem_outlined,
                  label: 'Escalate',
                  onTap: () {
                    store.escalateReport(row.id);
                    Navigator.pop(context);
                    distributionSnack(context, 'Report escalated');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.check_circle_outline,
                  label: 'Close',
                  onTap: () {
                    store.closeReport(row.id);
                    Navigator.pop(context);
                    distributionSnack(context, 'Report closed');
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

class _ChartBar extends StatelessWidget {
  final DistributionChartPoint point;

  const _ChartBar({required this.point});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tone = distributionToneColor(context, point.tone);
    final widthFactor = math.max(0.16, point.value / 35);
    return Tooltip(
      message: '${point.label}: ${point.value}M value',
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              point.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: widthFactor.clamp(0.0, 1.0),
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(tone),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${point.value}',
            style: AppTextStyles.statusText.copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final DistributionReportRecord row;
  final DistributionStatus status;
  final VoidCallback onDetail;
  final VoidCallback onClose;

  const _ReportRow({
    required this.row,
    required this.status,
    required this.onDetail,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 16,
      padding: const EdgeInsets.all(11),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.partner,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              DistributionStatusChip(status: status),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${row.territory} - ${row.channel} - ${row.revenue}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.info_outline_rounded,
                  label: 'Detail',
                  compact: true,
                  onTap: onDetail,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.check_circle_outline,
                  label: 'Close',
                  compact: true,
                  onTap: onClose,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
