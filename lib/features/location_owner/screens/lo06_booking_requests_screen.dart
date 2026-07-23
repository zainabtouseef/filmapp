import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../data/location_owner_demo_data.dart';
import '../widgets/location_owner_components.dart';
import '../widgets/location_owner_live.dart';

class LO06BookingRequestsScreen extends StatefulWidget {
  final String? initialRequestId;

  const LO06BookingRequestsScreen({super.key, this.initialRequestId});

  @override
  State<LO06BookingRequestsScreen> createState() =>
      _LO06BookingRequestsScreenState();
}

class _LO06BookingRequestsScreenState extends State<LO06BookingRequestsScreen> {
  BookingsController? _bookings;
  Future<List<Booking>>? _future;
  String _query = '';
  String _filter = 'All';
  String _sort = 'Newest';
  String? _busyBookingId;

  @override
  void initState() {
    super.initState();
    _query = widget.initialRequestId ?? '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bookings = BookingsScope.maybeOf(context);
    if (bookings == null || identical(bookings, _bookings)) return;
    _bookings = bookings;
    _future = _load();
  }

  Future<List<Booking>> _load({bool force = false}) async {
    final rows = await _bookings!.bookings(role: 'provider', force: force);
    return rows.where((booking) => booking.category == 'location').toList();
  }

