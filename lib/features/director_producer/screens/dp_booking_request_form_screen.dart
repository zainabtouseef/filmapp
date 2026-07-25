import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/marketplace/marketplace_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/projects/project_models.dart';
import '../../../core/projects/projects_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/dp_candidate.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_booking_status_spine.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';
import '../../../shared/layout/kyc_status_banner.dart';

class DPBookingRequestFormScreen extends StatefulWidget {
  final String? candidateId;
  final String? projectId;
  final String? category;

  const DPBookingRequestFormScreen({
    super.key,
    this.candidateId,
    this.projectId,
    this.category,
  });

  @override
  State<DPBookingRequestFormScreen> createState() =>
      _DPBookingRequestFormScreenState();
}

class _DPBookingRequestFormScreenState
    extends State<DPBookingRequestFormScreen> {
  Future<_BookingFormData>? _future;
  List<Project> _projects = const [];
  List<ProjectRequirement> _requirements = const [];
  MarketplaceListing? _listing;
  DpCandidate? _candidate;
  String? _projectId;
  String? _requirementId;
  String? _category;
  final _dates = TextEditingController();
  final _fee = TextEditingController();
  final _deposit = TextEditingController(text: '30');
  final _middle = TextEditingController(text: '40');
  final _final = TextEditingController(text: '30');
  final _deliverables = TextEditingController();
  final _usageRights = TextEditingController();
  final _conditions = TextEditingController();
  final _expiry = TextEditingController(text: '72');
  final _dynamicA = TextEditingController();
  final _dynamicB = TextEditingController();
  final _dynamicC = TextEditingController();
  int _step = 0;
  bool _sending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<_BookingFormData> _load() async {
    final listingId = widget.candidateId;
    final auth = AuthScope.maybeOf(context);
    final projectsController = ProjectsScope.maybeOf(context);
    if (listingId == null || listingId.isEmpty) {
      throw const ApiException(
        code: 'validation.missing_listing',
        message: 'Open booking request from a live marketplace listing.',
      );
    }
    if (auth == null || !auth.isAuthenticated) {
      throw const ApiException(
        code: 'auth.required',
        message: 'Sign in to compose a live booking request.',
      );
    }
    if (projectsController == null) {
      throw const ApiException(
        code: 'projects.scope_missing',
        message: 'Projects are not available in this session.',
      );
    }
    final listing = await auth.marketplaceListing(listingId);
    final projects = await projectsController.projects();
    if (projects.isEmpty) {
      throw const ApiException(
        code: 'projects.empty',
        message: 'Create a live project before sending booking requests.',
      );
    }
    final initialProjectId =
        projects.any((project) => project.publicId == widget.projectId)
            ? widget.projectId!
            : projects.first.publicId;
    final requirements =
        await projectsController.requirements(initialProjectId);
    return _BookingFormData(
      listing: listing,
      projects: projects,
      requirements: requirements,
      projectId: initialProjectId,
    );
  }

  void _acceptData(_BookingFormData data) {
    if (_listing?.publicId == data.listing.publicId &&
        _projectId == data.projectId &&
        _requirements.length == data.requirements.length) {
      return;
    }
    _listing = data.listing;
    _candidate = data.listing.toCandidate();
    _category = widget.category ?? _candidate!.category;
    _projects = data.projects;
    _requirements = data.requirements;
    _projectId = data.projectId;
    _requirementId =
        data.requirements.isEmpty ? null : data.requirements.first.publicId;
    _prefillFromSelection();
  }

  @override
  void dispose() {
    _dates.dispose();
    _fee.dispose();
    _deposit.dispose();
    _middle.dispose();
    _final.dispose();
    _deliverables.dispose();
    _usageRights.dispose();
    _conditions.dispose();
    _expiry.dispose();
    _dynamicA.dispose();
    _dynamicB.dispose();
    _dynamicC.dispose();
    super.dispose();
  }

  void _prefillFromSelection() {
    final requirement = _selectedRequirement;
    final project = _project;
    _dates.text = requirement == null
        ? _projectDateLabel(project)
        : _requirementDateLabel(requirement);
    _fee.text = _feeLabel(requirement, _candidate);
    _deliverables.text = _schema.deliverablesHint;
    _usageRights.text = _schema.usageRightsHint;
    _conditions.text = 'Counteroffers allowed; chat remains in booking record.';
    _dynamicA.text = _schema.fieldHints[0];
    _dynamicB.text = _schema.fieldHints[1];
    _dynamicC.text = _schema.fieldHints[2];
  }

  Project get _project => _projects.firstWhere(
        (project) => project.publicId == _projectId,
        orElse: () => _projects.first,
      );

  ProjectRequirement? get _selectedRequirement {
    if (_requirementId == null) return null;
    if (_requirements.isEmpty) return null;
    return _requirements.firstWhere(
      (item) => item.publicId == _requirementId,
      orElse: () => _requirements.first,
    );
  }

  _BookingSchema get _schema =>
      _BookingSchema.forCategory(_category ?? 'Talent');

  int get _scheduleTotal {
    return (_parsePercent(_deposit.text) +
        _parsePercent(_middle.text) +
        _parsePercent(_final.text));
  }

  int _parsePercent(String value) {
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BookingFormData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const DPGlassCard(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _BookingErrorState(
            message: _friendlyError(snapshot.error),
            onRetry: () => setState(() => _future = _load()),
          );
        }
        _acceptData(snapshot.data!);
        return _buildLoaded(context);
      },
    );
  }

  Widget _buildLoaded(BuildContext context) {
    final steps = [
      'Project',
      'Requirement',
      'Terms',
      'Review',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DPProjectBreadcrumbs(project: _project, current: 'Booking composer'),
        const SizedBox(height: 10),
        dpHeaderAction(
          context,
          icon: _step == steps.length - 1
              ? Icons.send_rounded
              : Icons.arrow_forward_rounded,
          label: _step == steps.length - 1 ? 'Send' : 'Next',
          onTap: _next,
        ),
        const SizedBox(height: 8),
        const DPBookingStatusSpine(activeIndex: 0),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _step = i),
                    child: DPStatusChip(
                      label: '${i + 1}. ${steps[i]}',
                      tone: _step == i ? DpTone.warning : DpTone.neutral,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _stepBody(),
      ],
    );
  }

  Widget _stepBody() {
    return switch (_step) {
      0 => _ProjectAttachStep(
          projects: _projects,
          projectId: _projectId!,
          onProjectChanged: (value) async {
            final projectsController = ProjectsScope.of(context);
            final requirements = await projectsController.requirements(value);
            setState(() {
              _projectId = value;
              _requirements = requirements;
              _requirementId =
                  requirements.isEmpty ? null : requirements.first.publicId;
              _prefillFromSelection();
            });
          },
        ),
      1 => _RequirementStep(
          project: _project,
          requirements: _requirements,
          selectedRequirementId: _requirementId,
          onRequirementChanged: (value) {
            setState(() {
              _requirementId = value;
              _prefillFromSelection();
            });
          },
        ),
      2 => _TermsStep(
          candidate: _candidate!,
          schema: _schema,
          dates: _dates,
          fee: _fee,
          deposit: _deposit,
          middle: _middle,
          finalPayment: _final,
          deliverables: _deliverables,
          usageRights: _usageRights,
          conditions: _conditions,
          expiry: _expiry,
          dynamicA: _dynamicA,
          dynamicB: _dynamicB,
          dynamicC: _dynamicC,
          scheduleTotal: _scheduleTotal,
          onChanged: () => setState(() {}),
        ),
      _ => _ReviewStep(
          project: _project,
          requirement: _selectedRequirement,
          candidate: _candidate!,
          category: _category ?? _candidate!.category,
          schema: _schema,
          dates: _dates.text,
          fee: _fee.text,
          schedule:
              '${_deposit.text}% deposit / ${_middle.text}% milestone / ${_final.text}% final',
          deliverables: _deliverables.text,
          usageRights: _usageRights.text,
          conditions: _conditions.text,
          expiry: _expiry.text,
          scheduleTotal: _scheduleTotal,
          onSaveDraft: _saveDraft,
          onSend: _send,
          sending: _sending,
        ),
    };
  }

  void _next() {
    if (_step < 3) {
      setState(() => _step += 1);
      return;
    }
    _send();
  }

  void _saveDraft() {
    dpSnack(
      context,
      'Draft saved to ${_project.title} → ${_selectedRequirement?.title ?? 'General request'}.',
    );
  }

  Future<void> _send() async {
    if (!await ensureKycApproved(context)) return;
    if (!mounted) return;
    if (_scheduleTotal != 100) {
      dpSnack(context, 'Payment schedule must total 100%.');
      setState(() => _step = 2);
      return;
    }
    final bookings = BookingsScope.maybeOf(context);
    final listing = _listing;
    if (bookings == null || listing == null || _projectId == null) {
      dpSnack(context, 'Live booking service is unavailable.');
      return;
    }
    final feeMinor = _moneyFromLabel(_fee.text) * 100;
    if (feeMinor <= 0) {
      dpSnack(context, 'Enter a valid fee before sending.');
      setState(() => _step = 2);
      return;
    }
    setState(() => _sending = true);
    try {
      await bookings.createAndSendBooking(
        projectId: _projectId!,
        listingId: listing.publicId,
        requirementId: _requirementId,
        startAt: _startIso(),
        endAt: _endIso(),
        feeMinor: feeMinor,
        currency: listing.currency,
        message: _conditions.text,
      );
      if (!mounted) return;
      dpSnack(context, 'Booking request sent to ${_candidate!.name}.');
      Navigator.pushNamed(context, DirectorProducerRoutes.bargaining);
    } on ApiException catch (exception) {
      if (!mounted) return;
      dpSnack(context, exception.message);
    } catch (_) {
      if (!mounted) return;
      dpSnack(context, 'Could not send the booking request right now.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _friendlyError(Object? error) {
    if (error is ApiException) {
      return switch (error.code) {
        'auth.required' ||
        'auth.invalid_token' =>
          'Sign in to compose live booking requests.',
        'network.offline' =>
          'Live booking context is unavailable. Check your connection and retry.',
        _ => error.message,
      };
    }
    return 'Live booking context is unavailable right now.';
  }

  String _startIso() {
    final start = _selectedRequirement?.startDate ?? _project.startDate;
    return (start ?? DateTime.now().add(const Duration(days: 1)))
        .toUtc()
        .toIso8601String();
  }

  String _endIso() {
    final end = _selectedRequirement?.endDate ?? _project.endDate;
    final fallback = DateTime.now().add(const Duration(days: 2));
    return (end ?? fallback).toUtc().toIso8601String();
  }

  String _projectDateLabel(Project project) {
    return _dateRange(project.startDate, project.endDate);
  }

  String _requirementDateLabel(ProjectRequirement requirement) {
    return _dateRange(requirement.startDate, requirement.endDate);
  }

  String _feeLabel(ProjectRequirement? requirement, DpCandidate? candidate) {
    if (requirement?.budgetMinMinor != null ||
        requirement?.budgetMaxMinor != null) {
      final min = requirement?.budgetMinMinor == null
          ? null
          : requirement!.budgetMinMinor! ~/ 100;
      final max = requirement?.budgetMaxMinor == null
          ? null
          : requirement!.budgetMaxMinor! ~/ 100;
      final currency = requirement?.currency ?? 'PKR';
      if (min != null && max != null) {
        return '$currency ${_shortMoney(min)}-${_shortMoney(max)}';
      }
      if (min != null) return 'From $currency ${_shortMoney(min)}';
      return 'Up to $currency ${_shortMoney(max!)}';
    }
    return candidate?.rateRange ?? 'Rate on request';
  }
}

class _ProjectAttachStep extends StatelessWidget {
  final List<Project> projects;
  final String projectId;
  final ValueChanged<String> onProjectChanged;

  const _ProjectAttachStep({
    required this.projects,
    required this.projectId,
    required this.onProjectChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DPSectionCard(
      title: 'Project attach',
      icon: Icons.account_tree_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            key: ValueKey(projectId),
            initialValue: projectId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Parent project',
              prefixIcon: Icon(Icons.movie_creation_outlined),
            ),
            items: [
              for (final project in projects)
                DropdownMenuItem(
                  value: project.publicId,
                  child: Text(
                    project.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) onProjectChanged(value);
            },
          ),
          const SizedBox(height: 12),
          DPHolographicButton(
            label: 'New Project inline',
            icon: Icons.add_rounded,
            onTap: () => Navigator.pushNamed(
              context,
              DirectorProducerRoutes.createProject,
            ),
            secondary: true,
          ),
        ],
      ),
    );
  }
}

