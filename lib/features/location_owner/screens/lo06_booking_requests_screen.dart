import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../data/location_owner_demo_data.dart';
import '../models/location_owner_models.dart';
import '../widgets/location_owner_components.dart';

class LO06BookingRequestsScreen extends StatefulWidget {
  final String? initialRequestId;

  const LO06BookingRequestsScreen({super.key, this.initialRequestId});

  @override
  State<LO06BookingRequestsScreen> createState() =>
      _LO06BookingRequestsScreenState();
}

class _LO06BookingRequestsScreenState extends State<LO06BookingRequestsScreen> {
  String _query = '';
  String _sort = 'Newest';

  @override
  void initState() {
    super.initState();
    final id = widget.initialRequestId;
    if (id != null) {
      final match = LocationOwnerDemoData.requests
          .where((request) => request.id == id)
          .toList();
      if (match.isNotEmpty) {
        _query = match.first.project;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = LocationOwnerDemoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final requests = _filteredRequests(store).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RequestCommandBar(
              query: _query,
              selectedFilter: store.requestFilter,
              selectedSort: _sort,
              onQueryChanged: (value) => setState(() => _query = value),
              onFilterChanged: store.setRequestFilter,
              onSortChanged: (value) {
                setState(() => _sort = value);
                locationSnack(context, '$value sorting applied');
              },
            ),
            const SizedBox(height: 12),
            if (requests.isEmpty)
              CoreEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No matching requests',
                message:
                    'Change the filter or search text to show seeded jobs.',
                actionLabel: 'Clear filters',
                onAction: () {
                  setState(() => _query = '');
                  store.setRequestFilter('All');
                },
              )
            else
              LocationResponsiveGrid(
                minWidth: 320,
                children: [
                  for (final request in requests)
                    _RequestCard(
                      request: request,
                      status: store.requestStatus(request),
                      onDetails: () => _showRequestDetails(context, request),
                      onAccept: () {
                        store.acceptRequest(request.id);
                        locationSnack(
                          context,
                          '${request.project} moved to contract pending',
                        );
                      },
                      onCounter: () {
                        store.counterRequest(request.id);
                        Navigator.pushNamed(context, CoreRoutes.chat);
                      },
                      onReject: () => _confirmReject(context, store, request),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  Iterable<LocationBookingRequest> _filteredRequests(
    LocationOwnerDemoStore store,
  ) {
    final lowerQuery = _query.trim().toLowerCase();
    final result = LocationOwnerDemoData.requests.where((request) {
      final status = store.requestStatus(request);
      final matchesFilter = switch (store.requestFilter) {
        'Urgent' => status == LocationBookingStatus.requestReceived,
        'Negotiation' => status == LocationBookingStatus.underNegotiation,
        'Secured' => status == LocationBookingStatus.secured ||
            status == LocationBookingStatus.contractPending,
        _ => true,
      };
      final haystack =
          '${request.project} ${request.producer} ${request.purpose}'
              .toLowerCase();
      return matchesFilter && haystack.contains(lowerQuery);
    }).toList();
    if (_sort == 'Budget') {
      result.sort((a, b) => _budgetValue(b.budget) - _budgetValue(a.budget));
    }
    return result;
  }

  int _budgetValue(String budget) {
    final digits = budget.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  void _showRequestDetails(
    BuildContext context,
    LocationBookingRequest request,
  ) {
    showLocationSheet(
      context,
      title: request.project,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocationInfoRow(
            icon: Icons.business_outlined,
            label: 'Producer',
            value: request.producer,
          ),
          LocationInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Requested dates',
            value: request.dates,
          ),
          LocationInfoRow(
            icon: Icons.groups_2_outlined,
            label: 'Crew size',
            value: request.crewSize,
          ),
          LocationInfoRow(
            icon: Icons.payments_outlined,
            label: 'Budget',
            value: request.budget,
          ),
          const SizedBox(height: 8),
          CorePrimaryButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Open negotiation',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, CoreRoutes.chat);
            },
          ),
        ],
      ),
    );
  }

  void _confirmReject(
    BuildContext context,
    LocationOwnerDemoStore store,
    LocationBookingRequest request,
  ) {
    showLocationSheet(
      context,
      title: 'Reject request',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Reject ${request.project}? The producer action center will update immediately.',
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
                    store.rejectRequest(request.id);
                    Navigator.pop(context);
                    locationSnack(context, 'Request rejected');
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

class _RequestCommandBar extends StatelessWidget {
  final String query;
  final String selectedFilter;
  final String selectedSort;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSortChanged;

  const _RequestCommandBar({
    required this.query,
    required this.selectedFilter,
    required this.selectedSort,
    required this.onQueryChanged,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return LocationSectionCard(
      title: 'Request inbox',
      icon: Icons.move_to_inbox_outlined,
      selected: true,
      child: Column(
        children: [
          TextField(
            onChanged: onQueryChanged,
            style: AppTextStyles.body.copyWith(color: colors.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search project, producer, purpose...',
              hintStyle: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
              ),
              prefixIcon:
                  Icon(Icons.search_rounded, color: colors.goldDark, size: 20),
              filled: true,
              fillColor: colors.surface
                  .withValues(alpha: colors.isLight ? 0.74 : 0.36),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.goldMid),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in [
                  'All',
                  'Urgent',
                  'Negotiation',
                  'Secured',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CoreChip(
                      label: filter,
                      selected: selectedFilter == filter,
                      onTap: () => onFilterChanged(filter),
                    ),
                  ),
                const SizedBox(width: 8),
                for (final sort in ['Newest', 'Budget'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CoreChip(
                      label: sort,
                      selected: selectedSort == sort,
                      icon: Icons.sort_rounded,
                      onTap: () => onSortChanged(sort),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final LocationBookingRequest request;
  final LocationBookingStatus status;
  final VoidCallback onDetails;
  final VoidCallback onAccept;
  final VoidCallback onCounter;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.status,
    required this.onDetails,
    required this.onAccept,
    required this.onCounter,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final actionable = status == LocationBookingStatus.requestReceived ||
        status == LocationBookingStatus.underNegotiation;
    return GlassSectionCard(
      radius: 20,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocationMediaFrame(
            imageUrl: request.imageUrl,
            title: request.project,
            badge: request.dates,
            fallbackIcon: Icons.movie_filter_outlined,
            aspectRatio: 16 / 9,
            compact: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  request.project,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              LocationBookingStatusChip(status: status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${request.producer} - ${request.crewSize} - ${request.budget}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            request.purpose,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 11),
          if (actionable) ...[
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
                    icon: Icons.edit_note_outlined,
                    label: 'Counter',
                    compact: true,
                    onTap: onCounter,
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
                  child: CorePrimaryButton(
                    icon: Icons.check_circle_outline,
                    label: 'Accept',
                    compact: true,
                    onTap: onAccept,
                  ),
                ),
              ],
            ),
          ] else
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
