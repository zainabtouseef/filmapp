import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../widgets/casting_agency_components.dart';

class CA04CandidateShortlistScreen extends StatefulWidget {
  const CA04CandidateShortlistScreen({super.key});

  @override
  State<CA04CandidateShortlistScreen> createState() =>
      _CA04CandidateShortlistScreenState();
}

class _CA04CandidateShortlistScreenState
    extends State<CA04CandidateShortlistScreen> {
  final _note = TextEditingController();
  Future<List<AuditionDto>>? _future;
  String? _selectedAuditionId;
  String? _busyCandidateId;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= SpecialistScope.maybeOf(context)?.auditions(force: true);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _future = SpecialistScope.maybeOf(context)?.auditions(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AgencyTwoColumn(
      left: AgencySectionCard(
        title: 'Shortlist builder',
        icon: Icons.view_kanban_outlined,
        selected: true,
        actionText: _future == null ? null : 'Refresh',
        onActionTap: _refresh,
        child: _future == null
            ? const CoreEmptyState(
                icon: Icons.lock_outline_rounded,
                title: 'Sign in to build shortlists',
                message: 'Audition candidates are loaded from the server.',
              )
            : FutureBuilder<List<AuditionDto>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SkeletonCard(height: 420);
                  }
                  if (snapshot.hasError) {
                    return _LoadError(
                      message: 'Could not load audition candidates',
                      onRetry: _refresh,
                    );
                  }
                  final auditions = snapshot.data ?? const [];
                  if (auditions.isEmpty) {
                    return const CoreEmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'No live auditions',
                      message: 'Shortlists appear after auditions are created.',
                    );
                  }
                  final selected = auditions.firstWhere(
                    (item) => item.publicId == _selectedAuditionId,
                    orElse: () => auditions.first,
                  );
                  _selectedAuditionId ??= selected.publicId;
                  return _BuilderBody(
                    auditions: auditions,
                    selected: selected,
                    note: _note,
                    error: _error,
                    busyCandidateId: _busyCandidateId,
                    onSelectedAudition: (id) =>
                        setState(() => _selectedAuditionId = id),
                    onToggleCandidate: _toggleCandidate,
                    onSubmitNote: _submitNote,
                  );
                },
              ),
      ),
      right: AgencySectionCard(
        title: 'Submission Rules',
        icon: Icons.rule_folder_outlined,
        child: Column(
          children: const [
            AgencyInfoRow(
              icon: Icons.cloud_done_outlined,
              label: 'Source',
              value: 'Live audition candidates',
            ),
            AgencyInfoRow(
              icon: Icons.check_circle_outline,
              label: 'Selection',
              value: 'PATCH candidate status',
            ),
            AgencyInfoRow(
              icon: Icons.notes_outlined,
              label: 'Notes',
              value: 'Saved to candidate notes',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleCandidate(AuditionCandidateDto candidate) async {
    final specialist = SpecialistScope.maybeOf(context);
    if (specialist == null) return;
    final nextStatus =
        candidate.status == 'shortlisted' ? 'submitted' : 'shortlisted';
    setState(() {
      _busyCandidateId = candidate.publicId;
      _error = null;
    });
    try {
      await specialist.updateAuditionCandidate(candidate.publicId, {
        'status': nextStatus,
      });
      if (!mounted) return;
      agencySnack(context, '${candidate.screenName} marked $nextStatus');
      _refresh();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Could not update candidate: $error');
    } finally {
      if (mounted) setState(() => _busyCandidateId = null);
    }
  }

  Future<void> _submitNote(AuditionCandidateDto candidate) async {
    final specialist = SpecialistScope.maybeOf(context);
    if (specialist == null) return;
    final body = _note.text.trim();
    if (body.length < 8) {
      setState(() => _error = 'Add a useful note before saving.');
      return;
    }
    setState(() {
      _busyCandidateId = candidate.publicId;
      _error = null;
    });
    try {
      await specialist.addSelectionNote(candidate.publicId, {
        'note': body,
        'score': 8,
        'visibility': 'director',
      });
      if (!mounted) return;
      _note.clear();
      agencySnack(context, 'Selection note saved');
      _refresh();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Could not save note: $error');
    } finally {
      if (mounted) setState(() => _busyCandidateId = null);
    }
  }
}

class _BuilderBody extends StatelessWidget {
  final List<AuditionDto> auditions;
  final AuditionDto selected;
  final TextEditingController note;
  final String? error;
  final String? busyCandidateId;
  final ValueChanged<String> onSelectedAudition;
  final ValueChanged<AuditionCandidateDto> onToggleCandidate;
  final ValueChanged<AuditionCandidateDto> onSubmitNote;

  const _BuilderBody({
    required this.auditions,
    required this.selected,
    required this.note,
    required this.error,
    required this.busyCandidateId,
    required this.onSelectedAudition,
    required this.onToggleCandidate,
    required this.onSubmitNote,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final audition in auditions)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CoreChip(
                    label: audition.roleTitle,
                    selected: selected.publicId == audition.publicId,
                    icon: Icons.local_activity_outlined,
                    onTap: () => onSelectedAudition(audition.publicId),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AgencyInfoRow(
          icon: Icons.movie_filter_outlined,
          label: 'Project',
          value: selected.projectId,
        ),
        AgencyInfoRow(
          icon: Icons.group_outlined,
          label: 'Candidates',
          value: '${selected.candidates.length}',
        ),
        const SizedBox(height: 12),
        if (selected.candidates.isEmpty)
          const CoreEmptyState(
            icon: Icons.people_outline_rounded,
            title: 'No live candidates yet',
            message: 'Candidate records will appear after roster submissions.',
          )
        else
          AgencyResponsiveGrid(
            minWidth: 250,
            children: [
              for (final candidate in selected.candidates)
                _CandidatePickCard(
                  candidate: candidate,
                  busy: busyCandidateId == candidate.publicId,
                  onToggle: () => onToggleCandidate(candidate),
                  onNote: () => onSubmitNote(candidate),
                ),
            ],
          ),
        const SizedBox(height: 12),
        TextField(
          controller: note,
          minLines: 3,
          maxLines: 5,
          style: AppTextStyles.body.copyWith(
            color: context.appColors.textPrimary,
          ),
          decoration: InputDecoration(
            labelText: 'Selection note for director',
            errorText: error,
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}

class _CandidatePickCard extends StatelessWidget {
  final AuditionCandidateDto candidate;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onNote;

  const _CandidatePickCard({
    required this.candidate,
    required this.busy,
    required this.onToggle,
    required this.onNote,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final shortlisted = candidate.status == 'shortlisted';
    return Opacity(
      opacity: busy ? 0.62 : 1,
      child: GlassSectionCard(
        radius: 18,
        padding: const EdgeInsets.all(11),
        selected: shortlisted,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    candidate.screenName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                AgencyStatusChip(
                  status: agencyStatusFromString(candidate.status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AgencyInfoRow(
              icon: Icons.video_collection_outlined,
              label: 'Self-tapes',
              value: '${candidate.selfTapeCount}',
            ),
            AgencyInfoRow(
              icon: Icons.notes_outlined,
              label: 'Notes',
              value: '${candidate.selectionNoteCount}',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                CoreSecondaryButton(
                  icon: shortlisted
                      ? Icons.remove_circle_outline
                      : Icons.check_circle_outline,
                  label: shortlisted ? 'Remove' : 'Shortlist',
                  compact: true,
                  onTap: busy ? null : onToggle,
                ),
                CorePrimaryButton(
                  icon: Icons.notes_outlined,
                  label: 'Save note',
                  compact: true,
                  onTap: busy ? null : onNote,
                ),
              ],
            ),
          ],
        ),
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
