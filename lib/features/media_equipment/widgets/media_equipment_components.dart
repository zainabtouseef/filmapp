import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/formatters/cine_format.dart';
import '../../../shared/widgets/status_chip.dart';
import '../models/media_equipment_models.dart';

Color mediaToneColor(BuildContext context, MediaTone tone) {
  final colors = context.appColors;
  return switch (tone) {
    MediaTone.gold => colors.goldMid,
    MediaTone.blue => colors.infoBlue,
    MediaTone.green => colors.success,
    MediaTone.purple => colors.infoPurple,
    MediaTone.danger => colors.danger,
    MediaTone.neutral => colors.textSecondary,
  };
}

Color mediaStatusColor(BuildContext context, MediaBookingStatus status) {
  final colors = context.appColors;
  return switch (status) {
    MediaBookingStatus.secured ||
    MediaBookingStatus.inProgress ||
    MediaBookingStatus.returned ||
    MediaBookingStatus.closed =>
      colors.success,
    MediaBookingStatus.depositPending ||
    MediaBookingStatus.contractPending ||
    MediaBookingStatus.requestReceived =>
      colors.goldMid,
    MediaBookingStatus.rejected => colors.danger,
    MediaBookingStatus.disputed => colors.danger,
    MediaBookingStatus.underNegotiation => colors.infoBlue,
  };
}

Color mediaAvailabilityColor(
  BuildContext context,
  MediaAvailabilityStatus status,
) {
  final colors = context.appColors;
  return switch (status) {
    MediaAvailabilityStatus.available => colors.success,
    MediaAvailabilityStatus.hold => colors.goldMid,
    MediaAvailabilityStatus.booked => colors.infoBlue,
    MediaAvailabilityStatus.maintenance => colors.danger,
    MediaAvailabilityStatus.transit => colors.textSecondary,
  };
}

IconData mediaAvailabilityIcon(MediaAvailabilityStatus status) {
  return switch (status) {
    MediaAvailabilityStatus.available => Icons.check_circle_outline_rounded,
    MediaAvailabilityStatus.hold => Icons.hourglass_top_rounded,
    MediaAvailabilityStatus.booked => Icons.event_available_outlined,
    MediaAvailabilityStatus.maintenance => Icons.handyman_outlined,
    MediaAvailabilityStatus.transit => Icons.local_shipping_outlined,
  };
}

String mediaAvailabilityLabel(MediaAvailabilityStatus status) {
  return switch (status) {
    MediaAvailabilityStatus.available => 'Available',
    MediaAvailabilityStatus.hold => 'Hold',
    MediaAvailabilityStatus.booked => 'Booked',
    MediaAvailabilityStatus.maintenance => 'Maintenance',
    MediaAvailabilityStatus.transit => 'In transit',
  };
}

String mediaBookingStatusLabel(MediaBookingStatus status) {
  return switch (status) {
    MediaBookingStatus.requestReceived => 'REQUEST RECEIVED',
    MediaBookingStatus.underNegotiation => 'UNDER NEGOTIATION',
    MediaBookingStatus.contractPending => 'CONTRACT PENDING',
    MediaBookingStatus.depositPending => 'DEPOSIT PENDING',
    MediaBookingStatus.secured => 'SECURED BOOKING',
    MediaBookingStatus.inProgress => 'IN PROGRESS',
    MediaBookingStatus.returned => 'RETURNED',
    MediaBookingStatus.closed => 'CLOSED',
    MediaBookingStatus.rejected => 'REJECTED',
    MediaBookingStatus.disputed => 'DISPUTED',
  };
}

String mediaMoney(int amount) {
  return CineFormat.currency(amount);
}

void mediaSnack(BuildContext context, String message) {
  showCoreSnack(context, message);
}

Future<void> showMediaSheet(
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

class MediaSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final String? actionText;
  final VoidCallback? onActionTap;
  final bool selected;

  const MediaSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.actionText,
    this.onActionTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: title,
      leading: IconBadge(
        icon: icon,
        tone: CineTone.premium,
        compact: true,
      ),
      action: actionText == null
          ? null
          : TextButton(onPressed: onActionTap, child: Text(actionText!)),
      treatment: selected ? SectionTreatment.elevated : SectionTreatment.open,
      child: child,
    );
  }
}

class MediaResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minWidth;
  final double gap;

  const MediaResponsiveGrid({
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

class MediaTwoColumn extends StatelessWidget {
  final Widget left;
  final Widget right;

  const MediaTwoColumn({
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
            children: [left, const SizedBox(height: 12), right],
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

class MediaKpiRail extends StatelessWidget {
  final List<MediaMetric> metrics;

  const MediaKpiRail({super.key, required this.metrics});

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
            accentColor: mediaToneColor(context, metric.tone),
            onTap: () => Navigator.pushNamed(context, metric.route),
          ),
      ],
    );
  }
}

class MediaKpiCard extends StatelessWidget {
  final MediaMetric metric;

  const MediaKpiCard({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    return MetricActionCard(
      item: MetricActionItem(
        icon: metric.icon,
        value: metric.value,
        title: metric.label,
        subtitle: metric.delta,
        accentColor: mediaToneColor(context, metric.tone),
        onTap: () => Navigator.pushNamed(context, metric.route),
      ),
    );
  }
}

class MediaTaskRail extends StatelessWidget {
  final List<MediaTask> tasks;

  const MediaTaskRail({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return QuickActionRail(
      items: [
        for (final task in tasks)
          QuickActionItem(
            icon: task.icon,
            title: task.title,
            description: task.subtitle,
            tone:
                cineToneFromColor(context, mediaToneColor(context, task.tone)),
            onTap: () => Navigator.pushNamed(context, task.route),
          ),
      ],
    );
  }
}

class MediaFrame extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String badge;
  final IconData fallbackIcon;
  final double aspectRatio;
  final bool compact;

  const MediaFrame({
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
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _MediaFallback(icon: fallbackIcon),
              errorBuilder: (_, __, ___) => _MediaFallback(icon: fallbackIcon),
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

class _MediaFallback extends StatelessWidget {
  final IconData icon;

  const _MediaFallback({required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(gradient: colors.cardGradient),
      child: Center(child: Icon(icon, color: colors.goldDark, size: 28)),
    );
  }
}

class MediaInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const MediaInfoRow({
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

class MediaTaskTile extends StatelessWidget {
  final MediaTask task;
  final VoidCallback onComplete;
  final VoidCallback onSnooze;

  const MediaTaskTile({
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
          tone: cineToneFromColor(context, mediaToneColor(context, task.tone)),
          onTap: () => Navigator.pushNamed(context, task.route),
        ),
      ),
    );
  }
}

class MediaBookingStatusChip extends StatelessWidget {
  final MediaBookingStatus status;

  const MediaBookingStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      label: mediaBookingStatusLabel(status),
      color: mediaStatusColor(context, status),
    );
  }
}

class MediaMiniBarChart extends StatelessWidget {
  final List<double> values;
  final List<Color> colors;
  final double height;

  const MediaMiniBarChart({
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
                  message: '${values[i].toStringAsFixed(0)} points',
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
