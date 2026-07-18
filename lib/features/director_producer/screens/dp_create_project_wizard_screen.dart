import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/projects/projects_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_budget_health_bar.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';

class DPCreateProjectWizardScreen extends StatefulWidget {
  const DPCreateProjectWizardScreen({super.key});

  @override
  State<DPCreateProjectWizardScreen> createState() =>
      _DPCreateProjectWizardScreenState();
}

class _DPCreateProjectWizardScreenState
    extends State<DPCreateProjectWizardScreen> {
  final _title = TextEditingController(text: 'Aurora Biscuit TVC');
  final _type = TextEditingController(text: 'tvc');
  final _description = TextEditingController(
    text: 'Premium family brand film with warm interiors.',
  );
  final _startDate = TextEditingController(text: '2026-08-18');
  final _endDate = TextEditingController(text: '2026-08-22');
  final _budget = TextEditingController(text: '8500000');
  int _step = 0;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _type.dispose();
    _description.dispose();
    _startDate.dispose();
    _endDate.dispose();
    _budget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = ['Type + Info', 'Dates', 'Budget', 'Review'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dpHeaderAction(
          context,
          icon: _step == steps.length - 1
              ? Icons.check_circle_outline
              : Icons.arrow_forward_rounded,
          label: _saving
              ? 'Creating...'
              : _step == steps.length - 1
                  ? 'Create'
                  : 'Next',
          onTap: _saving ? () {} : _next,
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: steps
                .asMap()
                .entries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: DPStatusChip(
                      label: '${entry.key + 1}. ${entry.value}',
                      tone:
                          entry.key == _step ? DpTone.warning : DpTone.neutral,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 14),
        DPGlassCard(child: _stepBody(context)),
      ],
    );
  }

  Widget _stepBody(BuildContext context) {
    return switch (_step) {
      0 => Column(
          children: [
            CoreTextField(
              controller: _type,
              label: 'Project type',
              icon: Icons.movie_creation_outlined,
            ),
            const SizedBox(height: 12),
            CoreTextField(
              controller: _title,
              label: 'Project title',
              icon: Icons.title_rounded,
            ),
            const SizedBox(height: 12),
            CoreTextField(
              controller: _description,
              label: 'Description / tone',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
          ],
        ),
      1 => Column(
          children: [
            CoreTextField(
              controller: _startDate,
              label: 'Start date (YYYY-MM-DD)',
              icon: Icons.date_range_outlined,
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 12),
            CoreTextField(
              controller: _endDate,
              label: 'End date (YYYY-MM-DD)',
              icon: Icons.event_available_outlined,
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 12),
            const DPStatusChip(label: 'Tentative dates', tone: DpTone.warning),
          ],
        ),
      2 => Column(
          children: [
            CoreTextField(
              controller: _budget,
              label: 'Estimated budget (PKR)',
              icon: Icons.payments_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),
            const DPBudgetHealthBar(value: .62, label: 'Budget health preview'),
          ],
        ),
      _ => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReviewRow(label: 'Project', value: _title.text),
            const SizedBox(height: 10),
            _ReviewRow(label: 'Type', value: _type.text),
            const SizedBox(height: 10),
            _ReviewRow(
              label: 'Dates',
              value: '${_startDate.text} → ${_endDate.text}',
            ),
            const SizedBox(height: 10),
            _ReviewRow(label: 'Budget', value: 'PKR ${_budget.text}'),
            const SizedBox(height: 12),
            DPHolographicButton(
              label: _saving ? 'Creating Project' : 'Create Project',
              icon: Icons.check_circle_outline,
              onTap: _saving ? null : _createProject,
            ),
          ],
        ),
    };
  }

  void _next() {
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _createProject();
    }
  }

  Future<void> _createProject() async {
    final controller = ProjectsScope.maybeOf(context);
    if (controller == null) {
      dpSnack(context, 'Sign in to create projects');
      return;
    }
    if (_title.text.trim().length < 2 || _type.text.trim().length < 2) {
      dpSnack(context, 'Project title and type are required');
      return;
    }
    setState(() => _saving = true);
    try {
      final project = await controller.createProject(
        title: _title.text.trim(),
        projectType: _type.text.trim(),
        description: _description.text.trim(),
        startDate: _startDate.text.trim(),
        endDate: _endDate.text.trim(),
        estimatedBudgetMinor: _parseBudgetMinor(_budget.text),
      );
      if (!mounted) return;
      dpSnack(context, 'Project created');
      Navigator.pushNamed(
        context,
        DirectorProducerRoutes.projectDetail,
        arguments: project.publicId,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      dpSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int? _parseBudgetMinor(String value) {
    final whole = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (whole == null) return null;
    return whole * 100;
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
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
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