  void _reload() {
    if (_bookings == null) return;
    setState(() => _future = _load(force: true));
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) return _buildPreview();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RequestCommandBar(
          query: _query,
          selectedFilter: _filter,
          selectedSort: _sort,
          onQueryChanged: (value) => setState(() => _query = value),
          onFilterChanged: (value) => setState(() => _filter = value),
          onSortChanged: (value) => setState(() => _sort = value),
          onRefresh: _reload,
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Booking>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError) {
              return CoreEmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Requests unavailable',
                message: locationApiMessage(snapshot.error!),
                actionLabel: 'Try again',
                onAction: _reload,
              );
            }
            final rows = _filtered(snapshot.data ?? const []);
            if (rows.isEmpty) {
              return CoreEmptyState(
                icon: Icons.inbox_outlined,
                title: 'No matching requests',
                message: snapshot.data?.isEmpty == true
                    ? 'Location booking requests will appear here after a producer sends an offer.'
                    : 'Change the search or status filter.',
                actionLabel:
                    snapshot.data?.isEmpty == true ? null : 'Clear filters',
                onAction: snapshot.data?.isEmpty == true
                    ? null
                    : () => setState(() {
                          _query = '';
                          _filter = 'All';
                        }),
              );
            }
            return LocationResponsiveGrid(
              minWidth: 320,
              children: [
                for (final booking in rows)
                  _LiveRequestCard(
                    booking: booking,
                    currentUserId: AuthScope.maybeOf(context)?.user?.publicId,
                    busy: _busyBookingId == booking.publicId,
                    onDetails: () => _showDetails(booking),
                    onAccept: () => _accept(booking),
                    onCounter: () => _counter(booking),
                    onReject: () => _reject(booking),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  List<Booking> _filtered(List<Booking> rows) {
    final query = _query.trim().toLowerCase();
    final filtered = rows.where((booking) {
      final matchesFilter = switch (_filter) {
        'New' => {'sent', 'viewed'}.contains(booking.status),
        'Negotiation' => booking.status == 'under_negotiation',
        'Accepted' => {'accepted', 'secured'}.contains(booking.status),
        'Closed' =>
          {'rejected', 'cancelled', 'completed'}.contains(booking.status),
        _ => true,
      };
      final haystack = '${booking.publicId} ${booking.projectId} '
              '${booking.requester.displayName} ${booking.status}'
          .toLowerCase();
      return matchesFilter && haystack.contains(query);
    }).toList();
    if (_sort == 'Fee') {
      filtered.sort((a, b) {
        final left = a.activeOffer?.feeMinor ?? a.agreedAmountMinor ?? 0;
        final right = b.activeOffer?.feeMinor ?? b.agreedAmountMinor ?? 0;
        return right.compareTo(left);
      });
    } else {
      filtered.sort((a, b) => b.startAt.compareTo(a.startAt));
    }
    return filtered;
  }

  Future<void> _accept(Booking booking) async {
    final offer = booking.activeOffer;
    final currentUserId = AuthScope.maybeOf(context)?.user?.publicId;
    if (offer == null || offer.recipient.publicId != currentUserId) {
      locationSnack(context, 'There is no active offer for you to accept');
      return;
    }
    setState(() => _busyBookingId = booking.publicId);
    try {
      await _bookings!.acceptOffer(offer.publicId);
      if (!mounted) return;
      locationSnack(context, 'Offer accepted and dates secured');
      _reload();
    } catch (error) {
      if (!mounted) return;
      locationSnack(context, locationApiMessage(error));
    } finally {
      if (mounted) setState(() => _busyBookingId = null);
    }
  }

  void _counter(Booking booking) {
    final fee = TextEditingController(
      text:
          ((booking.activeOffer?.feeMinor ?? booking.agreedAmountMinor ?? 0) ~/
                  100)
              .toString(),
    );
    final conditions = TextEditingController(
      text: booking.activeOffer?.conditions ?? '',
    );
    final message = TextEditingController();
    showLocationSheet(
      context,
      title: 'Counteroffer',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoreTextField(
            controller: fee,
            label: 'Location fee (PKR)',
            icon: Icons.payments_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          CoreTextField(
            controller: conditions,
            label: 'Conditions and access terms',
            icon: Icons.rule_folder_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 10),
          CoreTextField(
            controller: message,
            label: 'Message to producer',
            icon: Icons.chat_bubble_outline_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.send_outlined,
            label: 'Send counteroffer',
            onTap: () async {
              final amount = int.tryParse(fee.text.trim()) ?? 0;
              if (amount <= 0) {
                locationSnack(context, 'Enter a valid location fee');
                return;
              }
              Navigator.pop(context);
              await _sendCounter(
                booking,
                amountMinor: amount * 100,
                conditions: conditions.text.trim(),
                message: message.text.trim(),
              );
            },
          ),
        ],
      ),
    ).whenComplete(() {
      fee.dispose();
      conditions.dispose();
      message.dispose();
    });
  }

  Future<void> _sendCounter(
    Booking booking, {
    required int amountMinor,
    required String conditions,
    required String message,
  }) async {
    setState(() => _busyBookingId = booking.publicId);
    try {
      await _bookings!.createCounterOffer(
        bookingId: booking.publicId,
        feeMinor: amountMinor,
        conditions: conditions.isEmpty ? null : conditions,
        message: message.isEmpty ? null : message,
      );
      if (!mounted) return;
      locationSnack(context, 'Counteroffer sent');
      _reload();
    } catch (error) {
      if (!mounted) return;
      locationSnack(context, locationApiMessage(error));
    } finally {
      if (mounted) setState(() => _busyBookingId = null);
    }
  }

  void _reject(Booking booking) {
    final reason = TextEditingController();
    showLocationSheet(
      context,
      title: 'Decline request',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoreTextField(
            controller: reason,
            label: 'Reason for the producer',
            icon: Icons.edit_note_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.block_rounded,
            label: 'Decline request',
            onTap: () async {
              if (reason.text.trim().length < 3) {
                locationSnack(context, 'Add a short decline reason');
                return;
              }
              Navigator.pop(context);
              await _sendReject(booking, reason.text.trim());
            },
          ),
        ],
      ),
    ).whenComplete(reason.dispose);
  }

  Future<void> _sendReject(Booking booking, String reason) async {
    setState(() => _busyBookingId = booking.publicId);
    try {
      await _bookings!.rejectBooking(booking.publicId, reason: reason);
      if (!mounted) return;
      locationSnack(context, 'Request declined');
      _reload();
    } catch (error) {
      if (!mounted) return;
      locationSnack(context, locationApiMessage(error));
    } finally {
      if (mounted) setState(() => _busyBookingId = null);
    }
  }

  void _showDetails(Booking booking) {
    final offer = booking.activeOffer;
    showLocationSheet(
      context,
      title: 'Booking ${booking.publicId}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocationInfoRow(
            icon: Icons.business_outlined,
            label: 'Producer',
            value: booking.requester.displayName,
          ),
          LocationInfoRow(
            icon: Icons.movie_creation_outlined,
            label: 'Project',
            value: booking.projectId,
          ),
          LocationInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Requested dates',
            value: locationBookingDates(booking),
          ),
          LocationInfoRow(
            icon: Icons.payments_outlined,
            label: 'Current fee',
            value: locationBookingAmount(booking),
          ),
          LocationInfoRow(
            icon: Icons.rule_folder_outlined,
            label: 'Conditions',
            value: offer?.conditions?.isNotEmpty == true
                ? offer!.conditions!
                : 'No special conditions',
          ),
          const SizedBox(height: 8),
          CoreSecondaryButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: booking.conversationId == null
                ? 'Chat unavailable'
                : 'Open chat',
            onTap: booking.conversationId == null
                ? null
                : () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      CoreRoutes.chat,
                      arguments: booking.conversationId,
                    );
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final store = LocationOwnerDemoStore.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RequestCommandBar(
          query: '',
          selectedFilter: 'All',
          selectedSort: 'Newest',
          onQueryChanged: _noopString,
          onFilterChanged: _noopString,
          onSortChanged: _noopString,
          onRefresh: _noop,
        ),
        const SizedBox(height: 12),
        LocationResponsiveGrid(
          minWidth: 320,
          children: [
            for (final request in LocationOwnerDemoData.requests)
              GlassSectionCard(
                radius: 18,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.project,
                      style: AppTextStyles.cardLabel.copyWith(
                        color: context.appColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${request.producer} · ${request.dates}',
                      style: AppTextStyles.smallMeta.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LocationBookingStatusChip(
                      status: store.requestStatus(request),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

void _noopString(String _) {}
void _noop() {}

class _RequestCommandBar extends StatelessWidget {
  final String query;
  final String selectedFilter;
  final String selectedSort;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onRefresh;

  const _RequestCommandBar({
    required this.query,
    required this.selectedFilter,
    required this.selectedSort,
    required this.onQueryChanged,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return LocationSectionCard(
      title: 'Request inbox',
      icon: Icons.move_to_inbox_outlined,
      selected: true,
      actionText: 'Refresh',
      onActionTap: onRefresh,
      child: Column(
        children: [
          TextFormField(
            key: ValueKey(query),
            initialValue: query,
            onChanged: onQueryChanged,
            style: AppTextStyles.body.copyWith(color: colors.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search booking, project or producer...',
              prefixIcon:
                  Icon(Icons.search_rounded, color: colors.goldDark, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in [
                  'All',
                  'New',
                  'Negotiation',
                  'Accepted',
                  'Closed',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CoreChip(
                      label: filter,
                      selected: selectedFilter == filter,
                      onTap: () => onFilterChanged(filter),
                    ),
                  ),
                const SizedBox(width: 8),
                for (final sort in ['Newest', 'Fee'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CoreChip(
                      label: sort,
                      selected: selectedSort == sort,
                      icon: Icons.sort_rounded,
                      onTap: () => onSortChanged(sort),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveRequestCard extends StatelessWidget {
  final Booking booking;
  final String? currentUserId;
  final bool busy;
  final VoidCallback onDetails;
  final VoidCallback onAccept;
  final VoidCallback onCounter;
  final VoidCallback onReject;

  const _LiveRequestCard({
    required this.booking,
    required this.currentUserId,
    required this.busy,
    required this.onDetails,
    required this.onAccept,
    required this.onCounter,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final mutable =
        {'sent', 'viewed', 'under_negotiation'}.contains(booking.status);
    final canAccept = mutable &&
        booking.activeOffer?.status == 'active' &&
        booking.activeOffer?.recipient.publicId == currentUserId;
    return GlassSectionCard(
      radius: 18,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              LocationBookingStatusChip(
                status: locationBookingStatusFromBooking(booking),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${booking.requester.displayName} · '
            '${locationBookingDates(booking)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            locationBookingAmount(booking),
            style: AppTextStyles.statusText.copyWith(
              color: colors.goldDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.info_outline_rounded,
                  label: 'Review',
                  compact: true,
                  onTap: busy ? null : onDetails,
                ),
              ),
              if (mutable) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: CoreSecondaryButton(
                    icon: Icons.edit_note_outlined,
                    label: 'Counter',
                    compact: true,
                    onTap: busy ? null : onCounter,
                  ),
                ),
              ],
            ],
          ),
          if (mutable) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CoreSecondaryButton(
                    icon: Icons.block_rounded,
                    label: 'Decline',
                    compact: true,
                    onTap: busy ? null : onReject,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CorePrimaryButton(
                    icon: Icons.check_circle_outline,
                    label: busy ? 'Working...' : 'Accept',
                    compact: true,
                    onTap: busy || !canAccept ? null : onAccept,
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
