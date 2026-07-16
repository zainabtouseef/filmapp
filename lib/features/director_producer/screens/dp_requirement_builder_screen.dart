import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/director_producer_demo_data.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_requirement_card.dart';
import '../widgets/dp_status_chip.dart';

class DPRequirementBuilderScreen extends StatefulWidget {
  const DPRequirementBuilderScreen({super.key});

  @override
  State<DPRequirementBuilderScreen> createState() =>
      _DPRequirementBuilderScreenState();
}

class _DPRequirementBuilderScreenState
    extends State<DPRequirementBuilderScreen> {
  String _category = 'Roles';

  @override
  Widget build(BuildContext context) {
    final requirements = DirectorProducerDemoData.requirements
        .where((req) => req.category == _category)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dpHeaderAction(
          context,
          icon: Icons.add_circle_outline_rounded,
          label: 'Add',
          onTap: () => dpSnack(context, 'Requirement saved for demo'),
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
            children: const [
              _RequirementInput(
                label: 'Requirement title',
                icon: Icons.title_rounded,
                value: 'Lead actor, 28-34',
              ),
              SizedBox(height: 10),
              _RequirementInput(
                label: 'Filters summary / notes',
                icon: Icons.tune_rounded,
                value: 'Urdu/Pashto, athletic, winter exterior comfort',
              ),
              SizedBox(height: 10),
              _RequirementInput(
                label: 'Fee range and dates',
                icon: Icons.payments_outlined,
                value: 'PKR 1.2M - 1.8M - Aug 7 - Aug 26',
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: DPHolographicButton(
            label: 'Save Requirement',
            icon: Icons.save_outlined,
            onTap: () => dpSnack(context, 'Requirement saved'),
          ),
        ),
        const SizedBox(height: 14),
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

class _RequirementInput extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;

  const _RequirementInput({
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
