import 'package:flutter/material.dart';

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
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    final steps = ['Type + Info', 'Cities + Dates', 'Budget', 'Team'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dpHeaderAction(
          context,
          icon: Icons.auto_awesome_rounded,
          label: _step == steps.length - 1 ? 'Create' : 'Next',
          onTap: _next,
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
          children: const [
            _FormPreviewRow(
              label: 'Project type',
              icon: Icons.movie_creation_outlined,
              value: 'TVC',
            ),
            SizedBox(height: 12),
            _FormPreviewRow(
              label: 'Project title',
              icon: Icons.title_rounded,
              value: 'Aurora Biscuit TVC',
            ),
            SizedBox(height: 12),
            _FormPreviewRow(
              label: 'Description / tone',
              icon: Icons.notes_rounded,
              value: 'Premium family brand film with warm interiors.',
            ),
          ],
        ),
      1 => Column(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                DPStatusChip(label: 'Lahore', tone: DpTone.warning),
                DPStatusChip(label: 'Karachi', tone: DpTone.info),
                DPStatusChip(label: 'Islamabad', tone: DpTone.neutral),
                DPStatusChip(label: 'Hunza', tone: DpTone.neutral),
              ],
            ),
            const SizedBox(height: 12),
            const _FormPreviewRow(
              label: 'Date range',
              icon: Icons.date_range_outlined,
              value: 'Jul 18 - Jul 22',
            ),
            const SizedBox(height: 12),
            const DPStatusChip(label: 'Tentative dates', tone: DpTone.warning),
          ],
        ),
      2 => Column(
          children: const [
            _FormPreviewRow(
              label: 'Minimum budget',
              icon: Icons.payments_outlined,
              value: 'PKR 6.5M',
            ),
            SizedBox(height: 12),
            _FormPreviewRow(
              label: 'Maximum budget',
              icon: Icons.savings_outlined,
              value: 'PKR 8.5M',
            ),
            SizedBox(height: 14),
            DPBudgetHealthBar(value: .62, label: 'Budget health preview'),
          ],
        ),
      _ => Column(
          children: [
            ...[
              'Invite co-producer - Manage bookings',
              'Invite production manager - Requirements + schedule',
              'Invite finance lead - Payments only',
            ].map((row) => dpBullet(context, row)),
            const SizedBox(height: 12),
            DPHolographicButton(
              label: 'Create Project',
              icon: Icons.check_circle_outline,
              onTap: _next,
            ),
          ],
        ),
    };
  }

  void _next() {
    if (_step < 3) {
      setState(() => _step++);
    } else {
      dpSnack(context, 'Demo project created');
      Navigator.pushNamed(context, DirectorProducerRoutes.projectDetail);
    }
  }
}

class _FormPreviewRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;

  const _FormPreviewRow({
    required this.label,
    required this.icon,
    required this.value,
  });

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
          Icon(icon, color: colors.goldDark, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
