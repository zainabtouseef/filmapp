import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../data/crew_services_demo_data.dart';
import '../models/crew_services_models.dart';
import '../widgets/crew_services_components.dart';

class CR05RequestsNegotiationScreen extends StatefulWidget {
  final String? initialRequestId;

  const CR05RequestsNegotiationScreen({super.key, this.initialRequestId});

  @override
  State<CR05RequestsNegotiationScreen> createState() =>
      _CR05RequestsNegotiationScreenState();
}

class _CR05RequestsNegotiationScreenState
    extends State<CR05RequestsNegotiationScreen> {
  String _query = '';
  String _sort = 'Newest';

  @override
  void initState() {
    super.initState();
    final id = widget.initialRequestId;
    if (id != null) {
      final match = CrewServicesDemoData.requests
          .where((request) => request.id == id)
          .toList();
      if (match.isNotEmpty) {
        _query = match.first.project;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = CrewServicesDemoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final requests = _filteredRequests(store).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CrewSectionCard(
              title: 'Request inbox',
              icon: Icons.move_to_inbox_outlined,
              selected: true,
              child: Column(
                children: [
                  _SearchField(
                      onChanged: (value) => setState(() => _query = value)),
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
                              selected: store.requestFilter == filter,
                              onTap: () => store.setRequestFilter(filter),
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
                                crewSnack(context, '$sort sorting applied');
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
                title: 'No matching requests',
                message: 'Try another search or saved filter.',
                actionLabel: 'Clear filters',
                onAction: () {
                  setState(() => _query = '');
                  store.setRequestFilter('All');
                },
              )
            else
              CrewResponsiveGrid(
                minWidth: 320,
                children: [
                  for (final request in requests)
                    _RequestCard(
                      request: request,
                      status: store.requestStatus(request),
                      onDetails: () => _showDetails(context, request),
                      onAccept: () {
                        store.acceptRequest(request.id);
                        crewSnack(
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

  Iterable<CrewRequest> _filteredRequests(CrewServicesDemoStore store) {
    final lower = _query.trim().toLowerCase();
    final result = CrewServicesDemoData.requests.where((request) {
      final status = store.requestStatus(request);
      final matchesFilter = switch (store.requestFilter) {
        'Urgent' => status == CrewBookingStatus.requestReceived,
        'Negotiation' => status == CrewBookingStatus.underNegotiation,
        'Secured' => status == CrewBookingStatus.secured ||
            status == CrewBookingStatus.contractPending,
        _ => true,
      };
      final haystack =
          '${request.project} ${request.producer} ${request.requirement} ${request.city}'
              .toLowerCase();
      return matchesFilter && haystack.contains(lower);
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

  void _showDetails(BuildContext context, CrewRequest request) {
    showCrewSheet(
      context,
      title: request.project,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CrewInfoRow(
            icon: Icons.business_outlined,
            label: 'Producer',
            value: request.producer,
          ),
          CrewInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Dates',
            value: request.dates,
          ),
          CrewInfoRow(
            icon: Icons.engineering_outlined,
            label: 'Requirement',
            value: request.requirement,
          ),
          CrewInfoRow(
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
    CrewServicesDemoStore store,
    CrewRequest request,
  ) {
    showCrewSheet(
      context,
      title: 'Reject request',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Reject ${request.project}? The producer action center updates immediately.',
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
                    crewSnack(context, 'Request rejected');
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

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TextField(
      onChanged: onChanged,
      style: AppTextStyles.body.copyWith(color: colors.textPrimary),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search projects, producers, crew terms...',
        hintStyle: AppTextStyles.smallMeta.copyWith(
          color: colors.textSecondary,
        ),
        prefixIcon:
            Icon(Icons.search_rounded, color: colors.goldDark, size: 20),
        filled: true,
        fillColor:
            colors.surface.withValues(alpha: colors.isLight ? 0.74 : 0.36),
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
    );
  }
}

class _RequestCard extends StatelessWidget {
  final CrewRequest request;
  final CrewBookingStatus status;
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
    final actionable = status == CrewBookingStatus.requestReceived ||
        status == CrewBookingStatus.underNegotiation;
    return GlassSectionCard(
      radius: 20,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CrewMediaFrame(
            imageUrl: request.imageUrl,
            title: request.project,
            badge: request.city,
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
              CrewStatusChip(status: status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${request.producer} - ${request.dates} - ${request.budget}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            request.requirement,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
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
