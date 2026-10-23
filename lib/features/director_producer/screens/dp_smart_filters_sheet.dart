import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/cine_marketplace_card.dart';
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
  String _category = 'Actors';
  String _city = 'Lahore';
  bool _verifiedOnly = true;
  bool _saving = false;

  void _applyFilters() {
    Navigator.pushNamed(
      context,
      DirectorProducerRoutes.marketplace,
      arguments: {
        'category': _category,
        'query': _city,
        'verifiedOnly': _verifiedOnly,
      },
    );
  }

  Future<void> _saveView() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) {
      dpSnack(context, 'Sign in to save this search.');
      return;
    }
    setState(() => _saving = true);
    try {
      await auth.createSavedSearch(
        name: '$_city $_category',
        listingType: switch (_category) {
          'Actors' => 'actor',
          'Models' => 'model',
          'Crew' => 'crew',
          'Locations' => 'location',
          'Media & Equipment' => 'equipment',
          'Agencies' => 'agency',
          'Distribution' => 'distribution',
          _ => null,
        },
        queryText: _city,
      );
      if (mounted) dpSnack(context, 'Search saved.');
    } catch (_) {
      if (mounted) dpSnack(context, 'Could not save this search. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dpHeaderAction(
          context,
          icon: Icons.tune_rounded,
          label: 'Apply',
          onTap: _applyFilters,
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
                    'Actors',
                    'Models',
                    'Influencers',
                    'Crew',
                    'Locations',
                    'Media & Equipment',
                    'Agencies',
                    'Distribution',
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
                Text(
                    'Choose a category and city, then open matching live listings.',
                    style: AppTextStyles.smallMeta.copyWith(
                      color: context.appColors.textSecondary,
                    )),
              ],
            ),
          ),
          right: DPSectionCard(
            title: 'Production Rules',
            icon: Icons.rule_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _verifiedOnly,
                  onChanged: (value) => setState(() => _verifiedOnly = value),
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
                      onTap: _applyFilters,
                    ),
                    DPHolographicButton(
                      label: _saving ? 'Saving…' : 'Save View',
                      icon: Icons.bookmark_outline_rounded,
                      onTap: _saving ? null : _saveView,
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
                  label: marketplaceCategoryLabel(option),
                  tone: option == active ? DpTone.warning : DpTone.neutral,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
