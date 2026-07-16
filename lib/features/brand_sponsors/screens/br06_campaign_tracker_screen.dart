import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../data/brand_sponsor_demo_data.dart';
import '../models/brand_sponsor_models.dart';
import '../routes/brand_sponsor_routes.dart';
import '../widgets/brand_sponsor_components.dart';

class BR06CampaignTrackerScreen extends StatefulWidget {
  const BR06CampaignTrackerScreen({super.key});

  @override
  State<BR06CampaignTrackerScreen> createState() =>
      _BR06CampaignTrackerScreenState();
}

class _BR06CampaignTrackerScreenState extends State<BR06CampaignTrackerScreen> {
  String _tab = 'All';

  @override
  Widget build(BuildContext context) {
    final store = BrandSponsorDemoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final items = _deliverables(store).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BrandSectionCard(
              title: 'Campaign context',
              icon: Icons.track_changes_outlined,
              selected: true,
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final tab in ['All', 'Due', 'Review', 'Approved'])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CoreChip(
                              label: tab,
                              selected: _tab == tab,
                              onTap: () {
                                setState(() => _tab = tab);
                                brandSnack(context, '$tab deliverables shown');
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
                        icon: Icons.fact_check_outlined,
                        value: '2',
                        title: 'Due',
                        subtitle: 'Campaign',
                        accentColor: context.appColors.goldDark,
                      ),
                      MetricActionItem(
                        icon: Icons.fact_check_outlined,
                        value: '3',
                        title: 'Proofs',
                        subtitle: 'Campaign',
                        accentColor: context.appColors.goldDark,
                      ),
                      MetricActionItem(
                        icon: Icons.fact_check_outlined,
                        value: '1',
                        title: 'Risks',
                        subtitle: 'Campaign',
                        accentColor: context.appColors.goldDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              CoreEmptyState(
                icon: Icons.fact_check_outlined,
                title: 'No deliverables here',
                message: 'Switch tabs or wait for proof uploads.',
                actionLabel: 'Open payments',
                onAction: () => Navigator.pushNamed(
                  context,
                  BrandSponsorRoutes.payments,
                ),
              )
            else
              BrandResponsiveGrid(
                minWidth: 320,
                children: [
                  for (final item in items)
                    _DeliverableCard(
                      item: item,
                      status: store.deliverableStatus(item),
                      onApprove: () {
                        store.approveDeliverable(item.id);
                        brandSnack(context, 'Deliverable approved');
                      },
                      onRevision: () {
                        store.requestRevision(item.id);
                        brandSnack(context, 'Revision requested');
                      },
                      onDelivered: () {
                        store.markDelivered(item.id);
                        brandSnack(context, 'Proof marked delivered');
                      },
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  Iterable<BrandDeliverable> _deliverables(BrandSponsorDemoStore store) {
    return BrandSponsorDemoData.deliverables.where((item) {
      final status = store.deliverableStatus(item);
      return switch (_tab) {
        'Due' => status == BrandStatus.pending,
        'Review' =>
          status == BrandStatus.reviewing || status == BrandStatus.revision,
        'Approved' => status == BrandStatus.approved,
        _ => true,
      };
    });
  }
}

class _DeliverableCard extends StatelessWidget {
  final BrandDeliverable item;
  final BrandStatus status;
  final VoidCallback onApprove;
  final VoidCallback onRevision;
  final VoidCallback onDelivered;

  const _DeliverableCard({
    required this.item,
    required this.status,
    required this.onApprove,
    required this.onRevision,
    required this.onDelivered,
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
          BrandMediaFrame(
            imageUrl: item.imageUrl,
            title: item.label,
            badge: item.dueDate,
            fallbackIcon: Icons.fact_check_outlined,
            aspectRatio: 16 / 9,
            compact: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              BrandStatusChip(status: status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${item.owner} - ${item.proof}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.cloud_upload_outlined,
                  label: 'Proof',
                  compact: true,
                  onTap: onDelivered,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.edit_note_outlined,
                  label: 'Revision',
                  compact: true,
                  onTap: onRevision,
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
