import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/cineplanner/cineplanner_controller.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/save_download.dart';
import '../../../core/projects/projects_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/uploads/upload_repository.dart';

class CinePlannerConsoleScreen extends StatefulWidget {
  const CinePlannerConsoleScreen({super.key});

  @override
  State<CinePlannerConsoleScreen> createState() =>
      _CinePlannerConsoleScreenState();
}

class _CinePlannerConsoleScreenState extends State<CinePlannerConsoleScreen> {
  static const _modules = <_CineModule>[
    _CineModule('Dashboard', Icons.grid_view_rounded),
    _CineModule('Screenplay', Icons.description_outlined),
    _CineModule('Scenes', Icons.movie_filter_outlined),
    _CineModule('Characters', Icons.theater_comedy_outlined),
    _CineModule('Casting', Icons.groups_2_outlined),
    _CineModule('Locations', Icons.location_city_outlined),
    _CineModule('Props', Icons.inventory_2_outlined),
    _CineModule('Wardrobe', Icons.checkroom_outlined),
    _CineModule('Makeup', Icons.face_retouching_natural_outlined),
    _CineModule('Vehicles', Icons.directions_car_outlined),
    _CineModule('Extras', Icons.groups_outlined),
    _CineModule('Stunts', Icons.sports_martial_arts_outlined),
    _CineModule('VFX / SFX', Icons.auto_awesome_motion_outlined),
    _CineModule('Equipment', Icons.videocam_outlined),
    _CineModule('Crew', Icons.badge_outlined),
    _CineModule('Scheduling', Icons.calendar_month_outlined),
    _CineModule('Timetable', Icons.view_timeline_outlined),
    _CineModule('Budget', Icons.account_balance_wallet_outlined),
    _CineModule('Call Sheets', Icons.assignment_outlined),
    _CineModule('Reports', Icons.analytics_outlined),
    _CineModule('AI Assistant', Icons.auto_awesome_outlined),
    _CineModule('Settings', Icons.tune_outlined),
  ];

