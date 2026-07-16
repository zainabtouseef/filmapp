part of '../super_admin_screens.dart';

class ReceiptsLedgerAdminScreen extends StatefulWidget {
  const ReceiptsLedgerAdminScreen({super.key});

  @override
  State<ReceiptsLedgerAdminScreen> createState() =>
      _ReceiptsLedgerAdminScreenState();
}

class _ReceiptsLedgerAdminScreenState extends State<ReceiptsLedgerAdminScreen> {
  String _filter = 'All';
  final _search = TextEditingController();

  static const _filters = [
    'All',
    'Incoming',
    'Outgoing',
    'Verified',
    'Released',
    'Refunded',
    'Disputed',
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(LedgerRowData entry) {
    final query = _search.text.toLowerCase();
    final queryMatch = query.isEmpty ||
        entry.bookingId.toLowerCase().contains(query) ||
        entry.projectName.toLowerCase().contains(query);
    if (!queryMatch) return false;
    return switch (_filter) {
      'All' => true,
      'Incoming' => entry.direction == LedgerDirection.incoming,
      'Outgoing' => entry.direction == LedgerDirection.outgoing,
      'Verified' => entry.status == LedgerStatus.verified,
      'Released' => entry.status == LedgerStatus.released,
      'Refunded' => entry.status == LedgerStatus.refunded,
      'Disputed' => entry.status == LedgerStatus.disputed,
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final rows = AdminMockData.ledgerEntries.where(_matches).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoreTextField(
          controller: _search,
          label: 'Search booking or project',
          icon: Icons.search_rounded,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        AdminFilterBar(
          filters: _filters,
          selected: _filter,
          onSelected: (value) => setState(() => _filter = value),
        ),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          const AdminEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No matching ledger entries',
            message: 'Try a different filter or search term.',
          )
        else
          AdminSurface(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Column(
              children: rows.asMap().entries.map((entry) {
                return _LedgerRow(
                  entry: entry.value,
                  showDivider: entry.key != rows.length - 1,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
