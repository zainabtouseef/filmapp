import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/insurance/insurance_controller.dart';
import '../../../core/insurance/insurance_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../widgets/insurance_partner_components.dart';

class IN03ClaimSupportScreen extends StatefulWidget {
  const IN03ClaimSupportScreen({super.key});

  @override
  State<IN03ClaimSupportScreen> createState() => _IN03ClaimSupportScreenState();
}

class _IN03ClaimSupportScreenState extends State<IN03ClaimSupportScreen> {
  String _query = '';
  String _status = 'All';
  Future<List<InsuranceClaimDto>>? _future;
  String? _busyClaimId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= InsuranceScope.maybeOf(context)?.claims(force: true);
  }

  void _refresh() {
    setState(() {
      _future = InsuranceScope.maybeOf(context)?.claims(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return InsuranceSectionCard(
      title: 'Claim support',
      icon: Icons.assignment_late_outlined,
      selected: true,
      actionText: _future == null ? null : 'Refresh',
      onActionTap: _refresh,
      child: _future == null
          ? const CoreEmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Sign in to review claims',
              message: 'Claim records are loaded from the server.',
            )
          : FutureBuilder<List<InsuranceClaimDto>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SkeletonCard(height: 500);
                }
                if (snapshot.hasError) {
                  return _LoadError(
                    message: 'Could not load claims',
                    onRetry: _refresh,
                  );
                }
                final allRows = snapshot.data ?? const [];
                final rows = _rows(allRows).toList();
                return Column(
                  children: [
                    InsuranceSearchField(
                      hintText: 'Search title, policy, booking...',
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
                        icon: Icons.assignment_late_outlined,
                        title: allRows.isEmpty
                            ? 'No live claims'
                            : 'No claims match filters',
                        message: allRows.isEmpty
                            ? 'Seed insurance claims in MySQL to make this screen visible for demo.'
                            : 'Clear filters or search another claim.',
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
                        minWidth: 310,
                        children: [
                          for (final row in rows)
                            _ClaimCard(
                              claim: row,
                              busy: _busyClaimId == row.publicId,
                              onApprove: () => _decide(row, 'approved'),
                              onEscalate: () => _decide(row, 'escalated'),
                            ),
                        ],
                      ),
                  ],
                );
              },
            ),
    );
  }

  Iterable<InsuranceClaimDto> _rows(List<InsuranceClaimDto> rows) {
    final lower = _query.trim().toLowerCase();
    return rows.where((row) {
      final matchesStatus = _status == 'All' || row.status == _status;
      final haystack =
          '${row.publicId} ${row.policyId} ${row.bookingId ?? ''} ${row.title} ${row.status}'
              .toLowerCase();
      return matchesStatus && haystack.contains(lower);
    });
  }

  List<String> _statuses(List<InsuranceClaimDto> rows) {
    final statuses = rows
        .map((row) => row.status.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...statuses];
  }

  Future<void> _decide(InsuranceClaimDto claim, String status) async {
    final insurance = InsuranceScope.maybeOf(context);
    if (insurance == null) return;
    setState(() => _busyClaimId = claim.publicId);
    try {
      await insurance.decideClaim(
        claimId: claim.publicId,
        status: status,
        estimateMinor: claim.estimateMinor,
      );
      if (!mounted) return;
      insuranceSnack(context, 'Claim marked $status');
      _refresh();
    } catch (error) {
      if (!mounted) return;
      insuranceSnack(context, 'Could not update claim: $error');
    } finally {
      if (mounted) setState(() => _busyClaimId = null);
    }
  }
}

class _ClaimCard extends StatelessWidget {
  final InsuranceClaimDto claim;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onEscalate;

  const _ClaimCard({
    required this.claim,
    required this.busy,
    required this.onApprove,
    required this.onEscalate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
                    claim.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                InsuranceStatusChip(
                  status: insuranceStatusFromString(claim.status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InsuranceInfoRow(
              icon: Icons.policy_outlined,
              label: 'Policy',
              value: claim.policyId,
            ),
            InsuranceInfoRow(
              icon: Icons.book_online_outlined,
              label: 'Booking',
              value: claim.bookingId ?? 'Not linked',
            ),
            InsuranceInfoRow(
              icon: Icons.attach_money_outlined,
              label: 'Estimate',
              value: _money(claim),
            ),
            InsuranceInfoRow(
              icon: Icons.attachment_outlined,
              label: 'Evidence',
              value: '${claim.evidence.length}',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CoreSecondaryButton(
                    icon: Icons.report_problem_outlined,
                    label: 'Escalate',
                    compact: true,
                    onTap: busy ? null : onEscalate,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CorePrimaryButton(
                    icon: Icons.check_circle_outline,
                    label: 'Approve',
                    compact: true,
                    onTap: busy ? null : onApprove,
                  ),
                ),
              ],
            ),
          ],
        ),
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

String _money(InsuranceClaimDto claim) {
  final currency = claim.currency.isEmpty ? 'PKR' : claim.currency;
  final minor = claim.estimateMinor;
  if (minor == null) return '$currency pending';
  return '$currency ${(minor / 100).toStringAsFixed(0)}';
}