  String _selectedModule = 'Dashboard';
  String _query = '';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    scheduleMicrotask(() async {
      try {
        await CinePlannerScope.of(context).loadProductions();
      } catch (_) {
        // The connected error state is rendered by the controller.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = CinePlannerScope.of(context);
    return _CinePlannerTheme(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.loading && controller.snapshot == null) {
            return const _CineLoadingState();
          }
          if (controller.errorMessage != null && controller.snapshot == null) {
            return _CineErrorState(
              message: controller.errorMessage!,
              onRetry: () => controller.loadProductions(),
            );
          }
          if (controller.productions.isEmpty) {
            return _CineOnboarding(
              onCreate: (title, file) =>
                  _createProjectAndUpload(controller, title, file),
            );
          }
          final snapshot = controller.snapshot;
          if (snapshot == null) return const _CineLoadingState();
          return _console(controller, snapshot);
        },
      ),
    );
  }

  Widget _console(
    CinePlannerController controller,
    Map<String, dynamic> snapshot,
  ) {
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
            _showCommandPalette(controller),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            _showCommandPalette(controller),
        const SingleActivator(LogicalKeyboardKey.keyR, alt: true): () =>
            controller.loadProductions(selectFirst: false),
      },
      child: Focus(
        autofocus: true,
        child: Column(
          key: const ValueKey('cineplanner-premium-shell'),
          children: [
            _CineCommandBar(
              productions: controller.productions,
              selectedId: controller.selectedProductionId,
              onSelected: (value) {
                if (value != null) controller.selectProduction(value);
              },
              onUpload: () => _uploadScreenplay(controller),
              onCreateProject: () => _showNewProjectDialog(controller),
              onRefresh: () => controller.loadProductions(selectFirst: false),
              onCommandPalette: () => _showCommandPalette(controller),
              onModuleSearch: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 188,
                          child: _CineSidebar(
                            modules: _modules,
                            selected: _selectedModule,
                            onSelected: (value) =>
                                setState(() => _selectedModule = value),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CinePanel(
                            child: _moduleContent(controller, snapshot),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _selectedModule,
                          decoration: const InputDecoration(
                            labelText: 'CinePlanner module',
                            prefixIcon:
                                Icon(Icons.dashboard_customize_outlined),
                          ),
                          items: _modules
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.label,
                                  child: Text(item.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedModule = value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _CinePanel(
                            child: _moduleContent(controller, snapshot),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCommandPalette(CinePlannerController controller) async {
    final selection = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('CinePlanner command palette'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'upload'),
            child: const ListTile(
              leading: Icon(Icons.upload_file_outlined),
              title: Text('Upload script'),
              subtitle: Text('U'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'new_project'),
            child: const ListTile(
              leading: Icon(Icons.add_box_outlined),
              title: Text('New project with script'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'refresh'),
            child: const ListTile(
              leading: Icon(Icons.refresh_outlined),
              title: Text('Refresh production'),
              subtitle: Text('Alt+R'),
            ),
          ),
          const Divider(),
          for (final module in _modules)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, module.label),
              child: ListTile(
                leading: Icon(module.icon),
                title: Text('Open ${module.label}'),
              ),
            ),
        ],
      ),
    );
    if (!mounted || selection == null) return;
    if (selection == 'upload') {
      await _uploadScreenplay(controller);
    } else if (selection == 'new_project') {
      await _showNewProjectDialog(controller);
    } else if (selection == 'refresh') {
      await controller.loadProductions(selectFirst: false);
    } else {
      setState(() => _selectedModule = selection);
    }
  }

  Widget _moduleContent(
    CinePlannerController controller,
    Map<String, dynamic> snapshot,
  ) {
    return switch (_selectedModule) {
      'Dashboard' => _CineDashboard(snapshot: snapshot),
      'Screenplay' => _CineScreenplay(
          snapshot: snapshot,
          onUpload: () => _uploadScreenplay(controller),
          onApprove: () => _runMutation(
            controller,
            () => controller.repository.approveBreakdown(
              controller.selectedProductionId!,
            ),
            successMessage: 'Breakdown approved.',
          ),
        ),
      'Scenes' => _CineScenes(
          snapshot: snapshot,
          query: _query,
          onEdit: (item) => _editScene(controller, item),
        ),
      'Characters' => _CineCharacters(
          snapshot: snapshot,
          query: _query,
          onEdit: (item) => _editCharacter(controller, item),
        ),
      'Casting' => _CineCasting(
          snapshot: snapshot,
          onAddActor: () => _addActor(controller),
          onAssign: (character, actor, status) => _runMutation(
            controller,
            () => controller.repository.assignActor(
              productionId: controller.selectedProductionId!,
              characterId: character,
              actorId: actor,
              status: status,
            ),
            successMessage: 'Casting status updated.',
          ),
          onAvailability: (actor) => _addAvailability(controller, actor),
        ),
      'Locations' => _CineLocations(
          snapshot: snapshot,
          onAdd: () => _addLocation(controller, snapshot),
          onStatus: (item, status) => _runMutation(
            controller,
            () => controller.repository.updateItem(
              productionId: controller.selectedProductionId!,
              resource: 'locations',
              itemId: item['public_id'] as String,
              values: {'status': status},
            ),
            successMessage: 'Location status updated.',
          ),
        ),
      'Props' => _elements(controller, snapshot, const {'props'}),
      'Wardrobe' => _elements(controller, snapshot, const {'wardrobe'}),
      'Makeup' => _elements(controller, snapshot, const {'makeup'}),
      'Vehicles' => _elements(controller, snapshot, const {'vehicles'}),
      'Extras' => _elements(controller, snapshot, const {'extras'}),
      'Stunts' => _elements(controller, snapshot, const {'stunts'}),
      'VFX / SFX' => _elements(controller, snapshot, const {'vfx', 'sfx'}),
      'Equipment' => _elements(controller, snapshot, const {'equipment'}),
      'Crew' => _CineCrew(
          snapshot: snapshot,
          onAdd: () => _addCrew(controller),
        ),
      'Scheduling' => _CineScheduling(
          snapshot: snapshot,
          onPreview: () => _schedulePreview(controller),
          onOptimize: (apply) => _optimize(controller, apply),
          onLock: (locked) => _runMutation(
            controller,
            () => controller.repository.lockSchedule(
              controller.selectedProductionId!,
              locked,
            ),
            successMessage: locked ? 'Schedule locked.' : 'Schedule unlocked.',
          ),
        ),
      'Timetable' => _CineTimetable(
          snapshot: snapshot,
          onMove: (event, day) => _moveEvent(controller, event, day),
        ),
      'Budget' => _CineBudget(
          snapshot: snapshot,
          onEdit: (line) => _editBudgetLine(controller, line),
        ),
      'Call Sheets' => _CineCallSheets(
          snapshot: snapshot,
          onDownload: (sheetId) => _downloadCallSheet(controller, sheetId),
          onGenerate: (dayId) => _runMutation(
            controller,
            () async {
              await controller.repository.generateCallSheet(
                productionId: controller.selectedProductionId!,
                shootDayId: dayId,
              );
            },
            successMessage: 'Call sheet generated.',
          ),
        ),
      'Reports' => _CineReports(
          productionId: controller.selectedProductionId!,
          controller: controller,
        ),
      'AI Assistant' => _CineAssistant(
          productionId: controller.selectedProductionId!,
          controller: controller,
        ),
      'Settings' => _CineSettings(snapshot: snapshot),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _elements(
    CinePlannerController controller,
    Map<String, dynamic> snapshot,
    Set<String> categories,
  ) {
    return _CineElements(
      snapshot: snapshot,
      categories: categories,
      onAdd: () => _addElement(controller, categories.first),
      onEdit: (item) => _editElement(controller, item),
    );
  }

  Future<void> _uploadScreenplay(CinePlannerController controller) async {
    final file = await _pickPdf();
    if (file == null) return;
    await _processScreenplay(controller, file);
  }

  Future<PickedFileData?> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (!mounted || result == null) return null;
    final picked = result.files.single;
    if (picked.bytes == null) {
      _notice('The selected PDF could not be read.', error: true);
      return null;
    }
    return PickedFileData(
      name: picked.name,
      mimeType: 'application/pdf',
      bytes: picked.bytes!,
    );
  }

  Future<void> _processScreenplay(
    CinePlannerController controller,
    PickedFileData file,
  ) async {
    final progress = ValueNotifier<_ProcessingProgress>(
      const _ProcessingProgress('File uploaded', 0.02),
    );
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ProcessingDialog(progress: progress),
      ),
    );
    try {
      final upload = await controller.uploadScreenplay(
        file: file,
        label:
            'Draft ${(controller.snapshot?['scripts'] as List? ?? const []).length + 1}',
        onProgress: (sent, total) => progress.value = _ProcessingProgress(
          'Uploading screenplay securely',
          total == 0 ? 0.05 : 0.05 + (sent / total * 0.12),
        ),
        onStatus: (status) => progress.value = _ProcessingProgress(
          status,
          progress.value.progress,
        ),
      );
      final job = upload['job'] as Map<String, dynamic>;
      final finalJob = await controller.waitForJob(
        job['public_id'] as String,
        onProgress: (value) => progress.value = _ProcessingProgress(
          _stageLabel(value['current_stage'] as String? ?? 'processing'),
          ((value['progress_percent'] as num?)?.toDouble() ?? 0) / 100,
        ),
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (finalJob['status'] == 'completed') {
        _notice('CinePlanner is ready for review.');
        setState(() => _selectedModule = 'Screenplay');
      } else {
        final error = finalJob['error'] as Map<String, dynamic>?;
        _notice(
          error?['message'] as String? ?? 'Screenplay analysis failed.',
          error: true,
        );
      }
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _notice(_message(error), error: true);
    } finally {
      progress.dispose();
    }
  }

  Future<void> _createProjectAndUpload(
    CinePlannerController controller,
    String title,
    PickedFileData file,
  ) async {
    try {
      final project = await ProjectsScope.of(context).createProject(
        title: title,
        projectType: 'film',
        description: 'Production workspace created in CinePlanner.',
      );
      await controller.createProduction(
        title: title,
        projectId: project.publicId,
      );
      await _processScreenplay(controller, file);
    } catch (error) {
      if (mounted) _notice(_message(error), error: true);
    }
  }

  Future<void> _showNewProjectDialog(
    CinePlannerController controller,
  ) async {
    final title = TextEditingController();
    PickedFileData? file;
    final input = await showDialog<_NewProjectScript>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New project and script'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create the portal project and start its CinePlanner breakdown in one step.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: title,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Project name',
                    prefixIcon: Icon(Icons.movie_outlined),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await _pickPdf();
                    if (picked != null) {
                      setDialogState(() => file = picked);
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(file?.name ?? 'Select screenplay PDF'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: title.text.trim().length >= 2 && file != null
                  ? () => Navigator.pop(
                        context,
                        _NewProjectScript(title.text.trim(), file!),
                      )
                  : null,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Create & plan'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    if (!mounted || input == null) return;
    await _createProjectAndUpload(controller, input.title, input.file);
  }

  String _stageLabel(String stage) => switch (stage) {
        'file_uploaded' => 'File uploaded',
        'script_detected' => 'Script detected',
        'scenes_extracted' => 'Scenes extracted',
        'characters_extracted' => 'Characters extracted',
        'locations_extracted' => 'Locations extracted',
        'production_elements_extracted' => 'Production elements extracted',
        'continuity_analyzed' => 'Continuity analyzed',
        'saving_breakdown' => 'Schedule prepared',
        'cineplanner_ready' => 'CinePlanner ready',
        _ => 'Processing screenplay',
      };

  Future<void> _runMutation(
    CinePlannerController controller,
    Future<void> Function() operation, {
    required String successMessage,
  }) async {
    try {
      await controller.mutate(operation);
      if (mounted) _notice(successMessage);
    } catch (error) {
      if (mounted) _notice(_message(error), error: true);
    }
  }

  Future<void> _editScene(
    CinePlannerController controller,
    Map<String, dynamic> item,
  ) async {
    final result = await _textEditDialog(
      title: 'Edit scene ${item['scene_number']}',
      fields: {
        'slugline': item['slugline'] as String? ?? '',
        'summary': item['summary'] as String? ?? '',
        'production_notes': item['production_notes'] as String? ?? '',
        'safety_notes': item['safety_notes'] as String? ?? '',
        'continuity_notes': item['continuity_notes'] as String? ?? '',
      },
    );
    if (result == null) return;
    await _runMutation(
      controller,
      () => controller.repository.updateItem(
        productionId: controller.selectedProductionId!,
        resource: 'scenes',
        itemId: item['public_id'] as String,
        values: {...result, 'review_status': 'reviewed'},
      ),
      successMessage: 'Scene updated.',
    );
  }

  Future<void> _editCharacter(
    CinePlannerController controller,
    Map<String, dynamic> item,
  ) async {
    final result = await _textEditDialog(
      title: 'Edit ${item['name']}',
      fields: {
        'name': item['name'] as String? ?? '',
        'playing_age': item['playing_age'] as String? ?? '',
        'description': item['description'] as String? ?? '',
      },
    );
    if (result == null) return;
    await _runMutation(
      controller,
      () => controller.repository.updateItem(
        productionId: controller.selectedProductionId!,
        resource: 'characters',
        itemId: item['public_id'] as String,
        values: {...result, 'review_status': 'reviewed'},
      ),
      successMessage: 'Character updated.',
    );
  }

  Future<void> _addActor(CinePlannerController controller) async {
    final result = await _textEditDialog(
      title: 'Create actor profile',
      fields: const {
        'name': '',
        'playing_age_min': '',
        'playing_age_max': '',
        'languages': '',
        'skills': '',
        'city': '',
        'agency': '',
        'phone': '',
        'email': '',
        'daily_rate_minor': '',
        'notes': '',
      },
    );
    if (result == null) return;
    await _runMutation(
      controller,
      () => controller.repository.createActor({
        ...result,
        'playing_age_min': int.tryParse(result['playing_age_min'] ?? ''),
        'playing_age_max': int.tryParse(result['playing_age_max'] ?? ''),
        'daily_rate_minor': int.tryParse(result['daily_rate_minor'] ?? ''),
        'languages': _commaList(result['languages']),
        'skills': _commaList(result['skills']),
      }),
      successMessage: 'Actor profile created.',
    );
  }

  Future<void> _addAvailability(
    CinePlannerController controller,
    String actorId,
  ) async {
    final result = await _textEditDialog(
      title: 'Actor availability',
      fields: {
        'starts_on': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'ends_on': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'status': 'available',
        'notes': '',
      },
    );
    if (result == null) return;
    await _runMutation(
      controller,
      () => controller.repository.addActorAvailability(
        actorId: actorId,
        values: {
          ...result,
          'production_id': controller.selectedProductionId,
        },
      ),
      successMessage: 'Availability added.',
    );
  }

  Future<void> _addLocation(
    CinePlannerController controller,
    Map<String, dynamic> snapshot,
  ) async {
    final extracted = (snapshot['locations'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final result = await _textEditDialog(
      title: 'Add location option',
      fields: {
        'screenplay_name': extracted.isEmpty
            ? ''
            : extracted.first['screenplay_name'] as String? ?? '',
        'option_name': '',
        'address': '',
        'contact_name': '',
        'contact_phone': '',
        'rental_rate_minor': '',
        'parking': '',
        'electricity': '',
        'permit_requirements': '',
        'notes': '',
      },
    );
    if (result == null) return;
    await _runMutation(
      controller,
      () => controller.repository.createLocation(
        productionId: controller.selectedProductionId!,
        values: {
          ...result,
          'rental_rate_minor': int.tryParse(result['rental_rate_minor'] ?? ''),
        },
      ),
      successMessage: 'Location option added.',
    );
  }

  Future<void> _addElement(
    CinePlannerController controller,
    String category,
  ) async {
    final result = await _textEditDialog(
      title: 'Add ${category.toUpperCase()} item',
      fields: const {
        'name': '',
        'description': '',
        'scene_numbers': '',
        'quantity': '1',
        'cost_rate_minor': '',
        'rate_basis': 'flat',
        'owner_vendor': '',
        'continuity_notes': '',
      },
    );
    if (result == null) return;
    await _runMutation(
      controller,
      () => controller.repository.createElement(
        productionId: controller.selectedProductionId!,
        values: {
          ...result,
          'category': category,
          'scene_numbers': _commaList(result['scene_numbers']),
          'quantity': int.tryParse(result['quantity'] ?? '') ?? 1,
          'cost_rate_minor': int.tryParse(result['cost_rate_minor'] ?? ''),
        },
      ),
      successMessage: 'Production item added.',
    );
  }

  Future<void> _editElement(
    CinePlannerController controller,
    Map<String, dynamic> item,
  ) async {
    final result = await _textEditDialog(
      title: 'Edit ${item['name']}',
      fields: {
        'name': item['name'] as String? ?? '',
        'quantity': '${item['quantity'] ?? 1}',
        'cost_rate_minor': '${item['cost_rate_minor'] ?? ''}',
        'owner_vendor': item['owner_vendor'] as String? ?? '',
        'status': item['status'] as String? ?? 'required',
        'continuity_notes': item['continuity_notes'] as String? ?? '',
        'notes': item['notes'] as String? ?? '',
      },
    );
    if (result == null) return;
    await _runMutation(
      controller,
      () => controller.repository.updateItem(
        productionId: controller.selectedProductionId!,
        resource: 'elements',
        itemId: item['public_id'] as String,
        values: {
          ...result,
          'quantity': int.tryParse(result['quantity'] ?? '') ?? 1,
          'cost_rate_minor': int.tryParse(result['cost_rate_minor'] ?? ''),
          'review_status': 'reviewed',
        },
      ),
      successMessage: 'Production item updated.',
    );
  }

  Future<void> _addCrew(CinePlannerController controller) async {
    final result = await _textEditDialog(
      title: 'Add crew member',
      fields: const {
        'name': '',
        'department': '',
        'job_title': '',
        'phone': '',
        'email': '',
        'daily_rate_minor': '',
        'status': 'confirmed',
      },
    );
    if (result == null) return;
    await _runMutation(
      controller,
      () => controller.repository.createCrewMember(
        productionId: controller.selectedProductionId!,
        values: {
          ...result,
          'daily_rate_minor': int.tryParse(result['daily_rate_minor'] ?? ''),
        },
      ),
      successMessage: 'Crew member added.',
    );
  }

  Future<void> _schedulePreview(CinePlannerController controller) async {
    try {
      final result = await controller.repository.generateSchedule(
        productionId: controller.selectedProductionId!,
      );
      if (!mounted) return;
      final plans =
          (result['plans'] as List<dynamic>).cast<Map<String, dynamic>>();
      final strategy = await showDialog<String>(
        context: context,
        builder: (context) => _SchedulePlanDialog(plans: plans),
      );
      if (strategy == null) return;
      await _runMutation(
        controller,
        () async {
          await controller.repository.generateSchedule(
            productionId: controller.selectedProductionId!,
            strategy: strategy,
            apply: true,
          );
        },
        successMessage: 'Shooting schedule generated.',
      );
    } catch (error) {
      if (mounted) _notice(_message(error), error: true);
    }
  }

  Future<void> _optimize(
    CinePlannerController controller,
    bool apply,
  ) async {
    try {
      final result = await controller.repository.optimizeSchedule(
        productionId: controller.selectedProductionId!,
        apply: apply,
      );
      if (!mounted) return;
      if (apply) await controller.refresh();
      final savings = (result['estimated_savings_minor'] as num?)?.toInt() ?? 0;
      _notice(
        apply
            ? 'Optimized schedule applied.'
            : 'Estimated savings: ${_money(savings, _currency(controller.snapshot))}',
      );
    } catch (error) {
      if (mounted) _notice(_message(error), error: true);
    }
  }

  Future<void> _moveEvent(
    CinePlannerController controller,
    Map<String, dynamic> event,
    Map<String, dynamic> day,
  ) async {
    await _runMutation(
      controller,
      () => controller.repository.moveScheduleEvent(
        productionId: controller.selectedProductionId!,
        eventId: event['public_id'] as String,
        shootDayId: day['public_id'] as String,
        startsAt: event['starts_at'] as String,
        endsAt: event['ends_at'] as String,
      ),
      successMessage: 'Scene moved and conflicts rechecked.',
    );
  }

  Future<void> _editBudgetLine(
    CinePlannerController controller,
    Map<String, dynamic> line,
  ) async {
    final result = await _textEditDialog(
      title: 'Update budget line',
      fields: {
        'quoted_minor': '${line['quoted_minor'] ?? 0}',
        'approved_minor': '${line['approved_minor'] ?? 0}',
        'committed_minor': '${line['committed_minor'] ?? 0}',
        'paid_minor': '${line['paid_minor'] ?? 0}',
        'status': line['status'] as String? ?? 'estimated',
        'notes': line['notes'] as String? ?? '',
      },
    );
    if (result == null) return;
    await _runMutation(
      controller,
      () => controller.repository.updateBudgetLine(
        productionId: controller.selectedProductionId!,
        lineId: line['public_id'] as String,
        values: {
          ...result,
          for (final key in const [
            'quoted_minor',
            'approved_minor',
            'committed_minor',
            'paid_minor',
          ])
            key: int.tryParse(result[key] ?? '') ?? 0,
        },
      ),
      successMessage: 'Budget updated.',
    );
  }

  Future<void> _downloadCallSheet(
    CinePlannerController controller,
    String sheetId,
  ) async {
    try {
      final download = await controller.repository.downloadCallSheet(
        productionId: controller.selectedProductionId!,
        callSheetId: sheetId,
      );
      final saved = saveDownload(
        download.filename,
        download.bytes,
        download.contentType,
      );
      if (mounted) {
        _notice(
          saved
              ? 'Call sheet PDF downloaded.'
              : 'PDF download is available in the web app.',
        );
      }
    } catch (error) {
      if (mounted) _notice(_message(error), error: true);
    }
  }

  Future<Map<String, String>?> _textEditDialog({
    required String title,
    required Map<String, String> fields,
  }) async {
    final controllers = fields.map(
      (key, value) => MapEntry(key, TextEditingController(text: value)),
    );
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: controllers.entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: entry.value,
                        minLines: _longField(entry.key) ? 2 : 1,
                        maxLines: _longField(entry.key) ? 5 : 1,
                        decoration: InputDecoration(
                          labelText: _fieldLabel(entry.key),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              controllers.map((key, value) => MapEntry(key, value.text.trim())),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    for (final controller in controllers.values) {
      controller.dispose();
    }
    return result;
  }

  bool _longField(String key) =>
      key.contains('notes') ||
      key == 'summary' ||
      key == 'description' ||
      key == 'permit_requirements';

  String _fieldLabel(String key) => key
      .split('_')
      .map((word) => word.isEmpty
          ? word
          : '${word.substring(0, 1).toUpperCase()}${word.substring(1)}')
      .join(' ');

  List<String> _commaList(String? value) => (value ?? '')
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  String _message(Object error) =>
      error is ApiException ? error.message : error.toString();

  void _notice(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade800 : null,
      ),
    );
  }
}

class _CinePlannerTheme extends StatelessWidget {
  final Widget child;

  const _CinePlannerTheme({required this.child});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final colors = context.appColors;
    final textTheme = base.textTheme.copyWith(
      displayLarge:
          AppTextStyles.displayLarge.copyWith(color: colors.textPrimary),
      headlineMedium: AppTextStyles.heading.copyWith(color: colors.textPrimary),
      titleLarge:
          AppTextStyles.sectionTitle.copyWith(color: colors.textPrimary),
      titleMedium: AppTextStyles.cardTitle.copyWith(color: colors.textPrimary),
      titleSmall: AppTextStyles.label.copyWith(color: colors.textPrimary),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: colors.textPrimary),
      bodyMedium: AppTextStyles.body.copyWith(color: colors.textPrimary),
      bodySmall: AppTextStyles.caption.copyWith(color: colors.textSecondary),
      labelLarge: AppTextStyles.label.copyWith(color: colors.textPrimary),
      labelMedium: AppTextStyles.caption.copyWith(color: colors.textSecondary),
      labelSmall: AppTextStyles.micro.copyWith(color: colors.textSecondary),
    );
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
    );

    return Theme(
      data: base.copyWith(
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        splashFactory: InkRipple.splashFactory,
        textTheme: textTheme,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colors.elevatedSurface,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          labelStyle: AppTextStyles.caption.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          hintStyle:
              AppTextStyles.bodyMuted.copyWith(color: colors.textTertiary),
          prefixIconColor: colors.iconMuted,
          suffixIconColor: colors.iconMuted,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(color: colors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(color: colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(color: colors.focusRing, width: 1.4),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(40, 40),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: controlShape,
            textStyle: AppTextStyles.label,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(40, 40),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            side: BorderSide(color: colors.border),
            shape: controlShape,
            textStyle: AppTextStyles.label,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(36, 36),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            foregroundColor: colors.goldDark,
            textStyle: AppTextStyles.label,
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            minimumSize: const Size.square(38),
            padding: const EdgeInsets.all(8),
            shape: controlShape,
          ),
        ),
        listTileTheme: ListTileThemeData(
          dense: true,
          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          iconColor: colors.iconMuted,
          textColor: colors.textPrimary,
          titleTextStyle: AppTextStyles.cardTitle.copyWith(
            color: colors.textPrimary,
            fontSize: 13.5,
          ),
          subtitleTextStyle:
              AppTextStyles.caption.copyWith(color: colors.textSecondary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        expansionTileTheme: ExpansionTileThemeData(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          iconColor: colors.goldDark,
          collapsedIconColor: colors.iconMuted,
          textColor: colors.textPrimary,
          collapsedTextColor: colors.textPrimary,
          shape: const RoundedRectangleBorder(),
          collapsedShape: const RoundedRectangleBorder(),
        ),
        dataTableTheme: DataTableThemeData(
          headingRowHeight: 38,
          dataRowMinHeight: 40,
          dataRowMaxHeight: 52,
          horizontalMargin: 14,
          columnSpacing: 24,
          dividerThickness: 1,
          headingTextStyle: AppTextStyles.panelLabel.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
          dataTextStyle: AppTextStyles.caption.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          headingRowColor: WidgetStatePropertyAll(colors.softSurface),
        ),
      ),
      child: DefaultTextStyle.merge(
        style: AppTextStyles.body.copyWith(color: colors.textPrimary),
        child: child,
      ),
    );
  }
}

class _CineModule {
  final String label;
  final IconData icon;

  const _CineModule(this.label, this.icon);
}

class _NewProjectScript {
  final String title;
  final PickedFileData file;

  const _NewProjectScript(this.title, this.file);
}

class _CineCommandBar extends StatelessWidget {
  final List<Map<String, dynamic>> productions;
  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final VoidCallback onUpload;
  final VoidCallback onCreateProject;
  final VoidCallback onRefresh;
  final VoidCallback onCommandPalette;
  final ValueChanged<String> onModuleSearch;

  const _CineCommandBar({
    required this.productions,
    required this.selectedId,
    required this.onSelected,
    required this.onUpload,
    required this.onCreateProject,
    required this.onRefresh,
    required this.onCommandPalette,
    required this.onModuleSearch,
  });

  @override
  Widget build(BuildContext context) {
    return _CinePanel(
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final selector = DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: selectedId,
            decoration: const InputDecoration(
              labelText: 'Active production',
              prefixIcon: Icon(Icons.movie_creation_outlined),
              isDense: true,
            ),
            items: productions
                .map(
                  (item) => DropdownMenuItem(
                    value: item['public_id'] as String,
                    child: Text(
                      item['title'] as String? ?? 'Untitled',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: onSelected,
          );
          final actions = Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              FilledButton.icon(
                onPressed: onUpload,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Upload script'),
              ),
              OutlinedButton.icon(
                onPressed: onCreateProject,
                icon: const Icon(Icons.add_rounded),
                label: const Text('New project'),
              ),
              IconButton.filledTonal(
                onPressed: onCommandPalette,
                tooltip: 'Command palette · Ctrl/⌘ K',
                icon: const Icon(Icons.terminal_rounded),
              ),
              IconButton.filledTonal(
                onPressed: onRefresh,
                tooltip: 'Refresh production data',
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: _CineBrand(),
                ),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: actions),
                const SizedBox(height: 10),
                selector,
                const SizedBox(height: 10),
                TextField(
                  onChanged: onModuleSearch,
                  decoration: const InputDecoration(
                    hintText: 'Search the current module',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              const _CineBrand(),
              const SizedBox(width: 16),
              SizedBox(width: 270, child: selector),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  onChanged: onModuleSearch,
                  decoration: const InputDecoration(
                    hintText: 'Search the current module',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _CineBrand extends StatelessWidget {
  const _CineBrand();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: colors.goldGradient,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: colors.goldMid),
            boxShadow: AppShadows.control,
          ),
          child: Icon(
            Icons.view_timeline_rounded,
            color: colors.onGold,
            size: 19,
          ),
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CinePlanner',
              style: AppTextStyles.cardTitle.copyWith(
                color: colors.textPrimary,
                fontSize: 16,
              ),
            ),
            Text(
              'Production intelligence',
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CineSidebar extends StatelessWidget {
  final List<_CineModule> modules;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CineSidebar({
    required this.modules,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return _CinePanel(
      padding: const EdgeInsets.fromLTRB(7, 8, 7, 8),
      child: ListView(
        children: modules.map((item) {
          final active = item.label == selected;
          return Container(
            key: ValueKey('cineplanner-module-${item.label}'),
            height: 38,
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: active
                  ? colors.goldGlow
                      .withValues(alpha: colors.isLight ? 0.52 : 0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: active
                  ? Border(left: BorderSide(color: colors.goldMid, width: 3))
                  : null,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: ListTile(
                dense: true,
                selected: active,
                selectedTileColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                visualDensity:
                    const VisualDensity(horizontal: -3, vertical: -4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                leading: Icon(
                  item.icon,
                  size: 18,
                  color: active ? colors.goldDark : colors.iconMuted,
                ),
                title: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: active ? colors.goldDark : colors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                onTap: () => onSelected(item.label),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CinePanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _CinePanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.elevatedSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.border),
        boxShadow: AppShadows.card,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 3, color: colors.goldMid),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class _CineCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final Color? accentColor;

  const _CineCard({
    required this.child,
    this.margin = const EdgeInsets.only(bottom: 8),
    this.color,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color ?? colors.elevatedSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderMuted),
        boxShadow: AppShadows.control,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              color: accentColor ?? colors.goldMid,
            ),
          ),
          // ListTile paints its background and ink on the nearest Material
          // ancestor; interpose a transparent Material so those effects are
          // not swallowed by this card's decorated Container.
          Material(type: MaterialType.transparency, child: child),
        ],
      ),
    );
  }
}

class _CineOnboarding extends StatefulWidget {
  final Future<void> Function(String title, PickedFileData file) onCreate;

  const _CineOnboarding({required this.onCreate});

  @override
  State<_CineOnboarding> createState() => _CineOnboardingState();
}

class _CineOnboardingState extends State<_CineOnboarding> {
  final _title = TextEditingController();
  PickedFileData? _file;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 660),
          child: _CinePanel(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CineBrand(),
                const SizedBox(height: 18),
                Text(
                  'Create your first project plan',
                  style: AppTextStyles.sectionHeaderStyle.copyWith(
                    color: colors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Name the project and add its screenplay PDF. CinePlanner will create '
                  'the portal project, analyze the script, and prepare the production plan.',
                  style: AppTextStyles.bodyMuted.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _title,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Project name',
                    prefixIcon: Icon(Icons.movie_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _pickScript,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(_file?.name ?? 'Select screenplay PDF'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Existing portal projects are added to the production dropdown automatically.',
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed:
                      _saving || _title.text.trim().length < 2 || _file == null
                          ? null
                          : _create,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Create project & plan script'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickScript() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (!mounted || result == null) return;
    final selected = result.files.single;
    if (selected.bytes == null) return;
    setState(
      () => _file = PickedFileData(
        name: selected.name,
        mimeType: 'application/pdf',
        bytes: selected.bytes!,
      ),
    );
  }

  Future<void> _create() async {
    final file = _file;
    if (_title.text.trim().length < 2 || file == null) return;
    setState(() => _saving = true);
    try {
      await widget.onCreate(_title.text.trim(), file);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _CineDashboard extends StatelessWidget {
  final Map<String, dynamic> snapshot;

  const _CineDashboard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final dashboard = snapshot['dashboard'] as Map<String, dynamic>;
    final currency = _currency(snapshot);
    final metrics = [
      ('Pages', '${dashboard['total_pages'] ?? 0}', Icons.menu_book_outlined),
      (
        'Scenes',
        '${dashboard['total_scenes'] ?? 0}',
        Icons.movie_filter_outlined
      ),
      (
        'Characters',
        '${dashboard['characters'] ?? 0}',
        Icons.theater_comedy_outlined
      ),
      ('Leads', '${dashboard['lead_characters'] ?? 0}', Icons.star_outline),
      (
        'Locations',
        '${dashboard['locations'] ?? 0}',
        Icons.location_city_outlined
      ),
      ('Props', '${dashboard['props'] ?? 0}', Icons.inventory_2_outlined),
      (
        'Shoot days',
        '${dashboard['scheduled_shoot_days'] ?? 0}',
        Icons.calendar_month_outlined
      ),
      (
        'Progress',
        '${dashboard['production_progress'] ?? 0}%',
        Icons.donut_large_rounded
      ),
      (
        'Estimated budget',
        _money(dashboard['estimated_budget_minor'], currency),
        Icons.account_balance_wallet_outlined
      ),
      (
        'Open conflicts',
        '${dashboard['schedule_conflicts'] ?? 0}',
        Icons.warning_amber_rounded
      ),
      (
        'Availability',
        '${dashboard['actor_availability_issues'] ?? 0}',
        Icons.event_busy_outlined
      ),
      (
        'AI review queue',
        '${dashboard['unapproved_ai_items'] ?? 0}',
        Icons.fact_check_outlined
      ),
      (
        'Complex scenes',
        '${dashboard['high_complexity_scenes'] ?? 0}',
        Icons.local_fire_department_outlined
      ),
    ];
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _ModuleHeader(
          eyebrow: 'Production command center',
          title: dashboard['screenplay_title'] as String? ??
              (snapshot['production'] as Map<String, dynamic>)['title']
                  as String,
          subtitle: dashboard['upcoming_shoot'] == null
              ? 'No upcoming shoot is scheduled.'
              : 'Next shoot · ${dashboard['upcoming_shoot']}',
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisExtent: 82,
              crossAxisSpacing: 9,
              mainAxisSpacing: 9,
            ),
            itemCount: metrics.length,
            itemBuilder: (context, index) {
              final item = metrics[index];
              return _MetricCard(
                label: item.$1,
                value: item.$2,
                icon: item.$3,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _ConflictSummary(snapshot: snapshot),
      ],
    );
  }
}

class _CineScreenplay extends StatelessWidget {
  final Map<String, dynamic> snapshot;
  final VoidCallback onUpload;
  final VoidCallback onApprove;

  const _CineScreenplay({
    required this.snapshot,
    required this.onUpload,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    final scripts = (snapshot['scripts'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final jobs = (snapshot['jobs'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _ModuleHeader(
          eyebrow: 'Versioned source of truth',
          title: 'Screenplay',
          subtitle:
              'Every uploaded revision is retained and independently reviewed.',
          actions: [
            OutlinedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload script'),
            ),
            FilledButton.icon(
              onPressed: scripts.isNotEmpty &&
                      scripts.first['analysis_status'] == 'review'
                  ? onApprove
                  : null,
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Approve breakdown'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (jobs.isNotEmpty) _JobStatus(job: jobs.first),
        const SizedBox(height: 12),
        if (scripts.isEmpty)
          const _EmptyState(
            icon: Icons.description_outlined,
            title: 'No screenplay yet',
            message: 'Upload a PDF to start the staged production breakdown.',
          )
        else
          ...scripts.map(
            (script) => _CineCard(
              child: ListTile(
                leading: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.appColors.goldGlow,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: context.appColors.goldLight),
                  ),
                  child: Text(
                    'v${script['version_number']}',
                    style: AppTextStyles.smallMeta.copyWith(
                      color: context.appColors.goldDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                title: Text(
                  script['screenplay_title'] as String? ??
                      script['label'] as String? ??
                      'Screenplay',
                ),
                subtitle: Text(
                  '${script['label']} · ${script['total_pages'] ?? 0} pages · '
                  '${script['created_at'] ?? ''}',
                ),
                trailing: _StatusPill('${script['analysis_status']}'),
              ),
            ),
          ),
      ],
    );
  }
}

class _CineScenes extends StatelessWidget {
  final Map<String, dynamic> snapshot;
  final String query;
  final ValueChanged<Map<String, dynamic>> onEdit;

  const _CineScenes({
    required this.snapshot,
    required this.query,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final all = (snapshot['scenes'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final normalized = query.trim().toLowerCase();
    final rows = all
        .where(
          (item) =>
              normalized.isEmpty ||
              '${item['scene_number']} ${item['slugline']} ${item['summary']}'
                  .toLowerCase()
                  .contains(normalized),
        )
        .toList();
    return _TableModule(
      title: 'Scenes',
      subtitle: '${rows.length} of ${all.length} scenes',
      emptyTitle: 'No extracted scenes',
      columns: const [
        DataColumn(label: Text('#')),
        DataColumn(label: Text('Slugline')),
        DataColumn(label: Text('Story day')),
        DataColumn(label: Text('Pages')),
        DataColumn(label: Text('Complexity')),
        DataColumn(label: Text('Confidence')),
        DataColumn(label: Text('Review')),
      ],
      rows: rows
          .map(
            (item) => DataRow(
              onSelectChanged: (_) => onEdit(item),
              cells: [
                DataCell(Text('${item['scene_number']}')),
                DataCell(
                  SizedBox(
                    width: 290,
                    child: Text('${item['slugline']}',
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
                DataCell(Text('${item['story_day'] ?? '—'}')),
                DataCell(Text(_eighths(item['page_length_eighths']))),
                DataCell(_StatusPill('${item['complexity']}')),
                DataCell(Text('${item['ai_confidence']}%')),
                DataCell(_StatusPill('${item['review_status']}')),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _CineCharacters extends StatelessWidget {
  final Map<String, dynamic> snapshot;
  final String query;
  final ValueChanged<Map<String, dynamic>> onEdit;

  const _CineCharacters({
    required this.snapshot,
    required this.query,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final all = (snapshot['characters'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final rows = all
        .where(
          (item) =>
              query.isEmpty ||
              '${item['name']} ${item['description']}'
                  .toLowerCase()
                  .contains(query.toLowerCase()),
        )
        .toList();
    return _TableModule(
      title: 'Characters',
      subtitle: '${rows.length} characters from the active script revision',
      emptyTitle: 'No extracted characters',
      columns: const [
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Class')),
        DataColumn(label: Text('Playing age')),
        DataColumn(label: Text('Scenes')),
        DataColumn(label: Text('Dialogue')),
        DataColumn(label: Text('Shoot days')),
        DataColumn(label: Text('Review')),
      ],
      rows: rows
          .map(
            (item) => DataRow(
              onSelectChanged: (_) => onEdit(item),
              cells: [
                DataCell(Text('${item['name']}')),
                DataCell(_StatusPill('${item['classification']}')),
                DataCell(Text('${item['playing_age'] ?? '—'}')),
                DataCell(
                    Text('${(item['scenes'] as List? ?? const []).length}')),
                DataCell(Text('${item['dialogue_count']}')),
                DataCell(Text('${item['estimated_shoot_days']}')),
                DataCell(_StatusPill('${item['review_status']}')),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _CineCasting extends StatefulWidget {
  final Map<String, dynamic> snapshot;
  final VoidCallback onAddActor;
  final Future<void> Function(String, String, String) onAssign;
  final ValueChanged<String> onAvailability;

  const _CineCasting({
    required this.snapshot,
    required this.onAddActor,
    required this.onAssign,
    required this.onAvailability,
  });

  @override
  State<_CineCasting> createState() => _CineCastingState();
}

class _CineCastingState extends State<_CineCasting> {
  String? _characterId;
  String? _actorId;

  @override
  Widget build(BuildContext context) {
    final characters =
        (widget.snapshot['characters'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
    final actors = (widget.snapshot['actors'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final assignments =
        (widget.snapshot['cast_assignments'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _ModuleHeader(
          eyebrow: 'Profiles · fit · availability',
          title: 'Casting',
          subtitle:
              'Confirmed actors feed both schedule validation and budget.',
          actions: [
            FilledButton.icon(
              onPressed: widget.onAddActor,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Actor profile'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _characterId,
                decoration: const InputDecoration(labelText: 'Character'),
                items: characters
                    .map(
                      (item) => DropdownMenuItem(
                        value: item['public_id'] as String,
                        child: Text('${item['name']}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _characterId = value),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _actorId,
                decoration: const InputDecoration(labelText: 'Actor'),
                items: actors
                    .map(
                      (item) => DropdownMenuItem(
                        value: item['public_id'] as String,
                        child: Text('${item['name']}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _actorId = value),
              ),
            ),
            FilledButton(
              onPressed: _characterId == null || _actorId == null
                  ? null
                  : () => widget.onAssign(
                        _characterId!,
                        _actorId!,
                        'shortlisted',
                      ),
              child: const Text('Shortlist'),
            ),
            FilledButton.tonal(
              onPressed: _characterId == null || _actorId == null
                  ? null
                  : () => widget.onAssign(
                        _characterId!,
                        _actorId!,
                        'confirmed',
                      ),
              child: const Text('Confirm actor'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (actors.isEmpty)
          const _EmptyState(
            icon: Icons.person_search_outlined,
            title: 'No reusable actor profiles',
            message:
                'Create a profile, add availability, then calculate a fit.',
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: actors
                .map(
                  (actor) => SizedBox(
                    width: 240,
                    child: _CineCard(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${actor['name']}',
                              style: AppTextStyles.cardTitle.copyWith(
                                color: context.appColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${actor['city'] ?? 'City not set'} · '
                              '${actor['daily_rate_minor'] ?? 0} ${actor['currency']}',
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () => widget.onAvailability(
                                actor['public_id'] as String,
                              ),
                              icon: const Icon(Icons.event_available, size: 18),
                              label: const Text('Availability'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 14),
        Text(
          'Casting decisions',
          style: AppTextStyles.sectionHeaderStyle.copyWith(
            color: context.appColors.textPrimary,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 8),
        ...assignments.map(
          (assignment) {
            final character = assignment['character'] as Map<String, dynamic>?;
            final actor = assignment['actor'] as Map<String, dynamic>?;
            return _CineCard(
              child: ListTile(
                title: Text(
                    '${character?['name'] ?? 'Character'} → ${actor?['name'] ?? 'Actor'}'),
                subtitle: Text('Fit ${assignment['fit_score']}%'),
                trailing: _StatusPill('${assignment['status']}'),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CineLocations extends StatelessWidget {
  final Map<String, dynamic> snapshot;
  final VoidCallback onAdd;
  final void Function(Map<String, dynamic>, String) onStatus;

  const _CineLocations({
    required this.snapshot,
    required this.onAdd,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    final rows = (snapshot['locations'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _ModuleHeader(
          eyebrow: 'Scripted places · real options',
          title: 'Locations',
          subtitle: 'Confirmed locations automatically update schedule costs.',
          actions: [
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add option'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          const _EmptyState(
            icon: Icons.location_city_outlined,
            title: 'No locations extracted',
            message: 'Process a screenplay or add a real location option.',
          )
        else
          ...rows.map(
            (item) => _CineCard(
              child: ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(
                  item['option_name'] as String? ??
                      item['screenplay_name'] as String? ??
                      'Location',
                ),
                subtitle: Text(
                  '${item['screenplay_name']} · ${item['address'] ?? 'Address not set'} · '
                  '${item['rental_rate_minor'] ?? 0} ${item['currency']}',
                ),
                trailing: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _StatusPill('${item['status']}'),
                    PopupMenuButton<String>(
                      onSelected: (value) => onStatus(item, value),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: 'shortlisted', child: Text('Shortlist')),
                        PopupMenuItem(value: 'rejected', child: Text('Reject')),
                        PopupMenuItem(
                            value: 'confirmed', child: Text('Confirm')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CineElements extends StatelessWidget {
  final Map<String, dynamic> snapshot;
  final Set<String> categories;
  final VoidCallback onAdd;
  final ValueChanged<Map<String, dynamic>> onEdit;

  const _CineElements({
    required this.snapshot,
    required this.categories,
    required this.onAdd,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final rows = (snapshot['elements'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .where((item) => categories.contains(item['category']))
        .toList();
    return _TableModule(
      title: categories.map((value) => value.toUpperCase()).join(' / '),
      subtitle: 'Scene-linked requirements, availability, cost and continuity',
      emptyTitle: 'No production items in this department',
      actions: [
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add item'),
        ),
      ],
      columns: const [
        DataColumn(label: Text('Item')),
        DataColumn(label: Text('Category')),
        DataColumn(label: Text('Scenes')),
        DataColumn(label: Text('Qty')),
        DataColumn(label: Text('Rate')),
        DataColumn(label: Text('Vendor')),
        DataColumn(label: Text('Status')),
      ],
      rows: rows
          .map(
            (item) => DataRow(
              onSelectChanged: (_) => onEdit(item),
              cells: [
                DataCell(Text('${item['name']}')),
                DataCell(Text('${item['category']}')),
                DataCell(Text(
                    '${(item['scene_numbers'] as List? ?? const []).length}')),
                DataCell(Text('${item['quantity']}')),
                DataCell(Text('${item['cost_rate_minor'] ?? 0}')),
                DataCell(Text('${item['owner_vendor'] ?? '—'}')),
                DataCell(_StatusPill('${item['status']}')),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _CineCrew extends StatelessWidget {
  final Map<String, dynamic> snapshot;
  final VoidCallback onAdd;

  const _CineCrew({required this.snapshot, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final rows = (snapshot['crew'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return _TableModule(
      title: 'Crew',
      subtitle: 'Department staffing and availability',
      emptyTitle: 'No crew members added',
      actions: [
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Add crew'),
        ),
      ],
      columns: const [
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Department')),
        DataColumn(label: Text('Role')),
        DataColumn(label: Text('Phone')),
        DataColumn(label: Text('Daily rate')),
        DataColumn(label: Text('Status')),
      ],
      rows: rows
          .map(
            (item) => DataRow(
              cells: [
                DataCell(Text('${item['name']}')),
                DataCell(Text('${item['department']}')),
                DataCell(Text('${item['job_title']}')),
                DataCell(Text('${item['phone'] ?? '—'}')),
                DataCell(Text('${item['daily_rate_minor'] ?? 0}')),
                DataCell(_StatusPill('${item['status']}')),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _CineScheduling extends StatelessWidget {
  final Map<String, dynamic> snapshot;
  final VoidCallback onPreview;
  final ValueChanged<bool> onOptimize;
  final ValueChanged<bool> onLock;

  const _CineScheduling({
    required this.snapshot,
    required this.onPreview,
    required this.onOptimize,
    required this.onLock,
  });

  @override
  Widget build(BuildContext context) {
    final schedule = snapshot['schedule'] as Map<String, dynamic>;
    final days = (schedule['days'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final locked = schedule['locked'] == true;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _ModuleHeader(
          eyebrow: 'Constraint-based production planning',
          title: 'Shooting schedule',
          subtitle:
              'Generate cost, speed and balanced plans, then resolve conflicts.',
          actions: [
            FilledButton.icon(
              onPressed: locked ? null : onPreview,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Generate schedule'),
            ),
            OutlinedButton.icon(
              onPressed: days.isEmpty ? null : () => onOptimize(false),
              icon: const Icon(Icons.savings_outlined),
              label: const Text('Find savings'),
            ),
            OutlinedButton.icon(
              onPressed: days.isEmpty || locked ? null : () => onOptimize(true),
              icon: const Icon(Icons.bolt_outlined),
              label: const Text('Apply optimization'),
            ),
            FilledButton.tonalIcon(
              onPressed: days.isEmpty ? null : () => onLock(!locked),
              icon: Icon(locked ? Icons.lock_open : Icons.lock_outline),
              label: Text(locked ? 'Unlock' : 'Lock schedule'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ConflictSummary(snapshot: snapshot),
        const SizedBox(height: 14),
        if (days.isEmpty)
          const _EmptyState(
            icon: Icons.calendar_month_outlined,
            title: 'No shooting schedule',
            message: 'Generate and compare three deterministic schedule plans.',
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: days
                .map(
                  (day) => SizedBox(
                    width: 210,
                    child: _CineCard(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Day ${day['shoot_day_number']}',
                              style: AppTextStyles.cardTitle.copyWith(
                                color: context.appColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            Text('${day['shoot_date']}'),
                            const SizedBox(height: 6),
                            Text(
                                '${day['crew_call']} — ${day['expected_wrap']}'),
                            Text(
                                '${(day['events'] as List? ?? const []).length} events'),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _CineTimetable extends StatelessWidget {
  final Map<String, dynamic> snapshot;
  final Future<void> Function(Map<String, dynamic>, Map<String, dynamic>)
      onMove;

  const _CineTimetable({required this.snapshot, required this.onMove});

  @override
  Widget build(BuildContext context) {
    final schedule = snapshot['schedule'] as Map<String, dynamic>;
    final days = (schedule['days'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    if (days.isEmpty) {
      return const _EmptyState(
        icon: Icons.view_timeline_outlined,
        title: 'Timetable not prepared',
        message: 'Generate a shooting schedule to create exact daily times.',
      );
    }
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      children: days
          .map(
            (day) => SizedBox(
              width: 300,
              child: DragTarget<Map<String, dynamic>>(
                onAcceptWithDetails: (details) => onMove(details.data, day),
                builder: (context, candidates, rejected) => _CineCard(
                  color: candidates.isEmpty
                      ? null
                      : context.appColors.goldGlow.withValues(alpha: 0.72),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shoot day ${day['shoot_day_number']}',
                          style: AppTextStyles.sectionHeaderStyle.copyWith(
                            color: context.appColors.textPrimary,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                            '${day['shoot_date']} · ${day['location_name'] ?? 'Multiple locations'}'),
                        const Divider(height: 18),
                        Expanded(
                          child: ListView(
                            children: (day['events'] as List<dynamic>? ??
                                    const [])
                                .cast<Map<String, dynamic>>()
                                .map(
                                  (event) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: event['event_type'] == 'scene'
                                        ? LongPressDraggable<
                                            Map<String, dynamic>>(
                                            data: event,
                                            feedback: Material(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: SizedBox(
                                                width: 280,
                                                child: _TimeEvent(event: event),
                                              ),
                                            ),
                                            child: _TimeEvent(event: event),
                                          )
                                        : _TimeEvent(event: event),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TimeEvent extends StatelessWidget {
  final Map<String, dynamic> event;

  const _TimeEvent({required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 9, 9, 9),
      decoration: BoxDecoration(
        color: colors.softSurface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border(
          left: BorderSide(color: colors.goldMid, width: 3),
          top: BorderSide(color: colors.borderMuted),
          right: BorderSide(color: colors.borderMuted),
          bottom: BorderSide(color: colors.borderMuted),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              '${event['starts_at']}',
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.goldDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${event['title']}',
                  style: AppTextStyles.label.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Until ${event['ends_at']}',
                  style: AppTextStyles.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (event['event_type'] == 'scene')
            const Icon(Icons.drag_indicator, size: 18),
        ],
      ),
    );
  }
}

class _CineBudget extends StatelessWidget {
  final Map<String, dynamic> snapshot;
  final ValueChanged<Map<String, dynamic>> onEdit;

  const _CineBudget({required this.snapshot, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final budget = snapshot['budget'] as Map<String, dynamic>?;
    if (budget == null) {
      return const _EmptyState(
        icon: Icons.lock_outline,
        title: 'Financial access required',
        message: 'Your production role does not include budget permissions.',
      );
    }
    final totals = budget['totals'] as Map<String, dynamic>;
    final lines =
        (budget['lines'] as List<dynamic>).cast<Map<String, dynamic>>();
    final currency = budget['currency'] as String? ?? 'PKR';
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const _ModuleHeader(
          eyebrow: 'Connected cost control',
          title: 'Budget',
          subtitle:
              'Cast, locations, equipment and schedule changes recalculate estimates.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _BudgetTotal('Estimated', totals['estimated_minor'], currency),
            _BudgetTotal('Committed', totals['committed_minor'], currency),
            _BudgetTotal('Paid', totals['paid_minor'], currency),
            _BudgetTotal('Remaining', totals['remaining_minor'], currency),
            _BudgetTotal('Variance', totals['variance_minor'], currency),
          ],
        ),
        const SizedBox(height: 14),
        _CineCard(
          margin: EdgeInsets.zero,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              showCheckboxColumn: false,
              showBottomBorder: true,
              columns: const [
                DataColumn(label: Text('Category')),
                DataColumn(label: Text('Description')),
                DataColumn(label: Text('Estimated')),
                DataColumn(label: Text('Approved')),
                DataColumn(label: Text('Committed')),
                DataColumn(label: Text('Paid')),
                DataColumn(label: Text('Status')),
              ],
              rows: lines
                  .map(
                    (line) => DataRow(
                      onSelectChanged: (_) => onEdit(line),
                      cells: [
                        DataCell(Text('${line['category']}')),
                        DataCell(Text('${line['description']}')),
                        DataCell(
                            Text(_money(line['estimated_minor'], currency))),
                        DataCell(
                            Text(_money(line['approved_minor'], currency))),
                        DataCell(
                            Text(_money(line['committed_minor'], currency))),
                        DataCell(Text(_money(line['paid_minor'], currency))),
                        DataCell(_StatusPill('${line['status']}')),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetTotal extends StatelessWidget {
  final String label;
  final dynamic value;
  final String currency;

  const _BudgetTotal(this.label, this.value, this.currency);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: _MetricCard(
        label: label,
        value: _money(value, currency),
        icon: Icons.payments_outlined,
      ),
    );
  }
}

class _CineCallSheets extends StatelessWidget {
  final Map<String, dynamic> snapshot;
  final ValueChanged<String> onGenerate;
  final ValueChanged<String> onDownload;

  const _CineCallSheets({
    required this.snapshot,
    required this.onGenerate,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final schedule = snapshot['schedule'] as Map<String, dynamic>;
    final days = (schedule['days'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final sheets = (snapshot['call_sheets'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final locked = schedule['locked'] == true;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _ModuleHeader(
          eyebrow: 'Locked schedule deliverables',
          title: 'Call sheets',
          subtitle: locked
              ? 'Generate a versioned call sheet from any locked shoot day.'
              : 'Lock the shooting schedule before generating call sheets.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: days
              .map(
                (day) => OutlinedButton.icon(
                  onPressed: locked
                      ? () => onGenerate(day['public_id'] as String)
                      : null,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text('Day ${day['shoot_day_number']}'),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        if (sheets.isEmpty)
          const _EmptyState(
            icon: Icons.assignment_outlined,
            title: 'No call sheets generated',
            message: 'Each generated sheet is stored as a revision.',
          )
        else
          ...sheets.map(
            (sheet) {
              final payload = sheet['payload'] as Map<String, dynamic>;
              return _CineCard(
                child: ExpansionTile(
                  leading: const Icon(Icons.assignment_turned_in_outlined),
                  title: Text(
                    'Shoot day ${payload['shoot_day']} · ${payload['shoot_date']}',
                  ),
                  subtitle: Text('Revision ${sheet['revision_number']}'),
                  trailing: _StatusPill('${sheet['status']}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Crew call ${payload['crew_call']} · Wrap ${payload['expected_wrap']}\n'
                          'Location: ${payload['location'] ?? 'TBC'}\n'
                          'Actors: ${(payload['actor_calls'] as List? ?? const []).join(', ')}',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.tonalIcon(
                          onPressed: () => onDownload(
                            sheet['public_id'] as String,
                          ),
                          icon: const Icon(Icons.download_outlined),
                          label: const Text('Download PDF'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _CineReports extends StatefulWidget {
  final String productionId;
  final CinePlannerController controller;

  const _CineReports({
    required this.productionId,
    required this.controller,
  });

  @override
  State<_CineReports> createState() => _CineReportsState();
}

class _CineReportsState extends State<_CineReports> {
  static const _types = [
    'full-script-breakdown',
    'scene-breakdown',
    'character-breakdown',
    'cast-breakdown',
    'actor-schedule',
    'day-out-of-days',
    'location-report',
    'props-report',
    'wardrobe-report',
    'makeup-report',
    'vehicles-report',
    'extras-report',
    'stunts-report',
    'vfx-report',
    'sfx-report',
    'equipment-report',
    'crew-report',
    'shooting-schedule',
    'daily-timetable',
    'weekly-timetable',
    'budget-report',
    'call-sheets',
    'production-progress',
    'script-revision-report',
  ];
  List<Map<String, dynamic>>? _rows;
  String _type = _types.first;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const _ModuleHeader(
          eyebrow: 'Live production exports',
          title: 'Reports',
          subtitle:
              'Reports are generated from the active production database.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 280,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Report'),
                items: _types
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.replaceAll('-', ' ')),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
            ),
            FilledButton.icon(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Generate report'),
            ),
            for (final format in const ['pdf', 'xlsx', 'csv'])
              OutlinedButton.icon(
                onPressed: _loading ? null : () => _download(format),
                icon: const Icon(Icons.download_outlined),
                label: Text(format.toUpperCase()),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (_loading)
          const LinearProgressIndicator()
        else if (_rows == null)
          const _EmptyState(
            icon: Icons.analytics_outlined,
            title: 'Choose a report',
            message:
                'The preview will use current approved and scheduled data.',
          )
        else
          _JsonRows(rows: _rows!),
      ],
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await widget.controller.repository.report(
        productionId: widget.productionId,
        reportType: _type,
      );
      if (mounted) setState(() => _rows = rows);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _download(String format) async {
    setState(() => _loading = true);
    try {
      final download = await widget.controller.repository.downloadReport(
        productionId: widget.productionId,
        reportType: _type,
        format: format,
      );
      final saved = saveDownload(
        download.filename,
        download.bytes,
        download.contentType,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              saved
                  ? '${format.toUpperCase()} report downloaded.'
                  : 'Report download is available in the web app.',
            ),
          ),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _JsonRows extends StatelessWidget {
  final List<Map<String, dynamic>> rows;

  const _JsonRows({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const _EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No report rows',
        message:
            'Add or schedule production data before generating this report.',
      );
    }
    return Column(
      children: rows
          .take(200)
          .map(
            (row) => _CineCard(
              child: ExpansionTile(
                title: Text(
                  '${row['name'] ?? row['scene_number'] ?? row['character'] ?? row['description'] ?? 'Report row'}',
                ),
                children: row.entries
                    .map(
                      (entry) => ListTile(
                        dense: true,
                        title: Text(entry.key.replaceAll('_', ' ')),
                        subtitle: Text('${entry.value}'),
                      ),
                    )
                    .toList(),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CineAssistant extends StatefulWidget {
  final String productionId;
  final CinePlannerController controller;

  const _CineAssistant({
    required this.productionId,
    required this.controller,
  });

  @override
  State<_CineAssistant> createState() => _CineAssistantState();
}

class _CineAssistantState extends State<_CineAssistant> {
  final _question = TextEditingController();
  final List<(String, String)> _messages = [];
  bool _asking = false;

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        const _ModuleHeader(
          eyebrow: 'Safe production intelligence',
          title: 'Ask CinePlanner',
          subtitle:
              'The assistant sees a scoped production snapshot, never direct database access.',
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _messages.isEmpty
              ? const _EmptyState(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Ask a production question',
                  message:
                      'Try “Which scenes require the hospital?” or “Show night exteriors.”',
                )
              : ListView(
                  children: _messages
                      .map(
                        (message) => Align(
                          alignment: message.$1 == 'You'
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 680),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
                            decoration: BoxDecoration(
                              color: message.$1 == 'You'
                                  ? colors.goldGlow.withValues(alpha: 0.75)
                                  : colors.softSurface,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border(
                                left: BorderSide(
                                  color: message.$1 == 'You'
                                      ? colors.goldMid
                                      : colors.holographicTeal,
                                  width: 3,
                                ),
                                top: BorderSide(color: colors.borderMuted),
                                right: BorderSide(color: colors.borderMuted),
                                bottom: BorderSide(color: colors.borderMuted),
                              ),
                            ),
                            child: Text(
                              message.$2,
                              style: AppTextStyles.body.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _question,
          onSubmitted: (_) => _ask(),
          decoration: InputDecoration(
            hintText: 'Ask about scenes, cast, locations, costs or conflicts…',
            prefixIcon: const Icon(Icons.auto_awesome_outlined),
            suffixIcon: IconButton(
              onPressed: _asking ? null : _ask,
              icon: _asking
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _ask() async {
    final question = _question.text.trim();
    if (question.length < 3) return;
    setState(() {
      _asking = true;
      _messages.add(('You', question));
      _question.clear();
    });
    try {
      final result = await widget.controller.repository.ask(
        productionId: widget.productionId,
        question: question,
      );
      if (mounted) {
        setState(() => _messages.add(('CinePlanner', '${result['answer']}')));
      }
    } catch (error) {
      if (mounted) setState(() => _messages.add(('CinePlanner', '$error')));
    } finally {
      if (mounted) setState(() => _asking = false);
    }
  }
}

class _CineSettings extends StatelessWidget {
  final Map<String, dynamic> snapshot;

  const _CineSettings({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final production = snapshot['production'] as Map<String, dynamic>;
    final team = (snapshot['team'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final permissions = snapshot['permissions'] as List<dynamic>? ?? const [];
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const _ModuleHeader(
          eyebrow: 'Production controls',
          title: 'Settings & access',
          subtitle: 'Role permissions protect financial and approval actions.',
        ),
        const SizedBox(height: 14),
        _CineCard(
          child: Column(
            children: [
              ListTile(
                  title: const Text('Production'),
                  subtitle: Text('${production['title']}')),
              ListTile(
                  title: const Text('Start date'),
                  subtitle: Text(
                      '${production['production_start_date'] ?? 'Not set'}')),
              ListTile(
                  title: const Text('Working day limit'),
                  subtitle: Text('${production['working_hours_limit']} hours')),
              ListTile(
                  title: const Text('Maximum shoot days'),
                  subtitle: Text('${production['maximum_shoot_days']}')),
              ListTile(
                  title: const Text('Your permissions'),
                  subtitle: Text(permissions.join(', '))),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Production team',
          style: AppTextStyles.sectionHeaderStyle.copyWith(
            color: context.appColors.textPrimary,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 8),
        ...team.map(
          (item) => _CineCard(
            child: ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: Text('${item['name']}'),
              subtitle: Text(
                  '${item['role']} · ${(item['permissions'] as List? ?? const []).join(', ')}'),
            ),
          ),
        ),
      ],
    );
  }
}

class _TableModule extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emptyTitle;
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final List<Widget> actions;

  const _TableModule({
    required this.title,
    required this.subtitle,
    required this.emptyTitle,
    required this.columns,
    required this.rows,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _ModuleHeader(
          eyebrow: 'Active production',
          title: title,
          subtitle: subtitle,
          actions: actions,
        ),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          _EmptyState(
            icon: Icons.table_rows_outlined,
            title: emptyTitle,
            message: 'Upload a screenplay or add an item to continue.',
          )
        else
          _CineCard(
            margin: EdgeInsets.zero,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                showCheckboxColumn: false,
                showBottomBorder: true,
                columns: columns,
                rows: rows,
              ),
            ),
          ),
      ],
    );
  }
}

class _ModuleHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final List<Widget> actions;

  const _ModuleHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 14,
      runSpacing: 10,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 660),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: AppTextStyles.micro.copyWith(
                  color: colors.goldDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: AppTextStyles.sectionHeaderStyle.copyWith(
                  color: colors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (actions.isNotEmpty)
          Wrap(spacing: 6, runSpacing: 6, children: actions),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return _CineCard(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.goldGlow.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border:
                    Border.all(color: colors.goldLight.withValues(alpha: 0.55)),
              ),
              child: Icon(icon, size: 18, color: colors.goldDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.smallMeta.copyWith(
                      color: colors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.metricNumberCompact.copyWith(
                      color: colors.textPrimary,
                      fontSize: value.length > 14 ? 15 : 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConflictSummary extends StatelessWidget {
  final Map<String, dynamic> snapshot;

  const _ConflictSummary({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final schedule = snapshot['schedule'] as Map<String, dynamic>;
    final conflicts = (schedule['conflicts'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    if (conflicts.isEmpty) {
      return _CineCard(
        accentColor: colors.success,
        child: ListTile(
          leading: Icon(Icons.verified_outlined, color: colors.success),
          title: const Text('No open schedule conflicts'),
          subtitle: const Text(
              'Availability and overlap checks are currently clear.'),
        ),
      );
    }
    return _CineCard(
      accentColor: colors.warning,
      child: ExpansionTile(
        leading: Icon(Icons.warning_amber_rounded, color: colors.warning),
        title: Text('${conflicts.length} open schedule conflicts'),
        subtitle: const Text('Open the conflict center to inspect severity.'),
        children: conflicts
            .take(20)
            .map(
              (item) => ListTile(
                dense: true,
                leading: _StatusPill('${item['severity']}'),
                title: Text('${item['message']}'),
                subtitle: Text('${item['type']}'),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill(this.label);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.goldGlow.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colors.goldLight.withValues(alpha: 0.7)),
      ),
      child: Text(
        label.replaceAll('_', ' '),
        style: AppTextStyles.smallMeta.copyWith(
          color: colors.goldDark,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return _CineCard(
      margin: EdgeInsets.zero,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 34, color: colors.goldDark),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.cardTitle.copyWith(
                  color: colors.textPrimary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                message,
                textAlign: TextAlign.center,
                style:
                    AppTextStyles.caption.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobStatus extends StatelessWidget {
  final Map<String, dynamic> job;

  const _JobStatus({required this.job});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final progress = (job['progress_percent'] as num?)?.toDouble() ?? 0;
    return _CineCard(
      accentColor:
          job['status'] == 'completed' ? colors.success : colors.goldMid,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${job['current_stage']}'.replaceAll('_', ' '),
                    style: AppTextStyles.cardTitle.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                _StatusPill('${job['status']}'),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress / 100),
          ],
        ),
      ),
    );
  }
}

class _CineLoadingState extends StatelessWidget {
  const _CineLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(
        dimension: 36,
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _CineErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CineErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _EmptyStateWithAction(message: message, onRetry: onRetry);
  }
}

class _EmptyStateWithAction extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _EmptyStateWithAction({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 42),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _ProcessingProgress {
  final String label;
  final double progress;

  const _ProcessingProgress(this.label, this.progress);
}

class _ProcessingDialog extends StatelessWidget {
  final ValueNotifier<_ProcessingProgress> progress;

  const _ProcessingDialog({required this.progress});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Processing screenplay'),
        content: SizedBox(
          width: 440,
          child: ValueListenableBuilder<_ProcessingProgress>(
            valueListenable: progress,
            builder: (context, value, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value.label),
                const SizedBox(height: 14),
                LinearProgressIndicator(value: value.progress.clamp(0, 1)),
                const SizedBox(height: 8),
                Text('${(value.progress * 100).round()}%'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SchedulePlanDialog extends StatelessWidget {
  final List<Map<String, dynamic>> plans;

  const _SchedulePlanDialog({required this.plans});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose a shooting plan'),
      content: SizedBox(
        width: 760,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: plans
              .map(
                (plan) => SizedBox(
                  width: 225,
                  child: _CineCard(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${plan['strategy']}'
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                            style: AppTextStyles.panelLabel.copyWith(
                              color: context.appColors.goldDark,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text('${plan['shoot_days']} shoot days'),
                          Text('${plan['total_hours']} total hours'),
                          Text('${plan['night_shoots']} night shoots'),
                          Text('${plan['location_moves']} company moves'),
                          Text(
                              '${(plan['conflicts'] as List? ?? const []).length} conflicts'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => Navigator.pop(
                              context,
                              plan['strategy'] as String,
                            ),
                            child: const Text('Apply plan'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

String _eighths(dynamic value) {
  final eighths = (value as num?)?.toInt() ?? 0;
  return '${eighths ~/ 8} ${eighths % 8}/8';
}

String _currency(Map<String, dynamic>? snapshot) =>
    (snapshot?['production'] as Map<String, dynamic>?)?['currency']
        as String? ??
    'PKR';

String _money(dynamic value, String currency) {
  if (value == null) return 'Restricted';
  final minor = (value as num?)?.toInt() ?? 0;
  return '$currency ${NumberFormat.decimalPattern().format(minor / 100)}';
}
