import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_widgets.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/payments/payment_models.dart';
import '../../../core/payments/payments_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/location_owner_demo_data.dart';
import '../models/location_owner_models.dart';
import '../widgets/location_owner_components.dart';
import '../widgets/location_owner_live.dart';

class LO09EarningsDepositsScreen extends StatefulWidget {
  const LO09EarningsDepositsScreen({super.key});

  @override
  State<LO09EarningsDepositsScreen> createState() =>
      _LO09EarningsDepositsScreenState();
}

class _LO09EarningsDepositsScreenState
    extends State<LO09EarningsDepositsScreen> {
  PaymentsController? _payments;
  Future<_EarningsData>? _future;
  String _filter = 'All';
  bool _addingAccount = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final payments = PaymentsScope.maybeOf(context);
    if (payments == null || identical(payments, _payments)) return;
    _payments = payments;
    _future = _load();
  }

  Future<_EarningsData> _load({bool force = false}) async {
    final dashboard = await _payments!.dashboard(force: force);
    final ledger = await _payments!.ledger(force: force);
    final accounts = await _payments!.payoutAccounts();
    return _EarningsData(
      dashboard: dashboard,
      ledger: ledger,
      accounts: accounts,
    );
  }

  void _reload() {
    if (_payments == null) return;
    setState(() => _future = _load(force: true));
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) return _buildPreview();
    return FutureBuilder<_EarningsData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return CoreEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Earnings unavailable',
            message: locationApiMessage(snapshot.error!),
            actionLabel: 'Try again',
            onAction: _reload,
          );
        }
        return _buildEarnings(snapshot.data!);
      },
    );
  }

  Widget _buildEarnings(_EarningsData data) {
    final colors = context.appColors;
    final credits = data.ledger
        .where((item) => item.direction == 'credit')
        .fold<int>(0, (total, item) => total + item.amountMinor);
    final verified = data.ledger
        .where(
            (item) => {'verified', 'posted', 'released'}.contains(item.status))
        .fold<int>(0, (total, item) => total + item.amountMinor);
    final disputed =
        data.ledger.where((item) => item.status == 'disputed').length;
    final rows = _filteredRows(data.ledger);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MetricActionRail(
          items: [
            MetricActionItem(
              value: _minorMoney(credits),
              icon: Icons.payments_outlined,
              title: 'Incoming ledger',
              subtitle: 'All credits',
              accentColor: colors.success,
            ),
            MetricActionItem(
              value: _minorMoney(data.dashboard.pendingReleaseMinor),
              icon: Icons.lock_clock_outlined,
              title: 'Pending release',
              subtitle: 'Admin-controlled',
              accentColor: colors.goldMid,
            ),
            MetricActionItem(
              value: _minorMoney(verified),
              icon: Icons.verified_outlined,
              title: 'Verified entries',
              subtitle: 'Posted or released',
              accentColor: colors.infoBlue,
            ),
            MetricActionItem(
              value: '$disputed',
              icon: Icons.report_problem_outlined,
              title: 'Disputed entries',
              subtitle: 'Needs review',
              accentColor: disputed > 0 ? colors.danger : colors.textSecondary,
            ),
          ],
        ),
        const SizedBox(height: 12),
        LocationTwoColumn(
          left: LocationSectionCard(
            title: 'Rental ledger',
            icon: Icons.table_rows_outlined,
            selected: true,
            actionText: 'Refresh',
            onActionTap: _reload,
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
                            onTap: () => setState(() => _filter = filter),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (rows.isEmpty)
                  const CoreEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No matching ledger entries',
                    message:
                        'Verified booking payments and release events will appear here.',
                  )
                else
                  for (final row in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _LedgerRow(item: row),
                    ),
              ],
            ),
          ),
          right: Column(
            children: [
              LocationSectionCard(
                title: 'Payment schedules',
                icon: Icons.account_tree_outlined,
                tone: LocationTone.blue,
                child: data.dashboard.schedules.isEmpty
                    ? const CoreEmptyState(
                        icon: Icons.event_note_outlined,
                        title: 'No payment schedules',
                        message:
                            'Schedules are created through secured booking contracts.',
                      )
                    : Column(
                        children: [
                          for (final schedule
                              in data.dashboard.schedules.take(4))
                            _ScheduleRow(schedule: schedule),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              LocationSectionCard(
                title: 'Payout & records',
                icon: Icons.account_balance_outlined,
                tone: LocationTone.green,
                child: Column(
                  children: [
                    if (data.accounts.isEmpty)
                      const LocationInfoRow(
                        icon: Icons.account_balance_outlined,
                        label: 'Payout account',
                        value: 'Not connected',
                      )
                    else
                      for (final account in data.accounts.take(2))
                        LocationInfoRow(
                          icon: Icons.account_balance_outlined,
                          label: account.accountName,
                          value:
                              '${account.accountMasked} · ${readableLocationStatus(account.status)}',
                        ),
                    const SizedBox(height: 8),
                    CoreSecondaryButton(
                      icon: Icons.science_outlined,
                      label: _addingAccount
                          ? 'Adding...'
                          : 'Add test payout account',
                      compact: true,
                      onTap: _addingAccount ? null : () => _addSandboxAccount(),
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
  }

  List<LedgerEntryDto> _filteredRows(List<LedgerEntryDto> rows) {
    return rows.where((item) {
      return switch (_filter) {
        'Pending' => {'pending', 'pending_release', 'pending_verification'}
            .contains(item.status),
        'Verified' => {'verified', 'posted', 'released'}.contains(item.status),
        'Disputed' => item.status == 'disputed',
        _ => true,
      };
    }).toList();
  }

  Future<void> _addSandboxAccount() async {
    final name =
        AuthScope.maybeOf(context)?.user?.displayName ?? 'Location owner';
    setState(() => _addingAccount = true);
    try {
      await _payments!.createSandboxPayoutAccount(accountName: name);
      if (!mounted) return;
      locationSnack(context, 'Test payout account added');
      _reload();
    } catch (error) {
      if (!mounted) return;
      locationSnack(context, locationApiMessage(error));
    } finally {
      if (mounted) setState(() => _addingAccount = false);
    }
  }

  String _minorMoney(int amountMinor) {
    return 'PKR ${compactLocationMoney(amountMinor ~/ 100)}';
  }

  Widget _buildPreview() {
    return LocationSectionCard(
      title: 'Earnings preview',
      icon: Icons.payments_outlined,
      selected: true,
      child: Column(
        children: [
          for (final item in LocationOwnerDemoData.ledger)
            LocationInfoRow(
              icon: Icons.receipt_long_outlined,
              label: item.label,
              value: item.amount,
            ),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final LedgerEntryDto item;

  const _LedgerRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final status = _statusFor(item.status);
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
                  item.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.currency} ${compactLocationMoney(item.amountMinor ~/ 100)} · '
                  '${item.bookingId ?? item.entryType}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          LocationBookingStatusChip(status: status),
          CardMenu<String>(
            items: const [
              CardMenuItem(
                value: 'receipts',
                label: 'Receipts',
                icon: Icons.receipt_long_outlined,
              ),
              CardMenuItem(
                value: 'issue',
                label: 'Report issue',
                icon: Icons.report_problem_outlined,
              ),
            ],
            onSelected: (value) {
              if (value == 'receipts') {
                Navigator.pushNamed(context, CoreRoutes.ledger);
              } else {
                Navigator.pushNamed(
                  context,
                  CoreRoutes.report,
                  arguments: 'Location ledger issue ${item.publicId}',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  static LocationBookingStatus _statusFor(String status) {
    return switch (status) {
      'verified' || 'posted' || 'released' => LocationBookingStatus.secured,
      'disputed' || 'rejected' => LocationBookingStatus.disputed,
      _ => LocationBookingStatus.depositPending,
    };
  }
}

class _ScheduleRow extends StatelessWidget {
  final PaymentScheduleDto schedule;

  const _ScheduleRow({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: colors.inactiveChipGradient,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.event_note_outlined, color: colors.goldDark, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.bookingId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${schedule.totalLabel} · '
                    '${schedule.milestones.length} milestones',
                    style: AppTextStyles.smallMeta.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            StatusChip(
              label: readableLocationStatus(schedule.status),
              color: colors.infoBlue,
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningsData {
  final PaymentDashboardDto dashboard;
  final List<LedgerEntryDto> ledger;
  final List<PayoutAccountDto> accounts;

  const _EarningsData({
    required this.dashboard,
    required this.ledger,
    required this.accounts,
  });
}
