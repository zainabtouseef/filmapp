part of '../super_admin_screens.dart';

class ListingsModerationScreen extends StatelessWidget {
  const ListingsModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminListingsControlView();
  }
}

class AdminListingsControlView extends StatefulWidget {
  final bool reviewOnly;

  const AdminListingsControlView({super.key, this.reviewOnly = false});

  @override
  State<AdminListingsControlView> createState() =>
      _AdminListingsControlViewState();
}

class _AdminListingsControlViewState extends State<AdminListingsControlView> {
  Future<List<AdminListingRecordDto>>? _future;
  final _search = TextEditingController();
  String _filter = 'All';
  String? _busyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AdminScope.of(context).listings();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() => _future = AdminScope.of(context).listings(force: true));
  }

  List<AdminListingRecordDto> _visible(
    List<AdminListingRecordDto> listings,
  ) {
    final query = _search.text.trim().toLowerCase();
    return listings.where((listing) {
      if (widget.reviewOnly && listing.moderationStatus != 'pending') {
        return false;
      }
      final haystack = [
        listing.publicId,
        listing.title,
        listing.owner.displayName,
        listing.listingType,
        listing.city ?? '',
      ].join(' ').toLowerCase();
      if (query.isNotEmpty && !haystack.contains(query)) return false;
      return switch (_filter) {
        'Pending' => listing.moderationStatus == 'pending',
        'Approved' => listing.moderationStatus == 'approved',
        'Rejected' => listing.moderationStatus == 'rejected',
        'Changes' => listing.moderationStatus == 'changes_requested',
        'Locations' => listing.listingType.toLowerCase().contains('location'),
        'Equipment' => listing.listingType.toLowerCase().contains('equipment'),
        'Services' => listing.listingType.toLowerCase().contains('service'),
        'Private' => listing.visibility == 'private',
        _ => true,
      };
    }).toList();
  }

  Future<void> _update(
    AdminListingRecordDto listing, {
    required String moderationStatus,
    required String visibility,
    String? reason,
  }) async {
    if (_busyId != null) return;
    setState(() => _busyId = listing.publicId);
    try {
      await AdminScope.of(context).updateListing(
        listing.publicId,
        moderationStatus: moderationStatus,
        visibility: visibility,
        reason: reason,
      );
      if (!mounted) return;
      showCoreSnack(
        context,
        moderationStatus == 'approved'
            ? 'Listing approved and made public.'
            : 'Listing updated to $moderationStatus.',
      );
      _refresh();
    } on ApiException catch (error) {
      if (mounted) showCoreSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _reject(AdminListingRecordDto listing) async {
    final note = await _adminNotePrompt(
      context,
      title: 'Reject ${listing.title}',
      hint: 'Give the owner a clear moderation reason.',
    );
    if (!mounted || note == null) return;
    await _update(
      listing,
      moderationStatus: 'rejected',
      visibility: 'private',
      reason: note,
    );
  }

  Future<void> _requestChanges(AdminListingRecordDto listing) async {
    final note = await _adminNotePrompt(
      context,
      title: 'Request listing changes',
      hint: 'List the required media, pricing, or policy corrections.',
    );
    if (!mounted || note == null) return;
    await _update(
      listing,
      moderationStatus: 'changes_requested',
      visibility: 'private',
      reason: note,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSurface(
          child: Column(
            children: [
              CoreTextField(
                controller: _search,
                label: 'Search listing, owner, city or ID',
                icon: Icons.search_rounded,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              AdminFilterBar(
                filters: widget.reviewOnly
                    ? const ['All', 'Locations', 'Equipment', 'Services']
                    : const [
                        'All',
                        'Pending',
                        'Approved',
                        'Rejected',
                        'Changes',
                        'Locations',
                        'Equipment',
                        'Services',
                        'Private',
                      ],
                selected: _filter,
                onSelected: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: AdminActionButton(
                  icon: Icons.refresh_rounded,
                  label: 'Refresh',
                  secondary: true,
                  onTap: _refresh,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<AdminListingRecordDto>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const AdminSurface(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              final error = snapshot.error;
              return AdminSurface(
                child: Column(
                  children: [
                    AdminEmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Could not load marketplace listings',
                      message: error is ApiException
                          ? error.message
                          : 'Check the backend connection and try again.',
                    ),
                    const SizedBox(height: 12),
                    AdminActionButton(
                      icon: Icons.refresh_rounded,
                      label: 'Retry',
                      secondary: true,
                      onTap: _refresh,
                    ),
                  ],
                ),
              );
            }
            final rows = _visible(snapshot.data ?? const []);
            if (rows.isEmpty) {
              return const AdminEmptyState(
                icon: Icons.storefront_outlined,
                title: 'No matching listings',
                message: 'This review view is currently clear.',
              );
            }
            return Column(
              children: [
                for (final listing in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LiveListingCard(
                      listing: listing,
                      busy: _busyId == listing.publicId,
                      onApprove: () => _update(
                        listing,
                        moderationStatus: 'approved',
                        visibility: 'public',
                      ),
                      onReject: () => _reject(listing),
                      onChanges: () => _requestChanges(listing),
                      onPreview: () => _listingDetail(context, listing),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LiveListingCard extends StatelessWidget {
  final AdminListingRecordDto listing;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onChanges;
  final VoidCallback onPreview;

  const _LiveListingCard({
    required this.listing,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    required this.onChanges,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final approved = listing.moderationStatus == 'approved';
    final rejected = listing.moderationStatus == 'rejected';
    final amount = listing.priceFromMinor == null
        ? 'Price on request'
        : '${listing.currency} '
            '${(listing.priceFromMinor! / 100).toStringAsFixed(0)}';
    return AdminSurface(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: rejected
                    ? colors.danger
                    : approved
                        ? colors.success
                        : colors.goldMid,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final actions = Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _tinyAction(
                          context,
                          'Approve',
                          busy || approved ? null : onApprove,
                        ),
                        _tinyAction(
                          context,
                          'Changes',
                          busy ? null : onChanges,
                        ),
                        _tinyAction(
                          context,
                          'Reject',
                          busy || rejected ? null : onReject,
                        ),
                        AdminIconButton(
                          icon: Icons.open_in_new_rounded,
                          tooltip: 'Inspect listing',
                          onTap: onPreview,
                        ),
                      ],
                    );
                    final details = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardTitle.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${listing.owner.displayName} · '
                          '${listing.city ?? 'Remote'} · ${listing.listingType}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            AdminStatusBadge(
                              label: listing.moderationStatus,
                              tone: approved
                                  ? AdminDecisionTone.success
                                  : rejected
                                      ? AdminDecisionTone.danger
                                      : AdminDecisionTone.warning,
                            ),
                            AdminStatusBadge(
                              label: listing.visibility,
                              tone: AdminDecisionTone.neutral,
                            ),
                            AdminStatusBadge(
                              label: amount,
                              tone: AdminDecisionTone.info,
                            ),
                            AdminStatusBadge(
                              label: '${listing.mediaCount} media',
                              tone: AdminDecisionTone.neutral,
                            ),
                          ],
                        ),
                      ],
                    );
                    if (constraints.maxWidth < 720) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          details,
                          const SizedBox(height: 10),
                          actions,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: details),
                        const SizedBox(width: 12),
                        actions,
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _listingDetail(BuildContext context, AdminListingRecordDto listing) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AdminDetailDrawer(
      title: listing.title,
      children: [
        _kv(context, 'Listing ID', listing.publicId),
        _kv(context, 'Owner', listing.owner.displayName),
        _kv(context, 'Type', listing.listingType),
        _kv(context, 'City', listing.city ?? 'Remote'),
        _kv(context, 'Verification', listing.verificationStatus),
        _kv(context, 'Moderation', listing.moderationStatus),
        _kv(context, 'Visibility', listing.visibility),
        _kv(context, 'Media', '${listing.mediaCount} files'),
        const SizedBox(height: 12),
        _text(
          context,
          listing.summary.isEmpty
              ? 'No listing summary was supplied.'
              : listing.summary,
        ),
      ],
    ),
  );
}
