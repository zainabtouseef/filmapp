import 'package:flutter/material.dart';

import '../../../core/contracts/contract_models.dart';
import '../../../core/contracts/contracts_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../widgets/legal_live_widgets.dart';
import '../widgets/legal_partner_components.dart';

class LG03TemplateReviewScreen extends StatefulWidget {
  const LG03TemplateReviewScreen({super.key});

  @override
  State<LG03TemplateReviewScreen> createState() =>
      _LG03TemplateReviewScreenState();
}

class _LG03TemplateReviewScreenState extends State<LG03TemplateReviewScreen> {
  Future<_TemplateReviewBundle>? _future;
  String? _busyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<_TemplateReviewBundle>? _load() {
    final contracts = ContractsScope.maybeOf(context);
    if (contracts == null) return null;
    return Future.wait([
      contracts.legalTemplates(force: true),
      contracts.legalReviews(force: true),
    ]).then(
      (values) => _TemplateReviewBundle(
        templates: values[0] as List<ContractTemplate>,
        reviews: values[1] as List<LegalReviewDto>,
      ),
    );
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    if (_future == null) {
      return const LegalSectionCard(
        title: 'Template review',
        icon: Icons.article_outlined,
        selected: true,
        child: CoreEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Sign in to review templates',
          message:
              'Contract templates and review history load from the server.',
        ),
      );
    }
    return FutureBuilder<_TemplateReviewBundle>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonCard(height: 500);
        }
        if (snapshot.hasError) {
          return LegalSectionCard(
            title: 'Template review',
            icon: Icons.article_outlined,
            child: LegalLoadError(
              message: 'Could not load templates',
              onRetry: _refresh,
            ),
          );
        }
        final data = snapshot.data!;
        return LegalTwoColumn(
          left: LegalSectionCard(
            title: 'Template review',
            icon: Icons.article_outlined,
            selected: true,
            actionText: 'Refresh',
            onActionTap: _refresh,
            child: data.templates.isEmpty
                ? const CoreEmptyState(
                    icon: Icons.article_outlined,
                    title: 'No contract templates',
                    message:
                        'Templates created by platform administrators appear here.',
                  )
                : LegalResponsiveGrid(
                    minWidth: 310,
                    children: [
                      for (final template in data.templates)
                        _TemplateCard(
                          template: template,
                          latestReview: _latestReview(data.reviews, template),
                          busy: _busyId == template.publicId,
                          onApprove: () =>
                              _decide(template, status: 'approved'),
                          onChanges: () => _requestChanges(template),
                        ),
                    ],
                  ),
          ),
          right: LegalSectionCard(
            title: 'Review activity',
            icon: Icons.history_outlined,
            child: Column(
              children: [
                LegalInfoRow(
                  icon: Icons.article_outlined,
                  label: 'Templates',
                  value: '${data.templates.length}',
                ),
                LegalInfoRow(
                  icon: Icons.rate_review_outlined,
                  label: 'Decisions logged',
                  value: '${data.templateReviews.length}',
                ),
                LegalInfoRow(
                  icon: Icons.check_circle_outline,
                  label: 'Approved',
                  value:
                      '${data.templateReviews.where((row) => row.status == 'approved').length}',
                ),
                LegalInfoRow(
                  icon: Icons.edit_note_outlined,
                  label: 'Changes requested',
                  value:
                      '${data.templateReviews.where((row) => row.status == 'changes_requested').length}',
                ),
                if (data.templateReviews.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  for (final review in data.templateReviews.take(4))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: LegalReviewCard(review: review),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  LegalReviewDto? _latestReview(
    List<LegalReviewDto> reviews,
    ContractTemplate template,
  ) {
    for (final review in reviews) {
      if (review.templateId == template.publicId &&
          review.contractId == null &&
          review.addendumId == null) {
        return review;
      }
    }
    return null;
  }

  Future<void> _requestChanges(ContractTemplate template) async {
    final notes = await _changeNotes();
    if (notes == null || notes.trim().isEmpty) return;
    await _decide(
      template,
      status: 'changes_requested',
      decisionNotes: notes.trim(),
    );
  }

  Future<String?> _changeNotes() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request template changes'),
        content: CoreTextField(
          controller: controller,
          label: 'Required changes',
          icon: Icons.edit_note_outlined,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              final value = controller.text.trim();
              if (value.length >= 3) Navigator.pop(dialogContext, value);
            },
            icon: const Icon(Icons.send_outlined),
            label: const Text('Send decision'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  Future<void> _decide(
    ContractTemplate template, {
    required String status,
    String? decisionNotes,
  }) async {
    final contracts = ContractsScope.maybeOf(context);
    if (contracts == null) return;
    setState(() => _busyId = template.publicId);
    try {
      await contracts.reviewTemplate(
        templateId: template.publicId,
        status: status,
        decisionNotes: decisionNotes,
      );
      if (!mounted) return;
      legalSnack(context, 'Template review saved as $status');
      _refresh();
    } catch (error) {
      if (mounted) legalSnack(context, 'Could not save review: $error');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }
}

class _TemplateCard extends StatelessWidget {
  final ContractTemplate template;
  final LegalReviewDto? latestReview;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onChanges;

  const _TemplateCard({
    required this.template,
    required this.latestReview,
    required this.busy,
    required this.onApprove,
    required this.onChanges,
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
                    template.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                LegalStatusChip(
                  status: legalStatusFromString(
                    latestReview?.status ?? template.status,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LegalInfoRow(
              icon: Icons.category_outlined,
              label: 'Category',
              value: template.category,
            ),
            LegalInfoRow(
              icon: Icons.public_outlined,
              label: 'Jurisdiction',
              value: template.jurisdiction,
            ),
            LegalInfoRow(
              icon: Icons.numbers_outlined,
              label: 'Version',
              value: '${template.versionNumber}',
            ),
            LegalInfoRow(
              icon: Icons.rule_outlined,
              label: 'Clauses',
              value: '${template.clauses.length}',
            ),
            if (latestReview?.decisionNotes?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(
                latestReview!.decisionNotes!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.smallMeta.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: CoreSecondaryButton(
                    icon: Icons.edit_note_outlined,
                    label: 'Request changes',
                    compact: true,
                    onTap: busy ? null : onChanges,
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

class _TemplateReviewBundle {
  final List<ContractTemplate> templates;
  final List<LegalReviewDto> reviews;

  const _TemplateReviewBundle({
    required this.templates,
    required this.reviews,
  });

  List<LegalReviewDto> get templateReviews => reviews
      .where((row) =>
          row.templateId != null &&
          row.contractId == null &&
          row.addendumId == null)
      .toList();
}
