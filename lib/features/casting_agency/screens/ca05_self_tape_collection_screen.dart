import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../models/casting_agency_models.dart';
import '../routes/casting_agency_routes.dart';
import '../widgets/casting_agency_components.dart';

class CA05SelfTapeCollectionScreen extends StatefulWidget {
  const CA05SelfTapeCollectionScreen({super.key});

  @override
  State<CA05SelfTapeCollectionScreen> createState() =>
      _CA05SelfTapeCollectionScreenState();
}

class _CA05SelfTapeCollectionScreenState
    extends State<CA05SelfTapeCollectionScreen> {
  String _tab = 'All';
  Future<List<AuditionDto>>? _future;

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
          title: 'Submission command',
          icon: Icons.video_collection_outlined,
          selected: true,
          actionText: _future == null ? null : 'Refresh',
          onActionTap: _refresh,
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final tab in ['All', 'Received', 'Missing'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CoreChip(
                          label: tab,
                          selected: _tab == tab,
                          onTap: () => setState(() => _tab = tab),
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
            title: 'Sign in to view self-tape status',
            message:
                'Self-tape counts are loaded from live audition candidates.',
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
                  message: 'Could not load self-tape status',
                  onRetry: _refresh,
                );
              }
              final candidates = _candidates(snapshot.data ?? const []);
              final ready = candidates
                  .where((candidate) => candidate.selfTapeCount > 0)
                  .length;
              final missing = candidates.length - ready;
              final visible = candidates.where((candidate) {
                return switch (_tab) {
                  'Received' => candidate.selfTapeCount > 0,
                  'Missing' => candidate.selfTapeCount == 0,
                  _ => true,
                };
              }).toList();
              return Column(
                children: [
                  MetricActionRail(
                    items: [
                      MetricActionItem(
                        icon: Icons.play_circle_outline_rounded,
                        value: '$ready',
                        title: 'Received',
                        subtitle: 'Live candidates',
                        accentColor: context.appColors.success,
                      ),
                      MetricActionItem(
                        icon: Icons.pending_actions_outlined,
                        value: '$missing',
                        title: 'Missing',
                        subtitle: 'Live candidates',
                        accentColor: context.appColors.goldDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (visible.isEmpty)
                    CoreEmptyState(
                      icon: Icons.video_collection_outlined,
                      title: 'No self-tape candidates here',
                      message: 'Switch tabs or open auditions.',
                      actionLabel: 'Open auditions',
                      onAction: () => Navigator.pushNamed(
                        context,
                        CastingAgencyRoutes.auditions,
                      ),
                    )
                  else
                    AgencyResponsiveGrid(
                      minWidth: 300,
                      children: [
                        for (final candidate in visible)
                          _TapeStatusCard(candidate: candidate),
                      ],
                    ),
                ],
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
}

class _TapeStatusCard extends StatelessWidget {
  final AuditionCandidateDto candidate;

  const _TapeStatusCard({required this.candidate});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasTape = candidate.selfTapeCount > 0;
    return GlassSectionCard(
      radius: 20,
      padding: const EdgeInsets.all(12),
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
                status: hasTape
                    ? AgencyStatus.selfTapeReceived
                    : AgencyStatus.selfTapePending,
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
            label: 'Selection notes',
            value: '${candidate.selectionNoteCount}',
          ),
          const SizedBox(height: 8),
          Text(
            hasTape
                ? 'Tape files are attached to the live audition candidate record.'
                : 'No submitted tape is attached to this live candidate yet.',
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
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
