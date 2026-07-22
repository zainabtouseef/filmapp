import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../data/director_producer_demo_data.dart';
import '../models/dp_candidate.dart';
import '../models/dp_project.dart';
import '../models/dp_requirement.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_booking_status_spine.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_project_console_widgets.dart';
import '../widgets/dp_status_chip.dart';

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
  late String _projectId =
      widget.projectId ?? DirectorProducerDemoData.projects.first.id;
  String? _requirementId;
  late final DpCandidate _candidate =
      DirectorProducerDemoData.candidates.firstWhere(
    (item) => item.id == widget.candidateId,
    orElse: () => DirectorProducerDemoData.candidates.first,
  );
  late final String _category = widget.category ?? _candidate.category;
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

  @override
  void initState() {
    super.initState();
    final requirements = dpRequirementsForProject(_projectId);
    _requirementId = requirements.isEmpty ? null : requirements.first.id;
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
    _dates.text = requirement?.dates ?? 'Select shoot dates';
    _fee.text = requirement?.budgetRange ?? _candidate.rateRange;
    _deliverables.text = _schema.deliverablesHint;
    _usageRights.text = _schema.usageRightsHint;
    _conditions.text = 'Counteroffers allowed; chat remains in booking record.';
    _dynamicA.text = _schema.fieldHints[0];
    _dynamicB.text = _schema.fieldHints[1];
    _dynamicC.text = _schema.fieldHints[2];
  }

  DpProject get _project => dpProjectForId(_projectId);

  DpRequirement? get _selectedRequirement {
    if (_requirementId == null) return null;
    final requirements = dpRequirementsForProject(_projectId);
    if (requirements.isEmpty) return null;
    return DirectorProducerDemoData.requirements.firstWhere(
      (item) => item.id == _requirementId,
      orElse: () => requirements.first,
    );
  }

  _BookingSchema get _schema => _BookingSchema.forCategory(_category);

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
          projectId: _projectId,
          onProjectChanged: (value) {
            setState(() {
              _projectId = value;
              final requirements = dpRequirementsForProject(value);
              _requirementId =
                  requirements.isEmpty ? null : requirements.first.id;
              _prefillFromSelection();
            });
          },
        ),
      1 => _RequirementStep(
          project: _project,
          selectedRequirementId: _requirementId,
          onRequirementChanged: (value) {
            setState(() {
              _requirementId = value;
              _prefillFromSelection();
            });
          },
        ),
      2 => _TermsStep(
          candidate: _candidate,
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
          candidate: _candidate,
          category: _category,
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

  void _send() {
    if (_scheduleTotal != 100) {
      dpSnack(context, 'Payment schedule must total 100%.');
      setState(() => _step = 2);
      return;
    }
    dpSnack(context, 'Booking request sent to ${_candidate.name}.');
    Navigator.pushNamed(context, DirectorProducerRoutes.bargaining);
  }
}

class _ProjectAttachStep extends StatelessWidget {
  final String projectId;
  final ValueChanged<String> onProjectChanged;

  const _ProjectAttachStep({
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
              for (final project in DirectorProducerDemoData.projects)
                DropdownMenuItem(
                  value: project.id,
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
  final DpProject project;
  final String? selectedRequirementId;
  final ValueChanged<String?> onRequirementChanged;

  const _RequirementStep({
    required this.project,
    required this.selectedRequirementId,
    required this.onRequirementChanged,
  });

  @override
  Widget build(BuildContext context) {
    final requirements = dpRequirementsForProject(project.id);
    return DPSectionCard(
      title: 'Requirement link',
      icon: Icons.rule_folder_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String?>(
            key: ValueKey('${project.id}-$selectedRequirementId'),
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
                  value: requirement.id,
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
                    label: '${requirement.category}: ${requirement.status}',
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
  final DpProject project;
  final DpRequirement? requirement;
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
                  icon: Icons.send_rounded,
                  onTap: onSend,
                ),
              ),
            ],
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
