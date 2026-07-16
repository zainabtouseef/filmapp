part of '../super_admin_screens.dart';

class ListingsModerationScreen extends StatefulWidget {
  const ListingsModerationScreen({super.key});

  @override
  State<ListingsModerationScreen> createState() =>
      _ListingsModerationScreenState();
}

class _ListingsModerationScreenState extends State<ListingsModerationScreen> {
  String _tab = 'Locations';
  final Map<String, String> _statuses = {};

  bool _matches(AdminListing listing) {
    final status = _statuses[listing.title] ?? listing.status;
    return switch (_tab) {
      'Locations' => listing.category == 'Location',
      'Equipment' => listing.category == 'Equipment',
      'Packages' => listing.category == 'Packages',
      'Services' => listing.category == 'Services',
      'Rejected' => status == 'Rejected',
      'Approved' => status == 'Live' || status == 'Approved',
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final rows = AdminMockData.listings.where(_matches).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFilterBar(
          filters: const [
            'Locations',
            'Equipment',
            'Packages',
            'Services',
            'Rejected',
            'Approved'
          ],
          selected: _tab,
          onSelected: (value) => setState(() => _tab = value),
        ),
        const SizedBox(height: 14),
        if (rows.isEmpty)
          const AdminEmptyState(
            icon: Icons.storefront_outlined,
            title: 'No listings in this category',
            message: 'Try a different filter.',
          )
        else
          ...rows.map(
            (listing) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _listingCard(context, listing),
            ),
          ),
      ],
    );
  }

  Widget _listingCard(BuildContext context, AdminListing listing) {
    final colors = context.appColors;
    final status = _statuses[listing.title] ?? listing.status;
    final checks = listing.category == 'Equipment'
        ? const [
            'Inventory photos clear',
            'Serial number optional',
            'Deposit defined',
            'Handover terms clear',
            'Operator requirement stated',
            'Overtime terms added',
          ]
        : const [
            'Photos look genuine',
            'Exact address hidden',
            'Approximate area visible',
            'Pricing reasonable',
            'Deposit terms clear',
            'Rules and availability added',
          ];
    return AdminSurface(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
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
                color: colors.goldDark, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        listing.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle
                            .copyWith(color: colors.textPrimary),
                      ),
                    ),
                    AdminStatusBadge(
                      label: status == 'Live' ? 'Live' : status,
                      tone: status == 'Live'
                          ? AdminDecisionTone.success
                          : AdminDecisionTone.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${listing.owner} - ${listing.city} - ${listing.category}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.micro
                      .copyWith(color: colors.textSecondary, letterSpacing: 0),
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
                        tone: AdminDecisionTone.neutral),
                    AdminStatusBadge(
                        label: listing.visibility,
                        tone: AdminDecisionTone.neutral),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${checks.length}/${checks.length} checks passed',
                  style: AppTextStyles.micro
                      .copyWith(color: colors.success, letterSpacing: 0),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _tinyAction(context, 'Approve', () {
                        setState(() => _statuses[listing.title] = 'Live');
                        showCoreSnack(
                            context, 'Listing approved and made live');
                      }),
                    ),
                    Expanded(
                      child: _tinyAction(context, 'Reject',
                          () => _noteDialog(context, 'Reject with note')),
                    ),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.more_vert_rounded,
                          color: colors.iconMuted, size: 19),
                      onSelected: (value) {
                        switch (value) {
                          case 'changes':
                            showCoreSnack(context, 'Static notification sent');
                            return;
                          case 'preview':
                            _previewListing(context, listing);
                            return;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                            value: 'changes', child: Text('Request Changes')),
                        PopupMenuItem(value: 'preview', child: Text('Preview')),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
