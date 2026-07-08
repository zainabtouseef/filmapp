import 'package:flutter/material.dart';

import '../../core_ui/core_back_navigation.dart';
import '../../core_ui/widgets/core_widgets.dart';
import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';

class ReportBlockScreen extends StatefulWidget {
  final String? initialReason;

  const ReportBlockScreen({
    super.key,
    this.initialReason,
  });

  @override
  State<ReportBlockScreen> createState() => _ReportBlockScreenState();
}

class _ReportBlockScreenState extends State<ReportBlockScreen> {
  late String _reason = widget.initialReason ?? 'Fake offer';
  String _urgency = 'Normal';
  bool _uploaded = false;
  bool _block = false;
  final _description = TextEditingController();

  final _reasons = const [
    'Fake offer',
    'Harassment',
    'Fake profile',
    'Payment fraud',
    'Stolen portfolio content',
    'Image misuse',
    'Unsafe shoot environment',
    'Other',
  ];

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    showCoreSuccessDialog(
      context,
      title: 'Report submitted to CineConnect Support.',
      message: _block
          ? 'This user will no longer be able to contact you.'
          : 'Support CRM and moderation routing are simulated for this phase.',
      buttonLabel: 'Return',
      onDone: () => navigateCoreBack(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CoreScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CoreAppHeader(
            title: 'Report & Block',
            subtitle:
                'Report fake offers, harassment, payment issues or unsafe behavior.',
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: 18),
          CoreGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person_off_outlined, color: colors.goldDark),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Reported user/project: Ali Khan · TVC Shoot — Lahore',
                          style: AppTextStyles.label
                              .copyWith(color: colors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CoreDropdownField<String>(
                  value: _reason,
                  values: _reasons,
                  label: 'Reason picker',
                  icon: Icons.report_problem_outlined,
                  onChanged: (value) =>
                      setState(() => _reason = value ?? _reason),
                ),
                const SizedBox(height: 14),
                UploadCard(
                  title: 'Evidence attachment',
                  subtitle: 'Attach screenshots, contracts or payment proof',
                  uploaded: _uploaded,
                  onTap: () => setState(() => _uploaded = true),
                ),
                const SizedBox(height: 14),
                CoreTextField(
                  controller: _description,
                  label: 'Description',
                  icon: Icons.notes_outlined,
                  maxLines: 5,
                ),
                const SizedBox(height: 14),
                CoreDropdownField<String>(
                  value: _urgency,
                  values: const ['Normal', 'Urgent', 'Safety Risk'],
                  label: 'Urgency selector',
                  icon: Icons.priority_high_rounded,
                  onChanged: (value) =>
                      setState(() => _urgency = value ?? _urgency),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: colors.goldMid,
                  value: _block,
                  onChanged: (value) => setState(() => _block = value),
                  title: Text(
                    'Block user',
                    style:
                        AppTextStyles.label.copyWith(color: colors.textPrimary),
                  ),
                  subtitle: Text(
                    'This user will no longer be able to contact you.',
                    style: AppTextStyles.caption
                        .copyWith(color: colors.textSecondary),
                  ),
                ),
                const SizedBox(height: 18),
                CorePrimaryButton(
                  icon: Icons.outbox_outlined,
                  label: 'Submit report',
                  onTap: _submit,
                ),
                const SizedBox(height: 10),
                CoreSecondaryButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'Return to previous screen',
                  onTap: () => navigateCoreBack(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
