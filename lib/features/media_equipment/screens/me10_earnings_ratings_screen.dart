import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_widgets.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/media_equipment_demo_data.dart';
import '../models/media_equipment_models.dart';
import '../widgets/media_equipment_components.dart';

class ME10EarningsRatingsScreen extends StatefulWidget {
  const ME10EarningsRatingsScreen({super.key});

  @override
  State<ME10EarningsRatingsScreen> createState() =>
      _ME10EarningsRatingsScreenState();
}

class _ME10EarningsRatingsScreenState extends State<ME10EarningsRatingsScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final store = MediaEquipmentDemoStore.instance;
    final colors = context.appColors;
    final rows = _rows(store).toList();
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MetricActionRail(
              items: [
                MetricActionItem(
                  value: 'PKR 2.4M',
                  icon: Icons.payments_outlined,
                  title: 'Revenue',
                  subtitle: 'Current',
                  accentColor: mediaToneColor(context, MediaTone.green),
                ),
                MetricActionItem(
                  value: '72%',
                  icon: Icons.query_stats_outlined,
                  title: 'Utilization',
                  subtitle: 'Current',
                  accentColor: mediaToneColor(context, MediaTone.blue),
                ),
                MetricActionItem(
                  value:
                      MediaEquipmentDemoData.profile.rating.toStringAsFixed(1),
                  icon: Icons.star_outline_rounded,
                  title: 'Rating',
                  subtitle: 'Current',
                  accentColor: mediaToneColor(context, MediaTone.purple),
                ),
                MetricActionItem(
                  value: store.damageClaimOpen ? '1' : '0',
                  icon: Icons.report_problem_outlined,
                  title: 'Disputes',
                  subtitle: 'Current',
                  accentColor: mediaToneColor(
                    context,
                    store.damageClaimOpen ? MediaTone.danger : MediaTone.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            MediaTwoColumn(
              left: MediaSectionCard(
                title: 'Money ledger',
                icon: Icons.table_rows_outlined,
                selected: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final filter in [
                            'All',
                            'Pending',
                            'Verified',
                            'Disputed',
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: CoreChip(
                                label: filter,
                                selected: _filter == filter,
                                onTap: () {
                                  setState(() => _filter = filter);
                                  mediaSnack(
                                      context, '$filter ledger filter applied');
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final row in rows)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _LedgerRow(
                          item: row,
                          onReceipt: () =>
                              Navigator.pushNamed(context, CoreRoutes.ledger),
                          onIssue: () => Navigator.pushNamed(
                            context,
                            CoreRoutes.report,
                            arguments: 'Equipment earnings issue',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              right: Column(
                children: [
                  MediaSectionCard(
                    title: 'Ratings breakdown',
                    icon: Icons.stars_outlined,
                    child: Column(
                      children: [
                        _RatingRow(label: 'Quality', value: 4.9),
                        _RatingRow(label: 'Punctuality', value: 4.8),
                        _RatingRow(label: 'Condition', value: 4.9),
                        _RatingRow(label: 'Communication', value: 4.7),
                        const SizedBox(height: 10),
                        CoreSecondaryButton(
                          icon: Icons.rate_review_outlined,
                          label: 'Open reviews',
                          compact: true,
                          onTap: () =>
                              Navigator.pushNamed(context, CoreRoutes.review),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  MediaSectionCard(
                    title: 'Utilization report',
                    icon: Icons.bar_chart_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MediaMiniBarChart(
                          values: const [28, 36, 41, 50, 46, 58, 62],
                          colors: [
                            colors.goldMid,
                            colors.infoBlue,
                            colors.infoPurple,
                          ],
                          height: 112,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            StatusChip(
                                label: 'Camera 82%', color: colors.goldMid),
                            StatusChip(
                                label: 'Drone 64%', color: colors.infoBlue),
                            StatusChip(
                                label: 'Audio 71%', color: colors.infoPurple),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ExportActionButton(
                          exportType: 'ledger',
                          label: 'Export report',
                          builder: (context, onTap, label) => CorePrimaryButton(
                            icon: Icons.file_download_outlined,
                            label: label,
                            compact: true,
                            onTap: onTap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Iterable<MediaLedgerItem> _rows(MediaEquipmentDemoStore store) {
    return store.visibleLedger.where((item) {
      return switch (_filter) {
        'Pending' => item.status == MediaBookingStatus.depositPending,
        'Verified' => item.status == MediaBookingStatus.secured,
        'Disputed' => item.status == MediaBookingStatus.disputed,
        _ => true,
      };
    });
  }
}

class _LedgerRow extends StatelessWidget {
  final MediaLedgerItem item;
  final VoidCallback onReceipt;
  final VoidCallback onIssue;

  const _LedgerRow({
    required this.item,
    required this.onReceipt,
    required this.onIssue,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 16,
      padding: const EdgeInsets.all(11),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.id == 'mel-3' ? mediaMoney(MediaEquipmentDemoStore.instance.damageClaimAmount ?? 0) : item.amount} - due ${item.dueDate}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          MediaBookingStatusChip(status: item.status),
          CardMenu<String>(
            items: const [
              CardMenuItem(
                value: 'receipt',
                label: 'Receipt',
                icon: Icons.receipt_long_outlined,
              ),
              CardMenuItem(
                value: 'issue',
                label: 'Report issue',
                icon: Icons.report_problem_outlined,
              ),
            ],
            onSelected: (value) {
              if (value == 'receipt') onReceipt();
              if (value == 'issue') onIssue();
            },
          ),
        ],
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final String label;
  final double value;

  const _RatingRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.cardLabel.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value.toStringAsFixed(1),
            style: AppTextStyles.statusText.copyWith(color: colors.goldDark),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
            child: LinearProgressIndicator(
              value: value / 5,
              minHeight: 7,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: colors.border,
              color: colors.goldMid,
            ),
          ),
        ],
      ),
    );
  }
}
