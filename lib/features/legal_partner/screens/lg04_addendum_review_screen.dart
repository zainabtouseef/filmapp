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

class LG04AddendumReviewScreen extends StatefulWidget {
  const LG04AddendumReviewScreen({super.key});

  @override
  State<LG04AddendumReviewScreen> createState() =>
      _LG04AddendumReviewScreenState();
}

class _LG04AddendumReviewScreenState extends State<LG04AddendumReviewScreen> {
  Future<List<CineContract>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= ContractsScope.maybeOf(context)?.contracts(force: true);
  }

  void _refresh() {
    setState(() =>
        _future = ContractsScope.maybeOf(context)?.contracts(force: true));
  }

  @override
  Widget build(BuildContext context) {
    return LegalSectionCard(
      title: 'Addendum review',
      icon: Icons.post_add_outlined,
      selected: true,
      actionText: _future == null ? null : 'Refresh',
      onActionTap: _refresh,
      child: _future == null
          ? const CoreEmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Sign in to view addendums',
              message: 'Contract addendums are loaded from live contracts.',
            )
          : FutureBuilder<List<CineContract>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SkeletonCard(height: 460);
                }
                if (snapshot.hasError) {
                  return LegalLoadError(
                    message: 'Could not load contract addendums',
                    onRetry: _refresh,
                  );
                }
                final rows = _addendums(snapshot.data ?? const []);
                if (rows.isEmpty) {
                  return const CoreEmptyState(
                    icon: Icons.post_add_outlined,
                    title: 'No live addendums',
                    message:
                        'Create addendums through contract APIs to make this review screen visible.',
                  );
                }
                return LegalResponsiveGrid(
                  minWidth: 320,
                  children: [
                    for (final item in rows) _AddendumCard(item: item),
                  ],
                );
              },
            ),
    );
  }

  List<_AddendumRow> _addendums(List<CineContract> contracts) {
    return [
      for (final contract in contracts)
        for (final addendum in contract.addendums)
          _AddendumRow(contract: contract, addendum: addendum),
    ];
  }
}

class _AddendumRow {
  final CineContract contract;
  final ContractAddendum addendum;

  const _AddendumRow({required this.contract, required this.addendum});
}

class _AddendumCard extends StatelessWidget {
  final _AddendumRow item;

  const _AddendumCard({required this.item});

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
                  item.contract.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              LegalStatusChip(
                status: legalStatusFromString(item.addendum.status),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LegalInfoRow(
            icon: Icons.person_outline,
            label: 'Requested by',
            value: item.addendum.requestedBy.displayName,
          ),
          LegalInfoRow(
            icon: Icons.edit_note_outlined,
            label: 'Reason',
            value: item.addendum.reason.isEmpty
                ? 'No reason supplied'
                : item.addendum.reason,
          ),
          LegalInfoRow(
            icon: Icons.article_outlined,
            label: 'Content',
            value: item.addendum.content.isEmpty
                ? 'No content supplied'
                : item.addendum.content,
          ),
          LegalInfoRow(
            icon: Icons.description_outlined,
            label: 'Contract',
            value: item.contract.publicId,
          ),
        ],
      ),
    );
  }
}
