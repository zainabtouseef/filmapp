import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_widgets.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../data/location_owner_demo_data.dart';
import '../models/location_owner_models.dart';
import '../widgets/location_owner_components.dart';

class LO09EarningsDepositsScreen extends StatefulWidget {
  const LO09EarningsDepositsScreen({super.key});

  @override
  State<LO09EarningsDepositsScreen> createState() =>
      _LO09EarningsDepositsScreenState();
}

class _LO09EarningsDepositsScreenState
    extends State<LO09EarningsDepositsScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final store = LocationOwnerDemoStore.instance;
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
                  value: 'PKR 1.8M',
                  icon: Icons.payments_outlined,
                  title: 'Rental income',
                  subtitle: 'Current',
                  accentColor: locationToneColor(context, LocationTone.green),
                ),
                MetricActionItem(
                  value: locationMoney(store.depositHeldAmount),
                  icon: Icons.lock_clock_outlined,
                  title: 'Deposits held',
                  subtitle: 'Current',
                  accentColor: locationToneColor(context, LocationTone.gold),
                ),
                MetricActionItem(
                  value: locationMoney(store.depositReleasedAmount),
                  icon: Icons.verified_outlined,
                  title: 'Released',
                  subtitle: 'Current',
                  accentColor: locationToneColor(context, LocationTone.blue),
                ),
                MetricActionItem(
                  value: locationMoney(store.depositClaimedAmount),
                  icon: Icons.report_problem_outlined,
                  title: 'Claimed',
                  subtitle: 'Current',
                  accentColor: locationToneColor(
                    context,
                    store.damageClaimOpen
                        ? LocationTone.danger
                        : LocationTone.neutral,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LocationTwoColumn(
              left: LocationSectionCard(
                title: 'Rental ledger',
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
                                  locationSnack(
                                    context,
                                    '$filter earnings filter applied',
                                  );
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
                            arguments: 'Location ledger issue',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              right: Column(
                children: [
                  LocationSectionCard(
                    title: 'Payment timeline',
                    icon: Icons.account_tree_outlined,
                    child: Column(
                      children: [
                        const _CompactTimelineStep(
                          label: 'Deposit requested',
                          value: 'Jul 18',
                          status: LocationBookingStatus.depositPending,
                        ),
                        const _CompactTimelineStep(
                          label: 'Proof verified',
                          value: 'Admin queue',
                          status: LocationBookingStatus.secured,
                        ),
                        _CompactTimelineStep(
                          label: 'Shoot completed',
                          value: store.checkOutConfirmed
                              ? 'Checked out'
                              : store.checkInConfirmed
                                  ? 'In progress'
                                  : 'Pending check-in',
                          status: store.checkOutConfirmed
                              ? LocationBookingStatus.closed
                              : store.checkInConfirmed
                                  ? LocationBookingStatus.inProgress
                                  : LocationBookingStatus.depositPending,
                        ),
                        _CompactTimelineStep(
                          label: 'Release / claim',
                          value: store.damageClaimOpen
                              ? 'Claim filed'
                              : store.checkOutConfirmed
                                  ? 'Released'
                                  : 'After inspection',
                          status: store.damageClaimOpen
                              ? LocationBookingStatus.disputed
                              : store.checkOutConfirmed
                                  ? LocationBookingStatus.closed
                                  : LocationBookingStatus.depositPending,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  LocationSectionCard(
                    title: 'Money-safe actions',
                    icon: Icons.security_outlined,
                    child: Column(
                      children: [
                        CoreSecondaryButton(
                          icon: Icons.upload_file_outlined,
                          label: 'Preview payment proof',
                          compact: true,
                          onTap: () => Navigator.pushNamed(
                            context,
                            CoreRoutes.paymentProof,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CoreSecondaryButton(
                          icon: Icons.receipt_long_outlined,
                          label: 'Open receipts',
                          compact: true,
                          onTap: () =>
                              Navigator.pushNamed(context, CoreRoutes.ledger),
                        ),
                        const SizedBox(height: 8),
                        ExportActionButton(
                          exportType: 'ledger',
                          label: 'Export ledger',
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

  Iterable<LocationLedgerItem> _rows(LocationOwnerDemoStore store) {
    return store.visibleLedger.where((item) {
      return switch (_filter) {
        'Pending' => item.status == LocationBookingStatus.depositPending,
        'Verified' => item.status == LocationBookingStatus.secured,
        'Disputed' => item.status == LocationBookingStatus.disputed,
        _ => true,
      };
    });
  }
}

class _LedgerRow extends StatelessWidget {
  final LocationLedgerItem item;
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
                  '${item.id == 'led-3' ? locationMoney(LocationOwnerDemoStore.instance.damageClaimAmount ?? 0) : item.amount} - due ${item.dueDate}',
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
          LocationBookingStatusChip(status: item.status),
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

class _CompactTimelineStep extends StatelessWidget {
  final String label;
  final String value;
  final LocationBookingStatus status;

  const _CompactTimelineStep({
    required this.label,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = locationStatusColor(context, status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardLabel.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
