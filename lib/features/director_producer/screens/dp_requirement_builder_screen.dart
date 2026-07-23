import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/projects/project_models.dart';
import '../../../core/projects/projects_controller.dart';
import '../models/dp_requirement.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_empty_state.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_requirement_card.dart';
import '../widgets/dp_status_chip.dart';

class DPRequirementBuilderScreen extends StatefulWidget {
  final String? projectId;

  const DPRequirementBuilderScreen({super.key, this.projectId});

  @override
  State<DPRequirementBuilderScreen> createState() =>
      _DPRequirementBuilderScreenState();
}

class _DPRequirementBuilderScreenState
    extends State<DPRequirementBuilderScreen> {
  final _title = TextEditingController(text: 'Lead actor, 28-34');
  final _summary = TextEditingController(
    text: 'Urdu/Pashto, athletic, winter exterior comfort',
  );
  final _budgetMin = TextEditingController(text: '1200000');
  final _budgetMax = TextEditingController(text: '1800000');
  String _category = 'Roles';
  Future<List<ProjectRequirement>>? _requirementsFuture;
  bool _started = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _reload();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    _budgetMin.dispose();
    _budgetMax.dispose();
    super.dispose();
  }

  void _reload() {
    final controller = ProjectsScope.maybeOf(context);
    final projectId = widget.projectId;
    setState(() {
      _requirementsFuture = controller == null || projectId == null
          ? Future<List<ProjectRequirement>>.error(
              const ApiException(
                code: 'project.missing',
                message: 'Project id is required.',
              ),
            )
          : controller.requirements(projectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dpHeaderAction(
          context,
          icon: Icons.add_circle_outline_rounded,
          label: _saving ? 'Saving...' : 'Add',
          onTap: _saving ? () {} : _saveRequirement,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final category in const [
              'Roles',
              'Models',
              'Locations',
              'Media & Equipment',
              'Crew',
            ])
              GestureDetector(
                onTap: () => setState(() => _category = category),
                child: DPStatusChip(
                  label: category,
                  tone: _category == category ? DpTone.warning : DpTone.neutral,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        DPGlassCard(
          child: Column(
            children: [
              CoreTextField(
                controller: _title,
                label: 'Requirement title',
                icon: Icons.title_rounded,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: _summary,
                label: 'Filters summary / notes',
                icon: Icons.tune_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: _budgetMin,
                label: 'Minimum fee (PKR)',
                icon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: _budgetMax,
                label: 'Maximum fee (PKR)',
                icon: Icons.savings_outlined,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: DPHolographicButton(
            label: _saving ? 'Saving Requirement' : 'Save Requirement',
            icon: Icons.save_outlined,
            onTap: _saving ? null : _saveRequirement,
          ),
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<ProjectRequirement>>(
          future: _requirementsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const DPEmptyState(
                icon: Icons.hourglass_top_rounded,
                title: 'Loading requirements',
                message: 'Fetching project requirements from the server.',
              );
            }
            if (snapshot.hasError) {
              return CoreEmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Requirements unavailable',
                message:
                    'Could not load live project requirements from the database. Open a real project and retry.',
                actionLabel: 'Retry',
                onAction: _reload,
              );
            }
            final requirements = (snapshot.data ?? const [])
                .map((item) => item.toDpRequirement())
                .where((req) => req.category == _category)
                .toList();
            return _RequirementGrid(requirements: requirements);
          },
        ),
      ],
    );
  }

  Future<void> _saveRequirement() async {
    final controller = ProjectsScope.maybeOf(context);
    final projectId = widget.projectId;
    if (controller == null || projectId == null) {
      dpSnack(context, 'Open a live project before adding requirements');
      return;
    }
    if (_title.text.trim().length < 2) {
      dpSnack(context, 'Requirement title is required');
      return;
    }
    setState(() => _saving = true);
    try {
      await controller.createRequirement(
        projectId: projectId,
        category: _backendCategory(_category),
        title: _title.text.trim(),
        summary: _summary.text.trim(),
        budgetMinMinor: _parseMinor(_budgetMin.text),
        budgetMaxMinor: _parseMinor(_budgetMax.text),
      );
      if (!mounted) return;
      dpSnack(context, 'Requirement saved');
      _reload();
    } on ApiException catch (error) {
      if (!mounted) return;
      dpSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int? _parseMinor(String value) {
    final whole = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (whole == null) return null;
    return whole * 100;
  }

  String _backendCategory(String value) {
    return switch (value) {
      'Roles' || 'Models' => 'talent',
      'Locations' => 'location',
      'Media & Equipment' => 'equipment',
      'Crew' => 'crew',
      _ => 'service',
    };
  }
}

class _RequirementGrid extends StatelessWidget {
  final List<DpRequirement> requirements;

  const _RequirementGrid({required this.requirements});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (requirements.isEmpty)
          const DPEmptyState(
            icon: Icons.rule_folder_outlined,
            title: 'No requirements yet',
            message: 'Save a requirement to start matching people and vendors.',
          )
        else
          DPResponsiveGrid(
            children: requirements
                .map(
                  (req) => DPRequirementCard(
                    requirement: req,
                    onFindMatches: () => Navigator.pushNamed(
                      context,
                      DirectorProducerRoutes.marketplace,
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
