import 'package:flutter/material.dart';

import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/director_producer_demo_data.dart';
import '../models/dp_negotiation.dart';
import '../widgets/dp_empty_state.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';
import 'dp_negotiation_thread_screen.dart';

const _filterKeys = ['All', 'Your move', 'Replied', 'Locked', 'Closed'];

DpTone _filterTone(String key) {
  return switch (key) {
    'Your move' => DpTone.warning,
    'Replied' => DpTone.info,
    'Locked' => DpTone.success,
    _ => DpTone.neutral,
  };
}

String _demoFilterKey(DpNegotiation negotiation) {
  return switch (negotiation.status) {
    'Your move' || 'Expiring' => 'Your move',
    'Their move' => 'Replied',
    'Accepted' => 'Locked',
    'Withdrawn' => 'Closed',
    _ => 'All',
  };
}

String _liveFilterKey(String status) {
  return switch (status) {
    'accepted' => 'Locked',
    'rejected' => 'Closed',
    _ => 'Your move',
  };
}

/// Presents the full negotiation thread (rounds, counter-offer form,
/// accept, chat) as a tall bottom sheet instead of a page navigation —
/// same real API/demo-fallback logic, just a different presentation.
void openNegotiationSheet(BuildContext context, String? negotiationId) {
  final colors = context.appColors;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: colors.border,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                child: DPNegotiationThreadScreen(
                  negotiationId: negotiationId,
                  onClose: () => Navigator.pop(sheetContext),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class DPBargainingCenterScreen extends StatefulWidget {
  const DPBargainingCenterScreen({super.key});

  @override
  State<DPBargainingCenterScreen> createState() =>
      _DPBargainingCenterScreenState();
}

class _DPBargainingCenterScreenState extends State<DPBargainingCenterScreen> {
  late Future<List<NegotiationThread>> _future;
  String _filter = 'All';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future = BookingsScope.of(context).negotiations();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NegotiationThread>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const DPEmptyState(
            icon: Icons.hourglass_top_rounded,
            title: 'Loading negotiations',
            message: 'Fetching live booking threads.',
          );
        }
        if (snapshot.hasError) {
          return _DemoNegotiations(filter: _filter, onFilter: _setFilter);
        }
        final all = snapshot.data ?? const [];
        if (all.isEmpty) {
          return const DPEmptyState(
            icon: Icons.forum_outlined,
            title: 'No negotiations yet',
            message: 'Send a booking request to start a bargaining thread.',
          );
        }
        final negotiations = _filter == 'All'
            ? all
            : all.where((n) => _liveFilterKey(n.status) == _filter).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BargainingHeader(count: all.length),
            const SizedBox(height: 12),
            _FilterRow(value: _filter, onChanged: _setFilter),
            const SizedBox(height: 12),
            DPResponsiveGrid(
              minWidth: 300,
              children: negotiations
                  .map(
                    (negotiation) => _NegotiationCard(
                      title: negotiation.booking.provider.displayName,
                      project: 'Project ${negotiation.booking.projectId}',
                      subtitle: negotiation.booking.category,
                      rate: negotiation.currentOffer?.feeLabel ?? 'Rate TBD',
                      status: _statusLabel(negotiation.status),
                      tone: _filterTone(_liveFilterKey(negotiation.status)),
                      expiry: negotiation.currentOffer?.expiresAt == null
                          ? null
                          : 'Expiring',
                      onTap: () =>
                          openNegotiationSheet(context, negotiation.publicId),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  void _setFilter(String filter) => setState(() => _filter = filter);

  String _statusLabel(String status) {
    return switch (status) {
      'accepted' => 'Accepted',
      'rejected' => 'Rejected',
      _ => 'Open',
    };
  }
}

class _BargainingHeader extends StatelessWidget {
  final int count;

  const _BargainingHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return DPPageHeader(
      eyebrow: '$count open negotiations',
      title: 'Bargaining',
      actionLabel: 'Find Talent',
      actionIcon: Icons.manage_search_rounded,
      onActionTap: () =>
          Navigator.pushNamed(context, DirectorProducerRoutes.marketplace),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _FilterRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final key in _filterKeys) ...[
            DpDotChip(
              label: key,
              active: value == key,
              onTap: () => onChanged(key),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _DemoNegotiations extends StatelessWidget {
  final String filter;
  final ValueChanged<String> onFilter;

  const _DemoNegotiations({required this.filter, required this.onFilter});

  @override
  Widget build(BuildContext context) {
    final all = DirectorProducerDemoData.negotiations;
    final negotiations = filter == 'All'
        ? all
        : all.where((n) => _demoFilterKey(n) == filter).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BargainingHeader(count: all.length),
        const SizedBox(height: 12),
        _FilterRow(value: filter, onChanged: onFilter),
        const SizedBox(height: 12),
        DPSectionCard(
          title: 'Preview mode',
          icon: Icons.info_outline_rounded,
          child: dpText(
            context,
            'Live negotiations unavailable — showing preview threads.',
          ),
        ),
        const SizedBox(height: 12),
        DPResponsiveGrid(
          minWidth: 300,
          children: negotiations
              .map(
                (negotiation) => _NegotiationCard(
                  title: negotiation.candidate,
                  project: negotiation.project,
                  subtitle: negotiation.requirement,
                  rate: negotiation.currentRate,
                  status: negotiation.status,
                  tone: _filterTone(_demoFilterKey(negotiation)),
                  expiry: negotiation.expiry == 'Locked' ||
                          negotiation.expiry == 'Closed'
                      ? null
                      : negotiation.expiry,
                  onTap: () => openNegotiationSheet(context, negotiation.id),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _NegotiationCard extends StatelessWidget {
  final String title;
  final String project;
  final String subtitle;
  final String rate;
  final String status;
  final DpTone tone;
  final String? expiry;
  final VoidCallback onTap;

  const _NegotiationCard({
    required this.title,
    required this.project,
    required this.subtitle,
    required this.rate,
    required this.status,
    required this.tone,
    required this.expiry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      accentColor: dpToneColor(context, tone),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle
                      .copyWith(color: colors.textPrimary, fontSize: 15.5),
                ),
              ),
              const SizedBox(width: 8),
              DPStatusChip(label: status, tone: tone),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '$project · $subtitle',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Text(
                rate,
                style: AppTextStyles.metricNumberCompact
                    .copyWith(color: colors.textPrimary),
              ),
              const Spacer(),
              if (expiry != null)
                DPStatusChip(label: expiry!, tone: DpTone.warning),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: const Text('Open Negotiation'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textPrimary,
                side: BorderSide(color: colors.border),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
