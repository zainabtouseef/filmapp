import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../data/media_equipment_demo_data.dart';
import '../models/media_equipment_models.dart';
import '../widgets/media_equipment_components.dart';

class ME07BookingRequestsScreen extends StatefulWidget {
  final String? initialRequestId;

  const ME07BookingRequestsScreen({super.key, this.initialRequestId});

  @override
  State<ME07BookingRequestsScreen> createState() =>
      _ME07BookingRequestsScreenState();
}

class _ME07BookingRequestsScreenState extends State<ME07BookingRequestsScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    final id = widget.initialRequestId;
    if (id != null) {
      final match = MediaEquipmentDemoData.requests
          .where((request) => request.id == id)
          .toList();
      if (match.isNotEmpty) {
        _query = match.first.project;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = MediaEquipmentDemoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final requests = _filteredRequests(store).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MediaSectionCard(
              title: 'Shared inbox',
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
                message: 'Try another filter or search term.',
                actionLabel: 'Clear filters',
                onAction: () {
                  setState(() => _query = '');
                  store.setRequestFilter('All');
                },
              )
            else
              MediaResponsiveGrid(
                minWidth: 320,
                children: [
                  for (final request in requests)
                    _RequestCard(
                      request: request,
                      status: store.requestStatus(request),
                      onDetails: () => _showDetails(context, request),
                      onAccept: () {
                        store.acceptRequest(request.id);
                        mediaSnack(
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

  Iterable<MediaBookingRequest> _filteredRequests(
    MediaEquipmentDemoStore store,
  ) {
    final lower = _query.trim().toLowerCase();
    return MediaEquipmentDemoData.requests.where((request) {
      final status = store.requestStatus(request);
      final matchesFilter = switch (store.requestFilter) {
        'Urgent' => status == MediaBookingStatus.requestReceived,
        'Negotiation' => status == MediaBookingStatus.underNegotiation,
        'Secured' => status == MediaBookingStatus.secured ||
            status == MediaBookingStatus.contractPending,
        _ => true,
      };
      final haystack =
          '${request.project} ${request.producer} ${request.items} ${request.city}'
              .toLowerCase();
      return matchesFilter && haystack.contains(lower);
    });
  }

  void _showDetails(BuildContext context, MediaBookingRequest request) {
    showMediaSheet(
      context,
      title: request.project,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MediaInfoRow(
            icon: Icons.business_outlined,
            label: 'Producer',
            value: request.producer,
          ),
          MediaInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Dates',
            value: request.dates,
          ),
          MediaInfoRow(
            icon: Icons.videocam_outlined,
            label: 'Items',
            value: request.items,
          ),
          MediaInfoRow(
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
    MediaEquipmentDemoStore store,
    MediaBookingRequest request,
  ) {
    showMediaSheet(
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
                    mediaSnack(context, 'Request rejected');
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
        hintText: 'Search projects, producers, serials...',
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
  final MediaBookingRequest request;
  final MediaBookingStatus status;
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
    final actionable = status == MediaBookingStatus.requestReceived ||
        status == MediaBookingStatus.underNegotiation;
    return GlassSectionCard(
      radius: 20,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MediaFrame(
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
              MediaBookingStatusChip(status: status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${request.producer} - ${request.dates} - ${request.budget}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            request.items,
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
