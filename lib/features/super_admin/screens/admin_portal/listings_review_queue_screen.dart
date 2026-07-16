part of '../super_admin_screens.dart';

class ListingsReviewQueueScreen extends StatefulWidget {
  const ListingsReviewQueueScreen({super.key});

  @override
  State<ListingsReviewQueueScreen> createState() =>
      _ListingsReviewQueueScreenState();
}

class _ListingsReviewQueueScreenState extends State<ListingsReviewQueueScreen> {
  String _filter = 'All';
  final _search = TextEditingController();

  static const _filters = [
    'All',
    'Locations',
    'Equipment',
    'Packages',
    'Services',
    'High Risk',
    'SLA 24h+',
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(AdminListing listing) {
    final query = _search.text.toLowerCase();
    final queryMatch = query.isEmpty ||
        listing.title.toLowerCase().contains(query) ||
        listing.owner.toLowerCase().contains(query);
    if (!queryMatch) return false;
    return switch (_filter) {
      'All' => true,
      'Locations' => listing.category == 'Location',
      'Equipment' => listing.category == 'Equipment',
      'Packages' => listing.category == 'Packages',
      'Services' => listing.category == 'Services',
      'High Risk' => listing.status == 'Rejected',
      'SLA 24h+' => listing.status == 'Pending',
      _ => true,
    };
  }

  String _checklist(AdminListing listing) {
    return switch (listing.status) {
      'Rejected' => '2/6 checks passed',
      'Pending' => '4/6 checks passed',
      _ => '6/6 checks passed',
    };
  }

  @override
  Widget build(BuildContext context) {
    final rows = AdminMockData.listings.where(_matches).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoreTextField(
          controller: _search,
          label: 'Search listing or owner',
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
            title: 'No matching listings',
            message: 'Try a different filter or search term.',
          )
        else
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ListingQueueCard(
                listing: row,
                checklist: _checklist(row),
              ),
            ),
          ),
      ],
    );
  }
}

class _ListingQueueCard extends StatelessWidget {
  final AdminListing listing;
  final String checklist;

  const _ListingQueueCard({required this.listing, required this.checklist});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tone = listing.status == 'Rejected'
        ? AdminDecisionTone.danger
        : listing.status == 'Live'
            ? AdminDecisionTone.success
            : AdminDecisionTone.warning;
    return AdminSurface(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.goldGlow.withValues(alpha: 0.5),
                  colors.softSurface.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Icon(Icons.storefront_outlined,
                color: colors.goldDark, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${listing.owner} - ${listing.city} - ${listing.category}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.micro.copyWith(
                    color: colors.textSecondary,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    AdminStatusBadge(
                        label: listing.price, tone: AdminDecisionTone.info),
                    AdminStatusBadge(
                      label: 'Deposit ${listing.deposit}',
                      tone: AdminDecisionTone.neutral,
                    ),
                    AdminStatusBadge(label: listing.status, tone: tone),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  checklist,
                  style: AppTextStyles.micro.copyWith(
                    color: colors.textSecondary,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AdminRiskBadge(
                label: tone == AdminDecisionTone.danger
                    ? 'High Risk'
                    : 'Moderate Risk',
                risk: tone == AdminDecisionTone.danger
                    ? AdminRiskTone.high
                    : AdminRiskTone.medium,
              ),
              const SizedBox(height: 8),
              _ReviewOutlineButton(
                label: 'Open',
                onTap: () => _previewListing(context, listing),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    color: colors.iconMuted, size: 20),
                onSelected: (value) {
                  switch (value) {
                    case 'approve':
                      showCoreSnack(context, 'Listing approved and made live');
                      return;
                    case 'reject':
                      _noteDialog(context, 'Reject with note');
                      return;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'approve', child: Text('Approve')),
                  PopupMenuItem(value: 'reject', child: Text('Reject')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
