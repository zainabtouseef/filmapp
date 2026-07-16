import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../data/brand_sponsor_demo_data.dart';
import '../models/brand_sponsor_models.dart';
import '../routes/brand_sponsor_routes.dart';
import '../widgets/brand_sponsor_components.dart';

class BR04ApplicationsInboxScreen extends StatefulWidget {
  const BR04ApplicationsInboxScreen({super.key});

  @override
  State<BR04ApplicationsInboxScreen> createState() =>
      _BR04ApplicationsInboxScreenState();
}

class _BR04ApplicationsInboxScreenState
    extends State<BR04ApplicationsInboxScreen> {
  String _query = '';
  String _sort = 'Newest';

  @override
  Widget build(BuildContext context) {
    final store = BrandSponsorDemoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final applications = _filteredApplications(store).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BrandSectionCard(
              title: 'Applications command',
              icon: Icons.inbox_outlined,
              selected: true,
              child: Column(
                children: [
                  BrandSearchField(
                    hintText: 'Search applicants, proposals, audiences...',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final filter in [
                          'All',
                          'Pending',
                          'Shortlisted',
                          'Negotiation',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CoreChip(
                              label: filter,
                              selected: store.applicationsFilter == filter,
                              onTap: () => store.setApplicationsFilter(filter),
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
                                brandSnack(context, '$sort sorting applied');
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
            if (applications.isEmpty)
              CoreEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No applications found',
                message: 'Try another application status or search term.',
                actionLabel: 'Clear filters',
                onAction: () {
                  setState(() => _query = '');
                  store.setApplicationsFilter('All');
                },
              )
            else
              BrandResponsiveGrid(
                minWidth: 320,
                children: [
                  for (final application in applications)
                    _ApplicationCard(
                      application: application,
                      status: store.applicationStatus(application),
                      onDetails: () => _showApplication(context, application),
                      onShortlist: () {
                        store.shortlistApplication(application.id);
                        brandSnack(
                            context, '${application.applicant} shortlisted');
                      },
                      onInfo: () =>
                          Navigator.pushNamed(context, CoreRoutes.chat),
                      onNegotiate: () {
                        store.negotiateApplication(application.id);
                        Navigator.pushNamed(
                          context,
                          BrandSponsorRoutes.negotiation,
                        );
                      },
                      onReject: () =>
                          _confirmReject(context, store, application),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  Iterable<BrandApplication> _filteredApplications(
      BrandSponsorDemoStore store) {
    final lower = _query.trim().toLowerCase();
    var result = BrandSponsorDemoData.applications.where((application) {
      final status = store.applicationStatus(application);
      final matchesFilter = switch (store.applicationsFilter) {
        'Pending' => status == BrandStatus.pending,
        'Shortlisted' => status == BrandStatus.shortlisted,
        'Negotiation' => status == BrandStatus.negotiation,
        _ => true,
      };
      final haystack =
          '${application.applicant} ${application.type} ${application.proposal} ${application.audience}'
              .toLowerCase();
      return matchesFilter && haystack.contains(lower);
    }).toList();
    if (_sort == 'Budget') result = result.reversed.toList();
    return result;
  }

  void _showApplication(BuildContext context, BrandApplication application) {
    showBrandSheet(
      context,
      title: application.applicant,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandInfoRow(
            icon: Icons.movie_creation_outlined,
            label: 'Type',
            value: application.type,
          ),
          BrandInfoRow(
            icon: Icons.groups_outlined,
            label: 'Audience',
            value: application.audience,
          ),
          BrandInfoRow(
            icon: Icons.payments_outlined,
            label: 'Budget ask',
            value: application.budgetAsk,
          ),
          BrandInfoRow(
            icon: Icons.notes_outlined,
            label: 'Proposal',
            value: application.proposal,
          ),
          const SizedBox(height: 8),
          CorePrimaryButton(
            icon: Icons.handshake_outlined,
            label: 'Move to negotiation',
            onTap: () {
              BrandSponsorDemoStore.instance
                  .negotiateApplication(application.id);
              Navigator.pop(context);
              Navigator.pushNamed(context, BrandSponsorRoutes.negotiation);
            },
          ),
        ],
      ),
    );
  }

  void _confirmReject(
    BuildContext context,
    BrandSponsorDemoStore store,
    BrandApplication application,
  ) {
    showBrandSheet(
      context,
      title: 'Reject application',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Reject ${application.applicant}? Their action center updates in demo mode.',
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
                  label: 'Reject',
                  onTap: () {
                    store.rejectApplication(application.id);
                    Navigator.pop(context);
                    brandSnack(context, 'Application closed');
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

class _ApplicationCard extends StatelessWidget {
  final BrandApplication application;
  final BrandStatus status;
  final VoidCallback onDetails;
  final VoidCallback onShortlist;
  final VoidCallback onInfo;
  final VoidCallback onNegotiate;
  final VoidCallback onReject;

  const _ApplicationCard({
    required this.application,
    required this.status,
    required this.onDetails,
    required this.onShortlist,
    required this.onInfo,
    required this.onNegotiate,
    required this.onReject,
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
          BrandMediaFrame(
            imageUrl: application.imageUrl,
            title: application.applicant,
            badge: application.type,
            fallbackIcon: Icons.movie_creation_outlined,
            aspectRatio: 16 / 9,
            compact: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  application.applicant,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              BrandStatusChip(status: status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${application.audience} - ${application.budgetAsk}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            application.proposal,
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
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Info',
                  compact: true,
                  onTap: onInfo,
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
                  label: 'Reject',
                  compact: true,
                  onTap: onReject,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.playlist_add_check_outlined,
                  label: 'Shortlist',
                  compact: true,
                  onTap: onShortlist,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.handshake_outlined,
                  label: 'Terms',
                  compact: true,
                  onTap: onNegotiate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
