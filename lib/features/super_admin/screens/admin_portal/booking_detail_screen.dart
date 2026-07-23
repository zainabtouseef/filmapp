part of '../super_admin_screens.dart';

class BookingDetailScreen extends StatefulWidget {
  final String? bookingId;

  const BookingDetailScreen({super.key, this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Future<AdminBookingRecordDto>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<AdminBookingRecordDto> _load({bool force = false}) async {
    final admin = AdminScope.of(context);
    final id = widget.bookingId;
    if (id != null && id.isNotEmpty && id != ':id') {
      return admin.booking(id, force: force);
    }
    final rows = await admin.bookings(force: force);
    if (rows.isEmpty) {
      throw const ApiException(
        code: 'admin.booking_not_found',
        message: 'No booking record is available.',
      );
    }
    return rows.first;
  }

  void _refresh() {
    setState(() => _future = _load(force: true));
  }

  Future<void> _flag(AdminBookingRecordDto booking) async {
    final reason = await _adminNotePrompt(
      context,
      title: 'Move booking to admin review',
      hint: 'Describe the operational, payment, or safety concern.',
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
    return FutureBuilder<AdminBookingRecordDto>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AdminSurface(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          final error = snapshot.error;
          return AdminSurface(
            child: Column(
              children: [
                AdminEmptyState(
                  icon: Icons.work_off_outlined,
                  title: 'Booking detail unavailable',
                  message: error is ApiException
                      ? error.message
                      : 'The booking could not be loaded.',
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
        return _BookingDetailContent(
          booking: snapshot.data!,
          onFlag: () => _flag(snapshot.data!),
        );
      },
    );
  }
}

class _BookingDetailContent extends StatelessWidget {
  final AdminBookingRecordDto booking;
  final VoidCallback onFlag;

  const _BookingDetailContent({
    required this.booking,
    required this.onFlag,
  });

  @override
  Widget build(BuildContext context) {
    final flagged = booking.status == 'admin_review';
    final amount = booking.agreedAmountMinor == null
        ? 'Amount pending'
        : '${booking.currency} '
            '${(booking.agreedAmountMinor! / 100).toStringAsFixed(0)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSurface(
          padding: EdgeInsets.zero,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: flagged
                        ? context.appColors.danger
                        : context.appColors.goldMid,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(8),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _headline(
                                context,
                                booking.projectTitle,
                              ),
                            ),
                            AdminStatusBadge(
                              label: booking.status,
                              tone: flagged
                                  ? AdminDecisionTone.danger
                                  : AdminDecisionTone.warning,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _text(
                          context,
                          '${booking.publicId} · ${booking.listingTitle}',
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            AdminStatusBadge(
                              label: amount,
                              tone: AdminDecisionTone.info,
                            ),
                            AdminStatusBadge(
                              label: booking.category,
                              tone: AdminDecisionTone.neutral,
                            ),
                            if (booking.city != null)
                              AdminStatusBadge(
                                label: booking.city!,
                                tone: AdminDecisionTone.neutral,
                              ),
                            AdminStatusBadge(
                              label: '${booking.offersCount} offers',
                              tone: AdminDecisionTone.neutral,
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
        ),
        const SizedBox(height: 14),
        _TwoPane(
          left: AdminSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AdminSectionHeader(
                  title: 'People & schedule',
                  icon: Icons.groups_2_outlined,
                ),
                const SizedBox(height: 12),
                _kv(context, 'Requester', booking.requester.displayName),
                _kv(context, 'Provider', booking.provider.displayName),
                _kv(context, 'Listing', booking.listingTitle),
                _kv(context, 'Start', _adminDateTime(booking.startAt)),
                _kv(context, 'End', _adminDateTime(booking.endAt)),
              ],
            ),
          ),
          right: AdminSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AdminSectionHeader(
                  title: 'Commercial controls',
                  icon: Icons.account_balance_wallet_outlined,
                ),
                const SizedBox(height: 12),
                _kv(context, 'Negotiation',
                    booking.negotiationId ?? 'Not opened'),
                _kv(context, 'Contract', booking.contractStatus),
                _kv(context, 'Contract ID',
                    booking.contractId ?? 'Not generated'),
                _kv(context, 'Payment', booking.paymentStatus),
                _kv(context, 'Conversation',
                    booking.conversationId ?? 'Not opened'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        AdminSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminSectionHeader(
                title: 'Status timeline',
                icon: Icons.history_rounded,
              ),
              const SizedBox(height: 10),
              if (booking.statusEvents.isEmpty)
                const AdminEmptyState(
                  icon: Icons.history_toggle_off_rounded,
                  title: 'No status events yet',
                  message: 'Booking activity will appear here.',
                )
              else
                AdminTimeline(
                  items: [
                    for (final event in booking.statusEvents.reversed)
                      '${event.fromStatus ?? 'new'} → ${event.toStatus} · '
                          '${event.actor}'
                          '${event.reason == null ? '' : ' · ${event.reason}'}',
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AdminSurface(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AdminActionButton(
                icon: Icons.description_outlined,
                label: 'Open contract',
                secondary: true,
                onTap: booking.contractId == null
                    ? null
                    : () => Navigator.pushNamed(
                          context,
                          CoreRoutes.contract,
                          arguments: booking.contractId,
                        ),
              ),
              AdminActionButton(
                icon: Icons.payments_outlined,
                label: 'Payment controls',
                secondary: true,
                onTap: () => Navigator.pushNamed(
                  context,
                  SuperAdminRoutes.payments,
                ),
              ),
              AdminActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'View chat',
                secondary: true,
                onTap: booking.conversationId == null
                    ? null
                    : () => Navigator.pushNamed(
                          context,
                          CoreRoutes.chat,
                          arguments: booking.conversationId,
                        ),
              ),
              AdminActionButton(
                icon: flagged ? Icons.flag_rounded : Icons.flag_outlined,
                label: flagged ? 'In admin review' : 'Flag booking',
                secondary: true,
                onTap: flagged ? null : onFlag,
              ),
              AdminActionButton(
                icon: Icons.gpp_maybe_outlined,
                label: 'Dispute center',
                onTap: () =>
                    Navigator.pushNamed(context, SuperAdminRoutes.disputes),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _adminDateTime(DateTime? value) {
  if (value == null) return 'Not scheduled';
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}
