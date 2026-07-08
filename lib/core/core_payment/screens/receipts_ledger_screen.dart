import 'package:flutter/material.dart';

import '../../core_ui/core_routes.dart';
import '../../core_ui/mock_data/shared_mock_data.dart';
import '../../core_ui/models/shared_models.dart';
import '../../core_ui/widgets/core_widgets.dart';
import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';

class ReceiptsLedgerScreen extends StatefulWidget {
  const ReceiptsLedgerScreen({super.key});

  @override
  State<ReceiptsLedgerScreen> createState() => _ReceiptsLedgerScreenState();
}

class _ReceiptsLedgerScreenState extends State<ReceiptsLedgerScreen> {
  String _filter = 'All';
  final _filters = const [
    'All',
    'Incoming',
    'Outgoing',
    'Pending',
    'Verified',
    'Refunded',
    'Disputed',
  ];

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
          if (_rows.isEmpty)
            const CoreEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No ledger rows',
              message: 'No payments match this filter yet.',
            )
          else
            ..._rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: LedgerRowCard(row: row, onTap: () => _details(row)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryGrid(BuildContext context) {
    final items = const [
      ('Total paid', 'PKR 227k', Icons.north_east_rounded),
      ('Total received', 'PKR 190k', Icons.south_west_rounded),
      ('Pending verification', 'PKR 72k', Icons.hourglass_top_rounded),
      ('Disputed amount', 'PKR 50k', Icons.gpp_maybe_outlined),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _SummaryTile(label: item.$1, value: item.$2, icon: item.$3);
          },
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CoreGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: colors.goldDark),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sectionTitle.copyWith(
              color: colors.textPrimary,
              fontSize: 20,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class LedgerRowCard extends StatelessWidget {
  final LedgerRowData row;
  final VoidCallback onTap;

  const LedgerRowCard({
    super.key,
    required this.row,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: CoreGlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              row.direction == LedgerDirection.incoming
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              color: colors.goldDark,
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
                  const SizedBox(height: 5),
                  Text(
                    '${row.bookingId} · ${row.milestone} · ${row.date}',
                    style: AppTextStyles.caption
                        .copyWith(color: colors.textSecondary),
                  ),
                  const SizedBox(height: 9),
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
                  .copyWith(color: colors.textPrimary),
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
