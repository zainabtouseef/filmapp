import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../data/distribution_partner_demo_data.dart';
import '../models/distribution_partner_models.dart';
import '../routes/distribution_partner_routes.dart';
import '../widgets/distribution_partner_components.dart';

class DS02DistributorContactsScreen extends StatefulWidget {
  const DS02DistributorContactsScreen({super.key});

  @override
  State<DS02DistributorContactsScreen> createState() =>
      _DS02DistributorContactsScreenState();
}

class _DS02DistributorContactsScreenState
    extends State<DS02DistributorContactsScreen> {
  String _query = '';
  String _sort = 'Territory';
  Future<List<DistributorContactDto>>? _contactsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final specialist = SpecialistScope.maybeOf(context);
    _contactsFuture ??= specialist?.distributorContacts(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final store = DistributionPartnerDemoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final rows = _rows(store).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DistributionSectionCard(
              title: 'Contact command',
              icon: Icons.contacts_outlined,
              selected: true,
              child: Column(
                children: [
                  if (_contactsFuture != null)
                    FutureBuilder<List<DistributorContactDto>>(
                      future: _contactsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: InlineNotice(
                              message: 'Loading live distributor contacts...',
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
                                'Live contacts connected: ${rows.length} contact(s), latest ${rows.first.name}.',
                            icon: Icons.cloud_done_outlined,
                            tone: CoreStatusTone.success,
                          ),
                        );
                      },
                    ),
                  DistributionSearchField(
                    hintText: 'Search partner, territory, role...',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final filter in [
                          'All',
                          'Cinema',
                          'OTT',
                          'Television',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CoreChip(
                              label: filter,
                              selected: store.contactFilter == filter,
                              onTap: () => store.setContactFilter(filter),
                            ),
                          ),
                        const SizedBox(width: 8),
                        for (final sort in ['Territory', 'Channel'])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CoreChip(
                              label: sort,
                              selected: _sort == sort,
                              icon: Icons.sort_rounded,
                              onTap: () {
                                setState(() => _sort = sort);
                                distributionSnack(
                                  context,
                                  '$sort sorting applied',
                                );
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
            DistributionTwoColumn(
              left: DistributionSectionCard(
                title: 'Distributor records',
                icon: Icons.table_rows_outlined,
                child: rows.isEmpty
                    ? CoreEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No distributor records',
                        message: 'Clear filters or search another partner.',
                        actionLabel: 'Clear',
                        onAction: () {
                          setState(() => _query = '');
                          store.setContactFilter('All');
                        },
                      )
                    : Column(
                        children: [
                          for (final row in rows)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ContactRow(
                                contact: row,
                                status: store.contactStatus(row),
                                onDetail: () => _showContact(context, row),
                                onApprove: () {
                                  store.approveContact(row.id);
                                  distributionSnack(
                                    context,
                                    'Partner record approved',
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
              ),
              right: DistributionSectionCard(
                title: 'Partner summary',
                icon: Icons.public_outlined,
                child: Column(
                  children: [
                    DistributionInfoRow(
                      icon: Icons.contacts_outlined,
                      label: 'Total contacts',
                      value: '42 partners',
                    ),
                    DistributionInfoRow(
                      icon: Icons.movie_outlined,
                      label: 'Cinema',
                      value: '18 records',
                    ),
                    DistributionInfoRow(
                      icon: Icons.live_tv_outlined,
                      label: 'OTT / TV',
                      value: '16 records',
                    ),
                    DistributionInfoRow(
                      icon: Icons.public_outlined,
                      label: 'Territories',
                      value: '9 active',
                    ),
                    const SizedBox(height: 10),
                    CoreSecondaryButton(
                      icon: Icons.download_outlined,
                      label: 'Export contacts',
                      compact: true,
                      onTap: () => distributionSnack(
                        context,
                        'Distributor contact export prepared',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Iterable<DistributorContact> _rows(DistributionPartnerDemoStore store) {
    final lower = _query.trim().toLowerCase();
    var result = DistributionPartnerDemoData.contacts.where((row) {
      final matchesFilter =
          store.contactFilter == 'All' || row.channel == store.contactFilter;
      final haystack =
          '${row.name} ${row.channel} ${row.territory} ${row.contactRole} ${row.notes}'
              .toLowerCase();
      return matchesFilter && haystack.contains(lower);
    }).toList();
    if (_sort == 'Channel') result = result.reversed.toList();
    return result;
  }

  void _showContact(BuildContext context, DistributorContact contact) {
    final store = DistributionPartnerDemoStore.instance;
    showDistributionSheet(
      context,
      title: contact.name,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DistributionInfoRow(
            icon: Icons.public_outlined,
            label: 'Territory',
            value: contact.territory,
          ),
          DistributionInfoRow(
            icon: Icons.live_tv_outlined,
            label: 'Channel',
            value: contact.channel,
          ),
          DistributionInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Role',
            value: contact.contactRole,
          ),
          DistributionInfoRow(
            icon: Icons.movie_creation_outlined,
            label: 'Prior project',
            value: contact.priorProject,
          ),
          DistributionInfoRow(
            icon: Icons.notes_outlined,
            label: 'Notes',
            value: contact.notes,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.rocket_launch_outlined,
                  label: 'Release',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      DistributionPartnerRoutes.release,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.event_available_outlined,
                  label: 'Activate',
                  onTap: () {
                    store.activateContact(contact.id);
                    Navigator.pop(context);
                    distributionSnack(context, 'Release window activated');
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

class _ContactRow extends StatelessWidget {
  final DistributorContact contact;
  final DistributionStatus status;
  final VoidCallback onDetail;
  final VoidCallback onApprove;

  const _ContactRow({
    required this.contact,
    required this.status,
    required this.onDetail,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 16,
      padding: const EdgeInsets.all(11),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  contact.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              DistributionStatusChip(status: status),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${contact.channel} - ${contact.territory} - ${contact.contactRole}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.info_outline_rounded,
                  label: 'Detail',
                  compact: true,
                  onTap: onDetail,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.verified_outlined,
                  label: 'Approve',
                  compact: true,
                  onTap: onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
