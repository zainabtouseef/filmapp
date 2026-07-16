import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../data/insurance_partner_demo_data.dart';
import '../models/insurance_partner_models.dart';
import '../widgets/insurance_partner_components.dart';

class IN05IncidentReportsScreen extends StatefulWidget {
  const IN05IncidentReportsScreen({super.key});

  @override
  State<IN05IncidentReportsScreen> createState() =>
      _IN05IncidentReportsScreenState();
}

class _IN05IncidentReportsScreenState extends State<IN05IncidentReportsScreen> {
  String _query = '';
  String _severity = 'All';

  @override
  Widget build(BuildContext context) {
    final store = InsurancePartnerDemoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final rows = _rows(store).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InsuranceSectionCard(
              title: 'Incident command',
              icon: Icons.warning_amber_outlined,
              selected: true,
              child: Column(
                children: [
                  InsuranceSearchField(
                    hintText: 'Search incident, project, parties...',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final severity in ['All', 'Low', 'Medium', 'High'])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CoreChip(
                              label: severity,
                              selected: _severity == severity,
                              onTap: () => setState(() => _severity = severity),
                            ),
                          ),
                        const SizedBox(width: 8),
                        CoreChip(
                          label: 'This month',
                          selected: store.incidentFilter == 'This month',
                          icon: Icons.date_range_outlined,
                          onTap: () => store.setIncidentFilter('This month'),
                        ),
                        const SizedBox(width: 8),
                        CoreChip(
                          label: 'Export',
                          icon: Icons.download_outlined,
                          onTap: () {
                            store.exportIncidents();
                            insuranceSnack(
                              context,
                              'Incident export prepared',
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
            InsuranceTwoColumn(
              left: Column(
                children: [
                  InsuranceSectionCard(
                    title: 'Severity analytics',
                    icon: Icons.analytics_outlined,
                    child: Column(
                      children: [
                        MetricActionRail(
                          items: [
                            MetricActionItem(
                              icon: Icons.warning_amber_outlined,
                              value: '${rows.length}',
                              title: 'Open',
                              subtitle: 'Current',
                              accentColor: context.appColors.goldDark,
                            ),
                            MetricActionItem(
                              icon: Icons.priority_high_outlined,
                              value:
                                  '${rows.where((r) => r.severity == 'High').length}',
                              title: 'High',
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
                            in InsurancePartnerDemoData.incidentChart)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ChartBar(point: point),
                          ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            rows.isEmpty
                                ? 'No incidents match the selected filters.'
                                : 'Showing ${rows.length} incident records with drill-down source details.',
                            style: AppTextStyles.smallMeta.copyWith(
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  InsuranceSectionCard(
                    title: 'Incident table',
                    icon: Icons.table_rows_outlined,
                    child: rows.isEmpty
                        ? CoreEmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No incident records',
                            message: 'Clear filters or search another project.',
                            actionLabel: 'Clear',
                            onAction: () {
                              setState(() {
                                _query = '';
                                _severity = 'All';
                              });
                            },
                          )
                        : Column(
                            children: [
                              for (final row in rows)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _IncidentRow(
                                    row: row,
                                    status: store.incidentStatus(row),
                                    onDetail: () => _showIncident(context, row),
                                    onResolve: () {
                                      store.resolveIncident(row.id);
                                      insuranceSnack(
                                        context,
                                        'Incident marked resolved',
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
              right: InsuranceSectionCard(
                title: 'Response summary',
                icon: Icons.rule_folder_outlined,
                child: Column(
                  children: [
                    InsuranceInfoRow(
                      icon: Icons.report_problem_outlined,
                      label: 'Escalated',
                      value: '1 incident',
                    ),
                    InsuranceInfoRow(
                      icon: Icons.verified_outlined,
                      label: 'Resolved',
                      value: '9 this month',
                    ),
                    InsuranceInfoRow(
                      icon: Icons.fact_check_outlined,
                      label: 'Corrective actions',
                      value: '12 logged',
                    ),
                    InsuranceInfoRow(
                      icon: Icons.history_outlined,
                      label: 'Audit events',
                      value: '${store.auditEvents}',
                    ),
                    const SizedBox(height: 10),
                    CoreSecondaryButton(
                      icon: Icons.download_outlined,
                      label: 'Prepare report',
                      compact: true,
                      onTap: () {
                        store.exportIncidents();
                        insuranceSnack(context, 'Safety report prepared');
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

  Iterable<InsuranceIncident> _rows(InsurancePartnerDemoStore store) {
    final lower = _query.trim().toLowerCase();
    return InsurancePartnerDemoData.incidents.where((row) {
      final matchesSeverity = _severity == 'All' || row.severity == _severity;
      final haystack =
          '${row.title} ${row.project} ${row.parties} ${row.correctiveAction}'
              .toLowerCase();
      return matchesSeverity && haystack.contains(lower);
    });
  }

  void _showIncident(BuildContext context, InsuranceIncident row) {
    final store = InsurancePartnerDemoStore.instance;
    showInsuranceSheet(
      context,
      title: row.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InsuranceInfoRow(
            icon: Icons.movie_creation_outlined,
            label: 'Project',
            value: row.project,
          ),
          InsuranceInfoRow(
            icon: Icons.priority_high_outlined,
            label: 'Severity',
            value: row.severity,
          ),
          InsuranceInfoRow(
            icon: Icons.people_alt_outlined,
            label: 'Parties',
            value: row.parties,
          ),
          InsuranceInfoRow(
            icon: Icons.rule_outlined,
            label: 'Corrective action',
            value: row.correctiveAction,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.report_problem_outlined,
                  label: 'Escalate',
                  onTap: () {
                    store.escalateIncident(row.id);
                    Navigator.pop(context);
                    insuranceSnack(context, 'Incident escalated');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.check_circle_outline,
                  label: 'Resolve',
                  onTap: () {
                    store.resolveIncident(row.id);
                    Navigator.pop(context);
                    insuranceSnack(context, 'Incident resolved');
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
  final InsuranceChartPoint point;

  const _ChartBar({required this.point});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tone = insuranceToneColor(context, point.tone);
    final widthFactor = math.max(0.16, point.value / 10);
    return Tooltip(
      message: '${point.label}: ${point.value} incidents',
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

class _IncidentRow extends StatelessWidget {
  final InsuranceIncident row;
  final InsuranceStatus status;
  final VoidCallback onDetail;
  final VoidCallback onResolve;

  const _IncidentRow({
    required this.row,
    required this.status,
    required this.onDetail,
    required this.onResolve,
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
                  row.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              InsuranceStatusChip(status: status),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${row.project} - ${row.severity} - ${row.date}',
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
                  label: 'Resolve',
                  compact: true,
                  onTap: onResolve,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
