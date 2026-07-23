part of '../super_admin_screens.dart';

class BookingMonitorScreen extends StatefulWidget {
  const BookingMonitorScreen({super.key});

  @override
  State<BookingMonitorScreen> createState() => _BookingMonitorScreenState();
}

class _BookingMonitorScreenState extends State<BookingMonitorScreen> {
  Future<List<AdminBookingRecordDto>>? _future;
  String _filter = 'All';
  final _search = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AdminScope.of(context).bookings();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() => _future = AdminScope.of(context).bookings(force: true));
  }

  List<AdminBookingRecordDto> _visible(
    List<AdminBookingRecordDto> bookings,
  ) {
    final query = _search.text.trim().toLowerCase();
    return bookings.where((booking) {
      final matchesStatus = _filter == 'All' ||
          (_filter == 'Flagged'
              ? booking.status == 'admin_review'
              : booking.status == _filter);
      final haystack = [
        booking.publicId,
        booking.projectTitle,
        booking.listingTitle,
        booking.requester.displayName,
        booking.provider.displayName,
        booking.city ?? '',
        booking.category,
      ].join(' ').toLowerCase();
      return matchesStatus && (query.isEmpty || haystack.contains(query));
    }).toList();
  }

  Future<void> _flag(AdminBookingRecordDto booking) async {
    final reason = await _adminNotePrompt(
      context,
      title: 'Flag ${booking.publicId}',
      hint: 'Operational risk, payment mismatch, safety concern...',
    );
    if (!mounted || reason == null) return;
    try {
      await AdminScope.of(context).updateBooking(
        booking.publicId,
        status: 'admin_review',
        reason: reason,
      );
      if (!mounted) return;
      showCoreSnack(context, 'Booking moved to admin review.');
      _refresh();
    } on ApiException catch (error) {
      if (mounted) showCoreSnack(context, error.message);
    }
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
                label: 'Search booking, project, listing or member',
                icon: Icons.search_rounded,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              AdminFilterBar(
                filters: const [
                  'All',
                  'under_negotiation',
                  'accepted',
                  'secured',
                  'in_progress',
                  'completed',
                  'Flagged',
                  'cancelled',
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
        FutureBuilder<List<AdminBookingRecordDto>>(
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
                      title: 'Could not load booking operations',
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
                icon: Icons.work_outline_rounded,
                title: 'No matching bookings',
                message: 'Change the status filter or search term.',
              );
            }
            return Column(
              children: [
                for (final booking in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AdminBookingRow(
                      booking: booking,
                      onOpen: () => Navigator.pushNamed(
                        context,
                        SuperAdminRoutes.bookingPath(booking.publicId),
                      ),
                      onFlag: booking.status == 'admin_review'
                          ? null
                          : () => _flag(booking),
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

class _AdminBookingRow extends StatelessWidget {
  final AdminBookingRecordDto booking;
  final VoidCallback onOpen;
  final VoidCallback? onFlag;

  const _AdminBookingRow({
    required this.booking,
    required this.onOpen,
    required this.onFlag,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final flagged = booking.status == 'admin_review';
    final amount = booking.agreedAmountMinor == null
        ? 'Amount pending'
        : '${booking.currency} '
            '${(booking.agreedAmountMinor! / 100).toStringAsFixed(0)}';
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(8),
      child: AdminSurface(
        padding: EdgeInsets.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: flagged ? colors.danger : colors.goldMid,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: colors.goldGlow.withValues(alpha: 0.14),
                      ),
                      child: Icon(
                        _bookingCategoryIcon(booking.category),
                        color: colors.goldDark,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  booking.projectTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.cardTitle.copyWith(
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                amount,
                                style: AppTextStyles.caption.copyWith(
                                  color: colors.goldDark,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${booking.publicId} · '
                            '${booking.requester.displayName} → '
                            '${booking.provider.displayName}',
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
                                label: booking.status,
                                tone: flagged
                                    ? AdminDecisionTone.danger
                                    : AdminDecisionTone.warning,
                              ),
                              AdminStatusBadge(
                                label: booking.contractStatus,
                                tone: AdminDecisionTone.neutral,
                              ),
                              AdminStatusBadge(
                                label: booking.paymentStatus,
                                tone: AdminDecisionTone.info,
                              ),
                              if (booking.city != null)
                                AdminStatusBadge(
                                  label: booking.city!,
                                  tone: AdminDecisionTone.neutral,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        AdminIconButton(
                          icon: Icons.open_in_new_rounded,
                          tooltip: 'Open booking',
                          onTap: onOpen,
                        ),
                        const SizedBox(height: 6),
                        AdminIconButton(
                          icon: flagged
                              ? Icons.flag_rounded
                              : Icons.flag_outlined,
                          tooltip: flagged ? 'In admin review' : 'Flag booking',
                          onTap: onFlag,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _bookingCategoryIcon(String category) {
  return switch (category.toLowerCase()) {
    'actor' || 'talent' => Icons.theater_comedy_outlined,
    'model' => Icons.face_retouching_natural_outlined,
    'location' => Icons.apartment_rounded,
    'equipment' || 'media' => Icons.videocam_outlined,
    _ => Icons.work_outline_rounded,
  };
}

Future<String?> _adminNotePrompt(
  BuildContext context, {
  required String title,
  required String hint,
}) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        minLines: 3,
        maxLines: 6,
        autofocus: true,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = controller.text.trim();
            if (value.isNotEmpty) Navigator.pop(context, value);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}