class _RequirementStep extends StatelessWidget {
  final Project project;
  final List<ProjectRequirement> requirements;
  final String? selectedRequirementId;
  final ValueChanged<String?> onRequirementChanged;

  const _RequirementStep({
    required this.project,
    required this.requirements,
    required this.selectedRequirementId,
    required this.onRequirementChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DPSectionCard(
      title: 'Requirement link',
      icon: Icons.rule_folder_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String?>(
            key: ValueKey('${project.publicId}-$selectedRequirementId'),
            initialValue: selectedRequirementId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Project requirement',
              prefixIcon: Icon(Icons.link_outlined),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('General booking request'),
              ),
              for (final requirement in requirements)
                DropdownMenuItem<String?>(
                  value: requirement.publicId,
                  child: Text(
                    requirement.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: onRequirementChanged,
          ),
          const SizedBox(height: 12),
          if (requirements.isEmpty)
            dpText(context,
                'No requirements yet. Add them in the project builder.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final requirement in requirements)
                  DPStatusChip(
                    label:
                        '${requirement.displayCategory}: ${_titleCase(requirement.status)}',
                    tone: DpTone.info,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TermsStep extends StatelessWidget {
  final DpCandidate candidate;
  final _BookingSchema schema;
  final TextEditingController dates;
  final TextEditingController fee;
  final TextEditingController deposit;
  final TextEditingController middle;
  final TextEditingController finalPayment;
  final TextEditingController deliverables;
  final TextEditingController usageRights;
  final TextEditingController conditions;
  final TextEditingController expiry;
  final TextEditingController dynamicA;
  final TextEditingController dynamicB;
  final TextEditingController dynamicC;
  final int scheduleTotal;
  final VoidCallback onChanged;

  const _TermsStep({
    required this.candidate,
    required this.schema,
    required this.dates,
    required this.fee,
    required this.deposit,
    required this.middle,
    required this.finalPayment,
    required this.deliverables,
    required this.usageRights,
    required this.conditions,
    required this.expiry,
    required this.dynamicA,
    required this.dynamicB,
    required this.dynamicC,
    required this.scheduleTotal,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DPTwoColumn(
      left: DPSectionCard(
        title: 'Editable terms',
        icon: Icons.edit_note_outlined,
        child: Column(
          children: [
            CoreTextField(
              controller: dates,
              label: 'Dates',
              icon: Icons.date_range_outlined,
              onChanged: (_) => onChanged(),
            ),
            if (!candidate.available) ...[
              const SizedBox(height: 8),
              const DPStatusChip(
                label: 'Availability conflict warning',
                tone: DpTone.danger,
                icon: Icons.warning_amber_rounded,
              ),
            ],
            const SizedBox(height: 12),
            CoreTextField(
              controller: fee,
              label: 'Fee offered',
              icon: Icons.payments_outlined,
              onChanged: (_) => onChanged(),
            ),
            const SizedBox(height: 8),
            DPGlassCard(
              padding: const EdgeInsets.all(10),
              child: dpText(
                context,
                'Talent rate reference: ${candidate.rateRange}',
                strong: true,
              ),
            ),
            const SizedBox(height: 12),
            CoreTextField(
              controller: deliverables,
              label: 'Deliverables',
              icon: Icons.task_alt_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            if (schema.showUsageRights)
              CoreTextField(
                controller: usageRights,
                label: 'Usage rights',
                icon: Icons.copyright_outlined,
                maxLines: 2,
              ),
            const SizedBox(height: 12),
            CoreTextField(
              controller: conditions,
              label: 'Special conditions',
              icon: Icons.fact_check_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            CoreTextField(
              controller: expiry,
              label: 'Offer expiry (hours)',
              icon: Icons.timer_outlined,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      right: DPSectionCard(
        title: schema.title,
        icon: schema.icon,
        child: Column(
          children: [
            CoreTextField(
              controller: dynamicA,
              label: schema.fields[0],
              icon: schema.icon,
            ),
            const SizedBox(height: 12),
            CoreTextField(
              controller: dynamicB,
              label: schema.fields[1],
              icon: Icons.tune_outlined,
            ),
            const SizedBox(height: 12),
            CoreTextField(
              controller: dynamicC,
              label: schema.fields[2],
              icon: Icons.notes_outlined,
            ),
            const SizedBox(height: 14),
            _ScheduleBuilder(
              deposit: deposit,
              middle: middle,
              finalPayment: finalPayment,
              total: scheduleTotal,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleBuilder extends StatelessWidget {
  final TextEditingController deposit;
  final TextEditingController middle;
  final TextEditingController finalPayment;
  final int total;
  final VoidCallback onChanged;

  const _ScheduleBuilder({
    required this.deposit,
    required this.middle,
    required this.finalPayment,
    required this.total,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DPGlassCard(
      padding: const EdgeInsets.all(11),
      selected: total == 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: dpText(context, 'Payment schedule', strong: true)),
              DPStatusChip(
                label: '$total%',
                tone: total == 100 ? DpTone.success : DpTone.danger,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CoreTextField(
                  controller: deposit,
                  label: 'Deposit %',
                  icon: Icons.looks_one_outlined,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CoreTextField(
                  controller: middle,
                  label: 'Milestone %',
                  icon: Icons.looks_two_outlined,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CoreTextField(
                  controller: finalPayment,
                  label: 'Final %',
                  icon: Icons.looks_3_outlined,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  final Project project;
  final ProjectRequirement? requirement;
  final DpCandidate candidate;
  final String category;
  final _BookingSchema schema;
  final String dates;
  final String fee;
  final String schedule;
  final String deliverables;
  final String usageRights;
  final String conditions;
  final String expiry;
  final int scheduleTotal;
  final VoidCallback onSaveDraft;
  final VoidCallback onSend;
  final bool sending;

  const _ReviewStep({
    required this.project,
    required this.requirement,
    required this.candidate,
    required this.category,
    required this.schema,
    required this.dates,
    required this.fee,
    required this.schedule,
    required this.deliverables,
    required this.usageRights,
    required this.conditions,
    required this.expiry,
    required this.scheduleTotal,
    required this.onSaveDraft,
    required this.onSend,
    required this.sending,
  });

  @override
  Widget build(BuildContext context) {
    return DPSectionCard(
      title: 'Review exactly as recipient sees it',
      icon: Icons.fact_check_outlined,
      child: Column(
        children: [
          DPDetailRow(label: 'Project', value: project.title),
          DPDetailRow(
              label: 'Requirement',
              value: requirement?.title ?? 'General booking request'),
          DPDetailRow(
              label: 'Stakeholder', value: '${candidate.name} • $category'),
          DPDetailRow(label: 'Dates', value: dates),
          DPDetailRow(label: 'Fee', value: fee),
          DPDetailRow(label: 'Payment schedule', value: schedule),
          DPDetailRow(label: 'Deliverables', value: deliverables),
          if (schema.showUsageRights)
            DPDetailRow(label: 'Usage rights', value: usageRights),
          DPDetailRow(label: 'Special conditions', value: conditions),
          DPDetailRow(label: 'Expiry', value: '$expiry hours'),
          const SizedBox(height: 12),
          if (scheduleTotal != 100)
            const DPStatusChip(
              label: 'Payment schedule must total 100%',
              tone: DpTone.danger,
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DPHolographicButton(
                  label: 'Save Draft',
                  icon: Icons.save_outlined,
                  onTap: onSaveDraft,
                  secondary: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DPHolographicButton(
                  label: 'Send Booking Request',
                  icon: sending
                      ? Icons.hourglass_top_rounded
                      : Icons.send_rounded,
                  onTap: sending ? null : onSend,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingFormData {
  final MarketplaceListing listing;
  final List<Project> projects;
  final List<ProjectRequirement> requirements;
  final String projectId;

  const _BookingFormData({
    required this.listing,
    required this.projects,
    required this.requirements,
    required this.projectId,
  });
}

class _BookingErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _BookingErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      accentColor: colors.warning,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_outlined, color: colors.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Could not load booking composer',
                  style: AppTextStyles.cardTitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        DirectorProducerRoutes.marketplace,
                      ),
                      icon: const Icon(Icons.travel_explore_outlined),
                      label: const Text('Open marketplace'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DPProjectBreadcrumbs extends StatelessWidget {
  final Project project;
  final String current;

  const DPProjectBreadcrumbs({
    super.key,
    required this.project,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Icon(Icons.account_tree_outlined, size: 16, color: colors.goldDark),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${project.title} / $current',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class DPDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DPDetailRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: colors.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingSchema {
  final String title;
  final IconData icon;
  final List<String> fields;
  final List<String> fieldHints;
  final String deliverablesHint;
  final String usageRightsHint;
  final bool showUsageRights;

  const _BookingSchema({
    required this.title,
    required this.icon,
    required this.fields,
    required this.fieldHints,
    required this.deliverablesHint,
    required this.usageRightsHint,
    required this.showUsageRights,
  });

  factory _BookingSchema.forCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('location')) {
      return const _BookingSchema(
        title: 'Location details',
        icon: Icons.location_city_outlined,
        fields: ['Areas needed', 'Crew size', 'Timings / access'],
        fieldHints: ['Kitchen + lounge', '28 crew + 6 cast', '7 AM load-in'],
        deliverablesHint: 'Location access, holding area, parking support',
        usageRightsHint: '',
        showUsageRights: false,
      );
    }
    if (lower.contains('equipment') || lower.contains('media')) {
      return const _BookingSchema(
        title: 'Equipment details',
        icon: Icons.video_camera_back_outlined,
        fields: ['Items / package', 'Pickup / return', 'Deposit terms'],
        fieldHints: [
          'Camera + lighting package',
          'Pickup Jul 18, return Jul 20',
          '30% hold'
        ],
        deliverablesHint: 'Insured package, operator support, condition photos',
        usageRightsHint: '',
        showUsageRights: false,
      );
    }
    if (lower.contains('crew')) {
      return const _BookingSchema(
        title: 'Crew service details',
        icon: Icons.groups_2_outlined,
        fields: ['Service', 'Kit required', 'Travel / overtime'],
        fieldHints: [
          'DOP / gaffer package',
          'Monitor + basic lighting kit',
          'Travel included'
        ],
        deliverablesHint: 'Crew attendance, kit list, call-sheet compliance',
        usageRightsHint: '',
        showUsageRights: false,
      );
    }
    return const _BookingSchema(
      title: 'Talent details',
      icon: Icons.theater_comedy_outlined,
      fields: ['Role / wardrobe', 'Travel', 'Scene notes'],
      fieldHints: [
        'Lead role, winter wardrobe',
        'Travel and lodging included',
        'Exterior dialogue scenes'
      ],
      deliverablesHint: 'Performance, rehearsals, stills approval window',
      usageRightsHint: 'Digital + TV usage, Pakistan, 12 months',
      showUsageRights: true,
    );
  }
}

String _dateRange(DateTime? start, DateTime? end) {
  if (start == null && end == null) return 'Select shoot dates';
  if (start != null && end != null) {
    return '${_shortDate(start)} - ${_shortDate(end)}';
  }
  if (start != null) return 'From ${_shortDate(start)}';
  return 'Until ${_shortDate(end!)}';
}

String _shortDate(DateTime value) {
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
  return '${months[value.month - 1]} ${value.day}';
}

String _shortMoney(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).round()}k';
  return '$value';
}

int _moneyFromLabel(String label) {
  final normalized = label.toLowerCase().replaceAll(',', '');
  final matches = RegExp(r'(\d+(?:\.\d+)?)').allMatches(normalized).toList();
  if (matches.isEmpty) return 0;
  final value = double.tryParse(matches.last.group(1) ?? '0') ?? 0;
  if (normalized.contains('m')) return (value * 1000000).round();
  if (normalized.contains('k')) return (value * 1000).round();
  return value.round();
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.trim().isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
