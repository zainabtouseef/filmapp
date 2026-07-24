import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../widgets/casting_agency_components.dart';

class CA06SelectionNotesScreen extends StatefulWidget {
  const CA06SelectionNotesScreen({super.key});

  @override
  State<CA06SelectionNotesScreen> createState() =>
      _CA06SelectionNotesScreenState();
}

class _CA06SelectionNotesScreenState extends State<CA06SelectionNotesScreen> {
  String _query = '';
  String _filter = 'All';
  Future<List<AuditionDto>>? _future;
  String? _busyCandidateId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= SpecialistScope.maybeOf(context)?.auditions(force: true);
  }

  void _refresh() {
    setState(() {
      _future = SpecialistScope.maybeOf(context)?.auditions(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AgencySectionCard(
          title: 'Selection workspace',
          icon: Icons.edit_note_outlined,
          selected: true,
          actionText: _future == null ? null : 'Refresh',
          onActionTap: _refresh,
          child: Column(
            children: [
              AgencySearchField(
                hintText: 'Search candidates and statuses...',
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in [
                      'All',
                      'shortlisted',
                      'selected',
                      'rejected'
                    ])
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
            title: 'Sign in to view selection notes',
            message: 'Candidate notes are linked to live audition candidates.',
          )
        else
          FutureBuilder<List<AuditionDto>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SkeletonCard(height: 360);
              }
              if (snapshot.hasError) {
                return _LoadError(
                    message: 'Could not load notes', onRetry: _refresh);
              }
              final candidates = _candidates(snapshot.data ?? const []);
              final visible = _filtered(candidates);
              return AgencyTwoColumn(
                left: AgencySectionCard(
                  title: 'Candidate notes',
                  icon: Icons.rate_review_outlined,
                  child: visible.isEmpty
                      ? CoreEmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No live candidate notes',
                          message:
                              'Clear filters or add a note to a candidate.',
                          actionLabel: 'Clear',
                          onAction: () => setState(() {
                            _query = '';
                            _filter = 'All';
                          }),
                        )
                      : Column(
                          children: [
                            for (final candidate in visible)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _NoteCard(
                                  candidate: candidate,
                                  busy: _busyCandidateId == candidate.publicId,
                                  onAddNote: () =>
                                      _showAddNote(context, candidate),
                                  onSelect: () =>
                                      _updateCandidate(candidate, 'selected'),
                                  onReject: () =>
                                      _updateCandidate(candidate, 'rejected'),
                                ),
                              ),
                          ],
                        ),
                ),
                right: AgencySectionCard(
                  title: 'Feedback summary',
                  icon: Icons.stars_outlined,
                  child: Column(
                    children: [
                      AgencyInfoRow(
                        icon: Icons.notes_outlined,
                        label: 'Total notes',
                        value:
                            '${candidates.fold<int>(0, (sum, item) => sum + item.selectionNoteCount)}',
                      ),
                      AgencyInfoRow(
                        icon: Icons.check_circle_outline,
                        label: 'Selected',
                        value:
                            '${candidates.where((item) => item.status == 'selected').length}',
                      ),
                      AgencyInfoRow(
                        icon: Icons.block_outlined,
                        label: 'Rejected',
                        value:
                            '${candidates.where((item) => item.status == 'rejected').length}',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  List<AuditionCandidateDto> _candidates(List<AuditionDto> auditions) {
    return [
      for (final audition in auditions) ...audition.candidates,
    ];
  }

  List<AuditionCandidateDto> _filtered(List<AuditionCandidateDto> candidates) {
    final lower = _query.trim().toLowerCase();
    return candidates.where((candidate) {
      final matchesFilter = _filter == 'All' || candidate.status == _filter;
      final haystack =
          '${candidate.screenName} ${candidate.status}'.toLowerCase();
      return matchesFilter && (lower.isEmpty || haystack.contains(lower));
    }).toList();
  }

  Future<void> _updateCandidate(
      AuditionCandidateDto candidate, String status) async {
    final specialist = SpecialistScope.maybeOf(context);
    if (specialist == null) return;
    setState(() => _busyCandidateId = candidate.publicId);
    try {
      await specialist
          .updateAuditionCandidate(candidate.publicId, {'status': status});
      if (!mounted) return;
      agencySnack(context, '${candidate.screenName} marked $status');
      _refresh();
    } catch (error) {
      if (!mounted) return;
      agencySnack(context, 'Could not update candidate: $error');
    } finally {
      if (mounted) setState(() => _busyCandidateId = null);
    }
  }

  void _showAddNote(BuildContext context, AuditionCandidateDto candidate) {
    final controller = TextEditingController();
    showAgencySheet(
      context,
      title: 'Add note for ${candidate.screenName}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Candidate note',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.save_outlined,
            label: 'Save note',
            onTap: () async {
              final body = controller.text.trim();
              if (body.length < 8) {
                agencySnack(context, 'Add a useful note before saving');
                return;
              }
              Navigator.pop(context);
              await _saveNote(candidate, body);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveNote(AuditionCandidateDto candidate, String body) async {
    final specialist = SpecialistScope.maybeOf(context);
    if (specialist == null) return;
    setState(() => _busyCandidateId = candidate.publicId);
    try {
      await specialist.addSelectionNote(candidate.publicId, {
        'note': body,
        'score': 8,
        'visibility': 'agency',
      });
      if (!mounted) return;
      agencySnack(context, 'Selection note saved');
      _refresh();
    } catch (error) {
      if (!mounted) return;
      agencySnack(context, 'Could not save note: $error');
    } finally {
      if (mounted) setState(() => _busyCandidateId = null);
    }
  }
}

class _NoteCard extends StatelessWidget {
  final AuditionCandidateDto candidate;
  final bool busy;
  final VoidCallback onSelect;
  final VoidCallback onReject;
  final VoidCallback onAddNote;

  const _NoteCard({
    required this.candidate,
    required this.busy,
    required this.onSelect,
    required this.onReject,
    required this.onAddNote,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Opacity(
      opacity: busy ? 0.62 : 1,
      child: GlassSectionCard(
        radius: 16,
        padding: const EdgeInsets.all(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    candidate.screenName,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                AgencyStatusChip(
                    status: agencyStatusFromString(candidate.status)),
              ],
            ),
            const SizedBox(height: 8),
            AgencyInfoRow(
              icon: Icons.notes_outlined,
              label: 'Notes',
              value: '${candidate.selectionNoteCount}',
            ),
            AgencyInfoRow(
              icon: Icons.video_collection_outlined,
              label: 'Self-tapes',
              value: '${candidate.selfTapeCount}',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                CorePrimaryButton(
                  icon: Icons.add_comment_outlined,
                  label: 'Add note',
                  compact: true,
                  onTap: busy ? null : onAddNote,
                ),
                CoreSecondaryButton(
                  icon: Icons.check_circle_outline,
                  label: 'Select',
                  compact: true,
                  onTap: busy ? null : onSelect,
                ),
                CoreSecondaryButton(
                  icon: Icons.block_outlined,
                  label: 'Reject',
                  compact: true,
                  onTap: busy ? null : onReject,
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
