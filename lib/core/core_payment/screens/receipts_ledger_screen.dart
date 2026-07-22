import 'package:flutter/material.dart';

import '../../core_ui/core_routes.dart';
import '../../core_ui/mock_data/shared_mock_data.dart';
import '../../core_ui/models/shared_models.dart';
import '../../core_ui/widgets/core_widgets.dart';
import '../../payments/payment_models.dart';
import '../../payments/payments_controller.dart';
import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';
import '../../../shared/cards/cine_card_system.dart';

class ReceiptsLedgerScreen extends StatefulWidget {
  const ReceiptsLedgerScreen({super.key});

  @override
  State<ReceiptsLedgerScreen> createState() => _ReceiptsLedgerScreenState();
}

class _ReceiptsLedgerScreenState extends State<ReceiptsLedgerScreen> {
  String _filter = 'All';
  Future<List<LedgerEntryDto>>? _ledgerFuture;
  final _filters = const [
    'All',
    'Incoming',
    'Outgoing',
    'Pending',
    'Verified',
    'Refunded',
    'Disputed',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final payments = PaymentsScope.maybeOf(context);
    if (payments != null) _ledgerFuture ??= payments.ledger(force: true);
  }

  List<LedgerRowData> get _rows {
    return SharedMockData.ledgerRows.where((row) {
      return switch (_filter) {
        'Incoming' => row.direction == LedgerDirection.incoming,
        'Outgoing' => row.direction == LedgerDirection.outgoing,
        'Pending' => row.status == LedgerStatus.pendingVerification,
        'Verified' => row.status == LedgerStatus.verified,
        'Refunded' => row.status == LedgerStatus.refunded,
        'Disputed' => row.status == LedgerStatus.disputed,
        _ => true,
      };
    }).toList();
  }

  void _details(LedgerRowData row) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReceiptDetailsSheet(row: row),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_ledgerFuture != null) {
      return FutureBuilder<List<LedgerEntryDto>>(
        future: _ledgerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CoreScreenScaffold(
              child: CoreEmptyState(
                icon: Icons.hourglass_top_rounded,
                title: 'Loading ledger',
                message: 'Fetching verified and pending payments.',
              ),
            );
          }
          final liveRows = (snapshot.data ?? const [])
              .map((row) => row.toLedgerRow())
              .toList();
          if (!snapshot.hasError && liveRows.isNotEmpty) {
            return _ledgerScaffold(context, rows: _filterRows(liveRows));
          }
          return _ledgerScaffold(context, rows: _rows);
        },
      );
    }
    return _ledgerScaffold(context, rows: _rows);
  }

  Widget _ledgerScaffold(BuildContext context,
      {required List<LedgerRowData> rows}) {
    return CoreScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CoreAppHeader(
            title: 'Receipts & Ledger',
            subtitle:
                'Track verified, pending and disputed payments in and out.',
            icon: Icons.receipt_long_outlined,
          ),
          const SizedBox(height: 18),
          _summaryGrid(context),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters
                  .map(
                    (filter) => Padding(
                      padding: const EdgeInsets.only(right: 9),
                      child: CoreChip(
                        label: filter,
                        selected: _filter == filter,
                        onTap: () => setState(() => _filter = filter),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 18),
          if (rows.isEmpty)
            const CoreEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No ledger rows',
              message: 'No payments match this filter yet.',
            )
          else
            CoreGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++)
                    LedgerRowCard(
                      row: rows[i],
                      onTap: () => _details(rows[i]),
                      showDivider: i != rows.length - 1,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<LedgerRowData> _filterRows(List<LedgerRowData> rows) {
    return rows.where((row) {
      return switch (_filter) {
        'Incoming' => row.direction == LedgerDirection.incoming,
        'Outgoing' => row.direction == LedgerDirection.outgoing,
        'Pending' => row.status == LedgerStatus.pendingVerification,
        'Verified' => row.status == LedgerStatus.verified,
        'Refunded' => row.status == LedgerStatus.refunded,
        'Disputed' => row.status == LedgerStatus.disputed,
        _ => true,
      };
    }).toList();
  }

  Widget _summaryGrid(BuildContext context) {
    return MetricStrip(
      title: 'Financial overview',
      items: [
        MetricStripItem(
          label: 'Total paid',
          value: 'PKR 227K',
          icon: Icons.north_east_rounded,
          tone: CineTone.neutral,
          onTap: () => setState(() => _filter = 'Outgoing'),
        ),
        MetricStripItem(
          label: 'Total received',
          value: 'PKR 190K',
          icon: Icons.south_west_rounded,
          tone: CineTone.positive,
          onTap: () => setState(() => _filter = 'Incoming'),
        ),
        MetricStripItem(
          label: 'Pending verification',
          value: 'PKR 72K',
          icon: Icons.hourglass_top_rounded,
          tone: CineTone.warning,
          onTap: () => setState(() => _filter = 'Pending'),
        ),
        MetricStripItem(
          label: 'Disputed amount',
          value: 'PKR 50K',
          icon: Icons.gpp_maybe_outlined,
          tone: CineTone.critical,
          onTap: () => setState(() => _filter = 'Disputed'),
        ),
      ],
    );
  }
}

class LedgerRowCard extends StatelessWidget {
  final LedgerRowData row;
  final VoidCallback onTap;
  final bool showDivider;

  const LedgerRowCard({
    super.key,
    required this.row,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: colors.borderMuted))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              row.direction == LedgerDirection.incoming
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              color: colors.goldDark,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.projectName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${row.bookingId} · ${row.milestone} · ${row.date}',
                    style: AppTextStyles.caption
                        .copyWith(color: colors.textSecondary),
                  ),
                  const SizedBox(height: 7),
                  StatusBadge(
                    label: ledgerStatusLabel(row.status),
                    tone: ledgerStatusTone(row.status),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'PKR ${row.amount}',
                  style: AppTextStyles.label.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  row.direction == LedgerDirection.incoming
                      ? 'Received'
                      : 'Paid',
                  style: AppTextStyles.caption
                      .copyWith(color: colors.textTertiary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptDetailsSheet extends StatelessWidget {
  final LedgerRowData row;

  const _ReceiptDetailsSheet({required this.row});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
      decoration: BoxDecoration(
        gradient: colors.cardGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Receipt Detail',
              style: AppTextStyles.sectionTitle
                  .copyWith(color: colors.textPrimary, fontSize: 19),
            ),
            const SizedBox(height: 14),
            _line(context, 'Receipt ID', row.receiptId),
            _line(context, 'Contract ID', 'CC-CON-2026-0041'),
            _line(context, 'Admin verification stamp',
                ledgerStatusLabel(row.status)),
            _line(context, 'Transaction ID', row.transactionId),
            _line(context, 'Amount', 'PKR ${row.amount}'),
            _line(context, 'Parties', 'Sara Ahmed Productions and Ali Khan'),
            const SizedBox(height: 18),
            CorePrimaryButton(
              icon: Icons.picture_as_pdf_outlined,
              label: 'Download PDF',
              onTap: () =>
                  showCoreSnack(context, 'Receipt PDF download simulated'),
            ),
            const SizedBox(height: 10),
            CoreSecondaryButton(
              icon: Icons.gpp_maybe_outlined,
              label: 'Raise Payment Dispute',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, CoreRoutes.report,
                    arguments: 'Payment fraud');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style:
                  AppTextStyles.caption.copyWith(color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.label.copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
