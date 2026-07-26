import 'package:flutter/material.dart';

import '../../core/core_ui/widgets/core_widgets.dart';
import '../../core/scheduling/meeting_models.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/actor_talent/models/actor_talent_models.dart';
import '../../features/actor_talent/widgets/actor_casting_widgets.dart';
import '../../features/actor_talent/widgets/actor_talent_components.dart';

/// Shared audition / site-visit / viewing / interview scheduling panel —
/// one widget reused by the actor-side application detail screen, the
/// director-side casting and opportunity application review cards, and the
/// provider-side opportunity application detail screen. Supports full
/// back-and-forth negotiation: either side can propose, counter-propose,
/// accept or decline a meeting time/location.
class MeetingNegotiationPanel extends StatelessWidget {
  final MeetingThread? thread;
  final String meetingLabel;
  final String currentUserId;
  final bool working;
  final Future<void> Function({
    required DateTime meetingAt,
    String? location,
    String? onlineUrl,
    String? instructions,
    String? contact,
    String? message,
  }) onPropose;
  final Future<void> Function(String roundPublicId) onAccept;
  final Future<void> Function(String roundPublicId, String? reason) onDecline;

  const MeetingNegotiationPanel({
    super.key,
    required this.thread,
    required this.meetingLabel,
    required this.currentUserId,
    required this.working,
    required this.onPropose,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final currentRound = thread?.currentRound;
    final isMine = currentRound?.proposedBy.publicId == currentUserId;
    final canRespond = currentRound != null && currentRound.isPending && !isMine;
    return ActorSectionCard(
      title: meetingLabel,
      icon: Icons.event_available_outlined,
      tone: ActorTone.blue,
      selected: currentRound == null || currentRound.isPending,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (currentRound == null)
            Text(
              'No $meetingLabel proposed yet.',
              style: AppTextStyles.smallMeta.copyWith(
                color: context.appColors.textSecondary,
              ),
            )
          else ...[
            ActorInfoRow(
              icon: Icons.schedule_outlined,
              label: 'Date and time',
              value: actorCastingDate(currentRound.meetingAt),
            ),
            ActorInfoRow(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: currentRound.location ??
                  currentRound.onlineUrl ??
                  'Not specified',
            ),
            if ((currentRound.instructions ?? '').isNotEmpty)
              ActorInfoRow(
                icon: Icons.assignment_outlined,
                label: 'Instructions',
                value: currentRound.instructions!,
              ),
            if ((currentRound.contact ?? '').isNotEmpty)
              ActorInfoRow(
                icon: Icons.contact_mail_outlined,
                label: 'Contact',
                value: currentRound.contact!,
              ),
            ActorInfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Proposed by',
              value: isMine ? 'You' : currentRound.proposedBy.displayName,
            ),
            const SizedBox(height: 8),
            if (thread!.isAccepted)
              const InlineNotice(
                message: 'Meeting confirmed',
                tone: CoreStatusTone.success,
              )
            else if (currentRound.status == 'declined')
              InlineNotice(
                message: currentRound.declineReason?.isNotEmpty == true
                    ? 'Declined: ${currentRound.declineReason}'
                    : 'Proposal declined',
                tone: CoreStatusTone.warning,
              )
            else if (isMine)
              const InlineNotice(
                message: 'Waiting for a response',
                tone: CoreStatusTone.info,
              ),
            if (canRespond) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CorePrimaryButton(
                      icon: Icons.check_circle_outline,
                      label: 'Accept',
                      compact: true,
                      loading: working,
                      onTap: working
                          ? null
                          : () => onAccept(currentRound.publicId),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CoreSecondaryButton(
                      icon: Icons.block_outlined,
                      label: 'Decline',
                      compact: true,
                      onTap: working
                          ? null
                          : () => _showDeclineDialog(context, currentRound),
                    ),
                  ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 10),
          CoreSecondaryButton(
            icon: Icons.edit_calendar_outlined,
            label: currentRound == null ? 'Propose a time' : 'Propose new time',
            compact: true,
            onTap: working ? null : () => _showProposeDialog(context),
          ),
          if (thread != null && thread!.rounds.length > 1) ...[
            const SizedBox(height: 12),
            _MeetingHistory(rounds: thread!.rounds, currentUserId: currentUserId),
          ],
        ],
      ),
    );
  }

  Future<void> _showProposeDialog(BuildContext context) async {
    final result = await showDialog<_ProposedMeeting>(
      context: context,
      builder: (_) => const _ProposeMeetingDialog(),
    );
    if (result == null || !context.mounted) return;
    await onPropose(
      meetingAt: result.meetingAt,
      location: result.location,
      onlineUrl: result.onlineUrl,
      instructions: result.instructions,
      contact: result.contact,
      message: result.message,
    );
  }

  Future<void> _showDeclineDialog(
    BuildContext context,
    MeetingRound round,
  ) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Decline this proposal?'),
        content: CoreTextField(
          controller: reasonController,
          label: 'Reason (optional)',
          icon: Icons.notes_outlined,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final reason = reasonController.text.trim();
    await onDecline(round.publicId, reason.isEmpty ? null : reason);
  }
}

