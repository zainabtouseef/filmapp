import 'package:flutter/material.dart';

import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/tour/tour_target.dart';
import '../models/brand_sponsor_models.dart';
import '../widgets/brand_sponsor_components.dart';
import '../widgets/brand_sponsor_live.dart';

class BR11BrandBookingsScreen extends StatefulWidget {
  const BR11BrandBookingsScreen({super.key});

  @override
  State<BR11BrandBookingsScreen> createState() =>
      _BR11BrandBookingsScreenState();
}

class _BR11BrandBookingsScreenState extends State<BR11BrandBookingsScreen> {
  BookingsController? _controller;
  List<Booking> _bookings = const [];
  String _status = 'All';
  String _query = '';
  String? _error;
  bool _loading = false;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = BookingsScope.maybeOf(context);
    if (identical(controller, _controller)) return;
    _controller = controller;
    if (controller != null) _load();
  }

  Future<void> _load({bool force = false}) async {
    if (_controller == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bookings = await _controller!.bookings(force: force);
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _loaded = true;
      });
    } catch (error) {
      if (mounted) setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Booking> get _visibleBookings {
    final query = _query.trim().toLowerCase();
    return _bookings.where((booking) {
      final statusMatches = _status == 'All' ||
          booking.status.toLowerCase() == _status.toLowerCase();
      final queryMatches = query.isEmpty ||
          booking.projectTitle.toLowerCase().contains(query) ||
          booking.listingTitle.toLowerCase().contains(query) ||
          booking.provider.displayName.toLowerCase().contains(query);
      return statusMatches && queryMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const CoreEmptyState(
        icon: Icons.cloud_sync_outlined,
        title: 'Sign in to manage booking requests',
        message:
            'Requests, offers and confirmed bookings load from the backend.',
      );
    }
    if (_loading && !_loaded) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    final pending = _bookings
        .where((row) => {'draft', 'sent', 'viewed', 'under_negotiation'}
            .contains(row.status))
        .length;
    final confirmed = _bookings
        .where((row) => {'accepted', 'secured'}.contains(row.status))
        .length;
    final closed = _bookings
        .where((row) =>
            {'completed', 'rejected', 'cancelled'}.contains(row.status))
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandResponsiveGrid(
          minWidth: 220,
          children: [
            _RequestMetric(
              label: 'Pending requests',
              value: pending,
              icon: Icons.send_time_extension_outlined,
            ),
            _RequestMetric(
              label: 'Confirmed bookings',
              value: confirmed,
              icon: Icons.verified_outlined,
            ),
            _RequestMetric(
              label: 'Closed requests',
              value: closed,
              icon: Icons.inventory_2_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        TourTarget(
          id: 'brand:demo:booking-pipeline',
          child: BrandSectionCard(
            title: 'Requests and bookings',
            icon: Icons.handshake_outlined,
            selected: true,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: BrandSearchField(
                        hintText: 'Search project, provider or listing...',
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Refresh requests',
                      onPressed: _loading ? null : () => _load(force: true),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final status in const [
                        'All',
                        'Sent',
                        'Viewed',
                        'Under negotiation',
                        'Accepted',
                        'Secured',
                        'Completed',
                        'Cancelled',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: FilterChip(
                            label: Text(status),
                            selected: status == 'All'
                                ? _status == 'All'
                                : _status ==
                                    status.toLowerCase().replaceAll(' ', '_'),
                            onSelected: (_) => setState(
                              () => _status = status == 'All'
                                  ? 'All'
                                  : status.toLowerCase().replaceAll(' ', '_'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_error != null) ...[
          InlineNotice(
            message: _error!,
            icon: Icons.warning_amber_rounded,
            tone: CoreStatusTone.warning,
          ),
          const SizedBox(height: 12),
        ],
        if (_visibleBookings.isEmpty)
          CoreEmptyState(
            icon: Icons.mark_email_unread_outlined,
            title: _bookings.isEmpty
                ? 'No requests sent yet'
                : 'No requests match',
            message: _bookings.isEmpty
                ? 'Choose a resource from Discover or a shortlist to send the first booking request.'
                : 'Try another status or search.',
          )
        else
          TourTarget(
            id: 'brand:demo:request-results',
            child: BrandResponsiveGrid(
              minWidth: 330,
              children: [
                for (final booking in _visibleBookings)
                  _BookingCard(
                    booking: booking,
                    busy: _loading,
                    onMessage: () => _openConversation(booking),
                    onCancel: () => _cancel(booking),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  void _openConversation(Booking booking) {
    final conversationId = booking.conversationId;
    if (conversationId == null) {
      brandSnack(context, 'Conversation will open after the request is sent');
      return;
    }
    Navigator.pushNamed(
      context,
      CoreRoutes.chat,
      arguments: conversationId,
    );
  }

  Future<void> _cancel(Booking booking) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel booking request?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The provider will be notified and reserved availability will be released.',
            ),
            const SizedBox(height: 12),
            CoreTextField(
              controller: reasonController,
              label: 'Cancellation reason',
              icon: Icons.notes_outlined,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep request'),
          ),
          FilledButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.length < 3) return;
              Navigator.pop(dialogContext, reason);
            },
            child: const Text('Cancel request'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || !mounted) return;
    setState(() => _loading = true);
    try {
      await _controller!.cancelBooking(booking.publicId, reason: reason);
      await _load(force: true);
      if (mounted) brandSnack(context, 'Booking request cancelled');
    } catch (error) {
      if (mounted) brandSnack(context, brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _RequestMetric extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _RequestMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return BrandSectionCard(
      title: label,
      icon: icon,
      child: Text(
        '$value',
        style: AppTextStyles.heroSerifNumber.copyWith(
          color: context.appColors.textPrimary,
          fontSize: 28,
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final bool busy;
  final VoidCallback onMessage;
  final VoidCallback onCancel;

  const _BookingCard({
    required this.booking,
    required this.busy,
    required this.onMessage,
    required this.onCancel,
  });

  bool get _canCancel => !{
        'completed',
        'rejected',
        'cancelled',
      }.contains(booking.status);

  @override
  Widget build(BuildContext context) {
    final offer = booking.activeOffer;
    return BrandSectionCard(
      title: booking.listingTitle,
      icon: Icons.handshake_outlined,
      tone: {'accepted', 'secured', 'completed'}.contains(booking.status)
          ? BrandTone.green
          : BrandTone.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.projectTitle,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              BrandLiveStatusChip(status: booking.status),
            ],
          ),
          const SizedBox(height: 9),
          BrandInfoRow(
            icon: Icons.storefront_outlined,
            label: 'Provider',
            value: booking.provider.displayName,
          ),
          BrandInfoRow(
            icon: Icons.event_outlined,
            label: 'Dates',
            value: '${_date(booking.startAt)} – ${_date(booking.endAt)}',
          ),
          BrandInfoRow(
            icon: Icons.payments_outlined,
            label: 'Current offer',
            value: offer?.feeLabel ??
                brandMoney(
                  booking.agreedAmountMinor,
                  currency: booking.currency,
                ),
          ),
          if (booking.requirementTitle?.isNotEmpty == true)
            BrandInfoRow(
              icon: Icons.checklist_outlined,
              label: 'Requirement',
              value: booking.requirementTitle!,
            ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: busy ? null : onMessage,
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Messages'),
              ),
              if (_canCancel)
                OutlinedButton.icon(
                  onPressed: busy ? null : onCancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _date(DateTime value) {
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
