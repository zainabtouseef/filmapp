import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';

class DPSmartFiltersSheet extends StatefulWidget {
  const DPSmartFiltersSheet({super.key});

  @override
  State<DPSmartFiltersSheet> createState() => _DPSmartFiltersSheetState();
}

class _DPSmartFiltersSheetState extends State<DPSmartFiltersSheet> {
  String _category = 'Talent';
  String _city = 'Lahore';
  bool _verifiedOnly = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dpHeaderAction(
          context,
          icon: Icons.tune_rounded,
          label: 'Apply',
          onTap: () =>
              Navigator.pushNamed(context, DirectorProducerRoutes.marketplace),
        ),
        const SizedBox(height: 8),
        DPTwoColumn(
          left: DPSectionCard(
            title: 'Profile Match',
            icon: Icons.person_search_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FilterGroup(
                  title: 'Category',
                  options: const [
                    'Talent',
                    'Models',
                    'Crew',
                    'Locations',
                    'Media',
                    'Agencies',
                  ],
                  active: _category,
                  onSelected: (value) => setState(() => _category = value),
                ),
                const SizedBox(height: 14),
                _FilterGroup(
                  title: 'City',
                  options: const [
                    'Karachi',
                    'Lahore',
                    'Islamabad',
                    'Hunza',
                    'Murree',
                  ],
                  active: _city,
                  onSelected: (value) => setState(() => _city = value),
                ),
                const SizedBox(height: 14),
                _FilterRange(label: 'Rating floor', value: '4.5+'),
                _FilterRange(
                  label: 'Availability',
                  value: 'Next 14 days',
                  showDivider: false,
                ),
              ],
            ),
          ),
          right: DPSectionCard(
            title: 'Production Rules',
            icon: Icons.rule_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FilterRange(label: 'Budget range', value: 'PKR 150k - 1.8M'),
                _FilterRange(label: 'Usage rights', value: 'Digital + TVC'),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _verifiedOnly,
                  onChanged: (value) =>
                      setState(() => _verifiedOnly = value),
                  title: const Text('Verified only'),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    DPHolographicButton(
                      label: 'Apply Filters',
                      icon: Icons.check_rounded,
                      onTap: () => Navigator.pushNamed(
                        context,
                        DirectorProducerRoutes.marketplace,
                      ),
                    ),
                    DPHolographicButton(
                      label: 'Save View',
                      icon: Icons.bookmark_outline_rounded,
                      onTap: () => dpSnack(context, 'Filter view saved'),
                      secondary: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterGroup extends StatelessWidget {
  final String title;
  final List<String> options;
  final String active;
  final ValueChanged<String> onSelected;

  const _FilterGroup({
    required this.title,
    required this.options,
    required this.active,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTextStyles.smallMeta.copyWith(
            color: colors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              GestureDetector(
                onTap: () => onSelected(option),
                child: DPStatusChip(
                  label: option,
                  tone: option == active ? DpTone.warning : DpTone.neutral,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _FilterRange extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;

  const _FilterRange({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
      ),
      child: Row(
        children: [
          Expanded(child: dpText(context, label, strong: true)),
          const SizedBox(width: 10),
          Text(
            value,
            style: AppTextStyles.statusText.copyWith(color: colors.goldDark),
          ),
        ],
      ),
    );
  }
}
