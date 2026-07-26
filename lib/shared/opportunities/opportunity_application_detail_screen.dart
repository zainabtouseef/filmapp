import 'package:flutter/material.dart';

import '../../core/core_ui/widgets/core_widgets.dart';
import '../../core/network/api_exception.dart';
import '../../core/opportunities/opportunities_controller.dart';
import '../../core/opportunities/opportunities_models.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/actor_talent/models/actor_talent_models.dart';
import '../../features/actor_talent/widgets/actor_casting_widgets.dart';
import '../../features/actor_talent/widgets/actor_talent_components.dart';
import '../cards/cine_card_system.dart';
import '../scheduling/meeting_negotiation_panel.dart';

String _meetingLabelForCategory(String category) {
  return switch (category) {
    'model' => 'Meeting',
    'location' => 'Site Visit',
    'equipment' => 'Viewing',
    'crew' => 'Interview',
    _ => 'Meeting',
  };
}

/// Provider-side single-application view — shared by the Model, Location
/// Owner, Media/Equipment and Crew Services portals. Mirrors the
/// Actor/Talent AT15 application detail screen (role summary, cover note,
/// embedded meeting negotiation, status timeline, withdraw control).
class OpportunityApplicationDetailScreen extends StatefulWidget {
  final String? applicationId;

  const OpportunityApplicationDetailScreen({super.key, this.applicationId});

  @override
  State<OpportunityApplicationDetailScreen> createState() =>
      _OpportunityApplicationDetailScreenState();
}

