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
  Future<List<ContractTemplate>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= ContractsScope.maybeOf(context)?.templates();
  }

  void _refresh() {
    setState(() => _future = ContractsScope.maybeOf(context)?.templates());
  }

  @override
  Widget build(BuildContext context) {
    return LegalTwoColumn(
      left: LegalSectionCard(
        title: 'Template review',
        icon: Icons.article_outlined,
        selected: true,
        actionText: _future == null ? null : 'Refresh',
        onActionTap: _refresh,
        child: _future == null
            ? const CoreEmptyState(
                icon: Icons.lock_outline_rounded,
                title: 'Sign in to view templates',
                message: 'Contract templates are loaded from the server.',
              )
            : FutureBuilder<List<ContractTemplate>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SkeletonCard(height: 440);
                  }
                  if (snapshot.hasError) {
                    return LegalLoadError(
                      message: 'Could not load templates',
                      onRetry: _refresh,
                    );
                  }
                  final templates = snapshot.data ?? const [];
                  if (templates.isEmpty) {
                    return const CoreEmptyState(
                      icon: Icons.article_outlined,
                      title: 'No live templates',
                      message:
                          'Seed contract templates in MySQL to make this review screen visible.',
                    );
                  }
                  return LegalResponsiveGrid(
                    minWidth: 310,
                    children: [
                      for (final template in templates)
                        _TemplateCard(template: template),
                    ],
                  );
                },
              ),
      ),
      right: const LegalSectionCard(
        title: 'Template workflow gap',
        icon: Icons.api_outlined,
        child: Column(
          children: [
            LegalInfoRow(
              icon: Icons.check_circle_outline,
              label: 'Live',
              value: 'GET templates',
            ),
            LegalInfoRow(
              icon: Icons.edit_note_outlined,
              label: 'Needed',
              value: 'Template review decision',
            ),
            LegalInfoRow(
              icon: Icons.history_outlined,
              label: 'Needed',
              value: 'Template change log',
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final ContractTemplate template;

  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 18,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            template.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.cardLabel.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
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
          LegalInfoRow(
            icon: Icons.flag_outlined,
            label: 'Status',
            value: template.status,
          ),
        ],
      ),
    );
  }
}
