import 'package:flutter/material.dart';

import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../widgets/crew_services_components.dart';

/// CR-05 Requests & Negotiation
///
/// Same generic Booking API used by Location Owner (LO-06) and
/// Media/Equipment (ME-07) provider request inboxes, filtered to
/// `category == 'crew'`.
class CR05RequestsNegotiationScreen extends StatefulWidget {
  final String? initialRequestId;

  const CR05RequestsNegotiationScreen({super.key, this.initialRequestId});

  @override
  State<CR05RequestsNegotiationScreen> createState() =>
      _CR05RequestsNegotiationScreenState();
}

class _CR05RequestsNegotiationScreenState
    extends State<CR05RequestsNegotiationScreen> {
  String _query = '';
  String _filter = 'All';
  Future<List<Booking>>? _bookingsFuture;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _query = widget.initialRequestId ?? '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bookingsFuture != null) return;
    _reload();
  }

  void _reload() {
    final bookings = BookingsScope.maybeOf(context);
    if (bookings == null) return;
    _bookingsFuture = bookings.bookings(role: 'provider', force: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CrewSectionCard(
          title: 'Crew Request Inbox',
          icon: Icons.move_to_inbox_outlined,
          selected: true,
          child: Column(
            children: [
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search request, producer, project, status...',
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in const [
                      'All',
                      'New',
                      'Negotiation',
                      'Secured',
                      'Closed',
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
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_bookingsFuture == null)
          const InlineNotice(
            message: 'Preview mode. Sign in to view booking requests.',
            icon: Icons.visibility_outlined,
          )
        else
          FutureBuilder<List<Booking>>(
            future: _bookingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const InlineNotice(
                  message: 'Loading crew booking requests...',
                  icon: Icons.hourglass_top_rounded,
                );
              }
              if (snapshot.hasError) {
                return InlineNotice(
                  message: 'Could not load booking requests: ${snapshot.error}',
                  icon: Icons.cloud_off_outlined,
                );
              }
              final all = (snapshot.data ?? const [])
                  .where((booking) => booking.category == 'crew')
                  .toList();
              final rows = all.where(_matches).toList();
              if (rows.isEmpty) {
                return CoreEmptyState(
                  icon: Icons.inbox_outlined,
                  title:
                      all.isEmpty ? 'No crew requests yet' : 'No matching requests',
                  message: all.isEmpty
                      ? 'Published service profile and portfolio will receive Director booking requests here.'
                      : 'Change the search or status filter.',
                  actionLabel: all.isNotEmpty ? 'Clear filters' : null,
                  onAction: all.isNotEmpty
                      ? () => setState(() {
                            _query = '';
                            _filter = 'All';
                          })
                      : null,
                );
              }
              return CrewResponsiveGrid(
                minWidth: 320,
                children: [
                  for (final booking in rows)
                    _LiveRequestCard(
                      booking: booking,
                      busy: _busyId == booking.publicId,
                      onDetails: () => _showDetails(booking),
                      onAccept: () => _accept(booking),
                      onCounter: () => _showCounter(booking),
                      onReject: () => _showReject(booking),
                      onChat: () => _openChat(booking),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  bool _matches(Booking booking) {
    final query = _query.trim().toLowerCase();
    final searchMatch = query.isEmpty ||
        '${booking.publicId} ${booking.projectId} ${booking.requester.displayName} ${booking.status}'
            .toLowerCase()
            .contains(query);
    final filterMatch = switch (_filter) {
      'New' => {'sent', 'viewed'}.contains(booking.status),
      'Negotiation' => booking.status == 'under_negotiation',
      'Secured' =>
        {'accepted', 'secured', 'in_progress'}.contains(booking.status),
      'Closed' => {'rejected', 'cancelled', 'closed', 'completed'}
          .contains(booking.status),
      _ => true,
    };
    return searchMatch && filterMatch;
  }

  Future<void> _accept(Booking booking) async {
    final offer = booking.activeOffer;
    if (offer == null) {
      crewSnack(context, 'No active offer is available to accept');
      return;
    }
    final bookings = BookingsScope.maybeOf(context);
    if (bookings == null) return;
    setState(() => _busyId = booking.publicId);
    try {
      await bookings.acceptOffer(offer.publicId);
      if (!mounted) return;
      setState(_reload);
      crewSnack(context, 'Crew booking accepted');
    } catch (error) {
      if (mounted) crewSnack(context, 'Could not accept request: $error');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _showCounter(Booking booking) {
    final pageContext = context;
    final current =
        booking.activeOffer?.feeMinor ?? booking.agreedAmountMinor ?? 0;
    final amount = TextEditingController(
      text: current == 0 ? '' : '${current ~/ 100}',
    );
    final conditions = TextEditingController(
      text:
          'Rates include listed crew role only. Overtime, transport, and meal terms apply.',
    );
    showCrewSheet(
      context,
      title: 'Counter crew request',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoreTextField(
            controller: amount,
            label: 'Counter amount in PKR',
            icon: Icons.payments_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          CoreTextField(
            controller: conditions,
            label: 'Service and rate conditions',
            icon: Icons.rule_folder_outlined,
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.send_outlined,
            label: 'Send counteroffer',
            onTap: () async {
              final value = int.tryParse(amount.text.trim());
              if (value == null || value <= 0) {
                crewSnack(context, 'Enter a valid counter amount');
                return;
              }
              final bookings = BookingsScope.maybeOf(context);
              if (bookings == null) return;
              try {
                await bookings.createCounterOffer(
                  bookingId: booking.publicId,
                  feeMinor: value * 100,
                  conditions: conditions.text.trim(),
                  message: 'Crew provider counteroffer',
                );
                if (!mounted || !context.mounted) return;
                Navigator.pop(context);
                setState(_reload);
                crewSnack(pageContext, 'Counteroffer sent');
              } catch (error) {
                if (context.mounted) {
                  crewSnack(context, 'Could not send counteroffer: $error');
                }
              }
            },
          ),
        ],
      ),
    ).whenComplete(() {
      amount.dispose();
      conditions.dispose();
    });
  }

  void _showReject(Booking booking) {
    final pageContext = context;
    final reason = TextEditingController(text: 'Not available for these dates');
    showCrewSheet(
      context,
      title: 'Reject crew request',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoreTextField(
            controller: reason,
            label: 'Reason for producer',
            icon: Icons.notes_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.block_outlined,
            label: 'Reject request',
            onTap: () async {
              if (reason.text.trim().isEmpty) {
                crewSnack(context, 'Add a short rejection reason');
                return;
              }
              final bookings = BookingsScope.maybeOf(context);
              if (bookings == null) return;
              try {
                await bookings.rejectBooking(
                  booking.publicId,
                  reason: reason.text.trim(),
                );
                if (!mounted || !context.mounted) return;
                Navigator.pop(context);
                setState(_reload);
                crewSnack(pageContext, 'Request rejected');
              } catch (error) {
                if (context.mounted) {
                  crewSnack(context, 'Could not reject request: $error');
                }
              }
            },
          ),
        ],
      ),
    ).whenComplete(reason.dispose);
  }

  void _showDetails(Booking booking) {
    showCrewSheet(
      context,
      title: 'Booking ${booking.publicId}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CrewInfoRow(
            icon: Icons.movie_creation_outlined,
            label: 'Project',
            value: booking.projectId,
          ),
          CrewInfoRow(
            icon: Icons.business_outlined,
            label: 'Producer',
            value: booking.requester.displayName,
          ),
          CrewInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Dates',
            value: '${_date(booking.startAt)} - ${_date(booking.endAt)}',
          ),
          CrewInfoRow(
            icon: Icons.payments_outlined,
            label: 'Current offer',
            value: _money(booking),
          ),
          CrewInfoRow(
            icon: Icons.info_outline,
            label: 'Status',
            value: _title(booking.status),
          ),
          const SizedBox(height: 10),
          CoreSecondaryButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Open booking conversation',
            onTap: booking.conversationId == null
                ? null
                : () {
                    Navigator.pop(context);
                    _openChat(booking);
                  },
          ),
        ],
      ),
    );
  }

  void _openChat(Booking booking) {
    final conversationId = booking.conversationId;
    if (conversationId == null) {
      crewSnack(context, 'Conversation opens after the request is sent');
      return;
    }
    Navigator.pushNamed(
      context,
      CoreRoutes.chat,
      arguments: conversationId,
    );
  }
}

class _LiveRequestCard extends StatelessWidget {
  final Booking booking;
  final bool busy;
  final VoidCallback onDetails;
  final VoidCallback onAccept;
  final VoidCallback onCounter;
  final VoidCallback onReject;
  final VoidCallback onChat;

  const _LiveRequestCard({
    required this.booking,
    required this.busy,
    required this.onDetails,
    required this.onAccept,
    required this.onCounter,
    required this.onReject,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final actionable =
        {'sent', 'viewed', 'under_negotiation'}.contains(booking.status);
    final statusColor = switch (booking.status) {
      'accepted' || 'secured' => colors.success,
      'under_negotiation' => colors.infoBlue,
      'rejected' || 'cancelled' => colors.danger,
      _ => colors.goldMid,
    };
    return GlassSectionCard(
      radius: 8,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 118,
            decoration: BoxDecoration(
              color: colors.softSurface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colors.border),
            ),
            child: Icon(
              Icons.groups_2_outlined,
              color: colors.goldDark,
              size: 44,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Project ${booking.projectId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusChip(
                label: _title(booking.status),
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${booking.requester.displayName} · ${_date(booking.startAt)} - ${_date(booking.endAt)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          StatusChip(label: _money(booking), color: colors.goldMid),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.info_outline,
                  label: 'Details',
                  compact: true,
                  onTap: onDetails,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat',
                  compact: true,
                  onTap: onChat,
                ),
              ),
            ],
          ),
          if (actionable) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CoreSecondaryButton(
                    icon: Icons.block_outlined,
                    label: 'Reject',
                    compact: true,
                    onTap: busy ? null : onReject,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CoreSecondaryButton(
                    icon: Icons.edit_note_outlined,
                    label: 'Counter',
                    compact: true,
                    onTap: busy ? null : onCounter,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CorePrimaryButton(
                    icon: Icons.check_circle_outline,
                    label: 'Accept',
                    compact: true,
                    onTap: busy ? null : onAccept,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String _money(Booking booking) {
  final minor = booking.activeOffer?.feeMinor ?? booking.agreedAmountMinor;
  return minor == null
      ? 'Rate requested'
      : '${booking.currency} ${(minor ~/ 100).toString()}';
}

String _date(DateTime value) {
  return '${value.day}/${value.month}/${value.year}';
}

String _title(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
