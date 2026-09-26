import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/projects/projects_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/tour/tour_target.dart';
import '../../../shared/widgets/cine_animated_filter_rail.dart';
import '../../../shared/cards/cine_card_system.dart';
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

String _liveFilterKey(NegotiationThread negotiation, String? currentUserId) {
  return switch (negotiation.status) {
    'accepted' => 'Locked',
    'rejected' => 'Closed',
    _ => negotiation.currentOffer?.recipient.publicId == currentUserId
        ? 'Your move'
        : 'Replied',
  };
}

String? _expiryLabel(DateTime? expiresAt) {
  if (expiresAt == null) return null;
  final remaining = expiresAt.difference(DateTime.now());
  if (remaining.isNegative) return 'Expired';
  if (remaining.inHours < 1) {
    return 'Expires in ${remaining.inMinutes.clamp(1, 59)}m';
  }
  if (remaining.inDays < 1) return 'Expires in ${remaining.inHours}h';
  return 'Expires in ${remaining.inDays}d';
}

String _lastActivityLabel(DateTime? value) {
  if (value == null) return 'Activity time unavailable';
  final elapsed = DateTime.now().difference(value);
  if (elapsed.inMinutes < 1) return 'Updated now';
  if (elapsed.inHours < 1) return 'Updated ${elapsed.inMinutes}m ago';
  if (elapsed.inDays < 1) return 'Updated ${elapsed.inHours}h ago';
  return 'Updated ${elapsed.inDays}d ago';
}

/// Presents the full negotiation thread (rounds, counter-offer form,
/// accept, chat) as a tall bottom sheet instead of a page navigation —
/// same live API logic, just a different presentation.
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
  Future<List<NegotiationThread>>? _future;
  String _filter = 'All';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= BookingsScope.maybeOf(context)?.negotiations();
    // Populates the projects cache (if not already loaded) so negotiation
    // cards can resolve a real project title instead of a raw project ID.
    ProjectsScope.maybeOf(context)?.projects();
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    final projectTitles = {
      for (final project
          in ProjectsScope.maybeOf(context)?.cachedProjects ?? const [])
        project.publicId: project.title,
    };
    final currentUserId = AuthScope.maybeOf(context)?.user?.publicId;
    if (future == null) {
      return const CoreEmptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Sign in required',
        message: 'Connect a live Director account to view bargaining threads.',
      );
    }
    return FutureBuilder<List<NegotiationThread>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Column(
            children: [
              SkeletonCard(height: 72),
              SizedBox(height: 12),
              SkeletonCard(height: 180),
              SizedBox(height: 12),
              SkeletonCard(height: 180),
            ],
          );
        }
        if (snapshot.hasError) {
          return CoreEmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Negotiations unavailable',
            message:
                'Could not load live booking threads from the database. Check the API connection and try again.',
            actionLabel: 'Retry',
            onAction: _reload,
          );
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
            : all
                .where((n) => _liveFilterKey(n, currentUserId) == _filter)
                .toList();
        if (negotiations.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BargainingHeader(count: all.length),
              const SizedBox(height: 12),
              _FilterRow(value: _filter, onChanged: _setFilter),
              const SizedBox(height: 12),
              CoreEmptyState(
                icon: Icons.filter_alt_off_rounded,
                title: 'No $_filter negotiations',
                message:
                    'This filter has no live database records right now. Switch filters or send a new booking request.',
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BargainingHeader(count: all.length),
            const SizedBox(height: 12),
            _FilterRow(value: _filter, onChanged: _setFilter),
            const SizedBox(height: 12),
            TourTarget(
              id: 'dp.bargaining.list',
              child: DPResponsiveGrid(
                minWidth: 300,
                children: negotiations.indexed.map((entry) {
                  final (index, negotiation) = entry;
                  final state = _liveFilterKey(negotiation, currentUserId);
                  final card = _NegotiationCard(
                    title: negotiation.booking.provider.displayName,
                    project: projectTitles[negotiation.booking.projectId] ??
                        'Project ${negotiation.booking.projectId}',
                    subtitle: negotiation.booking.category,
                    rate: negotiation.currentOffer?.feeLabel ?? 'Rate TBD',
                    status: _statusLabel(negotiation.status, state),
                    tone: _filterTone(state),
                    turn: state == 'Your move'
                        ? 'Your response is required'
                        : state == 'Replied'
                            ? 'Waiting for ${negotiation.booking.provider.displayName}'
                            : state,
                    expiry: _expiryLabel(negotiation.currentOffer?.expiresAt),
                    lastActivity: _lastActivityLabel(
                      negotiation.currentOffer?.createdAt,
                    ),
                    wrapOpenButton: index == 0,
                    onTap: () =>
                        openNegotiationSheet(context, negotiation.publicId),
                  );
                  return index == 0
                      ? TourTarget(id: 'dp.bargaining.firstCard', child: card)
                      : card;
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  void _setFilter(String filter) => setState(() => _filter = filter);

  void _reload() {
    final bookings = BookingsScope.maybeOf(context);
    if (bookings == null) return;
    setState(() => _future = bookings.negotiations());
  }

  String _statusLabel(String status, String state) {
    return switch (status) {
      'accepted' => 'Accepted',
      'rejected' => 'Rejected',
      _ => state,
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
    return CineAnimatedFilterRail<String>(
      values: _filterKeys,
      selected: value,
      onSelected: onChanged,
      labelFor: (key) => key,
    );
  }
}

class _NegotiationCard extends StatelessWidget {
  final String title;
  final String project;
  final String subtitle;
  final String rate;
  final String status;
  final String turn;
  final String lastActivity;
  final DpTone tone;
  final String? expiry;
  final VoidCallback onTap;
  final bool wrapOpenButton;

  const _NegotiationCard({
    required this.title,
    required this.project,
    required this.subtitle,
    required this.rate,
    required this.status,
    required this.turn,
    required this.lastActivity,
    required this.tone,
    required this.expiry,
    required this.onTap,
    this.wrapOpenButton = false,
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
          Text(
            '$turn · $lastActivity',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color:
                  status == 'Your move' ? colors.goldDark : colors.textTertiary,
              fontWeight:
                  status == 'Your move' ? FontWeight.w800 : FontWeight.w600,
            ),
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
          _buildOpenButton(colors),
        ],
      ),
    );
  }

  Widget _buildOpenButton(CineThemeColors colors) {
    final button = SizedBox(
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
    );
    return wrapOpenButton
        ? TourTarget(id: 'dp.bargaining.open', child: button)
        : button;
  }
}
