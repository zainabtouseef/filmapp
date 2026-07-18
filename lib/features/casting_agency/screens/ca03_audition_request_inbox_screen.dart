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

class CA03AuditionRequestInboxScreen extends StatefulWidget {
  const CA03AuditionRequestInboxScreen({super.key});

  @override
  State<CA03AuditionRequestInboxScreen> createState() =>
      _CA03AuditionRequestInboxScreenState();
}

class _CA03AuditionRequestInboxScreenState
    extends State<CA03AuditionRequestInboxScreen> {
  String _query = '';
  String _sort = 'Newest';
  Future<List<AuditionDto>>? _auditionsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final specialist = SpecialistScope.maybeOf(context);
    _auditionsFuture ??= specialist?.auditions(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final store = CastingAgencyDemoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final requests = _filteredRequests(store).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AgencySectionCard(
              title: 'Audition inbox',
              icon: Icons.inbox_outlined,
              selected: true,
              child: Column(
                children: [
                  if (_auditionsFuture != null)
                    FutureBuilder<List<AuditionDto>>(
                      future: _auditionsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: InlineNotice(
                              message: 'Loading live audition requests...',
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
                                'Live auditions connected: ${rows.length} request(s), latest ${rows.first.publicId} is ${rows.first.status}.',
                            icon: Icons.cloud_done_outlined,
                            tone: CoreStatusTone.success,
                          ),
                        );
                      },
                    ),
                  AgencySearchField(
                    hintText: 'Search project, director, role...',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final filter in [
                          'All',
                          'New',
                          'Reviewing',
                          'Shortlisted',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CoreChip(
                              label: filter,
                              selected: store.auditionFilter == filter,
                              onTap: () => store.setAuditionFilter(filter),
                            ),
                          ),
                        const SizedBox(width: 8),
                        for (final sort in ['Newest', 'Budget'])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CoreChip(
                              label: sort,
                              selected: _sort == sort,
                              icon: Icons.sort_rounded,
                              onTap: () {
                                setState(() => _sort = sort);
                                agencySnack(context, '$sort sorting applied');
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (requests.isEmpty)
              CoreEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No audition requests',
                message: 'Try another saved filter.',
                actionLabel: 'Clear filters',
                onAction: () {
                  setState(() => _query = '');
                  store.setAuditionFilter('All');
                },
              )
            else
              AgencyResponsiveGrid(
                minWidth: 320,
                children: [
                  for (final audition in requests)
                    _AuditionCard(
                      audition: audition,
                      status: store.auditionStatus(audition),
                      onDetails: () => _showDetails(context, audition),
                      onReview: () {
                        store.reviewAudition(audition.id);
                        store.selectAudition(audition.id);
                        final specialist = SpecialistScope.maybeOf(context);
                        final live = _auditionsFuture;
                        if (specialist != null && live != null) {
                          () async {
                            try {
                              final rows = await live;
                              if (rows.isEmpty) return;
                              await specialist.updateAuditionStatus(
                                rows.first.publicId,
                                'reviewing',
                              );
                              if (!mounted) return;
                              setState(() => _auditionsFuture =
                                  specialist.auditions(force: true));
                            } catch (_) {
                              // Demo state remains the fallback if the live
                              // audition is not writable by this account.
                            }
                          }();
                        }
                        agencySnack(context, '${audition.project} in review');
                      },
                      onShortlist: () {
                        store.selectAudition(audition.id);
                        Navigator.pushNamed(
                          context,
                          CastingAgencyRoutes.shortlist,
                        );
                      },
                      onDecline: () =>
                          _confirmDecline(context, store, audition),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  Iterable<AgencyAudition> _filteredRequests(CastingAgencyDemoStore store) {
    final lower = _query.trim().toLowerCase();
    var result = CastingAgencyDemoData.auditions.where((audition) {
      final status = store.auditionStatus(audition);
      final matchesFilter = switch (store.auditionFilter) {
        'New' => status == AgencyStatus.newRequest,
        'Reviewing' => status == AgencyStatus.reviewing,
        'Shortlisted' => status == AgencyStatus.shortlisted,
        _ => true,
      };
      final haystack =
          '${audition.project} ${audition.director} ${audition.role} ${audition.city}'
              .toLowerCase();
      return matchesFilter && haystack.contains(lower);
    }).toList();
    if (_sort == 'Budget') result = result.reversed.toList();
    return result;
  }

  void _showDetails(BuildContext context, AgencyAudition audition) {
    showAgencySheet(
      context,
      title: audition.project,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AgencyInfoRow(
            icon: Icons.business_outlined,
            label: 'Director',
            value: audition.director,
          ),
          AgencyInfoRow(
            icon: Icons.theater_comedy_outlined,
            label: 'Role',
            value: audition.role,
          ),
          AgencyInfoRow(
            icon: Icons.schedule_outlined,
            label: 'Due',
            value: audition.dueDate,
          ),
          AgencyInfoRow(
            icon: Icons.payments_outlined,
            label: 'Budget',
            value: audition.budget,
          ),
          const SizedBox(height: 8),
          CorePrimaryButton(
            icon: Icons.view_kanban_outlined,
            label: 'Build shortlist',
            onTap: () {
              CastingAgencyDemoStore.instance.selectAudition(audition.id);
              Navigator.pop(context);
              Navigator.pushNamed(context, CastingAgencyRoutes.shortlist);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDecline(
    BuildContext context,
    CastingAgencyDemoStore store,
    AgencyAudition audition,
  ) {
    showAgencySheet(
      context,
      title: 'Decline request',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Decline ${audition.project}? The director action center updates in the demo state.',
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
                    store.declineAudition(audition.id);
                    Navigator.pop(context);
                    agencySnack(context, 'Audition declined');
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

class _AuditionCard extends StatelessWidget {
  final AgencyAudition audition;
  final AgencyStatus status;
  final VoidCallback onDetails;
  final VoidCallback onReview;
  final VoidCallback onShortlist;
  final VoidCallback onDecline;

  const _AuditionCard({
    required this.audition,
    required this.status,
    required this.onDetails,
    required this.onReview,
    required this.onShortlist,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 20,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AgencyMediaFrame(
            imageUrl: audition.imageUrl,
            title: audition.project,
            badge: audition.city,
            fallbackIcon: Icons.movie_creation_outlined,
            aspectRatio: 16 / 9,
            compact: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  audition.project,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              AgencyStatusChip(status: status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${audition.director} - ${audition.dueDate} - ${audition.budget}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            audition.role,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
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
                  icon: Icons.rate_review_outlined,
                  label: 'Review',
                  compact: true,
                  onTap: onReview,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.block_rounded,
                  label: 'Decline',
                  compact: true,
                  onTap: onDecline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.view_kanban_outlined,
                  label: 'Shortlist',
                  compact: true,
                  onTap: onShortlist,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
