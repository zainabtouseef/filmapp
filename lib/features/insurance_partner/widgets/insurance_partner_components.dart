import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/insurance_partner_demo_data.dart';
import '../models/insurance_partner_models.dart';

Color insuranceToneColor(BuildContext context, InsuranceTone tone) {
  final colors = context.appColors;
  return switch (tone) {
    InsuranceTone.gold => colors.goldMid,
    InsuranceTone.blue => colors.infoBlue,
    InsuranceTone.green => colors.success,
    InsuranceTone.purple => colors.infoPurple,
    InsuranceTone.danger => colors.danger,
    InsuranceTone.neutral => colors.textSecondary,
  };
}

Color insuranceStatusColor(BuildContext context, InsuranceStatus status) {
  final colors = context.appColors;
  return switch (status) {
    InsuranceStatus.active ||
    InsuranceStatus.verified ||
    InsuranceStatus.approved ||
    InsuranceStatus.completed ||
    InsuranceStatus.resolved =>
      colors.success,
    InsuranceStatus.highRisk ||
    InsuranceStatus.safetyDue ||
    InsuranceStatus.evidenceNeeded =>
      colors.goldMid,
    InsuranceStatus.openClaim ||
    InsuranceStatus.escalated ||
    InsuranceStatus.rejected =>
      colors.danger,
    InsuranceStatus.investigating || InsuranceStatus.draft => colors.infoPurple,
    _ => colors.infoBlue,
  };
}

void insuranceSnack(BuildContext context, String message) {
  showCoreSnack(context, message);
}

Future<void> showInsuranceSheet(
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

class InsuranceSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool selected;
  final String? actionText;
  final VoidCallback? onActionTap;

  const InsuranceSectionCard({
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

class InsuranceResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minWidth;
  final double gap;

  const InsuranceResponsiveGrid({
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

class InsuranceTwoColumn extends StatelessWidget {
  final Widget left;
  final Widget right;

  const InsuranceTwoColumn(
      {super.key, required this.left, required this.right});

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

class InsuranceKpiRail extends StatelessWidget {
  final List<InsuranceMetric> metrics;

  const InsuranceKpiRail({super.key, required this.metrics});

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
            accentColor: insuranceToneColor(context, metric.tone),
            onTap: () => Navigator.pushNamed(context, metric.route),
          ),
      ],
    );
  }
}

class InsuranceKpiCard extends StatelessWidget {
  final InsuranceMetric metric;

  const InsuranceKpiCard({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    return MetricActionCard(
      item: MetricActionItem(
        icon: metric.icon,
        value: metric.value,
        title: metric.label,
        subtitle: metric.delta,
        accentColor: insuranceToneColor(context, metric.tone),
        onTap: () => Navigator.pushNamed(context, metric.route),
      ),
    );
  }
}

class InsuranceMediaFrame extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String badge;
  final IconData fallbackIcon;
  final double aspectRatio;
  final bool compact;

  const InsuranceMediaFrame({
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
                  : _InsuranceFallback(icon: fallbackIcon),
              errorBuilder: (_, __, ___) =>
                  _InsuranceFallback(icon: fallbackIcon),
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

class _InsuranceFallback extends StatelessWidget {
  final IconData icon;

  const _InsuranceFallback({required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(gradient: colors.cardGradient),
      child: Center(child: Icon(icon, color: colors.goldDark, size: 28)),
    );
  }
}

class InsuranceTaskRail extends StatelessWidget {
  final List<InsuranceTask> tasks;

  const InsuranceTaskRail({super.key, required this.tasks});

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
            accentColor: insuranceToneColor(context, task.tone),
            onTap: () => Navigator.pushNamed(context, task.route),
          ),
      ],
    );
  }
}

class InsuranceInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InsuranceInfoRow({
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

class InsuranceTaskTile extends StatelessWidget {
  final InsuranceTask task;
  final VoidCallback onComplete;
  final VoidCallback onSnooze;

  const InsuranceTaskTile({
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
          accentColor: insuranceToneColor(context, task.tone),
          onTap: () => Navigator.pushNamed(context, task.route),
        ),
      ),
    );
  }
}

class InsuranceStatusChip extends StatelessWidget {
  final InsuranceStatus status;

  const InsuranceStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      label: InsurancePartnerDemoData.statusLabel(status),
      color: insuranceStatusColor(context, status),
    );
  }
}

class InsuranceSearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hintText;

  const InsuranceSearchField({
    super.key,
    required this.onChanged,
    this.hintText = 'Search policies, claims, incidents...',
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

class InsuranceProgressMeter extends StatelessWidget {
  final String label;
  final int percent;

  const InsuranceProgressMeter({
    super.key,
    required this.label,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final value = (percent / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style:
                    AppTextStyles.cardLabel.copyWith(color: colors.textPrimary),
              ),
            ),
            Text(
              '$percent%',
              style: AppTextStyles.statusText.copyWith(color: colors.goldDark),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: value,
            backgroundColor: colors.border,
            valueColor: AlwaysStoppedAnimation<Color>(colors.goldMid),
          ),
        ),
      ],
    );
  }
}

class InsuranceChecklistTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool checked;
  final bool mandatory;
  final VoidCallback onTap;

  const InsuranceChecklistTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.checked,
    required this.mandatory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: GlassSectionCard(
        radius: 16,
        padding: const EdgeInsets.all(11),
        selected: checked,
        child: Row(
          children: [
            Icon(
              checked
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: checked ? colors.success : colors.iconMuted,
              size: 21,
            ),
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
            const SizedBox(width: 8),
            StatusChip(
              label: mandatory ? 'Required' : 'Optional',
              color: mandatory ? colors.goldMid : colors.infoBlue,
            ),
          ],
        ),
      ),
    );
  }
}
