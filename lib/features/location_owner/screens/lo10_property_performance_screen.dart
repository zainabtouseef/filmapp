import 'package:flutter/material.dart';

import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/operations/operations_controller.dart';
import '../../../core/operations/operations_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/location_owner_demo_data.dart';
import '../models/location_owner_models.dart';
import '../routes/location_owner_routes.dart';
import '../widgets/location_owner_components.dart';
import '../widgets/location_owner_live.dart';

class LO10PropertyPerformanceScreen extends StatefulWidget {
  const LO10PropertyPerformanceScreen({super.key});

  @override
  State<LO10PropertyPerformanceScreen> createState() =>
      _LO10PropertyPerformanceScreenState();
}

class _LO10PropertyPerformanceScreenState
    extends State<LO10PropertyPerformanceScreen> {
  OperationsController? _operations;
  BookingsController? _bookings;
  Future<_InsightsData>? _future;
  String _range = '30 days';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final operations = OperationsScope.maybeOf(context);
    final bookings = BookingsScope.maybeOf(context);
    if (operations == null || bookings == null) return;
    if (identical(operations, _operations) && identical(bookings, _bookings)) {
      return;
    }
    _operations = operations;
    _bookings = bookings;
    _future = _load();
  }

  Future<_InsightsData> _load({bool force = false}) async {
    final properties = await _operations!.locationProperties(force: force);
    final allBookings =
        await _bookings!.bookings(role: 'provider', force: force);
    return _InsightsData(
      properties: properties,
      bookings:
          allBookings.where((item) => item.category == 'location').toList(),
    );
  }

  void _reload() {
    if (_operations == null || _bookings == null) return;
    setState(() => _future = _load(force: true));
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) return _buildPreview();
    return FutureBuilder<_InsightsData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return CoreEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Insights unavailable',
            message: locationApiMessage(snapshot.error!),
            actionLabel: 'Try again',
            onAction: _reload,
          );
        }
        return _buildInsights(snapshot.data!);
      },
    );
  }

  Widget _buildInsights(_InsightsData data) {
    final colors = context.appColors;
    final bookings = _bookingsInRange(data.bookings);
    final open = bookings.where((item) {
      return {'sent', 'viewed', 'under_negotiation'}.contains(item.status);
    }).length;
    final accepted = bookings.where((item) {
      return {'accepted', 'secured', 'in_progress'}.contains(item.status);
    }).length;
    final closed = bookings.where((item) {
      return {'rejected', 'cancelled', 'completed'}.contains(item.status);
    }).length;
    final rated =
        data.properties.where((item) => item.ratingAverage > 0).toList();
    final averageRating = rated.isEmpty
        ? 0.0
        : rated.map((item) => item.ratingAverage).reduce((a, b) => a + b) /
            rated.length;
    final complete = data.properties.where(_isComplete).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocationSectionCard(
          title: 'Booking window',
          icon: Icons.tune_outlined,
          selected: true,
          actionText: 'Refresh',
          onActionTap: _reload,
          child: SingleChildScrollView(
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
                      onTap: () => setState(() => _range = range),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        MetricActionRail(
          items: [
            MetricActionItem(
              value: '${data.properties.length}',
              icon: Icons.location_city_outlined,
              title: 'Properties',
              subtitle: '$complete production-ready',
              accentColor: colors.infoBlue,
            ),
            MetricActionItem(
              value: '$open',
              icon: Icons.move_to_inbox_outlined,
              title: 'Open requests',
              subtitle: 'Within $_range',
              accentColor: colors.goldMid,
            ),
            MetricActionItem(
              value: '$accepted',
              icon: Icons.event_available_outlined,
              title: 'Accepted bookings',
              subtitle: 'Within $_range',
              accentColor: colors.success,
            ),
            MetricActionItem(
              value: averageRating > 0
                  ? averageRating.toStringAsFixed(1)
                  : 'No ratings',
              icon: Icons.star_outline_rounded,
              title: 'Property rating',
              subtitle: '${rated.length} rated',
              accentColor: colors.infoPurple,
            ),
          ],
        ),
        const SizedBox(height: 12),
        LocationTwoColumn(
          left: LocationSectionCard(
            title: 'Booking status',
            icon: Icons.bar_chart_rounded,
            tone: LocationTone.blue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location bookings in $_range',
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                LocationMiniBarChart(
                  values: [
                    open.toDouble(),
                    accepted.toDouble(),
                    closed.toDouble(),
                  ],
                  colors: [
                    colors.goldMid,
                    colors.success,
                    colors.textSecondary,
                  ],
                  height: 144,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusChip(
                      label: '$open OPEN',
                      color: colors.goldMid,
                    ),
                    StatusChip(
                      label: '$accepted ACCEPTED',
                      color: colors.success,
                    ),
                    StatusChip(
                      label: '$closed CLOSED',
                      color: colors.textSecondary,
                    ),
                  ],
                ),
                if (bookings.isEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'No location bookings fall within the selected shoot-date window.',
                    style: AppTextStyles.smallMeta.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          right: Column(
            children: [
              LocationSectionCard(
                title: 'Portfolio actions',
                icon: Icons.tips_and_updates_outlined,
                tone: LocationTone.gold,
                child: _PropertySuggestions(properties: data.properties),
              ),
              const SizedBox(height: 12),
              LocationSectionCard(
                title: 'Property health',
                icon: Icons.table_chart_outlined,
                tone: LocationTone.green,
                child: data.properties.isEmpty
                    ? CoreEmptyState(
                        icon: Icons.add_location_alt_outlined,
                        title: 'No properties',
                        message:
                            'Create a property to start tracking portfolio readiness.',
                        actionLabel: 'Create property',
                        onAction: () => Navigator.pushNamed(
                          context,
                          LocationOwnerRoutes.listing,
                        ),
                      )
                    : Column(
                        children: [
                          for (final property in data.properties)
                            _PropertyHealthRow(
                              property: property,
                              active: property.publicId ==
                                  LocationOwnerDemoStore
                                      .instance.activeLivePropertyId,
                              onTap: () {
                                LocationOwnerDemoStore.instance
                                    .setActiveLiveProperty(property.publicId);
                                setState(() {});
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
  }

  List<Booking> _bookingsInRange(List<Booking> bookings) {
    final days = switch (_range) {
      '7 days' => 7,
      '90 days' => 90,
      _ => 30,
    };
    final now = DateTime.now();
    final limit = now.add(Duration(days: days));
    return bookings.where((booking) {
      return booking.startAt.isBefore(limit) && booking.endAt.isAfter(now);
    }).toList();
  }

  bool _isComplete(LocationPropertyDto property) {
    return property.status == 'published' &&
        property.spaces.isNotEmpty &&
        property.pricing.any((item) => item.enabled && item.amountMinor > 0) &&
        property.rules.isNotEmpty;
  }

  Widget _buildPreview() {
    return LocationSectionCard(
      title: 'Property insights preview',
      icon: Icons.analytics_outlined,
      selected: true,
      child: Column(
        children: [
          for (final property in LocationOwnerDemoData.properties)
            LocationInfoRow(
              icon: Icons.location_city_outlined,
              label: property.name,
              value: '${property.rating.toStringAsFixed(1)} rating',
            ),
        ],
      ),
    );
  }
}

class _PropertySuggestions extends StatelessWidget {
  final List<LocationPropertyDto> properties;

  const _PropertySuggestions({required this.properties});

  @override
  Widget build(BuildContext context) {
    final property = activeLocationProperty(properties);
    if (property == null) {
      return CoreEmptyState(
        icon: Icons.add_location_alt_outlined,
        title: 'Create a property',
        message: 'Property actions are based on live profile completeness.',
        actionLabel: 'Create property',
        onAction: () =>
            Navigator.pushNamed(context, LocationOwnerRoutes.listing),
      );
    }
    final suggestions =
        <({IconData icon, String title, String detail, String route})>[
      if (property.status != 'published')
        (
          icon: Icons.publish_outlined,
          title: 'Publish the property',
          detail: 'Make the profile available in director discovery.',
          route: LocationOwnerRoutes.listing,
        ),
      if (property.spaces.isEmpty)
        (
          icon: Icons.dashboard_customize_outlined,
          title: 'Add shoot spaces',
          detail: 'Name the interiors and exteriors available to productions.',
          route: LocationOwnerRoutes.listing,
        ),
      if (!property.pricing.any((item) => item.enabled))
        (
          icon: Icons.price_change_outlined,
          title: 'Add a full-day rate',
          detail: 'A clear baseline improves offer quality.',
          route: LocationOwnerRoutes.pricing,
        ),
      if (property.rules.isEmpty)
        (
          icon: Icons.rule_folder_outlined,
          title: 'Define property rules',
          detail: 'Document access, noise and equipment restrictions.',
          route: LocationOwnerRoutes.rules,
        ),
    ];
    if (suggestions.isEmpty) {
      return const CoreEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'Property profile complete',
        message: 'Core spaces, rates, rules and publication are in place.',
      );
    }
    return Column(
      children: [
        for (final item in suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.pushNamed(context, item.route),
              child: GlassSectionCard(
                radius: 16,
                padding: const EdgeInsets.all(11),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      color: context.appColors.goldDark,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: AppTextStyles.cardLabel.copyWith(
                              color: context.appColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.detail,
                            style: AppTextStyles.smallMeta.copyWith(
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.appColors.iconMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PropertyHealthRow extends StatelessWidget {
  final LocationPropertyDto property;
  final bool active;
  final VoidCallback onTap;

  const _PropertyHealthRow({
    required this.property,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final readiness = [
      property.spaces.isNotEmpty,
      property.pricing.any((item) => item.enabled),
      property.rules.isNotEmpty,
      property.status == 'published',
    ].where((item) => item).length;
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
            border: Border.all(
              color: active ? colors.goldMid : colors.border,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardLabel.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${property.spaces.length} spaces · '
                      '${property.pricing.length} rates · '
                      '${property.rules.length} rules',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(
                label: '$readiness/4 READY',
                color: readiness == 4 ? colors.success : colors.goldMid,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightsData {
  final List<LocationPropertyDto> properties;
  final List<Booking> bookings;

  const _InsightsData({
    required this.properties,
    required this.bookings,
  });
}
