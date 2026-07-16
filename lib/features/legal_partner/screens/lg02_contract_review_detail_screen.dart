import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../data/legal_partner_demo_data.dart';
import '../models/legal_partner_models.dart';
import '../routes/legal_partner_routes.dart';
import '../widgets/legal_partner_components.dart';

class LG02ContractReviewDetailScreen extends StatelessWidget {
  const LG02ContractReviewDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = LegalPartnerDemoStore.instance;
    final request = store.primaryRequest;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return LegalTwoColumn(
          left: LegalSectionCard(
            title: 'Rendered contract',
            icon: Icons.article_outlined,
            selected: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        request.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.metricNumberCompact.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    LegalStatusChip(status: store.requestStatus(request)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${request.id.toUpperCase()} - ${request.owner} -> ${request.counterparty} - ${request.sla} SLA',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                for (final clause in LegalPartnerDemoData.clauseRisks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ClauseCard(clause: clause),
                  ),
                const SizedBox(height: 4),
                CoreSecondaryButton(
                  icon: Icons.description_outlined,
                  label: 'Open full contract viewer',
                  compact: true,
                  onTap: () =>
                      Navigator.pushNamed(context, CoreRoutes.contract),
                ),
              ],
            ),
          ),
          right: Column(
            children: [
              LegalSectionCard(
                title: 'Review actions',
                icon: Icons.rule_folder_outlined,
                child: Column(
                  children: [
                    LegalInfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Assigned lawyer',
                      value: request.assignedLawyer,
                    ),
                    LegalInfoRow(
                      icon: Icons.warning_amber_outlined,
                      label: 'Risk',
                      value: request.risk,
                    ),
                    LegalInfoRow(
                      icon: Icons.comment_outlined,
                      label: 'Annotations',
                      value: '${store.annotationCount}',
                    ),
                    LegalInfoRow(
                      icon: Icons.history_outlined,
                      label: 'Audit events',
                      value: '${store.auditEvents}',
                    ),
                    const SizedBox(height: 10),
                    CorePrimaryButton(
                      icon: Icons.check_circle_outline,
                      label: 'Approve contract',
                      compact: true,
                      onTap: () => _confirmApprove(context, store, request),
                    ),
                    const SizedBox(height: 8),
                    CoreSecondaryButton(
                      icon: Icons.edit_note_outlined,
                      label: 'Request correction',
                      compact: true,
                      onTap: () {
                        store.requestCorrection(request.id);
                        legalSnack(context, 'Correction request sent');
                      },
                    ),
                    const SizedBox(height: 8),
                    CoreSecondaryButton(
                      icon: Icons.report_problem_outlined,
                      label: 'Escalate',
                      compact: true,
                      onTap: () {
                        store.escalateRequest(request.id);
                        Navigator.pushNamed(
                          context,
                          CoreRoutes.report,
                          arguments: 'Legal contract escalation',
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              LegalSectionCard(
                title: 'Client clarification',
                icon: Icons.question_answer_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ask the producer to narrow category exclusivity and confirm approval trigger.',
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CoreSecondaryButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Open matter chat',
                      compact: true,
                      onTap: () =>
                          Navigator.pushNamed(context, CoreRoutes.chat),
                    ),
                    const SizedBox(height: 8),
                    CoreSecondaryButton(
                      icon: Icons.post_add_outlined,
                      label: 'Prepare addendum',
                      compact: true,
                      onTap: () => Navigator.pushNamed(
                        context,
                        LegalPartnerRoutes.addendumReview,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmApprove(
    BuildContext context,
    LegalPartnerDemoStore store,
    LegalReviewRequest request,
  ) {
    showLegalSheet(
      context,
      title: 'Approve contract',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Approve ${request.title}? This appends an immutable legal audit event.',
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
                  icon: Icons.verified_outlined,
                  label: 'Approve',
                  onTap: () {
                    store.approveRequest(request.id);
                    Navigator.pop(context);
                    legalSnack(context, 'Contract approved');
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

class _ClauseCard extends StatelessWidget {
  final LegalClauseRisk clause;

  const _ClauseCard({required this.clause});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 16,
      padding: const EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  clause.clause,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              LegalStatusChip(status: clause.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            clause.issue,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            clause.recommendation,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.statusText.copyWith(color: colors.goldDark),
          ),
        ],
      ),
    );
  }
}
