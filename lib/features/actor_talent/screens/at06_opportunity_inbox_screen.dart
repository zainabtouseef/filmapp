import 'package:flutter/material.dart';

import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
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
                'All',
                'Direct Offers',
                'Audition Invites',
                'Casting Calls',
              ],
              selectedFilter: tab,
              onFilterChanged: store.setOpportunityTab,
            ),
            const SizedBox(height: 12),
            ActorSectionCard(
              title: 'Opportunity Queue',
              icon: Icons.inbox_outlined,
              actionText: _future == null ? null : 'Refresh',
              onActionTap: _refresh,
              child: FutureBuilder<List<Booking>>(
                future: _future,
                builder: (context, snapshot) {
                  if (_future == null) {
                    return _DemoOpportunityGrid(query: query, tab: tab);
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _EmptyOpportunity(tab: 'Loading offers');
                  }
                  if (snapshot.hasError) {
                    return _OpportunityLoadError(onRetry: _refresh);
                  }
                  final bookings = _filter(snapshot.data ?? const []);
                  if (bookings.isEmpty) {
                    return _EmptyOpportunity(tab: tab);
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
                          onHold: () => Navigator.pushNamed(
                            context,
                            ActorTalentRoutes.calendar,
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
    final selectedType = ActorTalentDemoStore.instance.selectedOpportunityTab;
    return rows.where((item) {
      final opportunity = item.toActorOpportunity();
      final haystack =
          '${item.requester.displayName} ${item.category} ${item.status}'
              .toLowerCase();
      final matchesQuery = normalized.isEmpty || haystack.contains(normalized);
      final matchesType =
          selectedType == 'All' || selectedType == _tabFor(opportunity.type);
      return matchesQuery && matchesType;
    }).toList();
  }

  void _refresh() {
    final bookings = BookingsScope.maybeOf(context);
    if (bookings == null) return;
    setState(() => _future = bookings.opportunities(force: true));
  }

  String _tabFor(ActorOpportunityType type) {
    return switch (type) {
      ActorOpportunityType.directOffer => 'Direct Offers',
      ActorOpportunityType.auditionInvite => 'Audition Invites',
      ActorOpportunityType.castingCall => 'Casting Calls',
    };
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
      final matchesTab = tab == 'All' || tab == _tabFor(item.type);
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
            onHold: () {
              store.holdDates(opportunity.id);
              Navigator.pushNamed(context, ActorTalentRoutes.calendar);
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
    return CoreEmptyState(
      icon: Icons.mark_email_read_outlined,
      title: tab == 'Loading offers' ? 'Loading opportunities' : 'No $tab',
      message: tab == 'Loading offers'
          ? 'Fetching your latest offers from CineConnect.'
          : 'New matching offers will appear here when a producer sends them.',
    );
  }
}

class _OpportunityLoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _OpportunityLoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CoreEmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load opportunities',
          message: 'Check your connection and try again.',
        ),
        const SizedBox(height: 10),
        CoreSecondaryButton(
          icon: Icons.refresh_rounded,
          label: 'Try again',
          compact: true,
          onTap: onRetry,
        ),
      ],
    );
  }
}
