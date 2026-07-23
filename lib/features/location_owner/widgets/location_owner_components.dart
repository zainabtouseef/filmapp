import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/formatters/cine_format.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/location_owner_demo_data.dart';
import '../models/location_owner_models.dart';

Color locationToneColor(BuildContext context, LocationTone tone) {
  final colors = context.appColors;
  return switch (tone) {
    LocationTone.gold => colors.goldMid,
    LocationTone.blue => colors.infoBlue,
    LocationTone.green => colors.success,
    LocationTone.purple => colors.infoPurple,
    LocationTone.danger => colors.danger,
    LocationTone.neutral => colors.textSecondary,
  };
}

Color locationStatusColor(BuildContext context, LocationBookingStatus status) {
  final colors = context.appColors;
  return switch (status) {
    LocationBookingStatus.secured ||
    LocationBookingStatus.inProgress ||
    LocationBookingStatus.closed =>
      colors.success,
    LocationBookingStatus.depositPending ||
    LocationBookingStatus.contractPending ||
    LocationBookingStatus.requestReceived =>
      colors.goldMid,
    LocationBookingStatus.disputed => colors.danger,
    LocationBookingStatus.underNegotiation => colors.infoBlue,
  };
}

Color locationCalendarColor(
  BuildContext context,
  LocationCalendarStatus status,
) {
  final colors = context.appColors;
  return switch (status) {
    LocationCalendarStatus.available => colors.success,
    LocationCalendarStatus.blocked => colors.textSecondary,
    LocationCalendarStatus.maintenance => colors.danger,
    LocationCalendarStatus.tentativeHold => colors.goldMid,
    LocationCalendarStatus.booked => colors.infoBlue,
  };
}

IconData locationCalendarIcon(LocationCalendarStatus status) {
  return switch (status) {
    LocationCalendarStatus.available => Icons.check_circle_outline_rounded,
    LocationCalendarStatus.blocked => Icons.block_rounded,
    LocationCalendarStatus.maintenance => Icons.handyman_outlined,
    LocationCalendarStatus.tentativeHold => Icons.hourglass_top_rounded,
    LocationCalendarStatus.booked => Icons.event_available_outlined,
  };
}

String locationCalendarLabel(LocationCalendarStatus status) {
  return switch (status) {
    LocationCalendarStatus.available => 'Available',
    LocationCalendarStatus.blocked => 'Blocked',
    LocationCalendarStatus.maintenance => 'Maintenance',
    LocationCalendarStatus.tentativeHold => 'Tentative',
    LocationCalendarStatus.booked => 'Booked',
  };
}

String locationMoney(int amount) {
  return CineFormat.currency(amount);
}

void locationSnack(BuildContext context, String message) {
  showCoreSnack(context, message);
}

Future<void> showLocationSheet(
  BuildContext context, {
  required String title,
  required Widget child,
}) {
  final colors = context.appColors;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 12,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: GlassSectionCard(
            radius: 24,
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.82,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.sectionHeading.copyWith(
                                color: colors.textPrimary,
                                fontSize: 16,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close_rounded, color: colors.icon),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class LocationSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final String? actionText;
  final VoidCallback? onActionTap;
  final bool selected;
  final LocationTone tone;

  const LocationSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.actionText,
    this.onActionTap,
    this.selected = false,
    this.tone = LocationTone.gold,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = locationToneColor(context, tone);
    return GlassSectionCard(
      radius: 18,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: selected ? 5 : 3,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(18),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.28),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 9),
                    Icon(icon, color: accent, size: 19),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (actionText != null) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onActionTap,
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                        ),
                        label: Text(actionText!),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LocationResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minWidth;
  final double gap;

  const LocationResponsiveGrid({
    super.key,
    required this.children,
    this.minWidth = 240,
    this.gap = 12,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count =
            (constraints.maxWidth / minWidth).floor().clamp(1, 4).toInt();
        final width = (constraints.maxWidth - (count - 1) * gap) / count;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}

class LocationTwoColumn extends StatelessWidget {
  final Widget left;
  final Widget right;

  const LocationTwoColumn({
    super.key,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppBreakpoints.tablet) {
          return Column(
            children: [
              left,
              const SizedBox(height: 12),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: left),
            const SizedBox(width: 12),
            Expanded(flex: 4, child: right),
          ],
        );
      },
    );
  }
}

