import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/location_owner_demo_data.dart';
import '../models/location_owner_models.dart';
import '../routes/location_owner_routes.dart';
import '../widgets/location_owner_components.dart';

class LO10PropertyPerformanceScreen extends StatefulWidget {
  const LO10PropertyPerformanceScreen({super.key});

  @override
  State<LO10PropertyPerformanceScreen> createState() =>
      _LO10PropertyPerformanceScreenState();
}

class _LO10PropertyPerformanceScreenState
    extends State<LO10PropertyPerformanceScreen> {
  String _range = '30 days';
  String _metric = 'Requests';

  @override
  Widget build(BuildContext context) {
    final store = LocationOwnerDemoStore.instance;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocationSectionCard(
              title: 'Performance filters',
              icon: Icons.tune_outlined,
              selected: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final range in ['7 days', '30 days', '90 days'])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CoreChip(
                              label: range,
                              selected: _range == range,
                              icon: Icons.date_range_outlined,
                              onTap: () {
                                setState(() => _range = range);
                                locationSnack(context, '$range selected');
                              },
                            ),
                          ),
                        const SizedBox(width: 8),
                        for (final metric in [
                          'Views',
                          'Requests',
                          'Bookings',
                          'Rating',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CoreChip(
                              label: metric,
                              selected: _metric == metric,
                              icon: Icons.query_stats_outlined,
                              onTap: () {
                                setState(() => _metric = metric);
                                locationSnack(
                                    context, '$metric chart selected');
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            MetricActionRail(
              items: [
                MetricActionItem(
                  value: switch (_range) {
                    '7 days' => '420',
                    '90 days' => '5.1K',
                    _ => '2.8K',
                  },
                  icon: Icons.visibility_outlined,
                  title: 'Listing views',
                  subtitle: '+18%',
                  accentColor: locationToneColor(context, LocationTone.blue),
                ),
                MetricActionItem(
                  value: '11.4%',
                  icon: Icons.move_to_inbox_outlined,
                  title: 'Request rate',
                  subtitle: '+2.1%',
                  accentColor: locationToneColor(context, LocationTone.gold),
                ),
                MetricActionItem(
                  value: '38%',
                  icon: Icons.trending_up_outlined,
                  title: 'Conversion',
                  subtitle: '+6%',
                  accentColor: locationToneColor(context, LocationTone.green),
                ),
                MetricActionItem(
                  value: store.activeProperty.rating.toStringAsFixed(1),
                  icon: Icons.star_outline_rounded,
                  title: 'Rating',
                  subtitle: 'stable',
                  accentColor: locationToneColor(context, LocationTone.purple),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LocationTwoColumn(
              left: LocationSectionCard(
                title: 'Primary chart',
                icon: Icons.bar_chart_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$_metric over $_range',
                            style: AppTextStyles.cardLabel.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        StatusChip(label: 'LIVE DEMO', color: colors.goldMid),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LocationMiniBarChart(
                      values: _chartValues(),
                      colors: [colors.goldMid],
                      height: 154,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusChip(
                          label: '$_metric - daily trend',
                          color: colors.goldMid,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CorePrimaryButton(
                      icon: Icons.file_download_outlined,
                      label: 'Export analytics',
                      compact: true,
                      onTap: () => showCoreSuccessDialog(
                        context,
                        title: 'Analytics export ready',
                        message:
                            'A demo CSV and chart snapshot were generated for ${store.activeProperty.name}.',
                      ),
                    ),
                  ],
                ),
              ),
              right: Column(
                children: [
                  LocationSectionCard(
                    title: 'Suggestions',
                    icon: Icons.auto_awesome_outlined,
                    child: Column(
                      children: [
                        _SuggestionRow(
                          icon: Icons.nights_stay_outlined,
                          title: 'Add night-shoot pricing',
                          subtitle: 'Commercial producers search this filter.',
                          onTap: () => Navigator.pushNamed(
                            context,
                            LocationOwnerRoutes.pricing,
                          ),
                        ),
                        _SuggestionRow(
                          icon: Icons.photo_camera_outlined,
                          title: 'Refresh rooftop photos',
                          subtitle:
                              'Listings with night frames convert better.',
                          onTap: () => Navigator.pushNamed(
                            context,
                            LocationOwnerRoutes.listing,
                          ),
                        ),
                        _SuggestionRow(
                          icon: Icons.rule_folder_outlined,
                          title: 'Clarify sound limits',
                          subtitle: 'Reduces negotiation back-and-forth.',
                          onTap: () => Navigator.pushNamed(
                            context,
                            LocationOwnerRoutes.rules,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  LocationSectionCard(
                    title: 'Detailed table',
                    icon: Icons.table_chart_outlined,
                    child: Column(
                      children: [
                        for (final entry in _propertyPerformance.entries)
                          _TableRow(
                            label: entry.key.name,
                            metric: entry.value.$1,
                            rate: entry.value.$2,
                            active: entry.key.id == store.activePropertyId,
                            onTap: () {
                              store.setActiveProperty(entry.key.id);
                              locationSnack(
                                context,
                                '${entry.key.name} set as active property',
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static final Map<LocationProperty, (String, String)> _propertyPerformance = {
    for (final property in LocationOwnerDemoData.properties)
      property: switch (property.id) {
        'LOC-102' => ('2.8K views', '38% conversion'),
        'LOC-210' => ('1.4K views', '31% conversion'),
        _ => ('1.1K views', '29% conversion'),
      },
  };

  List<double> _chartValues() {
    final base = switch (_metric) {
      'Views' => const [28, 36, 42, 49, 54, 61, 66],
      'Bookings' => const [8, 9, 14, 13, 18, 19, 22],
      'Rating' => const [42, 44, 43, 45, 48, 48, 49],
      _ => const [12, 18, 20, 26, 24, 31, 34],
    };
    final scale = switch (_range) {
      '7 days' => 1.0,
      '90 days' => 2.4,
      _ => 1.6,
    };
    return base.map((value) => value * scale).toList();
  }
}

class _SuggestionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SuggestionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: GlassSectionCard(
          radius: 16,
          padding: const EdgeInsets.all(11),
          child: Row(
            children: [
              Icon(icon, color: colors.goldDark, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardLabel.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.iconMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final String label;
  final String metric;
  final String rate;
  final bool active;
  final VoidCallback onTap;

  const _TableRow({
    required this.label,
    required this.metric,
    required this.rate,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: colors.inactiveChipGradient,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? colors.goldMid : colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardLabel.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      metric,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StatusChip(label: rate, color: colors.success),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