class _ProposedMeeting {
  final DateTime meetingAt;
  final String? location;
  final String? onlineUrl;
  final String? instructions;
  final String? contact;
  final String? message;

  const _ProposedMeeting({
    required this.meetingAt,
    required this.location,
    required this.onlineUrl,
    required this.instructions,
    required this.contact,
    required this.message,
  });
}

class _ProposeMeetingDialog extends StatefulWidget {
  const _ProposeMeetingDialog();

  @override
  State<_ProposeMeetingDialog> createState() => _ProposeMeetingDialogState();
}

class _ProposeMeetingDialogState extends State<_ProposeMeetingDialog> {
  final _date = TextEditingController();
  final _location = TextEditingController();
  final _onlineUrl = TextEditingController();
  final _instructions = TextEditingController();
  final _contact = TextEditingController();
  final _message = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _date.dispose();
    _location.dispose();
    _onlineUrl.dispose();
    _instructions.dispose();
    _contact.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Propose a meeting time'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CoreTextField(
                controller: _date,
                label: 'Date and time (ISO)',
                icon: Icons.schedule_outlined,
                keyboardType: TextInputType.datetime,
                errorText: _error,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: _location,
                label: 'Location',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: _onlineUrl,
                label: 'Online meeting link',
                icon: Icons.link_outlined,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: _instructions,
                label: 'Instructions',
                icon: Icons.assignment_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: _contact,
                label: 'Contact details',
                icon: Icons.contact_mail_outlined,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: _message,
                label: 'Note (optional)',
                icon: Icons.chat_bubble_outline,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final parsed = DateTime.tryParse(_date.text.trim());
            if (parsed == null) {
              setState(() => _error = 'Enter a valid ISO date and time');
              return;
            }
            Navigator.pop(
              context,
              _ProposedMeeting(
                meetingAt: parsed,
                location: _location.text.trim().isEmpty
                    ? null
                    : _location.text.trim(),
                onlineUrl: _onlineUrl.text.trim().isEmpty
                    ? null
                    : _onlineUrl.text.trim(),
                instructions: _instructions.text.trim().isEmpty
                    ? null
                    : _instructions.text.trim(),
                contact:
                    _contact.text.trim().isEmpty ? null : _contact.text.trim(),
                message:
                    _message.text.trim().isEmpty ? null : _message.text.trim(),
              ),
            );
          },
          child: const Text('Send proposal'),
        ),
      ],
    );
  }
}

class _MeetingHistory extends StatelessWidget {
  final List<MeetingRound> rounds;
  final String currentUserId;

  const _MeetingHistory({required this.rounds, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ordered = [...rounds]
      ..sort((a, b) => b.roundNumber.compareTo(a.roundNumber));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Proposal history',
          style: AppTextStyles.cardLabel.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        for (final round in ordered)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  switch (round.status) {
                    'accepted' => Icons.check_circle_outline,
                    'declined' => Icons.block_outlined,
                    'superseded' => Icons.history_outlined,
                    _ => Icons.hourglass_top_rounded,
                  },
                  size: 16,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${round.proposedBy.publicId == currentUserId ? 'You' : round.proposedBy.displayName} '
                    'proposed ${actorCastingDate(round.meetingAt)} '
                    '(${actorCastingTitleCase(round.status)})',
                    style: AppTextStyles.smallMeta.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