class _OpportunityApplicationDetailScreenState
    extends State<OpportunityApplicationDetailScreen> {
  Future<OpportunityApplication>? _future;
  bool _working = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<OpportunityApplication> _load() {
    final id = widget.applicationId;
    final controller = OpportunitiesScope.maybeOf(context);
    if (id == null || id.isEmpty || controller == null) {
      return Future<OpportunityApplication>.error(
        const ApiException(
          code: 'opportunities.application_missing',
          message: 'Open this screen from your application tracker.',
        ),
      );
    }
    return controller.application(id);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OpportunityApplication>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonCard(height: 600);
        }
        if (snapshot.hasError || snapshot.data == null) {
          return CoreEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Application unavailable',
            message: snapshot.error is ApiException
                ? (snapshot.error! as ApiException).message
                : 'Could not load this application.',
            actionLabel: 'Try again',
            onAction: _reload,
          );
        }
        final application = snapshot.data!;
        final meetingLabel =
            _meetingLabelForCategory(application.role.category);
        final canWithdraw = !const {'selected', 'rejected', 'withdrawn'}
            .contains(application.status);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OpportunityApplicationHeader(application: application),
            const SizedBox(height: 12),
            ActorTwoColumn(
              left: Column(
                children: [
                  _OpportunityApplicationSummary(application: application),
                  const SizedBox(height: 12),
                  MeetingNegotiationPanel(
                    thread: application.meetingThread,
                    meetingLabel: meetingLabel,
                    currentUserId: application.applicant.publicId,
                    working: _working,
                    onPropose: ({
                      required meetingAt,
                      location,
                      onlineUrl,
                      instructions,
                      contact,
                      message,
                    }) =>
                        _proposeMeeting(
                      application,
                      meetingAt: meetingAt,
                      location: location,
                      onlineUrl: onlineUrl,
                      instructions: instructions,
                      contact: contact,
                      message: message,
                    ),
                    onAccept: (roundId) =>
                        _acceptMeeting(application, roundId),
                    onDecline: (roundId, reason) =>
                        _declineMeeting(application, roundId, reason),
                  ),
                  const SizedBox(height: 12),
                  _OpportunityStatusTimeline(application: application),
                ],
              ),
              right: Column(
                children: [
                  if (canWithdraw)
                    ActorSectionCard(
                      title: 'Application Controls',
                      icon: Icons.tune_outlined,
                      tone: ActorTone.danger,
                      child: CoreSecondaryButton(
                        icon: Icons.undo_rounded,
                        label: 'Withdraw application',
                        onTap: _working ? null : () => _withdraw(application),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _proposeMeeting(
    OpportunityApplication application, {
    required DateTime meetingAt,
    String? location,
    String? onlineUrl,
    String? instructions,
    String? contact,
    String? message,
  }) async {
    final opportunities = OpportunitiesScope.maybeOf(context);
    if (opportunities == null) return;
    setState(() => _working = true);
    try {
      await opportunities.proposeMeeting(application.publicId, {
        'meeting_at': meetingAt.toUtc().toIso8601String(),
        if (location != null) 'location': location,
        if (onlineUrl != null) 'online_url': onlineUrl,
        if (instructions != null) 'instructions': instructions,
        if (contact != null) 'contact': contact,
        if (message != null) 'message': message,
      });
      if (!mounted) return;
      actorSnack(context, 'Meeting proposal sent');
      _reload();
    } on ApiException catch (error) {
      if (mounted) actorSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _acceptMeeting(
    OpportunityApplication application,
    String roundId,
  ) async {
    final opportunities = OpportunitiesScope.maybeOf(context);
    if (opportunities == null) return;
    setState(() => _working = true);
    try {
      await opportunities.acceptMeetingRound(application.publicId, roundId);
      if (!mounted) return;
      actorSnack(context, 'Meeting confirmed');
      _reload();
    } on ApiException catch (error) {
      if (mounted) actorSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _declineMeeting(
    OpportunityApplication application,
    String roundId,
    String? reason,
  ) async {
    final opportunities = OpportunitiesScope.maybeOf(context);
    if (opportunities == null) return;
    setState(() => _working = true);
    try {
      await opportunities.declineMeetingRound(
        application.publicId,
        roundId,
        reason: reason,
      );
      if (!mounted) return;
      actorSnack(context, 'Meeting proposal declined');
      _reload();
    } on ApiException catch (error) {
      if (mounted) actorSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _withdraw(OpportunityApplication application) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Withdraw application?'),
            content: const Text(
              'The production will see that you withdrew. This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Keep application'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Withdraw'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    final opportunities = OpportunitiesScope.maybeOf(context);
    if (opportunities == null) return;
    setState(() => _working = true);
    try {
      await opportunities.withdrawApplication(application.publicId);
      if (!mounted) return;
      actorSnack(context, 'Application withdrawn');
      _reload();
    } on ApiException catch (error) {
      if (mounted) actorSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }
}

class _OpportunityApplicationHeader extends StatelessWidget {
  final OpportunityApplication application;

  const _OpportunityApplicationHeader({required this.application});

  @override
  Widget build(BuildContext context) {
    return ActorSectionCard(
      title: application.role.title,
      icon: Icons.assignment_turned_in_outlined,
      selected: true,
      tone: ActorTone.purple,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  application.role.project.title,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: context.appColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  application.role.project.ownerName,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Chip(
            avatar: Icon(
              Icons.circle,
              size: 10,
              color: actorCastingStatusColor(context, application.status),
            ),
            label: Text(application.statusLabel),
          ),
        ],
      ),
    );
  }
}

class _OpportunityApplicationSummary extends StatelessWidget {
  final OpportunityApplication application;

  const _OpportunityApplicationSummary({required this.application});

  @override
  Widget build(BuildContext context) {
    return ActorSectionCard(
      title: 'Your Submission',
      icon: Icons.description_outlined,
      child: Column(
        children: [
          ActorInfoRow(
            icon: Icons.notes_outlined,
            label: 'Cover note',
            value: application.coverNote?.isNotEmpty == true
                ? application.coverNote!
                : 'No cover note added',
          ),
          ActorInfoRow(
            icon: Icons.attach_file_outlined,
            label: 'Attachments',
            value:
                '${application.attachmentFiles.length} file${application.attachmentFiles.length == 1 ? '' : 's'} attached',
          ),
          if ((application.rejectionReason ?? '').isNotEmpty)
            ActorInfoRow(
              icon: Icons.info_outline,
              label: 'Reason',
              value: application.rejectionReason!,
            ),
        ],
      ),
    );
  }
}

class _OpportunityStatusTimeline extends StatelessWidget {
  final OpportunityApplication application;

  const _OpportunityStatusTimeline({required this.application});

  @override
  Widget build(BuildContext context) {
    return ActorSectionCard(
      title: 'Status History',
      icon: Icons.timeline_outlined,
      child: application.statusEvents.isEmpty
          ? const CoreEmptyState(
              icon: Icons.history_toggle_off_outlined,
              title: 'No status changes yet',
              message: 'Updates from the production will appear here.',
            )
          : Column(
              children: [
                for (var index = 0;
                    index < application.statusEvents.length;
                    index++)
                  _OpportunityTimelineRow(
                    event: application.statusEvents[index],
                    last: index == application.statusEvents.length - 1,
                  ),
              ],
            ),
    );
  }
}

class _OpportunityTimelineRow extends StatelessWidget {
  final OpportunityStatusEvent event;
  final bool last;

  const _OpportunityTimelineRow({required this.event, required this.last});

  @override
  Widget build(BuildContext context) {
    final color = actorCastingStatusColor(context, event.toStatus);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!last)
                  Expanded(
                    child:
                        Container(width: 1, color: color.withValues(alpha: .4)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    actorCastingTitleCase(event.toStatus),
                    style: AppTextStyles.cardLabel.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    actorCastingDate(event.createdAt),
                    style: AppTextStyles.smallMeta.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                  if (event.note?.isNotEmpty == true) ...[
                    const SizedBox(height: 3),
                    Text(event.note!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
