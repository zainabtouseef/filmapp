import 'package:flutter/material.dart';

import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../models/actor_talent_models.dart';
import '../routes/actor_talent_routes.dart';
import '../widgets/actor_casting_widgets.dart';
import '../widgets/actor_talent_components.dart';

class AT17BookingsMessagesScreen extends StatefulWidget {
  const AT17BookingsMessagesScreen({super.key});

  @override
  State<AT17BookingsMessagesScreen> createState() =>
      _AT17BookingsMessagesScreenState();
}

class _AT17BookingsMessagesScreenState
    extends State<AT17BookingsMessagesScreen> {
  String _filter = 'All';
  String _query = '';
  Future<List<Booking>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<List<Booking>> _load() {
    final controller = BookingsScope.maybeOf(context);
    if (controller == null) {
      return Future<List<Booking>>.error(
        const ApiException(
          code: 'bookings.scope_missing',
          message: 'Sign in to view live bookings.',
        ),
      );
    }
    return controller.bookings(force: true);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ActorSearchFilterBar(
          query: _query,
          onQueryChanged: (value) => setState(() => _query = value),
          filters: const ['All', 'Offers', 'Confirmed', 'Closed'],
          selectedFilter: _filter,
          onFilterChanged: (value) => setState(() => _filter = value),
        ),
        const SizedBox(height: 12),
        ActorSectionCard(
          title: 'Bookings',
          icon: Icons.event_available_outlined,
          actionText: 'Refresh',
          onActionTap: _reload,
          child: FutureBuilder<List<Booking>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Column(
                  children: [
                    SkeletonCard(height: 170),
                    SizedBox(height: 10),
                    SkeletonCard(height: 170),
                  ],
                );
              }
              if (snapshot.hasError) {
                return CoreEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Bookings unavailable',
                  message: snapshot.error is ApiException
                      ? (snapshot.error! as ApiException).message
                      : 'Could not load your bookings.',
                  actionLabel: 'Try again',
                  onAction: _reload,
                );
              }
              final rows = (snapshot.data ?? const <Booking>[])
                  .where(_matchesFilter)
                  .toList();
              if (rows.isEmpty) {
                return CoreEmptyState(
                  icon: Icons.event_busy_outlined,
                  title: 'No $_filter bookings',
                  message:
                      'Offers and confirmed production work appear here with schedule, messages, contract and payment actions.',
                  actionLabel: 'Discover roles',
                  onAction: () => Navigator.pushNamed(
                    context,
                    ActorTalentRoutes.opportunities,
                  ),
                );
              }
              return Column(
                children: [
                  for (var index = 0; index < rows.length; index++) ...[
                    _BookingCard(booking: rows[index]),
                    if (index != rows.length - 1) const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  bool _matchesFilter(Booking item) {
    final query = _query.trim().toLowerCase();
    final matchesQuery = query.isEmpty ||
        [
          item.requester.displayName,
          item.projectTitle,
          item.requirementTitle ?? '',
          item.projectCity ?? '',
          item.projectId,
          item.category,
          item.status,
        ].join(' ').toLowerCase().contains(query);
    if (!matchesQuery) return false;
    return switch (_filter) {
      'Offers' =>
        const {'sent', 'viewed', 'under_negotiation'}.contains(item.status),
      'Confirmed' => const {'accepted', 'secured'}.contains(item.status),
      'Closed' =>
        const {'rejected', 'cancelled', 'completed'}.contains(item.status),
      _ => true,
    };
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isOffer =
        const {'sent', 'viewed', 'under_negotiation'}.contains(booking.status);
    return ActorSectionCard(
      title: booking.projectTitle,
      icon: isOffer
          ? Icons.local_activity_outlined
          : Icons.movie_creation_outlined,
      tone: isOffer ? ActorTone.gold : ActorTone.green,
      selected: isOffer,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.requirementTitle ??
                      actorCastingTitleCase(booking.category),
                  style: AppTextStyles.cardTitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Chip(
                label: Text(actorCastingTitleCase(booking.status)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ActorInfoRow(
            icon: Icons.date_range_outlined,
            label: 'Schedule',
            value:
                '${actorCastingDate(booking.startAt)} to ${actorCastingDate(booking.endAt)}',
          ),
          ActorInfoRow(
            icon: Icons.payments_outlined,
            label: 'Fee',
            value: booking.activeOffer?.feeLabel ??
                (booking.agreedAmountMinor == null
                    ? 'Rate to be confirmed'
                    : '${booking.currency} ${booking.agreedAmountMinor! ~/ 100}'),
          ),
          ActorInfoRow(
            icon: Icons.account_circle_outlined,
            label: 'Contact',
            value: booking.requester.displayName,
          ),
          ActorInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: booking.projectCity ?? 'To be confirmed',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isOffer)
                SizedBox(
                  width: 172,
                  child: CorePrimaryButton(
                    icon: Icons.rate_review_outlined,
                    label: 'Review offer',
                    compact: true,
                    onTap: () => Navigator.pushNamed(
                      context,
                      ActorTalentRoutes.offerDetail,
                      arguments: booking.publicId,
                    ),
                  ),
                ),
              if (booking.conversationId != null)
                SizedBox(
                  width: 156,
                  child: CoreSecondaryButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Messages',
                    compact: true,
                    onTap: () => Navigator.pushNamed(
                      context,
                      CoreRoutes.chat,
                      arguments: booking.conversationId,
                    ),
                  ),
                ),
              if (!isOffer)
                SizedBox(
                  width: 148,
                  child: CoreSecondaryButton(
                    icon: Icons.article_outlined,
                    label: 'Contract',
                    compact: true,
                    onTap: () => Navigator.pushNamed(
                      context,
                      ActorTalentRoutes.contracts,
                    ),
                  ),
                ),
              if (!isOffer)
                SizedBox(
                  width: 148,
                  child: CoreSecondaryButton(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Payment',
                    compact: true,
                    onTap: () => Navigator.pushNamed(
                      context,
                      ActorTalentRoutes.earnings,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
