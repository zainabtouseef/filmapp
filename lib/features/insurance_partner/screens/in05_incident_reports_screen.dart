import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/operations/operations_controller.dart';
import '../../../core/operations/operations_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/widgets/cine_animated_filter_rail.dart';
import '../widgets/insurance_partner_components.dart';

class IN05IncidentReportsScreen extends StatefulWidget {
  const IN05IncidentReportsScreen({super.key});

  @override
  State<IN05IncidentReportsScreen> createState() =>
      _IN05IncidentReportsScreenState();
}

class _IN05IncidentReportsScreenState extends State<IN05IncidentReportsScreen> {
  Future<List<IncidentDto>>? _future;
  String _query = '';
  String _status = 'All';
  String? _busyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= OperationsScope.maybeOf(context)?.incidents(force: true);
  }

  void _refresh() {
    setState(() {
      _future = OperationsScope.maybeOf(context)?.incidents(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) {
      return const InsuranceSectionCard(
        title: 'Incident reports',
        icon: Icons.warning_amber_outlined,
        selected: true,
        child: CoreEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Sign in to review incidents',
          message: 'Incident records are loaded from insured productions.',
        ),
      );
    }
    return FutureBuilder<List<IncidentDto>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonCard(height: 520);
        }
        if (snapshot.hasError) {
          return InsuranceSectionCard(
            title: 'Incident reports',
            icon: Icons.cloud_off_outlined,
            child: _LoadError(onRetry: _refresh),
          );
        }
        final allRows = snapshot.data ?? const [];
        final rows = _filtered(allRows).toList();
        return InsuranceTwoColumn(
          left: InsuranceSectionCard(
            title: 'Incident reports',
            icon: Icons.warning_amber_outlined,
            selected: true,
            actionText: 'Refresh',
            onActionTap: _refresh,
            child: Column(
              children: [
                InsuranceSearchField(
                  hintText: 'Search incident, project, reporter...',
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 10),
                CineAnimatedFilterRail<String>(
                  values: _statuses(allRows),
                  selected: _status,
                  onSelected: (value) => setState(() => _status = value),
                  labelFor: (value) => value,
                ),
                const SizedBox(height: 12),
                if (rows.isEmpty)
                  CoreEmptyState(
                    icon: Icons.assignment_turned_in_outlined,
                    title: allRows.isEmpty
                        ? 'No incidents reported'
                        : 'No incidents match your filters',
                    message: allRows.isEmpty
                        ? 'Reports from insured productions appear here automatically.'
                        : 'Clear the search or select another status.',
                    actionLabel: allRows.isEmpty ? null : 'Clear filters',
                    onAction: allRows.isEmpty
                        ? null
                        : () => setState(() {
                              _query = '';
                              _status = 'All';
                            }),
                  )
                else
                  InsuranceResponsiveGrid(
                    minWidth: 320,
                    children: [
                      for (final row in rows)
                        _IncidentCard(
                          incident: row,
                          busy: _busyId == row.publicId,
                          onInvestigate: () => _update(row, 'investigating'),
                          onResolve: () => _update(row, 'resolved'),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          right: InsuranceSectionCard(
            title: 'Incident overview',
            icon: Icons.analytics_outlined,
            child: Column(
              children: [
                InsuranceInfoRow(
                  icon: Icons.warning_amber_outlined,
                  label: 'Total reports',
                  value: '${allRows.length}',
                ),
                InsuranceInfoRow(
                  icon: Icons.priority_high_rounded,
                  label: 'High severity',
                  value:
                      '${allRows.where((row) => row.severity == 'high' || row.severity == 'critical').length}',
                ),
                InsuranceInfoRow(
                  icon: Icons.pending_actions_outlined,
                  label: 'Open',
                  value:
                      '${allRows.where((row) => row.status != 'resolved' && row.status != 'closed').length}',
                ),
                InsuranceInfoRow(
                  icon: Icons.task_alt_outlined,
                  label: 'Resolved',
                  value:
                      '${allRows.where((row) => row.status == 'resolved' || row.status == 'closed').length}',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Iterable<IncidentDto> _filtered(List<IncidentDto> rows) {
    final needle = _query.trim().toLowerCase();
    return rows.where((row) {
      final statusMatches = _status == 'All' || row.status == _status;
      final text =
          '${row.publicId} ${row.projectId} ${row.title} ${row.reportedByName} ${row.severity} ${row.status}'
              .toLowerCase();
      return statusMatches && text.contains(needle);
    });
  }

  List<String> _statuses(List<IncidentDto> rows) {
    final values = rows.map((row) => row.status).toSet().toList()..sort();
    return ['All', ...values];
  }

  Future<void> _update(IncidentDto incident, String status) async {
    final operations = OperationsScope.maybeOf(context);
    if (operations == null) return;
    setState(() => _busyId = incident.publicId);
    try {
      await operations.updateIncident(incident.publicId, {'status': status});
      if (!mounted) return;
      insuranceSnack(context, 'Incident marked $status');
      _refresh();
    } catch (error) {
      if (mounted) insuranceSnack(context, 'Could not update incident: $error');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }
}

class _IncidentCard extends StatelessWidget {
  final IncidentDto incident;
  final bool busy;
  final VoidCallback onInvestigate;
  final VoidCallback onResolve;

  const _IncidentCard({
    required this.incident,
    required this.busy,
    required this.onInvestigate,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final closed = incident.status == 'resolved' || incident.status == 'closed';
    return Opacity(
      opacity: busy ? 0.62 : 1,
      child: GlassSectionCard(
        radius: 18,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    incident.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                InsuranceStatusChip(
                  status: insuranceStatusFromString(incident.status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InsuranceInfoRow(
              icon: Icons.movie_creation_outlined,
              label: 'Project',
              value: incident.projectId,
            ),
            InsuranceInfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Reported by',
              value: incident.reportedByName,
            ),
            InsuranceInfoRow(
              icon: Icons.priority_high_rounded,
              label: 'Severity',
              value: incident.severity,
            ),
            InsuranceInfoRow(
              icon: Icons.schedule_outlined,
              label: 'Occurred',
              value: _date(incident.occurredAt),
            ),
            if (incident.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                incident.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.smallMeta.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
            if (incident.correctiveAction.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Corrective action: ${incident.correctiveAction}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.smallMeta.copyWith(
                  color: colors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (!closed) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CoreSecondaryButton(
                      icon: Icons.manage_search_outlined,
                      label: 'Investigate',
                      compact: true,
                      onTap: busy ? null : onInvestigate,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CorePrimaryButton(
                      icon: Icons.task_alt_outlined,
                      label: 'Resolve',
                      compact: true,
                      onTap: busy ? null : onResolve,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _LoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CoreEmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load incidents',
          message: 'Check your connection and try again.',
        ),
        const SizedBox(height: 10),
        CoreSecondaryButton(
          icon: Icons.refresh_rounded,
          label: 'Try again',
          compact: true,
          onTap: onRetry,
        ),
      ],
    );
  }
}

String _date(DateTime? value) {
  if (value == null) return 'Date unavailable';
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
