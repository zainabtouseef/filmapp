import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/director_producer/routes/director_producer_routes.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../data/casting_agency_demo_data.dart';
import '../models/casting_agency_models.dart';
import '../routes/casting_agency_routes.dart';
import '../widgets/casting_agency_components.dart';

class CA04CandidateShortlistScreen extends StatefulWidget {
  const CA04CandidateShortlistScreen({super.key});

  @override
  State<CA04CandidateShortlistScreen> createState() =>
      _CA04CandidateShortlistScreenState();
}

class _CA04CandidateShortlistScreenState
    extends State<CA04CandidateShortlistScreen> {
  final _note = TextEditingController(
    text: 'Priority shortlist with availability and tape status attached.',
  );
  bool _includeTapes = true;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = CastingAgencyDemoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return AgencyTwoColumn(
          left: AgencySectionCard(
            title: 'Shortlist builder',
            icon: Icons.view_kanban_outlined,
            selected: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AuditionSelector(store: store),
                const SizedBox(height: 12),
                Text(
                  'Select candidates',
                  style: AppTextStyles.cardLabel.copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                AgencyResponsiveGrid(
                  minWidth: 230,
                  children: [
                    for (final talent in CastingAgencyDemoData.roster)
                      _CandidatePickCard(
                        talent: talent,
                        selected: store.selectedTalentIds.contains(talent.id),
                        onTap: () => store.toggleTalent(talent.id),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _note,
                  minLines: 3,
                  maxLines: 5,
                  style: AppTextStyles.body.copyWith(
                    color: context.appColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Agency notes for director',
                    errorText: _error,
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile.adaptive(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: _includeTapes,
                  activeThumbColor: context.appColors.goldMid,
                  onChanged: (value) => setState(() => _includeTapes = value),
                  title: Text(
                    'Attach ready self-tapes',
                    style: AppTextStyles.cardLabel.copyWith(
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Ready tapes and candidate metadata travel with this shortlist.',
                    style: AppTextStyles.smallMeta.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CoreSecondaryButton(
                        icon: Icons.save_outlined,
                        label: 'Save draft',
                        compact: true,
                        onTap: () =>
                            agencySnack(context, 'Shortlist draft saved'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CorePrimaryButton(
                        icon: Icons.send_outlined,
                        label: 'Submit',
                        compact: true,
                        onTap: () => _submit(context, store),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          right: Column(
            children: [
              AgencySectionCard(
                title: 'Live preview',
                icon: Icons.preview_outlined,
                child: _ShortlistPreview(
                    store: store, includeTapes: _includeTapes),
              ),
              const SizedBox(height: 12),
              AgencySectionCard(
                title: 'Progress',
                icon: Icons.auto_graph_outlined,
                child: Column(
                  children: [
                    _ProgressRow(
                      label: 'Request selected',
                      value: store.selectedAudition.project,
                      complete: true,
                    ),
                    _ProgressRow(
                      label: 'Candidates',
                      value: '${store.selectedTalentIds.length} selected',
                      complete: store.selectedTalentIds.isNotEmpty,
                    ),
                    _ProgressRow(
                      label: 'Notes',
                      value: _note.text.trim().isEmpty ? 'Needed' : 'Ready',
                      complete: _note.text.trim().isNotEmpty,
                    ),
                    _ProgressRow(
                      label: 'Director board',
                      value: 'DP shortlist route',
                      complete: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submit(BuildContext context, CastingAgencyDemoStore store) {
    if (store.selectedTalentIds.isEmpty) {
      setState(() => _error = 'Select at least one candidate.');
      return;
    }
    if (_note.text.trim().length < 8) {
      setState(() => _error = 'Add a useful note before submitting.');
      return;
    }
    setState(() => _error = null);
    store.submitShortlist();
    agencySnack(context, 'Shortlist sent to director board');
    Navigator.pushNamed(context, DirectorProducerRoutes.shortlist);
  }
}

class _AuditionSelector extends StatelessWidget {
  final CastingAgencyDemoStore store;

  const _AuditionSelector({required this.store});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final audition in CastingAgencyDemoData.auditions)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CoreChip(
                label: audition.project,
                selected: store.selectedAuditionId == audition.id,
                icon: Icons.local_activity_outlined,
                onTap: () => store.selectAudition(audition.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _CandidatePickCard extends StatelessWidget {
  final AgencyTalent talent;
  final bool selected;
  final VoidCallback onTap;

  const _CandidatePickCard({
    required this.talent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: GlassSectionCard(
        radius: 18,
        padding: const EdgeInsets.all(11),
        selected: selected,
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: AgencyMediaFrame(
                imageUrl: talent.imageUrl,
                title: talent.name,
                badge: talent.city,
                fallbackIcon: Icons.person_outline_rounded,
                aspectRatio: 1,
                compact: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    talent.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${talent.category} - ${talent.availability}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.smallMeta.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? colors.success : colors.iconMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortlistPreview extends StatelessWidget {
  final CastingAgencyDemoStore store;
  final bool includeTapes;

  const _ShortlistPreview({required this.store, required this.includeTapes});

  @override
  Widget build(BuildContext context) {
    final selected = CastingAgencyDemoData.roster
        .where((talent) => store.selectedTalentIds.contains(talent.id))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AgencyInfoRow(
          icon: Icons.local_activity_outlined,
          label: 'Request',
          value: store.selectedAudition.project,
        ),
        AgencyInfoRow(
          icon: Icons.people_alt_outlined,
          label: 'Candidates',
          value: '${selected.length}',
        ),
        AgencyInfoRow(
          icon: Icons.video_collection_outlined,
          label: 'Self-tapes',
          value: includeTapes ? 'Attached' : 'Not attached',
        ),
        const SizedBox(height: 8),
        for (final talent in selected.take(4))
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: AgencyStatusChip(status: talent.status),
          ),
        if (selected.isEmpty)
          CoreEmptyState(
            icon: Icons.playlist_add_outlined,
            title: 'No candidates yet',
            message: 'Choose roster talent to build the preview.',
            actionLabel: 'Open roster',
            onAction: () => Navigator.pushNamed(
              context,
              CastingAgencyRoutes.roster,
            ),
          ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final String value;
  final bool complete;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.complete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            complete
                ? Icons.check_circle_outline
                : Icons.radio_button_unchecked,
            color: complete ? colors.success : colors.iconMuted,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.cardLabel.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
