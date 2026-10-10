import 'package:flutter/material.dart';

import '../../core_ui/core_routes.dart';
import '../../core_ui/models/shared_models.dart';
import '../../core_ui/widgets/core_widgets.dart';
import '../../network/save_download.dart';
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

  void _details(LedgerRowData row) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReceiptDetailsSheet(
        row: row,
        onDownload: row.receiptId.isEmpty ? null : () => _downloadReceipt(row),
      ),
    );
  }

  Future<void> _downloadReceipt(LedgerRowData row) async {
    try {
      final download =
          await PaymentsScope.of(context).downloadReceipt(row.receiptId);
      if (!mounted) return;
      final saved =
          saveDownload(download.filename, download.bytes, download.contentType);
      showCoreSnack(
        context,
        saved
            ? 'Receipt PDF downloaded'
            : 'Receipt PDF is ready. Browser download is available on web.',
      );
    } catch (error) {
      if (mounted) showCoreSnack(context, 'Receipt download failed: $error');
    }
  }

  void _retry() {
    setState(() {
      _ledgerFuture = PaymentsScope.of(context).ledger(force: true);
    });
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
          if (snapshot.hasError) {
            return _ledgerScaffold(
              context,
              rows: const [],
              error: snapshot.error,
            );
          }
          return _ledgerScaffold(
            context,
            rows: _filterRows(liveRows),
            summaryRows: liveRows,
          );
        },
      );
    }
    return _ledgerScaffold(context, rows: const []);
  }

  Widget _ledgerScaffold(
    BuildContext context, {
    required List<LedgerRowData> rows,
    List<LedgerRowData>? summaryRows,
    Object? error,
  }) {
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
          _summaryGrid(context, summaryRows ?? rows),
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
          if (error != null)
            CoreEmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Ledger unavailable',
              message:
                  'CineConnect could not load the live ledger. No preview data is being substituted.',
              actionLabel: 'Retry',
              onAction: _retry,
            )
          else if (rows.isEmpty)
            const CoreEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No ledger rows',
              message: 'No live payments match this filter yet.',
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

  Widget _summaryGrid(BuildContext context, List<LedgerRowData> rows) {
    final paid = rows
        .where((row) =>
            row.direction == LedgerDirection.outgoing &&
            row.status == LedgerStatus.verified)
        .fold<int>(0, (total, row) => total + row.amount);
    final received = rows
        .where((row) =>
            row.direction == LedgerDirection.incoming &&
            row.status == LedgerStatus.verified)
        .fold<int>(0, (total, row) => total + row.amount);
    final pending = rows
        .where((row) => row.status == LedgerStatus.pendingVerification)
        .fold<int>(0, (total, row) => total + row.amount);
    final disputed = rows
        .where((row) => row.status == LedgerStatus.disputed)
        .fold<int>(0, (total, row) => total + row.amount);
    return MetricStrip(
      title: 'Financial overview',
      items: [
        MetricStripItem(
          label: 'Total paid',
          value: _amountLabel(paid),
          icon: Icons.north_east_rounded,
          tone: CineTone.neutral,
          onTap: () => setState(() => _filter = 'Outgoing'),
        ),
        MetricStripItem(
          label: 'Total received',
          value: _amountLabel(received),
          icon: Icons.south_west_rounded,
          tone: CineTone.positive,
          onTap: () => setState(() => _filter = 'Incoming'),
        ),
        MetricStripItem(
          label: 'Pending verification',
          value: _amountLabel(pending),
          icon: Icons.hourglass_top_rounded,
          tone: CineTone.warning,
          onTap: () => setState(() => _filter = 'Pending'),
        ),
        MetricStripItem(
          label: 'Disputed amount',
          value: _amountLabel(disputed),
          icon: Icons.gpp_maybe_outlined,
          tone: CineTone.critical,
          onTap: () => setState(() => _filter = 'Disputed'),
        ),
      ],
    );
  }

  String _amountLabel(int amount) {
    if (amount >= 1000000) {
      return 'PKR ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) return 'PKR ${(amount / 1000).toStringAsFixed(0)}K';
    return 'PKR $amount';
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
  final VoidCallback? onDownload;

  const _ReceiptDetailsSheet({required this.row, required this.onDownload});

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
            _line(
              context,
              'Receipt',
              row.receiptNumber.isNotEmpty
                  ? row.receiptNumber
                  : row.receiptId.isNotEmpty
                      ? row.receiptId
                      : 'Not issued',
            ),
            _line(context, 'Booking', row.bookingId),
            _line(context, 'Admin verification stamp',
                ledgerStatusLabel(row.status)),
            _line(context, 'Transaction ID', row.transactionId),
            _line(context, 'Amount', 'PKR ${row.amount}'),
            const SizedBox(height: 18),
            CorePrimaryButton(
              icon: Icons.picture_as_pdf_outlined,
              label: onDownload == null ? 'Receipt not issued' : 'Download PDF',
              onTap: onDownload,
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
