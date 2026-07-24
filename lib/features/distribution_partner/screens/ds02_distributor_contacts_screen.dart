import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/cards/glass_section_card.dart';
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
  String _filter = 'All';
  Future<List<DistributorContactDto>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??=
        SpecialistScope.maybeOf(context)?.distributorContacts(force: true);
  }

  void _refresh() {
    setState(() {
      _future =
          SpecialistScope.maybeOf(context)?.distributorContacts(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DistributionSectionCard(
          title: 'Distributor contacts',
          icon: Icons.contacts_outlined,
          selected: true,
          actionText: _future == null ? null : 'Refresh',
          onActionTap: _refresh,
          child: Column(
            children: [
              DistributionSearchField(
                hintText: 'Search distributors, channels, territories...',
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in ['All', 'cinema', 'ott', 'tv'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CoreChip(
                          label:
                              filter == 'All' ? filter : filter.toUpperCase(),
                          selected: _filter == filter,
                          onTap: () => setState(() => _filter = filter),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_future == null)
          const CoreEmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Sign in to view distributor contacts',
            message: 'Contacts are loaded from the server.',
          )
        else
          FutureBuilder<List<DistributorContactDto>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SkeletonCard(height: 360);
              }
              if (snapshot.hasError) {
                return _LoadError(
                    message: 'Could not load contacts', onRetry: _refresh);
              }
              final contacts = _rows(snapshot.data ?? const []);
              if (contacts.isEmpty) {
                return CoreEmptyState(
                  icon: Icons.contacts_outlined,
                  title: 'No live distributor contacts',
                  message:
                      'Clear filters or create contacts from backend data.',
                  actionLabel: 'Clear',
                  onAction: () => setState(() {
                    _query = '';
                    _filter = 'All';
                  }),
                );
              }
              return DistributionResponsiveGrid(
                minWidth: 300,
                children: [
                  for (final contact in contacts)
                    _ContactCard(
                      contact: contact,
                      onDetails: () => _showContact(context, contact),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  List<DistributorContactDto> _rows(List<DistributorContactDto> rows) {
    final lower = _query.trim().toLowerCase();
    return rows.where((row) {
      final matchesFilter = _filter == 'All' || row.channel == _filter;
      final haystack =
          '${row.name} ${row.channel} ${row.territory ?? ''} ${row.contactRole ?? ''}'
              .toLowerCase();
      return matchesFilter && (lower.isEmpty || haystack.contains(lower));
    }).toList();
  }

  void _showContact(BuildContext context, DistributorContactDto contact) {
    showDistributionSheet(
      context,
      title: contact.name,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DistributionInfoRow(
            icon: Icons.hub_outlined,
            label: 'Channel',
            value: contact.channel,
          ),
          DistributionInfoRow(
            icon: Icons.public_outlined,
            label: 'Territory',
            value: contact.territory ?? 'Not set',
          ),
          DistributionInfoRow(
            icon: Icons.badge_outlined,
            label: 'Role',
            value: contact.contactRole ?? 'Not set',
          ),
          DistributionInfoRow(
            icon: Icons.notes_outlined,
            label: 'Notes',
            value: contact.notes ?? 'No notes',
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final DistributorContactDto contact;
  final VoidCallback onDetails;

  const _ContactCard({required this.contact, required this.onDetails});

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
              DistributionStatusChip(
                status: distributionStatusFromString(contact.status),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DistributionInfoRow(
            icon: Icons.hub_outlined,
            label: 'Channel',
            value: contact.channel,
          ),
          DistributionInfoRow(
            icon: Icons.public_outlined,
            label: 'Territory',
            value: contact.territory ?? 'Not set',
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
