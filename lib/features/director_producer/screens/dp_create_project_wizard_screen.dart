import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/profile/profile_models.dart';
import '../../../core/projects/project_models.dart';
import '../../../core/projects/projects_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/uploads/upload_repository.dart';
import '../data/project_draft_store.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_budget_health_bar.dart';
import '../widgets/dp_date_range_sheet.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';

const _wizardSteps = [
  'Type + Info',
  'Location + Dates',
  'Budget',
  'Team',
  'Script & Files',
  'Requirements',
  'Review',
];

const _projectTypes = [
  'TVC',
  'Feature Film',
  'Drama',
  'Music Video',
  'Fashion Shoot',
];

const _requirementCategories = [
  'Roles',
  'Models',
  'Locations',
  'Media & Equipment',
  'Crew',
];

const _requirementTemplates = [
  ('Lead actor', 'Roles'),
  ('Supporting cast', 'Roles'),
  ('Editorial model', 'Models'),
  ('DOP', 'Crew'),
  ('Location scout', 'Locations'),
  ('Lighting package', 'Media & Equipment'),
];

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

class _WizardFile {
  final String name;
  final Uint8List bytes;
  final String mimeType;
  double? progress;
  String? uploadedFileId;
  String? error;

  _WizardFile({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });
}

class _WizardRequirement {
  final String id;
  String name;
  String category;
  int quantity;
  String budget;
  String deadline;
  String description;
  String notes;

  _WizardRequirement({
    required this.id,
    required this.name,
    required this.category,
    this.quantity = 1,
    this.budget = '',
    this.deadline = '',
    this.description = '',
    this.notes = '',
  });

  _WizardRequirement copyWith() => _WizardRequirement(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        category: category,
        quantity: quantity,
        budget: budget,
        deadline: deadline,
        description: description,
        notes: notes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'quantity': quantity,
        'budget': budget,
        'deadline': deadline,
        'description': description,
        'notes': notes,
      };

