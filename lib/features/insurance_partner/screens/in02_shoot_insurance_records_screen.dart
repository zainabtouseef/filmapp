import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/insurance/insurance_controller.dart';
import '../../../core/insurance/insurance_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../widgets/insurance_partner_components.dart';

class IN02ShootInsuranceRecordsScreen extends StatefulWidget {
  const IN02ShootInsuranceRecordsScreen({super.key});

  @override
  State<IN02ShootInsuranceRecordsScreen> createState() =>
      _IN02ShootInsuranceRecordsScreenState();
}

class _IN02ShootInsuranceRecordsScreenState
    extends State<IN02ShootInsuranceRecordsScreen> {
  String _query = '';
  String _status = 'All';
  Future<List<InsurancePolicyDto>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= InsuranceScope.maybeOf(context)?.policies(force: true);
  }

  void _refresh() {
    setState(() {
      _future = InsuranceScope.maybeOf(context)?.policies(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return InsuranceSectionCard(
      title: 'Policy command',
      icon: Icons.policy_outlined,
      selected: true,
      actionText: _future == null ? null : 'Refresh',
      onActionTap: _refresh,
      child: _future == null
          ? const CoreEmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Sign in to view policies',
              message: 'Insurance records are loaded from the server.',
            )
          : FutureBuilder<List<InsurancePolicyDto>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SkeletonCard(height: 480);
                }
                if (snapshot.hasError) {
                  return _LoadError(
                    message: 'Could not load policies',
                    onRetry: _refresh,
                  );
                }
                final allRows = snapshot.data ?? const [];
                final rows = _rows(allRows).toList();
                return Column(
                  children: [
                    InsuranceSearchField(
                      hintText: 'Search insured, coverage, risk...',
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final status in _statuses(allRows))
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: CoreChip(
                                label: status,
                                selected: _status == status,
                                onTap: () => setState(() => _status = status),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (rows.isEmpty)
                      CoreEmptyState(
                        icon: Icons.policy_outlined,
                        title: allRows.isEmpty
                            ? 'No live policies'
                            : 'No policies match filters',
                        message: allRows.isEmpty
                            ? 'Seed insurance policies in MySQL to make this screen visible for demo.'
                            : 'Clear filters or search another insured party.',
                        actionLabel: allRows.isEmpty ? null : 'Clear',
                        onAction: allRows.isEmpty
                            ? null
                            : () => setState(() {
                                  _query = '';
                                  _status = 'All';
                                }),
                      )
                    else
                      InsuranceResponsiveGrid(
                        minWidth: 300,
                        children: [
                          for (final row in rows) _PolicyCard(policy: row),
                        ],
                      ),
                  ],
                );
              },
            ),
    );
  }

  Iterable<InsurancePolicyDto> _rows(List<InsurancePolicyDto> rows) {
    final lower = _query.trim().toLowerCase();
    return rows.where((row) {
      final matchesStatus = _status == 'All' || row.status == _status;
      final haystack =
          '${row.publicId} ${row.insuredUserName} ${row.coverageSummary} ${row.riskLevel} ${row.status}'
              .toLowerCase();
      return matchesStatus && haystack.contains(lower);
    });
  }

  List<String> _statuses(List<InsurancePolicyDto> rows) {
    final statuses = rows
        .map((row) => row.status.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...statuses];
  }
}

class _PolicyCard extends StatelessWidget {
  final InsurancePolicyDto policy;

  const _PolicyCard({required this.policy});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 18,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  policy.insuredUserName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              InsuranceStatusChip(
                status: insuranceStatusFromString(policy.status),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InsuranceInfoRow(
            icon: Icons.shield_outlined,
            label: 'Coverage',
            value: policy.coverageSummary.isEmpty
                ? 'Coverage not set'
                : policy.coverageSummary,
          ),
          InsuranceInfoRow(
            icon: Icons.warning_amber_outlined,
            label: 'Risk',
            value: policy.riskLevel,
          ),
          InsuranceInfoRow(
            icon: Icons.movie_creation_outlined,
            label: 'Project',
            value: policy.projectId ?? 'Not linked',
          ),
          InsuranceInfoRow(
            icon: Icons.book_online_outlined,
            label: 'Booking',
            value: policy.bookingId ?? 'Not linked',
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CoreEmptyState(
          icon: Icons.cloud_off_outlined,
          title: message,
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
