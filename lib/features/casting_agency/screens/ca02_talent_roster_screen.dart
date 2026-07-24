import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../widgets/casting_agency_components.dart';

class CA02TalentRosterScreen extends StatefulWidget {
  const CA02TalentRosterScreen({super.key});

  @override
  State<CA02TalentRosterScreen> createState() => _CA02TalentRosterScreenState();
}

class _CA02TalentRosterScreenState extends State<CA02TalentRosterScreen> {
  String _query = '';
  String _filter = 'All';
  String _sort = 'Name';
  Future<List<AgencyTalentDto>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= SpecialistScope.maybeOf(context)?.agencyRoster(force: true);
  }

  void _refresh() {
    setState(() {
      _future = SpecialistScope.maybeOf(context)?.agencyRoster(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AgencySectionCard(
          title: 'Roster command',
          icon: Icons.manage_search_outlined,
          selected: true,
          actionText: _future == null ? null : 'Refresh',
          onActionTap: _refresh,
          child: Column(
            children: [
              AgencySearchField(
                hintText: 'Search represented talent...',
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 10),
              _FilterRow(
                selected: _filter,
                sort: _sort,
                onFilter: (value) => setState(() => _filter = value),
                onSort: (value) => setState(() => _sort = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_future == null)
          const CoreEmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Sign in to view agency roster',
            message: 'Represented talent records are loaded from the server.',
          )
        else
          FutureBuilder<List<AgencyTalentDto>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SkeletonCard(height: 360);
              }
              if (snapshot.hasError) {
                return _LoadError(
                    message: 'Could not load roster', onRetry: _refresh);
              }
              final roster = _filtered(snapshot.data ?? const []);
              if (roster.isEmpty) {
                return CoreEmptyState(
                  icon: Icons.person_search_outlined,
                  title: 'No live roster matches',
                  message:
                      'Clear filters or wait for represented talent records.',
                  actionLabel: 'Clear',
                  onAction: () => setState(() {
                    _query = '';
                    _filter = 'All';
                  }),
                );
              }
              return AgencyResponsiveGrid(
                minWidth: 300,
                children: [
                  for (final talent in roster)
                    _TalentCard(
                      talent: talent,
                      onDetails: () => _showTalent(context, talent),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  List<AgencyTalentDto> _filtered(List<AgencyTalentDto> rows) {
    final lower = _query.trim().toLowerCase();
    final filtered = rows.where((talent) {
      final matchesFilter = _filter == 'All' ||
          talent.status.toLowerCase() == _filter.toLowerCase();
      final haystack =
          '${talent.screenName} ${talent.representationType} ${talent.status}'
              .toLowerCase();
      return matchesFilter && (lower.isEmpty || haystack.contains(lower));
    }).toList();
    if (_sort == 'Commission') {
      filtered.sort((a, b) => b.commissionBps.compareTo(a.commissionBps));
    } else {
      filtered.sort((a, b) => a.screenName.compareTo(b.screenName));
    }
    return filtered;
  }

  void _showTalent(BuildContext context, AgencyTalentDto talent) {
    showAgencySheet(
      context,
      title: talent.screenName,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AgencyInfoRow(
            icon: Icons.badge_outlined,
            label: 'Talent profile',
            value: talent.talentProfileId,
          ),
          AgencyInfoRow(
            icon: Icons.handshake_outlined,
            label: 'Representation',
            value: talent.representationType.replaceAll('_', ' '),
          ),
          AgencyInfoRow(
            icon: Icons.percent_rounded,
            label: 'Commission',
            value: '${(talent.commissionBps / 100).toStringAsFixed(1)}%',
          ),
          AgencyInfoRow(
            icon: Icons.verified_outlined,
            label: 'Status',
            value: talent.status,
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
          for (final filter in ['All', 'active', 'pending'])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CoreChip(
                label: filter == 'All' ? filter : filter.toUpperCase(),
                selected: selected == filter,
                onTap: () => onFilter(filter),
              ),
            ),
          const SizedBox(width: 8),
          for (final option in ['Name', 'Commission'])
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
  final AgencyTalentDto talent;
  final VoidCallback onDetails;

  const _TalentCard({required this.talent, required this.onDetails});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 20,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.goldMid.withValues(alpha: 0.16),
                child:
                    Icon(Icons.person_outline_rounded, color: colors.goldDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  talent.screenName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              AgencyStatusChip(status: agencyStatusFromString(talent.status)),
            ],
          ),
          const SizedBox(height: 10),
          AgencyInfoRow(
            icon: Icons.handshake_outlined,
            label: 'Representation',
            value: talent.representationType.replaceAll('_', ' '),
          ),
          AgencyInfoRow(
            icon: Icons.percent_rounded,
            label: 'Commission',
            value: '${(talent.commissionBps / 100).toStringAsFixed(1)}%',
          ),
          const SizedBox(height: 8),
          CoreSecondaryButton(
            icon: Icons.info_outline_rounded,
            label: 'Details',
            compact: true,
            onTap: onDetails,
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CoreEmptyState(
          icon: Icons.cloud_off_outlined,
          title: message,
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
