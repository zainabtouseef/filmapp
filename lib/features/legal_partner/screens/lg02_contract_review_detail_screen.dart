import 'package:flutter/material.dart';

import '../../../core/contracts/contract_models.dart';
import '../../../core/contracts/contracts_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../widgets/legal_live_widgets.dart';
import '../widgets/legal_partner_components.dart';

class LG02ContractReviewDetailScreen extends StatefulWidget {
  final String? reviewId;

  const LG02ContractReviewDetailScreen({super.key, this.reviewId});

  @override
  State<LG02ContractReviewDetailScreen> createState() =>
      _LG02ContractReviewDetailScreenState();
}

class _LG02ContractReviewDetailScreenState
    extends State<LG02ContractReviewDetailScreen> {
  Future<List<LegalReviewDto>>? _future;
  String? _busyReviewId;
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= ContractsScope.maybeOf(context)?.legalReviews(force: true);
  }

  void _refresh() {
    setState(() {
      _future = ContractsScope.maybeOf(context)?.legalReviews(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LegalSectionCard(
      title: 'Contract review queue',
      icon: Icons.rate_review_outlined,
      selected: true,
      actionText: _future == null ? null : 'Refresh',
      onActionTap: _refresh,
      child: _future == null
          ? const CoreEmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Sign in to review contracts',
              message: 'Legal review requests are loaded from the server.',
            )
          : FutureBuilder<List<LegalReviewDto>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SkeletonCard(height: 520);
                }
                if (snapshot.hasError) {
                  return LegalLoadError(
                    message: 'Could not load legal reviews',
                    onRetry: _refresh,
                  );
                }
                final allRows = snapshot.data ?? const [];
                final rows = _rows(allRows).toList();
                return Column(
                  children: [
                    LegalSearchField(
                      hintText: 'Search review, requester, risk...',
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: 12),
                    if (rows.isEmpty)
                      CoreEmptyState(
                        icon: Icons.rate_review_outlined,
                        title: allRows.isEmpty
                            ? 'No live legal reviews'
                            : 'No reviews match filters',
                        message: allRows.isEmpty
                            ? 'Seed legal review rows in MySQL to make this queue visible.'
                            : 'Clear search or try another requester/risk.',
                        actionLabel: allRows.isEmpty ? null : 'Clear',
                        onAction: allRows.isEmpty
                            ? null
                            : () => setState(() => _query = ''),
                      )
                    else
                      LegalResponsiveGrid(
                        minWidth: 330,
                        children: [
                          for (final review in rows)
                            LegalReviewCard(
                              review: review,
                              busy: _busyReviewId == review.publicId,
                              onDetail: () => _showReview(context, review),
                              onChanges: () =>
                                  _decide(review, 'changes_requested'),
                              onApprove: () => _decide(review, 'approved'),
                            ),
                        ],
                      ),
                  ],
                );
              },
            ),
    );
  }

  Iterable<LegalReviewDto> _rows(List<LegalReviewDto> rows) {
    final lower = _query.trim().toLowerCase();
    return rows.where((row) {
      if (widget.reviewId != null && row.publicId != widget.reviewId) {
        return false;
      }
      final haystack =
          '${row.publicId} ${row.title} ${row.requestedBy.displayName} ${row.contractType} ${row.risk} ${row.status}'
              .toLowerCase();
      return haystack.contains(lower);
    });
  }

  Future<void> _decide(LegalReviewDto review, String status) async {
    final contracts = ContractsScope.maybeOf(context);
    if (contracts == null) return;
    setState(() => _busyReviewId = review.publicId);
    try {
      await contracts.decideLegalReview(
        reviewId: review.publicId,
        status: status,
        decisionNotes: status == 'approved'
            ? 'Approved from Legal Partner portal.'
            : 'Changes requested from Legal Partner portal.',
      );
      if (!mounted) return;
      legalSnack(context, 'Review marked $status');
      _refresh();
    } catch (error) {
      if (!mounted) return;
      legalSnack(context, 'Could not update review: $error');
    } finally {
      if (mounted) setState(() => _busyReviewId = null);
    }
  }

  void _showReview(BuildContext context, LegalReviewDto review) {
    showLegalSheet(
      context,
      title: review.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LegalInfoRow(
            icon: Icons.person_outline,
            label: 'Requester',
            value: review.requestedBy.displayName,
          ),
          LegalInfoRow(
            icon: Icons.person_pin_outlined,
            label: 'Assigned',
            value: review.assignedLegal?.displayName ?? 'Unassigned',
          ),
          LegalInfoRow(
            icon: Icons.warning_amber_outlined,
            label: 'Risk',
            value: review.risk,
          ),
          const SizedBox(height: 8),
          if (review.risks.isEmpty)
            Text(
              'No clause risks attached to this review.',
              style: AppTextStyles.smallMeta,
            )
          else
            for (final risk in review.risks)
              LegalInfoRow(
                icon: Icons.rule_outlined,
                label: risk.riskLevel,
                value: risk.issue,
              ),
        ],
      ),
    );
  }
}
