import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../data/casting_agency_demo_data.dart';
import '../models/casting_agency_models.dart';
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

  @override
  Widget build(BuildContext context) {
    final store = CastingAgencyDemoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final notes = _notes(store).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AgencySectionCard(
              title: 'Selection workspace',
              icon: Icons.edit_note_outlined,
              selected: true,
              child: Column(
                children: [
                  AgencySearchField(
                    hintText: 'Search candidates, projects, feedback...',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final filter in [
                          'All',
                          'Selected',
                          'Reviewing',
                          'Rejected',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CoreChip(
                              label: filter,
                              selected: _filter == filter,
                              onTap: () {
                                setState(() => _filter = filter);
                                agencySnack(context, '$filter notes shown');
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
            AgencyTwoColumn(
              left: AgencySectionCard(
                title: 'Candidate notes',
                icon: Icons.rate_review_outlined,
                child: notes.isEmpty
                    ? CoreEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No notes found',
                        message: 'Clear filters or search another candidate.',
                        actionLabel: 'Clear',
                        onAction: () => setState(() {
                          _query = '';
                          _filter = 'All';
                        }),
                      )
                    : Column(
                        children: [
                          for (final note in notes)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _NoteCard(
                                note: note,
                                status: store.noteStatus(note),
                                onSelect: () {
                                  store.updateNoteStatus(
                                    note.id,
                                    AgencyStatus.selected,
                                  );
                                  agencySnack(context, 'Candidate selected');
                                },
                                onReject: () {
                                  store.updateNoteStatus(
                                    note.id,
                                    AgencyStatus.rejected,
                                  );
                                  agencySnack(context, 'Candidate rejected');
                                },
                                onDetail: () => _showNote(context, note),
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
                      icon: Icons.check_circle_outline,
                      label: 'Selected',
                      value: '${_count(store, AgencyStatus.selected)}',
                    ),
                    AgencyInfoRow(
                      icon: Icons.hourglass_top_outlined,
                      label: 'Reviewing',
                      value: '${_count(store, AgencyStatus.reviewing)}',
                    ),
                    AgencyInfoRow(
                      icon: Icons.block_outlined,
                      label: 'Rejected',
                      value: '${_count(store, AgencyStatus.rejected)}',
                    ),
                    const SizedBox(height: 10),
                    CorePrimaryButton(
                      icon: Icons.add_comment_outlined,
                      label: 'Add note',
                      compact: true,
                      onTap: () => _showAddNote(context),
                    ),
                    const SizedBox(height: 8),
                    CoreSecondaryButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Open director chat',
                      compact: true,
                      onTap: () =>
                          Navigator.pushNamed(context, CoreRoutes.chat),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Iterable<AgencySelectionNote> _notes(CastingAgencyDemoStore store) {
    final lower = _query.trim().toLowerCase();
    return CastingAgencyDemoData.notes.where((note) {
      final status = store.noteStatus(note);
      final matchesFilter = switch (_filter) {
        'Selected' => status == AgencyStatus.selected,
        'Reviewing' => status == AgencyStatus.reviewing,
        'Rejected' => status == AgencyStatus.rejected,
        _ => true,
      };
      final haystack =
          '${note.talentName} ${note.project} ${note.note} ${note.directorFeedback}'
              .toLowerCase();
      return matchesFilter && haystack.contains(lower);
    });
  }

  int _count(CastingAgencyDemoStore store, AgencyStatus status) {
    return CastingAgencyDemoData.notes
        .where((note) => store.noteStatus(note) == status)
        .length;
  }

  void _showNote(BuildContext context, AgencySelectionNote note) {
    showAgencySheet(
      context,
      title: note.talentName,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AgencyInfoRow(
            icon: Icons.movie_outlined,
            label: 'Project',
            value: note.project,
          ),
          AgencyInfoRow(
            icon: Icons.score_outlined,
            label: 'Score',
            value: '${note.score}',
          ),
          AgencyInfoRow(
            icon: Icons.notes_outlined,
            label: 'Agency note',
            value: note.note,
          ),
          AgencyInfoRow(
            icon: Icons.comment_outlined,
            label: 'Director',
            value: note.directorFeedback,
          ),
        ],
      ),
    );
  }

  void _showAddNote(BuildContext context) {
    final controller = TextEditingController();
    showAgencySheet(
      context,
      title: 'Add note',
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
            onTap: () {
              Navigator.pop(context);
              agencySnack(context, 'Demo note saved');
            },
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final AgencySelectionNote note;
  final AgencyStatus status;
  final VoidCallback onSelect;
  final VoidCallback onReject;
  final VoidCallback onDetail;

  const _NoteCard({
    required this.note,
    required this.status,
    required this.onSelect,
    required this.onReject,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 16,
      padding: const EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.talentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              AgencyStatusChip(status: status),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${note.project} - score ${note.score}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.statusText.copyWith(color: colors.goldDark),
          ),
          const SizedBox(height: 5),
          Text(
            note.note,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.info_outline_rounded,
                  label: 'Detail',
                  compact: true,
                  onTap: onDetail,
                ),
              ),
              const SizedBox(width: 8),
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
                  label: 'Select',
                  compact: true,
                  onTap: onSelect,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
