import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/casting/casting_controller.dart';
import '../../../core/casting/casting_models.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/marketplace/marketplace_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/open_url.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/uploads/upload_repository.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/scheduling/meeting_negotiation_panel.dart';
import '../models/actor_talent_models.dart';
import '../routes/actor_talent_routes.dart';
import '../widgets/actor_casting_widgets.dart';
import '../widgets/actor_talent_components.dart';

class AT15ApplicationDetailScreen extends StatefulWidget {
  final String? applicationId;

  const AT15ApplicationDetailScreen({
    super.key,
    this.applicationId,
  });

  @override
  State<AT15ApplicationDetailScreen> createState() =>
      _AT15ApplicationDetailScreenState();
}

class _AT15ApplicationDetailScreenState
    extends State<AT15ApplicationDetailScreen> {
  Future<CastingApplication>? _future;
  bool _working = false;
  double? _uploadProgress;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<CastingApplication> _load() {
    final id = widget.applicationId;
    final controller = CastingScope.maybeOf(context);
    if (id == null || id.isEmpty || controller == null) {
      return Future<CastingApplication>.error(
        const ApiException(
          code: 'casting.application_missing',
          message: 'Open this screen from your application tracker.',
        ),
      );
    }
    return controller.application(id);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CastingApplication>(
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ApplicationHeader(application: application),
            const SizedBox(height: 12),
            ActorTwoColumn(
              left: Column(
                children: [
                  _ApplicationSummary(application: application),
                  if (application.isAudition ||
                      application.meetingThread != null) ...[
                    const SizedBox(height: 12),
                    MeetingNegotiationPanel(
                      thread: application.meetingThread,
                      meetingLabel:
                          application.status == 'callback' ? 'Callback' : 'Audition',
                      currentUserId: application.actorId,
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
                      onAccept: (roundId) => _acceptMeeting(application, roundId),
                      onDecline: (roundId, reason) =>
                          _declineMeeting(application, roundId, reason),
                    ),
                  ],
                  if (application.status == 'self_tape_requested' ||
                      application.selfTapeFile != null) ...[
                    const SizedBox(height: 12),
                    _SelfTapePanel(
                      application: application,
                      working: _working,
                      uploadProgress: _uploadProgress,
                      onUpload: () => _uploadSelfTape(application),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _StatusTimeline(application: application),
                ],
              ),
              right: Column(
                children: [
                  _NextActionPanel(
                    application: application,
                    working: _working,
                    onEdit: () => _editDraft(application),
                    onSubmit: () => _submitDraft(application),
                    onMessage: () => _openConversation(application),
                  ),
                  const SizedBox(height: 12),
                  _RoleDocuments(application: application),
                  if (application.canWithdraw) ...[
                    const SizedBox(height: 12),
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
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitDraft(CastingApplication application) async {
    final casting = CastingScope.maybeOf(context);
    if (casting == null) return;
    setState(() => _working = true);
    try {
      await casting.submitApplication(application.publicId);
      if (!mounted) return;
      actorSnack(context, 'Application submitted');
      _reload();
    } on ApiException catch (error) {
      if (mounted) actorSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _editDraft(CastingApplication application) async {
    final auth = AuthScope.maybeOf(context);
    final casting = CastingScope.maybeOf(context);
    if (auth == null ||
        !auth.isAuthenticated ||
        casting == null ||
        application.status != 'draft') {
      return;
    }
    setState(() => _working = true);
    try {
      final portfolio = await auth.portfolioItems();
      if (!mounted) return;
      final changes = await showDialog<_DraftChanges>(
        context: context,
        builder: (_) => _EditDraftDialog(
          application: application,
          portfolio: portfolio,
        ),
      );
      if (changes == null || !mounted) return;
      await casting.updateApplication(
        application.publicId,
        {
          'cover_note': changes.coverNote,
          'availability_note': changes.availabilityNote,
          'answers': changes.answers,
          'portfolio_item_ids': changes.portfolioItemIds,
        },
      );
      if (!mounted) return;
      actorSnack(context, 'Application draft updated');
      _reload();
    } on ApiException catch (error) {
      if (mounted) actorSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _proposeMeeting(
    CastingApplication application, {
    required DateTime meetingAt,
    String? location,
    String? onlineUrl,
    String? instructions,
    String? contact,
    String? message,
  }) async {
    final casting = CastingScope.maybeOf(context);
    if (casting == null) return;
    setState(() => _working = true);
    try {
      await casting.proposeMeeting(application.publicId, {
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
    CastingApplication application,
    String roundId,
  ) async {
    final casting = CastingScope.maybeOf(context);
    if (casting == null) return;
    setState(() => _working = true);
    try {
      await casting.acceptMeetingRound(application.publicId, roundId);
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
    CastingApplication application,
    String roundId,
    String? reason,
  ) async {
    final casting = CastingScope.maybeOf(context);
    if (casting == null) return;
    setState(() => _working = true);
    try {
      await casting.declineMeetingRound(
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

  Future<void> _uploadSelfTape(CastingApplication application) async {
    final auth = AuthScope.maybeOf(context);
    final casting = CastingScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated || casting == null) {
      actorSnack(context, 'Sign in to upload a self-tape');
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp4'],
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return;
    setState(() {
      _working = true;
      _uploadProgress = 0;
    });
    try {
      final uploaded = await auth.uploadFile(
        purpose: 'self_tape',
        file: PickedFileData(
          name: file.name,
          mimeType: _videoMime(file.extension),
          bytes: bytes,
        ),
        onProgress: (sent, total) {
          if (mounted && total > 0) {
            setState(() => _uploadProgress = sent / total);
          }
        },
      );
      await casting.submitSelfTape(
        application.publicId,
        uploaded.publicId,
      );
      if (!mounted) return;
      actorSnack(context, 'Self-tape submitted');
      _reload();
    } on ApiException catch (error) {
      if (mounted) actorSnack(context, error.message);
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
          _uploadProgress = null;
        });
      }
    }
  }

  Future<void> _openConversation(CastingApplication application) async {
    final casting = CastingScope.maybeOf(context);
    if (casting == null) return;
    setState(() => _working = true);
    try {
      final conversationId = application.conversationId ??
          await casting.ensureConversation(application.publicId);
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        CoreRoutes.chat,
        arguments: conversationId,
      );
    } on ApiException catch (error) {
      if (mounted) actorSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _withdraw(CastingApplication application) async {
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
    final casting = CastingScope.maybeOf(context);
    if (casting == null) return;
    setState(() => _working = true);
    try {
      await casting.withdrawApplication(application.publicId);
      if (!mounted) return;
      actorSnack(context, 'Application withdrawn');
      _reload();
    } on ApiException catch (error) {
      if (mounted) actorSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  String _videoMime(String? extension) {
    return switch (extension?.toLowerCase()) {
      'mov' => 'video/quicktime',
      'webm' => 'video/webm',
      _ => 'video/mp4',
    };
  }
}

class _ApplicationHeader extends StatelessWidget {
  final CastingApplication application;

  const _ApplicationHeader({required this.application});

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
              color: actorCastingStatusColor(
                context,
                application.status,
              ),
            ),
            label: Text(application.statusLabel),
          ),
        ],
      ),
    );
  }
}

class _ApplicationSummary extends StatelessWidget {
  final CastingApplication application;

  const _ApplicationSummary({required this.application});

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
            icon: Icons.calendar_month_outlined,
            label: 'Availability',
            value: application.availabilityNote?.isNotEmpty == true
                ? application.availabilityNote!
                : 'No availability note added',
          ),
          ActorInfoRow(
            icon: Icons.video_library_outlined,
            label: 'Portfolio media',
            value:
                '${application.portfolioItemIds.length} item${application.portfolioItemIds.length == 1 ? '' : 's'} attached',
          ),
          if (application.selfTapeFile != null) ...[
            ActorInfoRow(
              icon: Icons.video_camera_front_outlined,
              label: 'Self-tape',
              value: application.selfTapeFile!.originalName,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final file = application.selfTapeFile!;
                  final auth = AuthScope.maybeOf(context);
                  if (auth == null) return;
                  try {
                    final url = await auth.authorizedDownloadUrl(file.publicId);
                    openUrlInNewTab(url);
                  } on ApiException catch (error) {
                    if (context.mounted) actorSnack(context, error.message);
                  }
                },
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: const Text('Open attached self-tape'),
              ),
            ),
          ],
          for (final answer in application.answers.entries)
            ActorInfoRow(
              icon: Icons.question_answer_outlined,
              label: answer.key,
              value: answer.value,
            ),
        ],
      ),
    );
  }
}

class _SelfTapePanel extends StatelessWidget {
  final CastingApplication application;
  final bool working;
  final double? uploadProgress;
  final VoidCallback onUpload;

  const _SelfTapePanel({
    required this.application,
    required this.working,
    required this.uploadProgress,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return ActorSectionCard(
      title: 'Self-Tape',
      icon: Icons.video_camera_front_outlined,
      tone: ActorTone.blue,
      selected: application.selfTapeFile == null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (uploadProgress != null) ...[
            LinearProgressIndicator(value: uploadProgress),
            const SizedBox(height: 6),
            Text('${(uploadProgress! * 100).round()}% uploaded'),
          ] else if (application.selfTapeFile == null)
            CoreSecondaryButton(
              icon: Icons.upload_rounded,
              label: 'Upload self-tape',
              onTap: working ? null : onUpload,
            )
          else
            InlineNotice(
              message:
                  'Self-tape submitted: ${application.selfTapeFile!.originalName}',
              tone: CoreStatusTone.success,
            ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final CastingApplication application;

  const _StatusTimeline({required this.application});

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
                  _TimelineRow(
                    event: application.statusEvents[index],
                    last: index == application.statusEvents.length - 1,
                  ),
              ],
            ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final CastingApplicationEvent event;
  final bool last;

  const _TimelineRow({required this.event, required this.last});

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
                    [
                      if (event.changedBy != null) event.changedBy!,
                      actorCastingDate(event.createdAt),
                    ].join(' · '),
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

class _DraftChanges {
  final String coverNote;
  final String availabilityNote;
  final Map<String, String> answers;
  final List<String> portfolioItemIds;

  const _DraftChanges({
    required this.coverNote,
    required this.availabilityNote,
    required this.answers,
    required this.portfolioItemIds,
  });
}

class _EditDraftDialog extends StatefulWidget {
  final CastingApplication application;
  final List<MarketplacePortfolioItem> portfolio;

  const _EditDraftDialog({
    required this.application,
    required this.portfolio,
  });

  @override
  State<_EditDraftDialog> createState() => _EditDraftDialogState();
}

class _EditDraftDialogState extends State<_EditDraftDialog> {
  late final TextEditingController _coverNote;
  late final TextEditingController _availability;
  late final Map<String, TextEditingController> _answers;
  late final Set<String> _selectedPortfolio;

  @override
  void initState() {
    super.initState();
    _coverNote = TextEditingController(
      text: widget.application.coverNote ?? '',
    );
    _availability = TextEditingController(
      text: widget.application.availabilityNote ?? '',
    );
    _answers = {
      for (final question in widget.application.role.castingQuestions)
        question: TextEditingController(
          text: widget.application.answers[question] ?? '',
        ),
    };
    _selectedPortfolio = widget.application.portfolioItemIds.toSet();
  }

  @override
  void dispose() {
    _coverNote.dispose();
    _availability.dispose();
    for (final controller in _answers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    Navigator.pop(
      context,
      _DraftChanges(
        coverNote: _coverNote.text.trim(),
        availabilityNote: _availability.text.trim(),
        answers: {
          for (final entry in _answers.entries)
            entry.key: entry.value.text.trim(),
        },
        portfolioItemIds: _selectedPortfolio.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final published =
        widget.portfolio.where((item) => item.status == 'published').toList();
    return AlertDialog(
      title: const Text('Edit application draft'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CoreTextField(
                controller: _coverNote,
                label: 'Why are you right for this role?',
                icon: Icons.notes_rounded,
                maxLines: 4,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: _availability,
                label: 'Availability and travel notes',
                icon: Icons.calendar_month_outlined,
                maxLines: 3,
              ),
              for (final entry in _answers.entries) ...[
                const SizedBox(height: 10),
                CoreTextField(
                  controller: entry.value,
                  label: entry.key,
                  icon: Icons.question_answer_outlined,
                  maxLines: 3,
                ),
              ],
              if (published.isNotEmpty) ...[
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Portfolio media',
                    style: AppTextStyles.cardLabel.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                for (final item in published)
                  CheckboxListTile(
                    value: _selectedPortfolio.contains(item.publicId),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(item.title),
                    subtitle: Text(item.displayCategory),
                    onChanged: (selected) {
                      setState(() {
                        if (selected ?? false) {
                          _selectedPortfolio.add(item.publicId);
                        } else {
                          _selectedPortfolio.remove(item.publicId);
                        }
                      });
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save draft'),
        ),
      ],
    );
  }
}

class _NextActionPanel extends StatelessWidget {
  final CastingApplication application;
  final bool working;
  final VoidCallback onEdit;
  final VoidCallback onSubmit;
  final VoidCallback onMessage;

  const _NextActionPanel({
    required this.application,
    required this.working,
    required this.onEdit,
    required this.onSubmit,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return ActorSectionCard(
      title: 'Next Action',
      icon: Icons.bolt_outlined,
      selected: true,
      child: Column(
        children: [
          ActorInfoRow(
            icon: Icons.info_outline_rounded,
            label: application.statusLabel,
            value: _message,
          ),
          const SizedBox(height: 10),
          if (application.status == 'draft') ...[
            CorePrimaryButton(
              icon: Icons.send_rounded,
              label: 'Submit application',
              loading: working,
              onTap: working ? null : onSubmit,
            ),
            const SizedBox(height: 8),
            CoreSecondaryButton(
              icon: Icons.edit_outlined,
              label: 'Edit draft',
              onTap: working ? null : onEdit,
            ),
          ] else if (application.status == 'offer_received')
            CorePrimaryButton(
              icon: Icons.rate_review_outlined,
              label: 'Review booking offer',
              onTap: () => Navigator.pushNamed(
                context,
                ActorTalentRoutes.bookings,
              ),
            )
          else if (application.status == 'selected')
            CorePrimaryButton(
              icon: Icons.event_available_outlined,
              label: 'Open booking',
              onTap: () => Navigator.pushNamed(
                context,
                ActorTalentRoutes.bookings,
              ),
            ),
          if (!const {'draft', 'withdrawn'}.contains(application.status)) ...[
            const SizedBox(height: 8),
            CoreSecondaryButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Message production',
              onTap: working ? null : onMessage,
            ),
          ],
        ],
      ),
    );
  }

  String get _message {
    return switch (application.status) {
      'draft' => 'Review your application and send it to the production.',
      'submitted' ||
      'viewed' =>
        'No action required while the production reviews your profile.',
      'shortlisted' => 'Keep your availability current for the next step.',
      'audition_requested' => 'Review the audition details and confirm.',
      'self_tape_requested' =>
        'Record and upload your self-tape before the deadline.',
      'callback' => 'Review callback details and confirm your availability.',
      'offer_received' => 'Review the fee, schedule and booking conditions.',
      'selected' => 'Continue to your booking, contract and schedule.',
      'rejected' => application.rejectionReason ??
          'This production has closed your application.',
      'withdrawn' => 'You withdrew this application.',
      _ => 'Check this page for the next production update.',
    };
  }
}

class _RoleDocuments extends StatelessWidget {
  final CastingApplication application;

  const _RoleDocuments({required this.application});

  @override
  Widget build(BuildContext context) {
    final sides = application.role.sidesFile;
    return ActorSectionCard(
      title: 'Role & Documents',
      icon: Icons.folder_outlined,
      child: Column(
        children: [
          ActorInfoRow(
            icon: Icons.movie_outlined,
            label: 'Role',
            value: application.role.title,
          ),
          ActorInfoRow(
            icon: Icons.payments_outlined,
            label: 'Fee',
            value: application.role.feeLabel,
          ),
          ActorInfoRow(
            icon: Icons.contact_mail_outlined,
            label: 'Casting contact',
            value: application.role.contactName ??
                application.audition.contact ??
                'Production team',
          ),
          if (sides != null)
            CoreSecondaryButton(
              icon: Icons.download_outlined,
              label: 'Open script or sides',
              onTap: () async {
                final auth = AuthScope.maybeOf(context);
                if (auth == null) return;
                try {
                  final url = await auth.authorizedDownloadUrl(sides.publicId);
                  openUrlInNewTab(url);
                } on ApiException catch (error) {
                  if (context.mounted) actorSnack(context, error.message);
                }
              },
            ),
        ],
      ),
    );
  }
}
