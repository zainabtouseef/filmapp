import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../data/casting_agency_demo_data.dart';
import '../models/casting_agency_models.dart';
import '../routes/casting_agency_routes.dart';
import '../widgets/casting_agency_components.dart';

class CA02TalentRosterScreen extends StatefulWidget {
  const CA02TalentRosterScreen({super.key});

  @override
  State<CA02TalentRosterScreen> createState() => _CA02TalentRosterScreenState();
}

class _CA02TalentRosterScreenState extends State<CA02TalentRosterScreen> {
  String _query = '';
  String _sort = 'Availability';
  Future<List<AgencyTalentDto>>? _rosterFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final specialist = SpecialistScope.maybeOf(context);
    _rosterFuture ??= specialist?.agencyRoster(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final store = CastingAgencyDemoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final roster = _filteredRoster(store).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AgencySectionCard(
              title: 'Roster command',
              icon: Icons.manage_search_outlined,
              selected: true,
              child: Column(
                children: [
                  if (_rosterFuture != null)
                    FutureBuilder<List<AgencyTalentDto>>(
                      future: _rosterFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: InlineNotice(
                              message: 'Loading live agency roster...',
                              icon: Icons.hourglass_top_rounded,
                            ),
                          );
                        }
                        final rows = snapshot.data ?? const [];
                        if (rows.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InlineNotice(
                            message:
                                'Live roster connected: ${rows.length} represented talent record(s), latest ${rows.first.screenName}.',
                            icon: Icons.cloud_done_outlined,
                            tone: CoreStatusTone.success,
                          ),
                        );
                      },
                    ),
                  AgencySearchField(
                    hintText: 'Search talent, category, city...',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 10),
                  _FilterRow(
                    selected: store.rosterFilter,
                    sort: _sort,
                    onFilter: store.setRosterFilter,
                    onSort: (value) {
                      setState(() => _sort = value);
                      agencySnack(context, '$value sorting applied');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (roster.isEmpty)
              CoreEmptyState(
                icon: Icons.person_search_outlined,
                title: 'No roster matches',
                message: 'Clear filters or search another talent category.',
                actionLabel: 'Clear',
                onAction: () {
                  setState(() => _query = '');
                  store.setRosterFilter('All');
                },
              )
            else
              AgencyResponsiveGrid(
                minWidth: 300,
                children: [
                  for (final talent in roster)
                    _TalentCard(
                      talent: talent,
                      selected: store.selectedTalentIds.contains(talent.id),
                      onToggle: () {
                        store.toggleTalent(talent.id);
                        agencySnack(context, 'Shortlist selection updated');
                      },
                      onDetails: () => _showTalent(context, talent),
                      onTape: () => Navigator.pushNamed(
                        context,
                        CastingAgencyRoutes.selfTapes,
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  Iterable<AgencyTalent> _filteredRoster(CastingAgencyDemoStore store) {
    final lower = _query.trim().toLowerCase();
    var result = CastingAgencyDemoData.roster.where((talent) {
      final matchesFilter = switch (store.rosterFilter) {
        'Linked' => talent.linkedAccount,
        'Available' => talent.availability.toLowerCase().contains('available'),
        'Shortlisted' => talent.status == AgencyStatus.shortlisted ||
            store.selectedTalentIds.contains(talent.id),
        _ => true,
      };
      final haystack =
          '${talent.name} ${talent.category} ${talent.city} ${talent.ageRange}'
              .toLowerCase();
      return matchesFilter && haystack.contains(lower);
    }).toList();
    if (_sort == 'Name') {
      result.sort((a, b) => a.name.compareTo(b.name));
    } else {
      result.sort((a, b) {
        final aAvailable = a.availability.toLowerCase().contains('available');
        final bAvailable = b.availability.toLowerCase().contains('available');
        if (aAvailable != bAvailable) return aAvailable ? -1 : 1;
        return a.availability.compareTo(b.availability);
      });
    }
    return result;
  }

  void _showTalent(BuildContext context, AgencyTalent talent) {
    showAgencySheet(
      context,
      title: talent.name,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AgencyInfoRow(
            icon: Icons.badge_outlined,
            label: 'Category',
            value: talent.category,
          ),
          AgencyInfoRow(
            icon: Icons.location_on_outlined,
            label: 'City',
            value: talent.city,
          ),
          AgencyInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Availability',
            value: talent.availability,
          ),
          AgencyInfoRow(
            icon: Icons.link_outlined,
            label: 'Account',
            value: talent.linkedAccount ? 'Linked' : 'Agency managed',
          ),
          const SizedBox(height: 8),
          CorePrimaryButton(
            icon: Icons.view_kanban_outlined,
            label: 'Add to shortlist',
            onTap: () {
              CastingAgencyDemoStore.instance.toggleTalent(talent.id);
              Navigator.pop(context);
              agencySnack(context, 'Candidate selection updated');
            },
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String selected;
  final String sort;
  final ValueChanged<String> onFilter;
  final ValueChanged<String> onSort;

  const _FilterRow({
    required this.selected,
    required this.sort,
    required this.onFilter,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in ['All', 'Linked', 'Available', 'Shortlisted'])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CoreChip(
                label: filter,
                selected: selected == filter,
                onTap: () => onFilter(filter),
              ),
            ),
          const SizedBox(width: 8),
          for (final option in ['Availability', 'Name'])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CoreChip(
                label: option,
                selected: sort == option,
                icon: Icons.sort_rounded,
                onTap: () => onSort(option),
              ),
            ),
        ],
      ),
    );
  }
}

class _TalentCard extends StatelessWidget {
  final AgencyTalent talent;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onDetails;
  final VoidCallback onTape;

  const _TalentCard({
    required this.talent,
    required this.selected,
    required this.onToggle,
    required this.onDetails,
    required this.onTape,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 20,
      padding: const EdgeInsets.all(12),
      selected: selected,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AgencyMediaFrame(
            imageUrl: talent.imageUrl,
            title: talent.name,
            badge: talent.city,
            fallbackIcon: Icons.person_outline_rounded,
            aspectRatio: 4 / 3,
            compact: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  talent.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              AgencyStatusChip(status: talent.status),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${talent.category} - ${talent.ageRange} - ${talent.bookings}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 5),
          Text(
            talent.availability,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.statusText.copyWith(color: colors.goldDark),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.info_outline_rounded,
                  label: 'Details',
                  compact: true,
                  onTap: onDetails,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.video_call_outlined,
                  label: 'Tape',
                  compact: true,
                  onTap: onTape,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CorePrimaryButton(
            icon: selected
                ? Icons.playlist_remove_outlined
                : Icons.playlist_add_check_outlined,
            label: selected ? 'Remove from shortlist' : 'Add to shortlist',
            compact: true,
            onTap: onToggle,
          ),
        ],
      ),
    );
  }
}
