import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ActorTalentDemoStore.instance,
      builder: (context, _) {
        final store = ActorTalentDemoStore.instance;
        final tab = store.selectedOpportunityTab;
        final filtered = ActorTalentDemoData.opportunities.where((item) {
          final matchesTab = tab == _tabFor(item.type);
          final normalized = query.toLowerCase().trim();
          final matchesQuery = normalized.isEmpty ||
              item.projectTitle.toLowerCase().contains(normalized) ||
              item.role.toLowerCase().contains(normalized) ||
              item.producer.toLowerCase().contains(normalized);
          return matchesTab && matchesQuery;
        }).toList();
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
              child: filtered.isEmpty
                  ? _EmptyOpportunity(tab: tab)
                  : ActorResponsiveGrid(
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
                              actorSnack(
                                context,
                                '${opportunity.projectTitle} dates held',
                              );
                            },
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
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
              label: 'No $tab', color: Theme.of(context).colorScheme.primary),
          StatusChip(
              label: 'Filtered-zero state',
              color: Theme.of(context).colorScheme.secondary),
        ],
      ),
    );
  }
}
