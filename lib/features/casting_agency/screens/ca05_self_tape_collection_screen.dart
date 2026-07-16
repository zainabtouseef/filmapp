import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../data/casting_agency_demo_data.dart';
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

  @override
  Widget build(BuildContext context) {
    final store = CastingAgencyDemoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final tapes = _tapes(store).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AgencySectionCard(
              title: 'Submission command',
              icon: Icons.video_collection_outlined,
              selected: true,
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final tab in ['All', 'Ready', 'Due', 'Forwarded'])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CoreChip(
                              label: tab,
                              selected: _tab == tab,
                              onTap: () {
                                setState(() => _tab = tab);
                                agencySnack(context, '$tab tapes shown');
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  MetricActionRail(
                    items: [
                      MetricActionItem(
                        icon: Icons.play_circle_outline_rounded,
                        value: '3',
                        title: 'Ready',
                        subtitle: 'Self-tapes',
                        accentColor: context.appColors.goldDark,
                      ),
                      MetricActionItem(
                        icon: Icons.play_circle_outline_rounded,
                        value: '2',
                        title: 'Due today',
                        subtitle: 'Self-tapes',
                        accentColor: context.appColors.goldDark,
                      ),
                      MetricActionItem(
                        icon: Icons.play_circle_outline_rounded,
                        value: '5',
                        title: 'Forwarded',
                        subtitle: 'Self-tapes',
                        accentColor: context.appColors.goldDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (tapes.isEmpty)
              CoreEmptyState(
                icon: Icons.video_collection_outlined,
                title: 'No self-tapes here',
                message: 'Switch tabs or request new tapes from the roster.',
                actionLabel: 'Request tapes',
                onAction: () => Navigator.pushNamed(
                  context,
                  CastingAgencyRoutes.roster,
                ),
              )
            else
              AgencyResponsiveGrid(
                minWidth: 320,
                children: [
                  for (final tape in tapes)
                    _TapeCard(
                      tape: tape,
                      status: store.tapeStatus(tape),
                      onRequest: () {
                        store.requestTape(tape.id);
                        agencySnack(context, 'Self-tape request sent');
                      },
                      onForward: () {
                        store.forwardTape(tape.id);
                        agencySnack(context, 'Tape forwarded with shortlist');
                      },
                      onPreview: () => _showTape(context, tape),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  Iterable<AgencyTape> _tapes(CastingAgencyDemoStore store) {
    return CastingAgencyDemoData.tapes.where((tape) {
      final status = store.tapeStatus(tape);
      return switch (_tab) {
        'Ready' => status == AgencyStatus.selfTapeReceived,
        'Due' => status == AgencyStatus.selfTapePending,
        'Forwarded' => status == AgencyStatus.shortlisted,
        _ => true,
      };
    });
  }

  void _showTape(BuildContext context, AgencyTape tape) {
    showAgencySheet(
      context,
      title: tape.talentName,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AgencyInfoRow(
            icon: Icons.movie_outlined,
            label: 'Project',
            value: tape.project,
          ),
          AgencyInfoRow(
            icon: Icons.timer_outlined,
            label: 'Duration',
            value: tape.duration,
          ),
          AgencyInfoRow(
            icon: Icons.notes_outlined,
            label: 'Transcript',
            value: tape.transcript,
          ),
          const SizedBox(height: 8),
          CorePrimaryButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Ask talent',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, CoreRoutes.chat);
            },
          ),
        ],
      ),
    );
  }
}

class _TapeCard extends StatelessWidget {
  final AgencyTape tape;
  final AgencyStatus status;
  final VoidCallback onRequest;
  final VoidCallback onForward;
  final VoidCallback onPreview;

  const _TapeCard({
    required this.tape,
    required this.status,
    required this.onRequest,
    required this.onForward,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 20,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AgencyMediaFrame(
            imageUrl: tape.imageUrl,
            title: tape.talentName,
            badge: tape.duration,
            fallbackIcon: Icons.video_collection_outlined,
            aspectRatio: 16 / 9,
            compact: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  tape.talentName,
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
          const SizedBox(height: 6),
          Text(
            '${tape.project} - ${tape.dueDate}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            tape.transcript,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.play_arrow_outlined,
                  label: 'Preview',
                  compact: true,
                  onTap: onPreview,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.video_call_outlined,
                  label: 'Request',
                  compact: true,
                  onTap: onRequest,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CorePrimaryButton(
            icon: Icons.forward_to_inbox_outlined,
            label: 'Forward selected tape',
            compact: true,
            onTap: onForward,
          ),
        ],
      ),
    );
  }
}