class LocationKpiRail extends StatelessWidget {
  final List<LocationMetric> metrics;

  const LocationKpiRail({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return MetricActionRail(
      items: [
        for (final metric in metrics)
          MetricActionItem(
            icon: metric.icon,
            value: metric.value,
            title: metric.label,
            subtitle: metric.delta,
            accentColor: locationToneColor(context, metric.tone),
            onTap: () => Navigator.pushNamed(context, metric.route),
          ),
      ],
    );
  }
}

class LocationKpiCard extends StatelessWidget {
  final LocationMetric metric;

  const LocationKpiCard({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    return MetricActionCard(
      item: MetricActionItem(
        icon: metric.icon,
        value: metric.value,
        title: metric.label,
        subtitle: metric.delta,
        accentColor: locationToneColor(context, metric.tone),
        onTap: () => Navigator.pushNamed(context, metric.route),
      ),
    );
  }
}

class LocationTaskRail extends StatelessWidget {
  final List<LocationTask> tasks;

  const LocationTaskRail({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return QuickActionRail(
      items: [
        for (final task in tasks)
          QuickActionItem(
            icon: task.icon,
            title: task.title,
            description: task.subtitle,
            tone: cineToneFromColor(
              context,
              locationToneColor(context, task.tone),
            ),
            onTap: () => Navigator.pushNamed(context, task.route),
          ),
      ],
    );
  }
}

class LocationMediaFrame extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String badge;
  final IconData fallbackIcon;
  final double aspectRatio;
  final bool compact;

  const LocationMediaFrame({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.badge,
    required this.fallbackIcon,
    this.aspectRatio = 16 / 10,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = compact ? 16.0 : 22.0;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : _LocationMediaFallback(
                      icon: fallbackIcon,
                    ),
              errorBuilder: (_, __, ___) => _LocationMediaFallback(
                icon: fallbackIcon,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(radius),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.62),
                  ],
                ),
              ),
            ),
            Positioned(
              left: compact ? 8 : 12,
              right: compact ? 8 : 12,
              bottom: compact ? 8 : 12,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.statusText.copyWith(
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.black87, blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StatusChip(label: badge, color: colors.goldMid),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationMediaFallback extends StatelessWidget {
  final IconData icon;

  const _LocationMediaFallback({required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(gradient: colors.cardGradient),
      child: Center(child: Icon(icon, color: colors.goldDark, size: 28)),
    );
  }
}

class LocationInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const LocationInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(icon, color: colors.goldDark, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
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

class LocationTaskTile extends StatelessWidget {
  final LocationTask task;
  final VoidCallback onComplete;
  final VoidCallback onSnooze;

  const LocationTaskTile({
    super.key,
    required this.task,
    required this.onComplete,
    required this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: QuickActionCard(
        item: QuickActionItem(
          icon: task.icon,
          title: task.title,
          description: task.subtitle,
          tone: cineToneFromColor(
            context,
            locationToneColor(context, task.tone),
          ),
          onTap: () => Navigator.pushNamed(context, task.route),
        ),
      ),
    );
  }
}

class LocationBookingStatusChip extends StatelessWidget {
  final LocationBookingStatus status;

  const LocationBookingStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      label: LocationOwnerDemoData.bookingStatusLabel(status),
      color: locationStatusColor(context, status),
    );
  }
}

class LocationMiniBarChart extends StatelessWidget {
  final List<double> values;
  final List<Color> colors;
  final double height;

  const LocationMiniBarChart({
    super.key,
    required this.values,
    required this.colors,
    this.height = 112,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final maxValue = values.fold<double>(1, (max, item) {
      return item > max ? item : max;
    });
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == values.length - 1 ? 0 : 7),
                child: Tooltip(
                  message: '${values[i].toStringAsFixed(0)} activity points',
                  child: Container(
                    height: 24 + ((height - 28) * (values[i] / maxValue)),
                    decoration: BoxDecoration(
                      color: colors[i % colors.length].withValues(
                        alpha: appColors.isLight ? 0.78 : 0.72,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            colors[i % colors.length].withValues(alpha: 0.38),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
