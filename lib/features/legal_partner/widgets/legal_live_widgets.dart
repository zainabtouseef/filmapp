import 'package:flutter/material.dart';

import '../../../core/contracts/contract_models.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import 'legal_partner_components.dart';

class LegalLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const LegalLoadError({
    super.key,
    required this.message,
    required this.onRetry,
  });

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

class LegalReviewCard extends StatelessWidget {
  final LegalReviewDto review;
  final bool busy;
  final VoidCallback? onApprove;
  final VoidCallback? onChanges;
  final VoidCallback? onDetail;

  const LegalReviewCard({
    super.key,
    required this.review,
    this.busy = false,
    this.onApprove,
    this.onChanges,
    this.onDetail,
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
                    review.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                LegalStatusChip(status: legalStatusFromString(review.status)),
              ],
            ),
            const SizedBox(height: 8),
            LegalInfoRow(
              icon: Icons.person_outline,
              label: 'Requested by',
              value: review.requestedBy.displayName,
            ),
            LegalInfoRow(
              icon: Icons.gavel_outlined,
              label: 'Type',
              value: review.contractType,
            ),
            LegalInfoRow(
              icon: Icons.warning_amber_outlined,
              label: 'Risk',
              value: review.risk,
            ),
            LegalInfoRow(
              icon: Icons.timer_outlined,
              label: 'SLA',
              value: review.slaLabel,
            ),
            LegalInfoRow(
              icon: Icons.rule_outlined,
              label: 'Risks',
              value: '${review.risks.length}',
            ),
            if (onDetail != null || onApprove != null || onChanges != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (onDetail != null)
                    CoreSecondaryButton(
                      icon: Icons.info_outline_rounded,
                      label: 'Detail',
                      compact: true,
                      onTap: busy ? null : onDetail,
                    ),
                  if (onChanges != null)
                    CoreSecondaryButton(
                      icon: Icons.edit_note_outlined,
                      label: 'Changes',
                      compact: true,
                      onTap: busy ? null : onChanges,
                    ),
                  if (onApprove != null)
                    CorePrimaryButton(
                      icon: Icons.check_circle_outline,
                      label: 'Approve',
                      compact: true,
                      onTap: busy ? null : onApprove,
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

class LegalContractCard extends StatelessWidget {
  final CineContract contract;

  const LegalContractCard({super.key, required this.contract});

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
                  contract.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              LegalStatusChip(status: legalStatusFromString(contract.status)),
            ],
          ),
          const SizedBox(height: 8),
          LegalInfoRow(
            icon: Icons.book_online_outlined,
            label: 'Booking',
            value: contract.bookingId,
          ),
          LegalInfoRow(
            icon: Icons.movie_creation_outlined,
            label: 'Project',
            value: contract.projectId,
          ),
          LegalInfoRow(
            icon: Icons.payments_outlined,
            label: 'Value',
            value: contract.displayValue,
          ),
          LegalInfoRow(
            icon: Icons.draw_outlined,
            label: 'Signatures',
            value: contract.signatureProgressPercent,
          ),
          LegalInfoRow(
            icon: Icons.post_add_outlined,
            label: 'Addendums',
            value: '${contract.addendums.length}',
          ),
        ],
      ),
    );
  }
}

String compactMoney(int minor, String currency) {
  final amount = minor / 100;
  if (amount >= 1000000) {
    return '$currency ${(amount / 1000000).toStringAsFixed(1)}M';
  }
  if (amount >= 1000) return '$currency ${(amount / 1000).toStringAsFixed(0)}K';
  return '$currency ${amount.toStringAsFixed(0)}';
}
