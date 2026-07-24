import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../widgets/distribution_partner_components.dart';

class DS03ReleaseCoordinationScreen extends StatefulWidget {
  const DS03ReleaseCoordinationScreen({super.key});

  @override
  State<DS03ReleaseCoordinationScreen> createState() =>
      _DS03ReleaseCoordinationScreenState();
}

class _DS03ReleaseCoordinationScreenState
    extends State<DS03ReleaseCoordinationScreen> {
  final _note = TextEditingController();
  Future<List<DistributionProjectDto>>? _future;
  String? _busyProjectId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??=
        SpecialistScope.maybeOf(context)?.distributionProjects(force: true);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _future =
          SpecialistScope.maybeOf(context)?.distributionProjects(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DistributionTwoColumn(
      left: DistributionSectionCard(
        title: 'Release coordination',
        icon: Icons.rocket_launch_outlined,
        selected: true,
        actionText: _future == null ? null : 'Refresh',
        onActionTap: _refresh,
        child: _future == null
            ? const CoreEmptyState(
                icon: Icons.lock_outline_rounded,
                title: 'Sign in to coordinate releases',
                message: 'Release projects are loaded from the server.',
              )
            : FutureBuilder<List<DistributionProjectDto>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SkeletonCard(height: 420);
                  }
                  if (snapshot.hasError) {
                    return _LoadError(
                      message: 'Could not load release projects',
                      onRetry: _refresh,
                    );
                  }
                  final projects = snapshot.data ?? const [];
                  if (projects.isEmpty) {
                    return const CoreEmptyState(
                      icon: Icons.movie_creation_outlined,
                      title: 'No live distribution projects',
                      message: 'Project release coordination will appear here.',
                    );
                  }
                  return Column(
                    children: [
                      for (final project in projects)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ProjectCard(
                            project: project,
                            busy: _busyProjectId == project.publicId,
                            onSubmit: () => _submit(project),
                            onNote: () => _showNoteSheet(context, project),
                          ),
                        ),
                    ],
                  );
                },
              ),
      ),
      right: DistributionSectionCard(
        title: 'Handover Rules',
        icon: Icons.rule_folder_outlined,
        child: Column(
          children: const [
            DistributionInfoRow(
              icon: Icons.inventory_2_outlined,
              label: 'Materials',
              value: 'Live handover count',
            ),
            DistributionInfoRow(
              icon: Icons.calendar_month_outlined,
              label: 'Windows',
              value: 'Live release windows',
            ),
            DistributionInfoRow(
              icon: Icons.cloud_done_outlined,
              label: 'Status',
              value: 'PATCH distribution project',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(DistributionProjectDto project) async {
    final specialist = SpecialistScope.maybeOf(context);
    if (specialist == null) return;
    setState(() => _busyProjectId = project.publicId);
    try {
      await specialist.updateDistributionProject(project.publicId, {
        'status': 'submitted',
        'status_note': _note.text.trim().isEmpty
            ? (project.statusNote ?? 'Release coordination submitted')
            : _note.text.trim(),
      });
      if (!mounted) return;
      distributionSnack(context, 'Release coordination submitted');
      _refresh();
    } catch (error) {
      if (!mounted) return;
      distributionSnack(context, 'Could not submit release: $error');
    } finally {
      if (mounted) setState(() => _busyProjectId = null);
    }
  }

  void _showNoteSheet(BuildContext context, DistributionProjectDto project) {
    _note.text = project.statusNote ?? '';
    showDistributionSheet(
      context,
      title: 'Update release note',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _note,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Status note',
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
              _submit(project);
            },
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final DistributionProjectDto project;
  final bool busy;
  final VoidCallback onSubmit;
  final VoidCallback onNote;

  const _ProjectCard({
    required this.project,
    required this.busy,
    required this.onSubmit,
    required this.onNote,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Opacity(
      opacity: busy ? 0.62 : 1,
      child: GlassSectionCard(
        radius: 18,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.projectId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                DistributionStatusChip(
                  status: distributionStatusFromString(project.status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DistributionInfoRow(
              icon: Icons.public_outlined,
              label: 'Territories',
              value: project.territories ?? 'Not set',
            ),
            DistributionInfoRow(
              icon: Icons.inventory_2_outlined,
              label: 'Handover items',
              value: '${project.handoverCount}',
            ),
            DistributionInfoRow(
              icon: Icons.calendar_month_outlined,
              label: 'Release windows',
              value: '${project.releaseWindowCount}',
            ),
            if ((project.missingItems ?? '').trim().isNotEmpty)
              DistributionInfoRow(
                icon: Icons.warning_amber_rounded,
                label: 'Missing',
                value: project.missingItems!,
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                CoreSecondaryButton(
                  icon: Icons.edit_note_outlined,
                  label: 'Note',
                  compact: true,
                  onTap: busy ? null : onNote,
                ),
                CorePrimaryButton(
                  icon: Icons.send_outlined,
                  label: 'Submit',
                  compact: true,
                  onTap: busy ? null : onSubmit,
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
