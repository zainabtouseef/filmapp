import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../models/brand_sponsor_models.dart';
import 'brand_sponsor_live.dart';

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
  double maxWidth = 620,
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
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: GlassSectionCard(
            radius: 20,
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

class BrandSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool selected;
  final String? actionText;
  final VoidCallback? onActionTap;
  final BrandTone tone;

  const BrandSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.selected = false,
    this.actionText,
    this.onActionTap,
    this.tone = BrandTone.gold,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = brandToneColor(context, tone);
    return GlassSectionCard(
      radius: 18,
      padding: EdgeInsets.zero,
      accentEdge: false,
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
    return QuickActionRail(
      items: [
        for (final task in tasks)
          QuickActionItem(
            icon: task.icon,
            title: task.title,
            description: task.subtitle,
            tone:
                cineToneFromColor(context, brandToneColor(context, task.tone)),
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
    final image = imageUrl.isEmpty
        ? _BrandFallback(icon: fallbackIcon)
        : imageUrl.startsWith('assets/')
            ? Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _BrandFallback(icon: fallbackIcon),
              )
            : Image.network(
                imageUrl,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
                    wasSynchronouslyLoaded || frame != null
                        ? child
                        : _BrandFallback(icon: fallbackIcon),
                errorBuilder: (_, __, ___) =>
                    _BrandFallback(icon: fallbackIcon),
              );
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
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
              top: compact ? 8 : 12,
              left: compact ? 8 : 12,
              child: SizedBox(
                width: compact ? 142 : 220,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: StatusChip(label: badge, color: colors.goldMid),
                  ),
                ),
              ),
            ),
            Positioned(
              left: compact ? 8 : 12,
              right: compact ? 8 : 12,
              bottom: compact ? 8 : 12,
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
    final accent = colors.goldDark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(colors.surface, accent, colors.isLight ? 0.10 : 0.20)!,
            colors.softSurface,
            Color.lerp(colors.surface, accent, colors.isLight ? 0.24 : 0.34)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -34,
            child: Icon(
              icon,
              size: 190,
              color: accent.withValues(alpha: 0.10),
            ),
          ),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.elevatedSurface.withValues(alpha: 0.76),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.32)),
              ),
              child: Icon(icon, color: accent, size: 32),
            ),
          ),
        ],
      ),
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
      child: QuickActionCard(
        item: QuickActionItem(
          icon: task.icon,
          title: task.title,
          description: task.subtitle,
          tone: cineToneFromColor(context, brandToneColor(context, task.tone)),
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
      label: brandStatusLabel(status),
      color: brandStatusColor(context, status),
    );
  }
}

class BrandLiveStatusChip extends StatelessWidget {
  final String status;

  const BrandLiveStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final normalized = status.toLowerCase();
    final color = switch (normalized) {
      'published' ||
      'accepted' ||
      'approved' ||
      'verified' ||
      'completed' =>
        colors.success,
      'rejected' || 'cancelled' || 'closed' => colors.danger,
      'shortlisted' ||
      'negotiating' ||
      'revision_requested' ||
      'submitted' =>
        colors.infoBlue,
      'paused' || 'reviewing' => colors.infoPurple,
      _ => colors.goldMid,
    };
    return StatusChip(
      label: readableBrandStatus(status).toUpperCase(),
      color: color,
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
