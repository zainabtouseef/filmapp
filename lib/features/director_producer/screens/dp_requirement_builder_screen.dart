import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/casting/casting_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/projects/project_models.dart';
import '../../../core/projects/projects_controller.dart';
import '../../../core/uploads/upload_repository.dart';
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
  final _title = TextEditingController();
  final _summary = TextEditingController();
  final _budgetMin = TextEditingController();
  final _budgetMax = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _requiredDocuments = TextEditingController();
  final _roleType = TextEditingController();
  final _workLocation = TextEditingController();
  final _deadline = TextEditingController();
  final _instructions = TextEditingController();
  final _eligibility = TextEditingController();
  final _questions = TextEditingController();
  final _contactName = TextEditingController();
  final _contactEmail = TextEditingController();
  String _category = 'Roles';
  String _auditionMode = 'self_tape';
  String _visibility = 'all';
  Future<List<ProjectRequirement>>? _requirementsFuture;
  bool _started = false;
  bool _saving = false;
  bool _uploadingSides = false;
  double? _sidesProgress;
  String? _sidesFileId;
  String? _sidesFileName;

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
    _quantity.dispose();
    _requiredDocuments.dispose();
    _roleType.dispose();
    _workLocation.dispose();
    _deadline.dispose();
    _instructions.dispose();
    _eligibility.dispose();
    _questions.dispose();
    _contactName.dispose();
    _contactEmail.dispose();
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
          onTap: _saving || _uploadingSides ? () {} : _saveRequirement,
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
              const SizedBox(height: 10),
              CoreTextField(
                controller: _quantity,
                label: 'Positions needed',
                icon: Icons.groups_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: _requiredDocuments,
                label: 'Required documents (comma separated)',
                icon: Icons.description_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in const {
                      'all': 'Show to all profiles',
                      'verified_only': 'Verified profiles only',
                    }.entries)
                      ChoiceChip(
                        label: Text(option.value),
                        selected: _visibility == option.key,
                        onSelected: (_) =>
                            setState(() => _visibility = option.key),
                      ),
                  ],
                ),
              ),
              if (_backendCategory(_category) == 'talent') ...[
                const SizedBox(height: 12),
                CoreTextField(
                  controller: _roleType,
                  label: 'Role type',
                  icon: Icons.theater_comedy_outlined,
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: _workLocation,
                  label: 'Work location or travel requirement',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: _deadline,
                  label: 'Application deadline (YYYY-MM-DD)',
                  icon: Icons.event_busy_outlined,
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final mode in const {
                        'self_tape': 'Self-tape',
                        'in_person': 'In person',
                        'online': 'Online',
                        'hybrid': 'Hybrid',
                      }.entries)
                        ChoiceChip(
                          label: Text(mode.value),
                          selected: _auditionMode == mode.key,
                          onSelected: (_) =>
                              setState(() => _auditionMode = mode.key),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: _eligibility,
                  label: 'Eligibility (comma separated)',
                  icon: Icons.rule_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: _questions,
                  label: 'Casting questions (one per line)',
                  icon: Icons.question_answer_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: _instructions,
                  label: 'Application and audition instructions',
                  icon: Icons.assignment_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: 210,
                        child: CoreSecondaryButton(
                          icon: Icons.picture_as_pdf_outlined,
                          label: _sidesFileName == null
                              ? 'Attach script / sides'
                              : 'Replace sides PDF',
                          compact: true,
                          onTap: _saving || _uploadingSides ? null : _pickSides,
                        ),
                      ),
                      if (_sidesFileName != null)
                        Chip(
                          avatar: const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 17,
                          ),
                          label: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 210),
                            child: Text(
                              _sidesFileName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          onDeleted: _saving || _uploadingSides
                              ? null
                              : () => setState(() {
                                    _sidesFileId = null;
                                    _sidesFileName = null;
                                    _sidesProgress = null;
                                  }),
                        ),
                    ],
                  ),
                ),
                if (_uploadingSides) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _sidesProgress),
                ],
                const SizedBox(height: 10),
                CoreTextField(
                  controller: _contactName,
                  label: 'Casting contact name',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: _contactEmail,
                  label: 'Casting contact email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: DPHolographicButton(
            label: _saving ? 'Saving Requirement' : 'Save Requirement',
            icon: Icons.save_outlined,
            onTap: _saving || _uploadingSides ? null : _saveRequirement,
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
    final casting = CastingScope.maybeOf(context);
    setState(() => _saving = true);
    try {
      final requirement = await controller.createRequirement(
        projectId: projectId,
        category: _backendCategory(_category),
        title: _title.text.trim(),
        summary: _summary.text.trim(),
        budgetMinMinor: _parseMinor(_budgetMin.text),
        budgetMaxMinor: _parseMinor(_budgetMax.text),
        visibility: _visibility,
        quantity: int.tryParse(_quantity.text.trim()) ?? 1,
        requiredDocuments: _commaValues(_requiredDocuments.text),
      );
      if (_backendCategory(_category) == 'talent') {
        if (casting == null) {
          throw const ApiException(
            code: 'casting.scope_missing',
            message: 'Casting service is unavailable.',
          );
        }
        final deadline = DateTime.tryParse(_deadline.text.trim());
        await casting.publishRole(
          requirement.publicId,
          {
            'role_type': _roleType.text.trim(),
            'work_location': _workLocation.text.trim(),
            'audition_mode': _auditionMode,
            'instructions': _instructions.text.trim(),
            'eligibility': _commaValues(_eligibility.text),
            'casting_questions': _lineValues(_questions.text),
            if (_sidesFileId != null) 'sides_file_id': _sidesFileId,
            if (deadline != null)
              'application_due_at': DateTime(
                deadline.year,
                deadline.month,
                deadline.day,
                23,
                59,
              ).toUtc().toIso8601String(),
            'contact_name': _contactName.text.trim(),
            'contact_email': _contactEmail.text.trim(),
            'publish': true,
          },
        );
      }
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

  Future<void> _pickSides() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) {
      dpSnack(context, 'Sign in to upload casting sides');
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return;
    setState(() {
      _uploadingSides = true;
      _sidesProgress = 0;
    });
    try {
      final uploaded = await auth.uploadFile(
        purpose: 'project_document',
        file: PickedFileData(
          name: file.name,
          mimeType: 'application/pdf',
          bytes: bytes,
        ),
        onProgress: (sent, total) {
          if (mounted && total > 0) {
            setState(() => _sidesProgress = sent / total);
          }
        },
      );
      if (!mounted) return;
      setState(() {
        _sidesFileId = uploaded.publicId;
        _sidesFileName = uploaded.originalName;
        _sidesProgress = 1;
      });
      dpSnack(context, 'Casting sides ready');
    } on ApiException catch (error) {
      if (mounted) dpSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _uploadingSides = false);
    }
  }

  int? _parseMinor(String value) {
    final whole = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (whole == null) return null;
    return whole * 100;
  }

  String _backendCategory(String value) {
    return switch (value) {
      'Roles' => 'talent',
      'Models' => 'model',
      'Locations' => 'location',
      'Media & Equipment' => 'equipment',
      'Crew' => 'crew',
      _ => 'service',
    };
  }

  List<String> _commaValues(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<String> _lineValues(String value) {
    return value
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
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
