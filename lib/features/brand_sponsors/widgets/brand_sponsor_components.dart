import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/brand_sponsor_demo_data.dart';
import '../models/brand_sponsor_models.dart';

Color brandToneColor(BuildContext context, BrandTone tone) {
  final colors = context.appColors;
  return switch (tone) {
    BrandTone.gold => colors.goldMid,
    BrandTone.blue => colors.infoBlue,
    BrandTone.green => colors.success,
    BrandTone.purple => colors.infoPurple,
    BrandTone.danger => colors.danger,
    BrandTone.neutral => colors.textSecondary,
  };
}

Color brandStatusColor(BuildContext context, BrandStatus status) {
  final colors = context.appColors;
  return switch (status) {
    BrandStatus.active ||
    BrandStatus.approved ||
    BrandStatus.delivered ||
    BrandStatus.verified ||
    BrandStatus.closed =>
      colors.success,
    BrandStatus.draft ||
    BrandStatus.pending ||
    BrandStatus.paymentPending =>
      colors.goldMid,
    BrandStatus.disputed || BrandStatus.revision => colors.infoPurple,
    _ => colors.infoBlue,
  };
}

void brandSnack(BuildContext context, String message) {
  showCoreSnack(context, message);
}

Future<void> showBrandSheet(
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
      child: GlassSectionCard(
        radius: 24,
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
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
  );
}

class BrandSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool selected;
  final String? actionText;
  final VoidCallback? onActionTap;

  const BrandSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.selected = false,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      padding: const EdgeInsets.all(14),
      selected: selected,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.goldDark, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionHeading.copyWith(
                    color: colors.textPrimary,
                    fontSize: 15.5,
                    letterSpacing: 1.45,
                  ),
                ),
              ),
              if (actionText != null)
                TextButton(onPressed: onActionTap, child: Text(actionText!)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class BrandResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minWidth;
  final double gap;

  const BrandResponsiveGrid({
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

class BrandTwoColumn extends StatelessWidget {
  final Widget left;
  final Widget right;

  const BrandTwoColumn({super.key, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return Column(children: [left, const SizedBox(height: 12), right]);
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

class BrandKpiRail extends StatelessWidget {
  final List<BrandMetric> metrics;

  const BrandKpiRail({super.key, required this.metrics});

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
            accentColor: brandToneColor(context, metric.tone),
            onTap: () => Navigator.pushNamed(context, metric.route),
          ),
      ],
    );
  }
}

class BrandKpiCard extends StatelessWidget {
  final BrandMetric metric;

  const BrandKpiCard({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    return MetricActionCard(
      item: MetricActionItem(
        icon: metric.icon,
        value: metric.value,
        title: metric.label,
        subtitle: metric.delta,
        accentColor: brandToneColor(context, metric.tone),
        onTap: () => Navigator.pushNamed(context, metric.route),
      ),
    );
  }
}

class BrandTaskRail extends StatelessWidget {
  final List<BrandTask> tasks;

  const BrandTaskRail({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return MetricActionRail(
      items: [
        for (final task in tasks)
          MetricActionItem(
            icon: task.icon,
            value: 'Open',
            title: task.title,
            subtitle: task.subtitle,
            accentColor: brandToneColor(context, task.tone),
            onTap: () => Navigator.pushNamed(context, task.route),
          ),
      ],
    );
  }
}

class BrandMediaFrame extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String badge;
  final IconData fallbackIcon;
  final double aspectRatio;
  final bool compact;

  const BrandMediaFrame({
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
                  progress == null ? child : _BrandFallback(icon: fallbackIcon),
              errorBuilder: (_, __, ___) => _BrandFallback(icon: fallbackIcon),
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

class _BrandFallback extends StatelessWidget {
  final IconData icon;

  const _BrandFallback({required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(gradient: colors.cardGradient),
      child: Center(child: Icon(icon, color: colors.goldDark, size: 28)),
    );
  }
}

class BrandInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const BrandInfoRow({
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
              style:
                  AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
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

class BrandTaskTile extends StatelessWidget {
  final BrandTask task;
  final VoidCallback onComplete;
  final VoidCallback onSnooze;

  const BrandTaskTile({
    super.key,
    required this.task,
    required this.onComplete,
    required this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: MetricActionCard(
        item: MetricActionItem(
          icon: task.icon,
          value: 'Open',
          title: task.title,
          subtitle: task.subtitle,
          accentColor: brandToneColor(context, task.tone),
          onTap: () => Navigator.pushNamed(context, task.route),
        ),
      ),
    );
  }
}

class BrandStatusChip extends StatelessWidget {
  final BrandStatus status;

  const BrandStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      label: BrandSponsorDemoData.statusLabel(status),
      color: brandStatusColor(context, status),
    );
  }
}

class BrandSearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hintText;

  const BrandSearchField({
    super.key,
    required this.onChanged,
    this.hintText = 'Search campaigns, applications, records...',
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TextField(
      onChanged: onChanged,
      style: AppTextStyles.body.copyWith(color: colors.textPrimary),
      decoration: InputDecoration(
        isDense: true,
        hintText: hintText,
        hintStyle: AppTextStyles.smallMeta.copyWith(
          color: colors.textSecondary,
        ),
        prefixIcon:
            Icon(Icons.search_rounded, color: colors.goldDark, size: 20),
        filled: true,
        fillColor:
            colors.surface.withValues(alpha: colors.isLight ? 0.74 : 0.36),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.goldMid),
        ),
      ),
    );
  }
}

class BrandMiniBarChart extends StatelessWidget {
  final List<double> values;
  final List<Color> colors;
  final double height;

  const BrandMiniBarChart({
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
