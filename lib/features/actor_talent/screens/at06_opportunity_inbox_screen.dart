import 'package:flutter/material.dart';

import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/actor_talent_demo_data.dart';
import '../models/actor_talent_models.dart';
import '../routes/actor_talent_routes.dart';
import '../widgets/actor_talent_components.dart';

/// AT-06 Opportunity Inbox
class AT06OpportunityInboxScreen extends StatefulWidget {
  const AT06OpportunityInboxScreen({super.key});

  @override
  State<AT06OpportunityInboxScreen> createState() =>
      _AT06OpportunityInboxScreenState();
}

class _AT06OpportunityInboxScreenState
    extends State<AT06OpportunityInboxScreen> {
  String query = '';
  Future<List<Booking>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bookings = BookingsScope.maybeOf(context);
    if (bookings != null) {
      _future ??= bookings.opportunities(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ActorTalentDemoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final tab = store.selectedOpportunityTab;
        return Column(
          children: [
            ActorSearchFilterBar(
              query: query,
              onQueryChanged: (value) => setState(() => query = value),
              filters: const [
                'Direct Offers',
                'Audition Invites',
                'Casting Calls',
              ],
              selectedFilter: tab,
              onFilterChanged: store.setOpportunityTab,
            ),
            const SizedBox(height: 12),
            ActorSectionCard(
              title: 'Sorted by Expiry',
              icon: Icons.inbox_outlined,
              child: FutureBuilder<List<Booking>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _EmptyOpportunity(tab: 'Loading offers');
                  }
                  if (snapshot.hasError) {
                    return _DemoOpportunityGrid(query: query, tab: tab);
                  }
                  final bookings = _filter(snapshot.data ?? const []);
                  if (bookings.isEmpty) {
                    return _DemoOpportunityGrid(query: query, tab: tab);
                  }
                  return ActorResponsiveGrid(
                    minWidth: 270,
                    children: [
                      for (final booking in bookings)
                        ActorOpportunityCard(
                          opportunity: booking.toActorOpportunity(),
                          status: booking.toActorOpportunity().status,
                          onOpen: () => Navigator.pushNamed(
                            context,
                            ActorTalentRoutes.offerDetail,
                            arguments: booking.publicId,
                          ),
                          onPrimary: () => _accept(booking),
                          onHold: () => actorSnack(
                            context,
                            'Live holds are managed in Availability Calendar',
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<Booking> _filter(List<Booking> rows) {
    final normalized = query.toLowerCase().trim();
    return rows.where((item) {
      final haystack =
          '${item.requester.displayName} ${item.category} ${item.status}'
              .toLowerCase();
      return normalized.isEmpty || haystack.contains(normalized);
    }).toList();
  }

  Future<void> _accept(Booking booking) async {
    final offer = booking.activeOffer;
    if (offer == null) return;
    final bookings = BookingsScope.maybeOf(context);
    if (bookings == null) {
      actorSnack(context, 'Offer accepted. Terms approved.');
      return;
    }
    try {
      await bookings.acceptOffer(offer.publicId);
      if (!mounted) return;
      actorSnack(context, 'Offer accepted. Terms approved.');
      setState(() => _future = bookings.opportunities(force: true));
    } catch (error) {
      if (!mounted) return;
      actorSnack(context, '$error');
    }
  }
}

class _DemoOpportunityGrid extends StatelessWidget {
  final String query;
  final String tab;

  const _DemoOpportunityGrid({required this.query, required this.tab});

  @override
  Widget build(BuildContext context) {
    final store = ActorTalentDemoStore.instance;
    final filtered = ActorTalentDemoData.opportunities.where((item) {
      final matchesTab = tab == _tabFor(item.type);
      final normalized = query.toLowerCase().trim();
      final matchesQuery = normalized.isEmpty ||
          item.projectTitle.toLowerCase().contains(normalized) ||
          item.role.toLowerCase().contains(normalized) ||
          item.producer.toLowerCase().contains(normalized);
      return matchesTab && matchesQuery;
    }).toList();
    if (filtered.isEmpty) return _EmptyOpportunity(tab: tab);
    return ActorResponsiveGrid(
      minWidth: 270,
      children: [
        for (final opportunity in filtered)
          ActorOpportunityCard(
            opportunity: opportunity,
            status: store.opportunityStatus(opportunity),
            onOpen: () => Navigator.pushNamed(
              context,
              ActorTalentRoutes.offerDetail,
              arguments: opportunity.id,
            ),
            onPrimary: () => store.acceptOffer(opportunity.id),
            onHold: () {
              store.holdDates(opportunity.id);
              actorSnack(context, '${opportunity.projectTitle} dates held');
            },
          ),
      ],
    );
  }

  String _tabFor(ActorOpportunityType type) {
    return switch (type) {
      ActorOpportunityType.directOffer => 'Direct Offers',
      ActorOpportunityType.auditionInvite => 'Audition Invites',
      ActorOpportunityType.castingCall => 'Casting Calls',
    };
  }
}

class _EmptyOpportunity extends StatelessWidget {
  final String tab;

  const _EmptyOpportunity({required this.tab});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          StatusChip(
            label: 'No $tab',
            color: Theme.of(context).colorScheme.primary,
          ),
          StatusChip(
            label: 'Filtered-zero state',
            color: Theme.of(context).colorScheme.secondary,
          ),
        ],
      ),
    );
  }
}
