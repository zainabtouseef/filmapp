import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../routes/casting_agency_routes.dart';
import '../widgets/casting_agency_components.dart';

class CA03AuditionRequestInboxScreen extends StatefulWidget {
  const CA03AuditionRequestInboxScreen({super.key});

  @override
  State<CA03AuditionRequestInboxScreen> createState() =>
      _CA03AuditionRequestInboxScreenState();
}

class _CA03AuditionRequestInboxScreenState
    extends State<CA03AuditionRequestInboxScreen> {
  String _query = '';
  String _filter = 'All';
  String _sort = 'Newest';
  Future<List<AuditionDto>>? _future;
  String? _busyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= SpecialistScope.maybeOf(context)?.auditions(force: true);
  }

  void _refresh() {
    setState(() {
      _future = SpecialistScope.maybeOf(context)?.auditions(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AgencySectionCard(
          title: 'Audition inbox',
          icon: Icons.inbox_outlined,
          selected: true,
          actionText: _future == null ? null : 'Refresh',
          onActionTap: _refresh,
          child: Column(
            children: [
              AgencySearchField(
                hintText: 'Search project, role, status...',
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
            title: 'Sign in to view audition requests',
            message: 'Director audition requests are loaded from the server.',
          )
        else
          FutureBuilder<List<AuditionDto>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SkeletonCard(height: 360);
              }
              if (snapshot.hasError) {
                return _LoadError(
                    message: 'Could not load auditions', onRetry: _refresh);
              }
              final requests = _filtered(snapshot.data ?? const []);
              if (requests.isEmpty) {
                return CoreEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No live audition requests',
                  message: 'Try another filter or wait for director requests.',
                  actionLabel: 'Clear filters',
                  onAction: () => setState(() {
                    _query = '';
                    _filter = 'All';
                  }),
                );
              }
              return AgencyResponsiveGrid(
                minWidth: 320,
                children: [
                  for (final audition in requests)
                    _AuditionCard(
                      audition: audition,
                      busy: _busyId == audition.publicId,
                      onDetails: () => _showDetails(context, audition),
                      onReview: () => _updateStatus(audition, 'reviewing'),
                      onShortlist: () => Navigator.pushNamed(
                        context,
                        CastingAgencyRoutes.shortlist,
                        arguments: audition.publicId,
                      ),
                      onDecline: () => _confirmDecline(context, audition),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  List<AuditionDto> _filtered(List<AuditionDto> rows) {
    final lower = _query.trim().toLowerCase();
    final filtered = rows.where((audition) {
      final matchesFilter = _filter == 'All' ||
          audition.status.toLowerCase() == _filter.toLowerCase();
      final haystack =
          '${audition.publicId} ${audition.projectId} ${audition.roleTitle} ${audition.status}'
              .toLowerCase();
      return matchesFilter && (lower.isEmpty || haystack.contains(lower));
    }).toList();
    if (_sort == 'Budget') {
      filtered
          .sort((a, b) => (b.budgetMinor ?? 0).compareTo(a.budgetMinor ?? 0));
    }
    return filtered;
  }

  Future<void> _updateStatus(AuditionDto audition, String status) async {
    final specialist = SpecialistScope.maybeOf(context);
    if (specialist == null) return;
    setState(() => _busyId = audition.publicId);
    try {
      await specialist.updateAuditionStatus(audition.publicId, status);
      if (!mounted) return;
      agencySnack(context, '${audition.roleTitle} marked $status');
      _refresh();
    } catch (error) {
      if (!mounted) return;
      agencySnack(context, 'Could not update audition: $error');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _showDetails(BuildContext context, AuditionDto audition) {
    showAgencySheet(
      context,
      title: audition.roleTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AgencyInfoRow(
            icon: Icons.confirmation_number_outlined,
            label: 'Audition',
            value: audition.publicId,
          ),
          AgencyInfoRow(
            icon: Icons.movie_filter_outlined,
            label: 'Project',
            value: audition.projectId,
          ),
          AgencyInfoRow(
            icon: Icons.payments_outlined,
            label: 'Budget',
            value: audition.budgetMinor == null
                ? 'Budget TBD'
                : _money(audition.budgetMinor!),
          ),
          AgencyInfoRow(
            icon: Icons.group_outlined,
            label: 'Candidates',
            value: '${audition.candidates.length}',
          ),
        ],
      ),
    );
  }

  void _confirmDecline(BuildContext context, AuditionDto audition) {
    showAgencySheet(
      context,
      title: 'Decline request',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Decline ${audition.roleTitle}? This updates the live audition status.',
            style: AppTextStyles.body.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.close_rounded,
                  label: 'Cancel',
                  onTap: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.block_rounded,
                  label: 'Decline',
                  onTap: () {
                    Navigator.pop(context);
                    _updateStatus(audition, 'rejected');
                  },
                ),
              ),
            ],
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
          for (final filter in ['All', 'requested', 'reviewing', 'rejected'])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CoreChip(
                label: filter == 'All' ? filter : filter.toUpperCase(),
                selected: selected == filter,
                onTap: () => onFilter(filter),
              ),
            ),
          const SizedBox(width: 8),
          for (final sort in ['Newest', 'Budget'])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CoreChip(
                label: sort,
                selected: this.sort == sort,
                icon: Icons.sort_rounded,
                onTap: () => onSort(sort),
              ),
            ),
        ],
      ),
    );
  }
}

class _AuditionCard extends StatelessWidget {
  final AuditionDto audition;
  final bool busy;
  final VoidCallback onDetails;
  final VoidCallback onReview;
  final VoidCallback onShortlist;
  final VoidCallback onDecline;

  const _AuditionCard({
    required this.audition,
    required this.busy,
    required this.onDetails,
    required this.onReview,
    required this.onShortlist,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Opacity(
      opacity: busy ? 0.62 : 1,
      child: GlassSectionCard(
        radius: 20,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    audition.roleTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                AgencyStatusChip(
                    status: agencyStatusFromString(audition.status)),
              ],
            ),
            const SizedBox(height: 8),
            AgencyInfoRow(
              icon: Icons.movie_filter_outlined,
              label: 'Project',
              value: audition.projectId,
            ),
            AgencyInfoRow(
              icon: Icons.payments_outlined,
              label: 'Budget',
              value: audition.budgetMinor == null
                  ? 'Budget TBD'
                  : _money(audition.budgetMinor!),
            ),
            AgencyInfoRow(
              icon: Icons.group_outlined,
              label: 'Candidates',
              value: '${audition.candidates.length}',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                CoreSecondaryButton(
                  icon: Icons.info_outline_rounded,
                  label: 'Details',
                  compact: true,
                  onTap: busy ? null : onDetails,
                ),
                CoreSecondaryButton(
                  icon: Icons.rate_review_outlined,
                  label: 'Review',
                  compact: true,
                  onTap: busy ? null : onReview,
                ),
                CorePrimaryButton(
                  icon: Icons.view_kanban_outlined,
                  label: 'Shortlist',
                  compact: true,
                  onTap: busy ? null : onShortlist,
                ),
                CoreSecondaryButton(
                  icon: Icons.block_rounded,
                  label: 'Decline',
                  compact: true,
                  onTap: busy ? null : onDecline,
                ),
              ],
            ),
          ],
        ),
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

String _money(int minor) {
  final whole = minor ~/ 100;
  if (whole >= 100000) return 'PKR ${(whole / 1000).round()}k';
  return 'PKR $whole';
}
