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

class IN04SafetyChecksPermitsScreen extends StatefulWidget {
  const IN04SafetyChecksPermitsScreen({super.key});

  @override
  State<IN04SafetyChecksPermitsScreen> createState() =>
      _IN04SafetyChecksPermitsScreenState();
}

class _IN04SafetyChecksPermitsScreenState
    extends State<IN04SafetyChecksPermitsScreen> {
  Future<List<SafetyCheckDto>>? _future;
  String _query = '';
  String _status = 'All';
  String? _busyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= OperationsScope.maybeOf(context)?.safetyChecks(force: true);
  }

  void _refresh() {
    setState(() {
      _future = OperationsScope.maybeOf(context)?.safetyChecks(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) {
      return const InsuranceSectionCard(
        title: 'Safety checks & permits',
        icon: Icons.fact_check_outlined,
        selected: true,
        child: CoreEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Sign in to review safety checks',
          message: 'Safety records are loaded from insured productions.',
        ),
      );
    }
    return FutureBuilder<List<SafetyCheckDto>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonCard(height: 520);
        }
        if (snapshot.hasError) {
          return InsuranceSectionCard(
            title: 'Safety checks & permits',
            icon: Icons.cloud_off_outlined,
            child: _LoadError(onRetry: _refresh),
          );
        }
        final allRows = snapshot.data ?? const [];
        final rows = _filtered(allRows).toList();
        return InsuranceTwoColumn(
          left: InsuranceSectionCard(
            title: 'Safety checks & permits',
            icon: Icons.fact_check_outlined,
            selected: true,
            actionText: 'Refresh',
            onActionTap: _refresh,
            child: Column(
              children: [
                InsuranceSearchField(
                  hintText: 'Search project, owner, risk...',
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
                    icon: Icons.health_and_safety_outlined,
                    title: allRows.isEmpty
                        ? 'No safety checks yet'
                        : 'No checks match your filters',
                    message: allRows.isEmpty
                        ? 'Checks created for insured productions appear here automatically.'
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
                  Column(
                    children: [
                      for (final row in rows) ...[
                        _SafetyCard(
                          check: row,
                          busyId: _busyId,
                          onItemTap: (item) => _toggle(row, item),
                          onApprove: () => _updateStatus(row, 'approved'),
                        ),
                        if (row != rows.last) const SizedBox(height: 10),
                      ],
                    ],
                  ),
              ],
            ),
          ),
          right: InsuranceSectionCard(
            title: 'Coverage overview',
            icon: Icons.shield_outlined,
            child: Column(
              children: [
                InsuranceInfoRow(
                  icon: Icons.fact_check_outlined,
                  label: 'Total checks',
                  value: '${allRows.length}',
                ),
                InsuranceInfoRow(
                  icon: Icons.warning_amber_outlined,
                  label: 'High risk',
                  value:
                      '${allRows.where((row) => row.riskLevel == 'high' || row.riskLevel == 'critical').length}',
                ),
                InsuranceInfoRow(
                  icon: Icons.pending_actions_outlined,
                  label: 'Needs review',
                  value:
                      '${allRows.where((row) => row.status != 'approved' && row.status != 'completed').length}',
                ),
                InsuranceInfoRow(
                  icon: Icons.task_alt_outlined,
                  label: 'Completed',
                  value:
                      '${allRows.where((row) => row.status == 'approved' || row.status == 'completed').length}',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Iterable<SafetyCheckDto> _filtered(List<SafetyCheckDto> rows) {
    final needle = _query.trim().toLowerCase();
    return rows.where((row) {
      final statusMatches = _status == 'All' || row.status == _status;
      final text =
          '${row.publicId} ${row.projectId} ${row.responsibleUserName} ${row.riskLevel} ${row.status}'
              .toLowerCase();
      return statusMatches && text.contains(needle);
    });
  }

  List<String> _statuses(List<SafetyCheckDto> rows) {
    final values = rows.map((row) => row.status).toSet().toList()..sort();
    return ['All', ...values];
  }

  Future<void> _toggle(
    SafetyCheckDto check,
    SafetyCheckItemDto item,
  ) async {
    final operations = OperationsScope.maybeOf(context);
    if (operations == null) return;
    setState(() => _busyId = item.id);
    try {
      await operations.updateSafetyCheckItem(
        checkId: check.publicId,
        itemId: item.id,
        completed: !item.completed,
      );
      if (!mounted) return;
      insuranceSnack(
        context,
        item.completed ? 'Item reopened' : 'Item completed',
      );
      _refresh();
    } catch (error) {
      if (mounted) insuranceSnack(context, 'Could not update item: $error');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _updateStatus(SafetyCheckDto check, String status) async {
    final operations = OperationsScope.maybeOf(context);
    if (operations == null) return;
    setState(() => _busyId = check.publicId);
    try {
      await operations.updateSafetyCheck(check.publicId, {'status': status});
      if (!mounted) return;
      insuranceSnack(context, 'Safety check marked $status');
      _refresh();
    } catch (error) {
      if (mounted) insuranceSnack(context, 'Could not update check: $error');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }
}

class _SafetyCard extends StatelessWidget {
  final SafetyCheckDto check;
  final String? busyId;
  final ValueChanged<SafetyCheckItemDto> onItemTap;
  final VoidCallback onApprove;

  const _SafetyCard({
    required this.check,
    required this.busyId,
    required this.onItemTap,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final completed = check.items.where((item) => item.completed).length;
    final busy = busyId == check.publicId;
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
                    check.projectId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                InsuranceStatusChip(
                  status: insuranceStatusFromString(check.status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InsuranceInfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Responsible',
              value: check.responsibleUserName,
            ),
            InsuranceInfoRow(
              icon: Icons.warning_amber_outlined,
              label: 'Risk',
              value: check.riskLevel,
            ),
            InsuranceInfoRow(
              icon: Icons.event_outlined,
              label: 'Due',
              value: _date(check.dueAt),
            ),
            InsuranceProgressMeter(
              label: '$completed of ${check.items.length} checklist items',
              percent: check.items.isEmpty
                  ? 0
                  : ((completed / check.items.length) * 100).round(),
            ),
            if (check.items.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final item in check.items) ...[
                Opacity(
                  opacity: busyId == item.id ? 0.55 : 1,
                  child: IgnorePointer(
                    ignoring: busyId != null,
                    child: InsuranceChecklistTile(
                      title: item.label,
                      subtitle: item.detail.isEmpty
                          ? 'Tap to update completion'
                          : item.detail,
                      checked: item.completed,
                      mandatory: item.mandatory,
                      onTap: () => onItemTap(item),
                    ),
                  ),
                ),
                if (item != check.items.last) const SizedBox(height: 8),
              ],
            ],
            if (check.status != 'approved' && check.status != 'completed') ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: CorePrimaryButton(
                  icon: Icons.verified_outlined,
                  label: 'Approve check',
                  compact: true,
                  onTap: busyId == null ? onApprove : null,
                ),
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
          title: 'Could not load safety checks',
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
  if (value == null) return 'No due date';
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
