import 'package:flutter/material.dart';

import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/actor_talent_demo_data.dart';
import '../models/actor_talent_models.dart';
import '../routes/actor_talent_routes.dart';
import '../widgets/actor_talent_components.dart';

/// AT-07 Offer Detail & Response
class AT07OfferDetailScreen extends StatefulWidget {
  final String? offerId;

  const AT07OfferDetailScreen({super.key, this.offerId});

  @override
  State<AT07OfferDetailScreen> createState() => _AT07OfferDetailScreenState();
}

class _AT07OfferDetailScreenState extends State<AT07OfferDetailScreen> {
  Future<Booking>? _future;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<Booking> _load() async {
    final id = widget.offerId;
    final bookings = BookingsScope.of(context);
    if (id != null && id.startsWith('BKG-')) return bookings.booking(id);
    final rows = await bookings.opportunities(force: true);
    if (rows.isEmpty) {
      throw const ApiException(
        code: 'booking.none',
        message: 'No live offers found.',
      );
    }
    return rows.first;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Booking>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ActorSectionCard(
            title: 'Loading Offer',
            icon: Icons.hourglass_top_rounded,
            child: CoreEmptyState(
              icon: Icons.description_outlined,
              title: 'Loading live offer',
              message: 'Fetching booking terms from the server.',
            ),
          );
        }
        if (snapshot.hasError) {
          return _DemoOfferDetail(offerId: widget.offerId);
        }
        return _LiveOfferDetail(
          booking: snapshot.data!,
          busy: _busy,
          onAccept: _accept,
          onReject: _rejectSheet,
        );
      },
    );
  }

  Future<void> _accept(Booking booking) async {
    final offer = booking.activeOffer;
    if (offer == null) return;
    setState(() => _busy = true);
    try {
      await BookingsScope.of(context).acceptOffer(offer.publicId);
      if (!mounted) return;
      actorSnack(context, 'Offer accepted. Terms approved.');
      setState(
          () => _future = BookingsScope.of(context).booking(booking.publicId));
    } on ApiException catch (error) {
      if (!mounted) return;
      actorSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _rejectSheet(Booking booking) {
    final reason = TextEditingController(text: 'Dates unavailable');
    showActorSheet(
      context,
      title: 'Reject with reason',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoreTextField(
            controller: reason,
            label: 'Reason',
            icon: Icons.notes_outlined,
          ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.send_outlined,
            label: 'Send rejection',
            compact: true,
            onTap: () async {
              Navigator.pop(context);
              await BookingsScope.of(context).rejectBooking(
                booking.publicId,
                reason: reason.text.trim(),
              );
              if (!mounted) return;
              actorSnack(context, 'Rejection sent to producer');
            },
          ),
        ],
      ),
    );
  }
}

class _LiveOfferDetail extends StatelessWidget {
  final Booking booking;
  final bool busy;
  final ValueChanged<Booking> onAccept;
  final ValueChanged<Booking> onReject;

  const _LiveOfferDetail({
    required this.booking,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final opportunity = booking.toActorOpportunity();
    final status = opportunity.status;
    return ActorTwoColumn(
      left: ActorSectionCard(
        title: '${booking.publicId} Structured Offer',
        icon: Icons.description_outlined,
        selected: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ActorMediaFrame(
              imageUrl: opportunity.imageUrl,
              title: opportunity.projectTitle,
              badge: opportunity.expiry,
              fallbackIcon: Icons.movie_filter_outlined,
            ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusChip(
                  label: ActorTalentDemoData.statusLabel(status),
                  color: actorStatusColor(context, status),
                ),
                StatusChip(
                  label: opportunity.fee,
                  color: context.appColors.goldMid,
                ),
                StatusChip(
                  label: booking.status,
                  color: context.appColors.infoBlue,
                ),
              ],
            ),
            const SizedBox(height: 9),
            ActorInfoRow(
              icon: Icons.badge_outlined,
              label: 'Role',
              value: opportunity.role,
            ),
            ActorInfoRow(
              icon: Icons.apartment_outlined,
              label: 'Producer',
              value: opportunity.producer,
            ),
            ActorInfoRow(
              icon: Icons.date_range_outlined,
              label: 'Dates',
              value: opportunity.dates,
            ),
            const SizedBox(height: 8),
            Text(
              booking.activeOffer?.conditions ?? opportunity.notes,
              style: AppTextStyles.body.copyWith(
                color: context.appColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
      right: ActorSectionCard(
        title: 'Response Rail',
        icon: Icons.route_outlined,
        child: Column(
          children: [
            ActorTimeline(
              items: [
                ('Offer received', ActorBookingStatus.sent),
                ('Terms review', status),
                ('Contract follows', ActorBookingStatus.contractPending),
              ],
            ),
            const SizedBox(height: 10),
            CorePrimaryButton(
              icon: Icons.check_circle_outline,
              label: 'Accept offer',
              compact: true,
              loading: busy,
              onTap: busy ? null : () => onAccept(booking),
            ),
            const SizedBox(height: 8),
            CoreSecondaryButton(
              icon: Icons.edit_note_outlined,
              label: 'Counteroffer',
              compact: true,
              onTap: () => Navigator.pushNamed(
                context,
                ActorTalentRoutes.counteroffer,
                arguments: booking.publicId,
              ),
            ),
            const SizedBox(height: 8),
            CoreSecondaryButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Ask question',
              compact: true,
              onTap: () => Navigator.pushNamed(
                context,
                CoreRoutes.chat,
                arguments: booking.conversationId,
              ),
            ),
            const SizedBox(height: 8),
            CoreSecondaryButton(
              icon: Icons.block_rounded,
              label: 'Reject',
              compact: true,
              onTap: busy ? null : () => onReject(booking),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoOfferDetail extends StatelessWidget {
  final String? offerId;

  const _DemoOfferDetail({this.offerId});

  @override
  Widget build(BuildContext context) {
    final store = ActorTalentDemoStore.instance;
    final opportunities = ActorTalentDemoData.opportunities;
    final offer = opportunities.firstWhere(
      (item) => item.id == offerId,
      orElse: () => opportunities.first,
    );
    final status = store.opportunityStatus(offer);
    return ActorTwoColumn(
      left: ActorSectionCard(
        title: '${offer.id} Structured Offer',
        icon: Icons.description_outlined,
        selected: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ActorMediaFrame(
              imageUrl: offer.imageUrl,
              title: offer.projectTitle,
              badge: offer.expiry,
              fallbackIcon: Icons.movie_filter_outlined,
            ),
            const SizedBox(height: 9),
            StatusChip(
              label: ActorTalentDemoData.statusLabel(status),
              color: actorStatusColor(context, status),
            ),
            const SizedBox(height: 9),
            ActorInfoRow(
              icon: Icons.badge_outlined,
              label: 'Role',
              value: offer.role,
            ),
            ActorInfoRow(
              icon: Icons.apartment_outlined,
              label: 'Producer',
              value: offer.producer,
            ),
          ],
        ),
      ),
      right: ActorSectionCard(
        title: 'Response Rail',
        icon: Icons.route_outlined,
        child: CoreSecondaryButton(
          icon: Icons.edit_note_outlined,
          label: 'Preview Counteroffer',
          compact: true,
          onTap: () => Navigator.pushNamed(
            context,
            ActorTalentRoutes.counteroffer,
            arguments: offer.id,
          ),
        ),
      ),
    );
  }
}
