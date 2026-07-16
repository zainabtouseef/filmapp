import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../data/legal_partner_demo_data.dart';
import '../models/legal_partner_models.dart';
import '../routes/legal_partner_routes.dart';
import '../widgets/legal_partner_components.dart';

class LG04AddendumReviewScreen extends StatefulWidget {
  const LG04AddendumReviewScreen({super.key});

  @override
  State<LG04AddendumReviewScreen> createState() =>
      _LG04AddendumReviewScreenState();
}

class _LG04AddendumReviewScreenState extends State<LG04AddendumReviewScreen> {
  String _tab = 'All';

  @override
  Widget build(BuildContext context) {
    final store = LegalPartnerDemoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final addendums = _addendums(store).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LegalSectionCard(
              title: 'Addendum workspace',
              icon: Icons.post_add_outlined,
              selected: true,
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final tab in [
                          'All',
                          'Pending',
                          'Reviewing',
                          'Approved'
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CoreChip(
                              label: tab,
                              selected: _tab == tab,
                              onTap: () {
                                setState(() => _tab = tab);
                                legalSnack(context, '$tab addendums shown');
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  MetricActionRail(
                    items: [
                      MetricActionItem(
                        icon: Icons.post_add_outlined,
                        value: '2',
                        title: 'Pending',
                        subtitle: 'Addendums',
                        accentColor: context.appColors.goldDark,
                      ),
                      MetricActionItem(
                        icon: Icons.post_add_outlined,
                        value: '5',
                        title: 'Pinned',
                        subtitle: 'Addendums',
                        accentColor: context.appColors.goldDark,
                      ),
                      MetricActionItem(
                        icon: Icons.post_add_outlined,
                        value: '1',
                        title: 'Approved',
                        subtitle: 'Addendums',
                        accentColor: context.appColors.goldDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (addendums.isEmpty)
              CoreEmptyState(
                icon: Icons.post_add_outlined,
                title: 'No addendums here',
                message:
                    'Switch tabs or wait for pinned project-room decisions.',
                actionLabel: 'Open contract',
                onAction: () => Navigator.pushNamed(
                  context,
                  LegalPartnerRoutes.contractReview,
                ),
              )
            else
              LegalResponsiveGrid(
                minWidth: 320,
                children: [
                  for (final item in addendums)
                    _AddendumCard(
                      item: item,
                      status: store.addendumStatus(item),
                      onApprove: () {
                        store.approveAddendum(item.id);
                        legalSnack(context, 'Addendum approved');
                      },
                      onCorrection: () {
                        store.correctAddendum(item.id);
                        legalSnack(context, 'Correction requested');
                      },
                      onDetail: () => _showAddendum(context, item),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  Iterable<LegalAddendumItem> _addendums(LegalPartnerDemoStore store) {
    return LegalPartnerDemoData.addendums.where((item) {
      final status = store.addendumStatus(item);
      return switch (_tab) {
        'Pending' => status == LegalStatus.addendumPending,
        'Reviewing' => status == LegalStatus.reviewing ||
            status == LegalStatus.correctionRequested,
        'Approved' => status == LegalStatus.approved,
        _ => true,
      };
    });
  }

  void _showAddendum(BuildContext context, LegalAddendumItem item) {
    showLegalSheet(
      context,
      title: item.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LegalInfoRow(
            icon: Icons.push_pin_outlined,
            label: 'Pinned decision',
            value: item.sourceDecision,
          ),
          LegalInfoRow(
            icon: Icons.article_outlined,
            label: 'Contract',
            value: item.affectedContract,
          ),
          LegalInfoRow(
            icon: Icons.schedule_outlined,
            label: 'Due',
            value: item.dueDate,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.description_outlined,
                  label: 'Contract',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, CoreRoutes.contract);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Chat',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, CoreRoutes.chat);
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

class _AddendumCard extends StatelessWidget {
  final LegalAddendumItem item;
  final LegalStatus status;
  final VoidCallback onApprove;
  final VoidCallback onCorrection;
  final VoidCallback onDetail;

  const _AddendumCard({
    required this.item,
    required this.status,
    required this.onApprove,
    required this.onCorrection,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 20,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LegalMediaFrame(
            imageUrl: item.imageUrl,
            title: item.title,
            badge: item.dueDate,
            fallbackIcon: Icons.post_add_outlined,
            aspectRatio: 16 / 9,
            compact: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              LegalStatusChip(status: status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.sourceDecision,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            item.affectedContract,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.statusText.copyWith(color: colors.goldDark),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.info_outline_rounded,
                  label: 'Detail',
                  compact: true,
                  onTap: onDetail,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.edit_note_outlined,
                  label: 'Correct',
                  compact: true,
                  onTap: onCorrection,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.check_circle_outline,
                  label: 'Approve',
                  compact: true,
                  onTap: onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