  factory _WizardRequirement.fromJson(Map<String, dynamic> json) {
    return _WizardRequirement(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      quantity: json['quantity'] as int? ?? 1,
      budget: json['budget'] as String? ?? '',
      deadline: json['deadline'] as String? ?? '',
      description: json['description'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }
}

class DPCreateProjectWizardScreen extends StatefulWidget {
  const DPCreateProjectWizardScreen({super.key});

  @override
  State<DPCreateProjectWizardScreen> createState() =>
      _DPCreateProjectWizardScreenState();
}

class _DPCreateProjectWizardScreenState
    extends State<DPCreateProjectWizardScreen> {
  final _draftStore = const ProjectDraftStore();
  final _title = TextEditingController();
  final _customType = TextEditingController();
  final _description = TextEditingController();
  final List<ProfileCity> _selectedCities = [];
  Future<List<ProfileCity>>? _citiesFuture;
  final _budgetMin = TextEditingController();
  final _budgetMax = TextEditingController();
  final _teamInput = TextEditingController();

  String _type = '';
  bool _customTypeSelected = false;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _tentative = false;
  final List<String> _team = [];
  _WizardFile? _coverPhoto;
  final List<_WizardFile> _files = [];
  final List<_WizardRequirement> _requirements = [];

  int _step = 0;
  bool _saving = false;
  bool _draftLoaded = false;
  final Map<String, String> _errors = {};

  Project? _createdProject;
  bool _justCreated = false;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _citiesFuture ??= AuthScope.maybeOf(context)?.cities();
  }

  @override
  void dispose() {
    _title.dispose();
    _customType.dispose();
    _description.dispose();
    _budgetMin.dispose();
    _budgetMax.dispose();
    _teamInput.dispose();
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    final draft = await _draftStore.load();
    if (draft == null || !mounted) {
      setState(() => _draftLoaded = true);
      return;
    }
    setState(() {
      _type = draft['type'] as String? ?? '';
      _customTypeSelected = _type.isNotEmpty && !_projectTypes.contains(_type);
      if (_customTypeSelected) _customType.text = _type;
      _title.text = draft['title'] as String? ?? '';
      _description.text = draft['description'] as String? ?? '';
      _selectedCities
        ..clear()
        ..addAll(
          (draft['cities'] as List<dynamic>? ?? []).map(
            (item) {
              final map = Map<String, dynamic>.from(item as Map);
              return ProfileCity(
                publicId: map['publicId'] as String,
                name: map['name'] as String,
                province: null,
                timezone: '',
              );
            },
          ),
        );
      _budgetMin.text = draft['budgetMin'] as String? ?? '';
      _budgetMax.text = draft['budgetMax'] as String? ?? '';
      _tentative = draft['tentative'] as bool? ?? false;
      final start = draft['startDate'] as String?;
      final end = draft['endDate'] as String?;
      _startDate = start == null ? null : DateTime.tryParse(start);
      _endDate = end == null ? null : DateTime.tryParse(end);
      _team
        ..clear()
        ..addAll((draft['team'] as List<dynamic>? ?? []).cast<String>());
      _requirements
        ..clear()
        ..addAll(
          (draft['requirements'] as List<dynamic>? ?? [])
              .map((item) => _WizardRequirement.fromJson(
                  Map<String, dynamic>.from(item as Map)))
              .toList(),
        );
      _draftLoaded = true;
    });
  }

  Future<void> _saveDraftNow({bool notify = true}) async {
    await _draftStore.save({
      'type': _type,
      'title': _title.text,
      'description': _description.text,
      'cities': _selectedCities
          .map((city) => {'publicId': city.publicId, 'name': city.name})
          .toList(),
      'budgetMin': _budgetMin.text,
      'budgetMax': _budgetMax.text,
      'tentative': _tentative,
      'startDate': _startDate?.toIso8601String(),
      'endDate': _endDate?.toIso8601String(),
      'team': _team,
      'requirements': _requirements.map((r) => r.toJson()).toList(),
    });
    if (!mounted || !notify) return;
    dpSnack(context, 'Draft saved');
  }

  @override
  Widget build(BuildContext context) {
    if (!_draftLoaded) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DPPageHeader(
          eyebrow: _justCreated
              ? 'Project setup · ready'
              : 'Project setup · step ${_step + 1} of ${_wizardSteps.length}',
          title: 'Create Project',
          trailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              DPHolographicButton(
                label: 'Save Draft',
                icon: Icons.save_outlined,
                onTap: _saving ? null : () => _saveDraftNow(),
                secondary: true,
              ),
              DPHolographicButton(
                label: 'Cancel',
                icon: Icons.close_rounded,
                onTap: _saving ? null : _cancel,
                secondary: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < _wizardSteps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: DpDotChip(
                    label: '${i + 1}. ${_wizardSteps[i]}',
                    active: _step == i,
                    onTap: () => setState(() => _step = i),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        DPGlassCard(
          accentColor: context.appColors.goldMid,
          child: _justCreated ? _successBody(context) : _stepBody(context),
        ),
        if (!_justCreated) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => setState(() => _step--),
                    child: const Text('Back'),
                  ),
                ),
              if (_step > 0) const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: DPHolographicButton(
                  label: _saving
                      ? 'Working…'
                      : _step == _wizardSteps.length - 1
                          ? 'Create Project'
                          : 'Next',
                  icon: _step == _wizardSteps.length - 1
                      ? Icons.check_circle_outline
                      : Icons.arrow_forward_rounded,
                  onTap: _saving ? null : _next,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _successBody(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
              shape: BoxShape.circle, gradient: colors.goldGradient),
          child: Icon(Icons.check_rounded, color: colors.onGold, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          'Project created',
          style: AppTextStyles.cardTitle.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          _createdProject?.title ?? '',
          style: AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _resetForm,
                child: const Text('Create Another'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DPHolographicButton(
                label: 'Open Project',
                icon: Icons.open_in_new_rounded,
                onTap: _openCreatedProject,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stepBody(BuildContext context) {
    return switch (_step) {
      0 => _typeInfoStep(),
      1 => _locationDatesStep(),
      2 => _budgetStep(),
      3 => _teamStep(),
      4 => _filesStep(),
      5 => _requirementsStep(),
      _ => _reviewStep(),
    };
  }

  Widget _typeInfoStep() {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _coverPhotoField(),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in _projectTypes)
              GestureDetector(
                onTap: () => setState(() {
                  _type = type;
                  _customTypeSelected = false;
                }),
                child: DPStatusChip(
                  label: type,
                  tone: !_customTypeSelected && _type == type
                      ? DpTone.warning
                      : DpTone.neutral,
                ),
              ),
            GestureDetector(
              onTap: () => setState(() {
                _customTypeSelected = true;
                _type = _customType.text.trim();
              }),
              child: DPStatusChip(
                label: 'Custom',
                tone: _customTypeSelected ? DpTone.warning : DpTone.neutral,
              ),
            ),
          ],
        ),
        if (_customTypeSelected) ...[
          const SizedBox(height: 12),
          CoreTextField(
            controller: _customType,
            label: 'Enter custom project type',
            icon: Icons.edit_outlined,
            onChanged: (value) => setState(() => _type = value.trim()),
          ),
        ],
        if (_errors['type'] != null) ...[
          const SizedBox(height: 6),
          Text(_errors['type']!,
              style: AppTextStyles.caption.copyWith(color: colors.danger)),
        ],
        const SizedBox(height: 12),
        CoreTextField(
          controller: _title,
          label: 'Project title (e.g., Ramadan Telefilm 2027)',
          icon: Icons.title_rounded,
          errorText: _errors['title'],
        ),
        const SizedBox(height: 12),
        CoreTextField(
          controller: _description,
          label: 'Description / tone',
          icon: Icons.notes_rounded,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _locationDatesStep() {
    final colors = context.appColors;
    final duration = (_startDate != null && _endDate != null)
        ? _endDate!.difference(_startDate!).inDays + 1
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _citiesField(),
        const SizedBox(height: 12),
        _dateRangeField(),
        if (_errors['dates'] != null) ...[
          const SizedBox(height: 6),
          Text(_errors['dates']!,
              style: AppTextStyles.caption.copyWith(color: colors.danger)),
        ],
        if (duration != null) ...[
          const SizedBox(height: 8),
          Text(
            '$duration day${duration == 1 ? '' : 's'} total',
            style: AppTextStyles.caption
                .copyWith(color: colors.goldDark, fontWeight: FontWeight.w700),
          ),
        ],
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => setState(() => _tentative = !_tentative),
          child: DPStatusChip(
            label: 'Tentative dates',
            tone: _tentative ? DpTone.warning : DpTone.neutral,
          ),
        ),
      ],
    );
  }

  Widget _citiesField() {
    final colors = context.appColors;
    return DPGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'City / cities',
            style:
                AppTextStyles.panelLabel.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final city in _selectedCities)
                GestureDetector(
                  onTap: () => setState(() => _selectedCities.remove(city)),
                  child: DPStatusChip(
                    label: '${city.name}  ✕',
                    tone: DpTone.warning,
                  ),
                ),
              GestureDetector(
                onTap: _pickCity,
                child: const DPStatusChip(
                  label: '+ Add city',
                  tone: DpTone.neutral,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickCity() async {
    final citiesFuture = _citiesFuture;
    if (citiesFuture == null) return;
    List<ProfileCity> cities;
    try {
      cities = await citiesFuture;
    } catch (_) {
      if (mounted) {
        setState(() => _errors['cities'] = 'Could not load the city list.');
      }
      return;
    }
    final available = cities
        .where((city) => !_selectedCities
            .any((selected) => selected.publicId == city.publicId))
        .toList();
    if (!mounted) return;
    final picked = await showModalBottomSheet<ProfileCity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CityPickerSheet(cities: available),
    );
    if (picked != null) {
      setState(() => _selectedCities.add(picked));
    }
  }

  // One shared calendar (Bookme.pk-style range picker) for both ends of
  // the shoot — start and end are picked in the same flow, so this is a
  // single tappable field with one calendar icon, not two independent
  // date pickers that happen to agree with each other.
  Widget _dateRangeField() {
    final colors = context.appColors;
    return GestureDetector(
      onTap: () async {
        final range = await showDpDateRangeSheet(
          context,
          initialStart: _startDate,
          initialEnd: _endDate,
        );
        if (range == null) return;
        setState(() {
          _startDate = range.start;
          _endDate = range.end;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: colors.softSurface,
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dateRangeRow('Start', _startDate),
                  const SizedBox(height: 8),
                  _dateRangeRow('End', _endDate),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.date_range_outlined, color: colors.goldDark, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _dateRangeRow(String label, DateTime? value) {
    final colors = context.appColors;
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(color: colors.textTertiary),
          ),
        ),
        Expanded(
          child: Text(
            value == null ? 'Select a date range' : _formatDate(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              color: value == null ? colors.textTertiary : colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _budgetStep() {
    final min = double.tryParse(_budgetMin.text) ?? 0;
    final max = double.tryParse(_budgetMax.text) ?? 0;
    final pct = (min > 0 && max > 0)
        ? 1.0
        : (min > 0 || max > 0)
            ? 0.5
            : 0.0;
    final label = (min > 0 && max > 0)
        ? 'Range set'
        : (min > 0 || max > 0)
            ? 'One bound set'
            : 'Budget starts empty';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoreTextField(
          controller: _budgetMin,
          label: 'Budget minimum (PKR)',
          icon: Icons.payments_outlined,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        CoreTextField(
          controller: _budgetMax,
          label: 'Budget maximum (PKR)',
          icon: Icons.account_balance_wallet_outlined,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        DPBudgetHealthBar(value: pct, label: label),
      ],
    );
  }

  Widget _teamStep() {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team',
          style: AppTextStyles.cardTitle.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: 6),
        dpText(context,
            'Add co-producers or department heads for quick reference.'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CoreTextField(
                controller: _teamInput,
                label: 'Team member name',
                icon: Icons.person_add_alt_1_outlined,
              ),
            ),
            const SizedBox(width: 8),
            DPHolographicButton(
              label: 'Add',
              icon: Icons.add_rounded,
              onTap: _addTeamMember,
              secondary: true,
            ),
          ],
        ),
        if (_team.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final member in _team)
                Chip(
                  label: Text(member),
                  onDeleted: () => setState(() => _team.remove(member)),
                ),
            ],
          ),
        ],
      ],
    );
  }

  void _addTeamMember() {
    final name = _teamInput.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _team.add(name);
      _teamInput.clear();
    });
  }

  Widget _filesStep() {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Script vault',
          style: AppTextStyles.cardTitle.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: 8),
        dpText(
          context,
          'Upload PDF, DOC, DOCX, or TXT. Scripts stay private to invited team members.',
        ),
        const SizedBox(height: 12),
        if (_files.isEmpty)
          const DPStatusChip(
              label: 'No files attached yet', tone: DpTone.neutral)
        else
          Column(
            children: [
              for (final file in _files) ...[
                _FileRow(
                  file: file,
                  onRemove: () => setState(() => _files.remove(file)),
                  onReplace: () => _replaceFile(file),
                  onRetry: () => _uploadFile(file),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        const SizedBox(height: 8),
        DPHolographicButton(
          label: 'Add script from device',
          icon: Icons.upload_file_outlined,
          onTap: _pickFiles,
        ),
      ],
    );
  }

  Widget _coverPhotoField() {
    final colors = context.appColors;
    final cover = _coverPhoto;
    return GestureDetector(
      onTap: cover?.error != null
          ? () => _uploadCoverPhoto(cover!)
          : _pickCoverPhoto,
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: colors.softSurface,
          border: Border.all(color: colors.border),
          image: cover == null
              ? null
              : DecorationImage(
                  image: MemoryImage(cover.bytes),
                  fit: BoxFit.cover,
                ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (cover == null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        color: colors.goldDark, size: 26),
                    const SizedBox(height: 6),
                    Text(
                      'Add project cover photo',
                      style: AppTextStyles.caption
                          .copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              )
            else ...[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
              ),
              if (cover.progress != null && cover.progress! < 1)
                const Positioned.fill(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              Positioned(
                right: 8,
                top: 8,
                child: GestureDetector(
                  onTap: () => setState(() => _coverPhoto = null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black54,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                bottom: 8,
                child: Text(
                  cover.error ?? 'Cover photo',
                  style: AppTextStyles.caption.copyWith(
                    color: cover.error != null ? colors.danger : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickCoverPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    final item = result?.files.single;
    final bytes = item?.bytes;
    if (item == null || bytes == null) return;
    final file = _WizardFile(
      name: item.name,
      bytes: bytes,
      mimeType: switch (item.extension?.toLowerCase()) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      },
    );
    setState(() => _coverPhoto = file);
    await _uploadCoverPhoto(file);
  }

  Future<void> _uploadCoverPhoto(_WizardFile file) async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null) {
      setState(() => file.error = 'Sign in to upload files');
      return;
    }
    setState(() {
      file.progress = 0;
      file.error = null;
    });
    try {
      final uploaded = await auth.uploadFile(
        purpose: 'project_cover',
        file: PickedFileData(
          name: file.name,
          mimeType: file.mimeType,
          bytes: file.bytes,
        ),
      );
      if (!mounted) return;
      setState(() {
        file.progress = 1;
        file.uploadedFileId = uploaded.publicId;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        file.progress = null;
        file.error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        file.progress = null;
        file.error = 'Upload failed. Tap to retry.';
      });
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'txt'],
      withData: true,
      allowMultiple: true,
    );
    final picked = result?.files ?? const <PlatformFile>[];
    for (final item in picked) {
      final bytes = item.bytes;
      if (bytes == null) continue;
      final file = _WizardFile(
        name: item.name,
        bytes: bytes,
        mimeType: _mimeTypeFor(item.extension),
      );
      setState(() => _files.add(file));
      _uploadFile(file);
    }
  }

  Future<void> _replaceFile(_WizardFile old) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'txt'],
      withData: true,
    );
    final item = result?.files.single;
    final bytes = item?.bytes;
    if (item == null || bytes == null) return;
    final replacement = _WizardFile(
      name: item.name,
      bytes: bytes,
      mimeType: _mimeTypeFor(item.extension),
    );
    setState(() {
      final index = _files.indexOf(old);
      if (index >= 0) {
        _files[index] = replacement;
      }
    });
    _uploadFile(replacement);
  }

  String _mimeTypeFor(String? extension) {
    return switch ((extension ?? '').toLowerCase()) {
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'txt' => 'text/plain',
      _ => 'application/octet-stream',
    };
  }

  Future<void> _uploadFile(_WizardFile file) async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null) {
      setState(() => file.error = 'Sign in to upload files');
      return;
    }
    setState(() {
      file.progress = 0;
      file.error = null;
    });
    try {
      final uploaded = await auth.uploadFile(
        purpose: 'project_document',
        file: PickedFileData(
          name: file.name,
          mimeType: file.mimeType,
          bytes: file.bytes,
        ),
      );
      if (!mounted) return;
      setState(() {
        file.progress = 1;
        file.uploadedFileId = uploaded.publicId;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        file.progress = null;
        file.error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        file.progress = null;
        file.error = 'Upload failed. Tap retry.';
      });
    }
  }

  Widget _requirementsStep() {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requirements',
          style: AppTextStyles.cardTitle.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: 6),
        dpText(
            context, 'Pick a template or add a completely custom requirement.'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final template in _requirementTemplates)
              GestureDetector(
                onTap: () => _openRequirementEditor(
                  template: _WizardRequirement(
                    id: '${DateTime.now().microsecondsSinceEpoch}',
                    name: template.$1,
                    category: template.$2,
                  ),
                ),
                child: DPStatusChip(label: template.$1, tone: DpTone.info),
              ),
            GestureDetector(
              onTap: () => _openRequirementEditor(
                template: _WizardRequirement(
                  id: '${DateTime.now().microsecondsSinceEpoch}',
                  name: '',
                  category: _requirementCategories.first,
                ),
              ),
              child: const DPStatusChip(
                label: 'Custom requirement',
                tone: DpTone.warning,
                icon: Icons.add_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_requirements.isEmpty)
          const DPStatusChip(
              label: 'No requirements added yet', tone: DpTone.neutral)
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _requirements.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = _requirements.removeAt(oldIndex);
                _requirements.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final requirement = _requirements[index];
              return Padding(
                key: ValueKey(requirement.id),
                padding: const EdgeInsets.only(bottom: 8),
                child: _RequirementRow(
                  index: index,
                  requirement: requirement,
                  onEdit: () => _openRequirementEditor(existing: requirement),
                  onDuplicate: () =>
                      setState(() => _requirements.add(requirement.copyWith())),
                  onDelete: () =>
                      setState(() => _requirements.remove(requirement)),
                ),
              );
            },
          ),
        if (_errors['requirements'] != null) ...[
          const SizedBox(height: 10),
          Text(_errors['requirements']!,
              style: AppTextStyles.caption.copyWith(color: colors.danger)),
        ],
      ],
    );
  }

  Future<void> _openRequirementEditor({
    _WizardRequirement? existing,
    _WizardRequirement? template,
  }) async {
    final result = await showModalBottomSheet<_WizardRequirement>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _RequirementEditorSheet(
        initial: existing ?? template!,
        isNew: existing == null,
      ),
    );
    if (result == null) return;
    setState(() {
      if (existing != null) {
        final index = _requirements.indexOf(existing);
        if (index >= 0) _requirements[index] = result;
      } else {
        _requirements.add(result);
      }
    });
  }

  Widget _reviewStep() {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReviewRow(label: 'Project', value: _title.text),
        const SizedBox(height: 10),
        _ReviewRow(label: 'Type', value: _type),
        const SizedBox(height: 10),
        _ReviewRow(
          label: 'Cities',
          value: _selectedCities.isEmpty
              ? 'Not set'
              : _selectedCities.map((city) => city.name).join(', '),
        ),
        const SizedBox(height: 10),
        _ReviewRow(
          label: 'Dates',
          value: (_startDate != null && _endDate != null)
              ? '${_formatDate(_startDate!)} → ${_formatDate(_endDate!)}'
              : '',
        ),
        const SizedBox(height: 10),
        _ReviewRow(
          label: 'Budget range',
          value: (_budgetMin.text.isEmpty && _budgetMax.text.isEmpty)
              ? ''
              : 'PKR ${_budgetMin.text} – ${_budgetMax.text}',
        ),
        const SizedBox(height: 10),
        _ReviewRow(label: 'Team', value: _team.join(', ')),
        const SizedBox(height: 10),
        _ReviewRow(
          label: 'Files',
          value: _files.isEmpty ? '' : '${_files.length} attached',
        ),
        const SizedBox(height: 10),
        _ReviewRow(
          label: 'Requirements',
          value: _requirements.isEmpty ? '' : '${_requirements.length} added',
        ),
        if (_errors['submit'] != null) ...[
          const SizedBox(height: 10),
          Text(_errors['submit']!,
              style: AppTextStyles.caption.copyWith(color: colors.danger)),
        ],
      ],
    );
  }

  void _next() {
    if (_step == _wizardSteps.length - 1) {
      _createProject();
      return;
    }
    if (!_validateStep(_step)) return;
    setState(() => _step++);
  }

  bool _validateStep(int step) {
    setState(() => _errors.clear());
    if (step == 0) {
      final errors = <String, String>{};
      if (_type.isEmpty) errors['type'] = 'Choose a project type.';
      if (_title.text.trim().length < 2) {
        errors['title'] = 'Project title is required.';
      }
      if (errors.isNotEmpty) {
        setState(() => _errors.addAll(errors));
        return false;
      }
    }
    if (step == 1) {
      if (_startDate != null &&
          _endDate != null &&
          _endDate!.isBefore(_startDate!)) {
        setState(() => _errors['dates'] = 'End date must be after start date.');
        return false;
      }
    }
    return true;
  }

  Future<void> _createProject() async {
    if (!_validateStep(0)) {
      setState(() => _step = 0);
      return;
    }
    if (!_validateStep(1)) {
      setState(() => _step = 1);
      return;
    }
    if (!_validateRequirementDates()) {
      setState(() => _step = 5);
      return;
    }
    final controller = ProjectsScope.maybeOf(context);
    if (controller == null) {
      setState(() => _errors['submit'] = 'Sign in to create projects.');
      return;
    }
    setState(() {
      _saving = true;
      _errors.remove('submit');
    });
    try {
      // The backend only tracks one primary city per project — the first
      // selected city becomes that; any additional ones are folded into
      // the description, same as Team (no dedicated field for those either).
      final extraCities = _selectedCities.length > 1
          ? _selectedCities.skip(1).map((city) => city.name).join(', ')
          : null;
      final descriptionParts = [
        _description.text.trim(),
        if (_team.isNotEmpty) 'Team: ${_team.join(', ')}',
        if (extraCities != null) 'Additional cities: $extraCities',
      ].where((part) => part.isNotEmpty);
      final description = descriptionParts.join('\n\n');
      final project = await controller.createProject(
        title: _title.text.trim(),
        projectType: _type,
        description: description,
        cityId: _selectedCities.isEmpty ? null : _selectedCities.first.publicId,
        startDate: _apiDate(_startDate),
        endDate: _apiDate(_endDate),
        estimatedBudgetMinor: _parseMinor(_budgetMax.text),
        coverFileId: _coverPhoto?.uploadedFileId,
      );

      for (final requirement in _requirements) {
        await controller.createRequirement(
          projectId: project.publicId,
          category: _backendCategory(requirement.category),
          title: requirement.name,
          summary: [requirement.description, requirement.notes]
              .where((s) => s.trim().isNotEmpty)
              .join(' — '),
          budgetMinMinor: _parseMinor(requirement.budget),
          budgetMaxMinor: _parseMinor(requirement.budget),
          startDate: _apiDate(_startDate),
          endDate: requirement.deadline.isEmpty
              ? _apiDate(_endDate)
              : _apiDate(_parseDateOnly(requirement.deadline)),
          quantity: requirement.quantity,
        );
      }

      for (final file in _files) {
        final fileId = file.uploadedFileId;
        if (fileId == null) continue;
        await controller.linkProjectFile(
          projectId: project.publicId,
          fileId: fileId,
          label: file.name,
          folder: 'scripts',
        );
      }

      if (!mounted) return;
      await _draftStore.clear();
      setState(() {
        _createdProject = project;
        _justCreated = true;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _errors['submit'] = _friendlyApiError(error));
    } catch (_) {
      if (!mounted) return;
      setState(
          () => _errors['submit'] = 'Could not create the project right now.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _resetForm() {
    setState(() {
      _type = '';
      _customTypeSelected = false;
      _customType.clear();
      _title.clear();
      _description.clear();
      _selectedCities.clear();
      _budgetMin.clear();
      _budgetMax.clear();
      _teamInput.clear();
      _startDate = null;
      _endDate = null;
      _tentative = false;
      _team.clear();
      _coverPhoto = null;
      _files.clear();
      _requirements.clear();
      _step = 0;
      _justCreated = false;
      _createdProject = null;
    });
  }

  void _openCreatedProject() {
    final project = _createdProject;
    if (project == null) return;
    Navigator.pushNamed(
      context,
      DirectorProducerRoutes.projectDetail,
      arguments: project.publicId,
    );
  }

  Future<void> _cancel() async {
    await _draftStore.clear();
    if (!mounted) return;
    Navigator.pop(context);
  }

  int? _parseMinor(String value) {
    final whole = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (whole == null) return null;
    return whole * 100;
  }

  String? _apiDate(DateTime? value) {
    if (value == null) return null;
    return value.toIso8601String().split('T').first;
  }

  DateTime? _parseDateOnly(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _validateRequirementDates() {
    final projectStart = _startDate == null ? null : _dateOnly(_startDate!);
    final projectEnd = _endDate == null ? null : _dateOnly(_endDate!);

    for (final requirement in _requirements) {
      final deadlineText = requirement.deadline.trim();
      if (deadlineText.isEmpty) continue;

      final deadline = _parseDateOnly(deadlineText);
      if (deadline == null) {
        setState(() {
          _errors['requirements'] =
              'Requirement "${requirement.name}" has an invalid deadline. Open Requirements and choose the date again.';
        });
        return false;
      }

      if (projectStart != null && deadline.isBefore(projectStart)) {
        setState(() {
          _errors['requirements'] =
              'Requirement "${requirement.name}" deadline must be on or after project start date ${_formatDate(projectStart)}.';
        });
        return false;
      }

      if (projectEnd != null && deadline.isAfter(projectEnd)) {
        setState(() {
          _errors['requirements'] =
              'Requirement "${requirement.name}" deadline must be on or before project end date ${_formatDate(projectEnd)}.';
        });
        return false;
      }
    }

    return true;
  }

  String _friendlyApiError(ApiException error) {
    if (error.fields.isEmpty) return error.message;
    final fieldMessages = error.fields.entries
        .expand(
          (entry) => entry.value.map((message) => '${entry.key}: $message'),
        )
        .join('\n');
    return '${error.message}\n$fieldMessages';
  }
}

class _CityPickerSheet extends StatefulWidget {
  final List<ProfileCity> cities;

  const _CityPickerSheet({required this.cities});

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final query = _search.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.cities
        : widget.cities
            .where((city) => city.name.toLowerCase().contains(query))
            .toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a city',
              style:
                  AppTextStyles.cardTitle.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: 14),
            CoreTextField(
              controller: _search,
              label: 'Search cities',
              icon: Icons.search_rounded,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        widget.cities.isEmpty
                            ? 'All available cities are already selected.'
                            : 'No cities match your search.',
                        style: AppTextStyles.body
                            .copyWith(color: colors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final city = filtered[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.location_on_outlined,
                              color: colors.goldDark),
                          title: Text(
                            city.name,
                            style: AppTextStyles.cardLabel
                                .copyWith(color: colors.textPrimary),
                          ),
                          subtitle: city.province == null
                              ? null
                              : Text(
                                  city.province!,
                                  style: AppTextStyles.caption
                                      .copyWith(color: colors.textSecondary),
                                ),
                          onTap: () => Navigator.pop(context, city),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  final _WizardFile file;
  final VoidCallback onRemove;
  final VoidCallback onReplace;
  final VoidCallback onRetry;

  const _FileRow({
    required this.file,
    required this.onRemove,
    required this.onReplace,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final uploading = file.progress != null && file.progress! < 1;
    final done = file.uploadedFileId != null;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colors.softSurface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined,
                  size: 18, color: colors.goldDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel
                      .copyWith(color: colors.textPrimary),
                ),
              ),
              if (done)
                Semantics(
                  label: 'Upload complete',
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 17,
                    color: colors.success,
                  ),
                ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onReplace,
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                tooltip: 'Replace',
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: 'Remove',
              ),
            ],
          ),
          if (uploading) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child:
                  LinearProgressIndicator(minHeight: 4, color: colors.goldMid),
            ),
          ],
          if (file.error != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    file.error!,
                    style: AppTextStyles.caption.copyWith(color: colors.danger),
                  ),
                ),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final int index;
  final _WizardRequirement requirement;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _RequirementRow({
    required this.index,
    required this.requirement,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colors.softSurface,
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Icon(Icons.drag_indicator_rounded,
                color: colors.iconMuted, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  requirement.quantity > 1
                      ? '${requirement.name} ×${requirement.quantity}'
                      : requirement.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    requirement.category,
                    if (requirement.budget.isNotEmpty)
                      'PKR ${requirement.budget}',
                    if (requirement.deadline.isNotEmpty) requirement.deadline,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta
                      .copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Edit',
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDuplicate,
            icon: const Icon(Icons.copy_all_outlined, size: 18),
            tooltip: 'Duplicate',
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}

class _RequirementEditorSheet extends StatefulWidget {
  final _WizardRequirement initial;
  final bool isNew;

  const _RequirementEditorSheet({required this.initial, required this.isNew});

  @override
  State<_RequirementEditorSheet> createState() =>
      _RequirementEditorSheetState();
}

class _RequirementEditorSheetState extends State<_RequirementEditorSheet> {
  late String _category = widget.initial.category;
  late final _name = TextEditingController(text: widget.initial.name);
  late int _quantity = widget.initial.quantity;
  late final _budget = TextEditingController(text: widget.initial.budget);
  late final _deadline = TextEditingController(text: widget.initial.deadline);
  late final _description =
      TextEditingController(text: widget.initial.description);
  late final _notes = TextEditingController(text: widget.initial.notes);
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _budget.dispose();
    _deadline.dispose();
    _description.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Requirement name is required.');
      return;
    }
    Navigator.pop(
      context,
      _WizardRequirement(
        id: widget.initial.id,
        name: _name.text.trim(),
        category: _category,
        quantity: _quantity,
        budget: _budget.text.trim(),
        deadline: _deadline.text.trim(),
        description: _description.text.trim(),
        notes: _notes.text.trim(),
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final range = await showDpDateRangeSheet(context);
    if (range == null) return;
    setState(
        () => _deadline.text = range.start.toIso8601String().split('T').first);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(color: colors.border),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isNew ? 'Add requirement' : 'Edit requirement',
                style:
                    AppTextStyles.cardTitle.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in _requirementCategories)
                    GestureDetector(
                      onTap: () => setState(() => _category = category),
                      child: DPStatusChip(
                        label: category,
                        tone: _category == category
                            ? DpTone.warning
                            : DpTone.neutral,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              CoreTextField(
                controller: _name,
                label: 'Requirement name',
                icon: Icons.title_rounded,
                errorText: _error,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Quantity',
                      style: AppTextStyles.body
                          .copyWith(color: colors.textSecondary)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(
                        () => _quantity = (_quantity - 1).clamp(1, 99)),
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
                  Text('$_quantity',
                      style: AppTextStyles.cardTitle
                          .copyWith(color: colors.textPrimary)),
                  IconButton(
                    onPressed: () => setState(
                        () => _quantity = (_quantity + 1).clamp(1, 99)),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CoreTextField(
                controller: _budget,
                label: 'Budget (PKR)',
                icon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDeadline,
                child: AbsorbPointer(
                  child: CoreTextField(
                    controller: _deadline,
                    label: 'Deadline',
                    icon: Icons.event_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CoreTextField(
                controller: _description,
                label: 'Description',
                icon: Icons.notes_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              CoreTextField(
                controller: _notes,
                label: 'Notes',
                icon: Icons.sticky_note_2_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DPHolographicButton(
                label: 'Save requirement',
                icon: Icons.check_rounded,
                onTap: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: colors.isLight ? 0.5 : 0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Text(
            label,
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not set' : value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardLabel.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
