import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../models/legal_partner_models.dart';

Color legalToneColor(BuildContext context, LegalTone tone) {
  final colors = context.appColors;
  return switch (tone) {
    LegalTone.gold => colors.goldMid,
    LegalTone.blue => colors.infoBlue,
    LegalTone.green => colors.success,
    LegalTone.purple => colors.infoPurple,
    LegalTone.danger => colors.danger,
    LegalTone.neutral => colors.textSecondary,
  };
}

Color legalStatusColor(BuildContext context, LegalStatus status) {
  final colors = context.appColors;
  return switch (status) {
    LegalStatus.approved ||
    LegalStatus.completed ||
    LegalStatus.billed =>
      colors.success,
    LegalStatus.queued ||
    LegalStatus.urgent ||
    LegalStatus.templatePending ||
    LegalStatus.addendumPending =>
      colors.goldMid,
    LegalStatus.escalated ||
    LegalStatus.blocked ||
    LegalStatus.correctionRequested =>
      colors.infoPurple,
    _ => colors.infoBlue,
  };
}

void legalSnack(BuildContext context, String message) {
  showCoreSnack(context, message);
}

String legalStatusLabel(LegalStatus status) {
  return switch (status) {
    LegalStatus.queued => 'Queued',
    LegalStatus.urgent => 'Urgent',
    LegalStatus.reviewing => 'Reviewing',
    LegalStatus.clarification => 'Clarification',
    LegalStatus.correctionRequested => 'Correction Requested',
    LegalStatus.approved => 'Approved',
    LegalStatus.escalated => 'Escalated',
    LegalStatus.templatePending => 'Template Pending',
    LegalStatus.addendumPending => 'Addendum Pending',
    LegalStatus.completed => 'Completed',
    LegalStatus.billed => 'Billed',
    LegalStatus.blocked => 'Blocked',
  };
}

LegalStatus legalStatusFromString(String value) {
  return switch (value.trim().toLowerCase().replaceAll('-', '_')) {
    'queued' || 'requested' || 'pending' => LegalStatus.queued,
    'urgent' || 'high' => LegalStatus.urgent,
    'reviewing' || 'in_review' || 'open' => LegalStatus.reviewing,
    'clarification' || 'needs_clarification' => LegalStatus.clarification,
    'correction_requested' ||
    'changes_requested' =>
      LegalStatus.correctionRequested,
    'approved' => LegalStatus.approved,
    'escalated' => LegalStatus.escalated,
    'template_pending' => LegalStatus.templatePending,
    'addendum_pending' => LegalStatus.addendumPending,
    'completed' || 'closed' => LegalStatus.completed,
    'billed' || 'paid' => LegalStatus.billed,
    'blocked' || 'rejected' => LegalStatus.blocked,
    _ => LegalStatus.queued,
  };
}

Future<void> showLegalSheet(
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

class LegalSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool selected;
  final String? actionText;
  final VoidCallback? onActionTap;

  const LegalSectionCard({
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

class LegalResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minWidth;
  final double gap;

  const LegalResponsiveGrid({
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

class LegalTwoColumn extends StatelessWidget {
  final Widget left;
  final Widget right;

  const LegalTwoColumn({super.key, required this.left, required this.right});

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

class LegalKpiRail extends StatelessWidget {
  final List<LegalMetric> metrics;

  const LegalKpiRail({super.key, required this.metrics});

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
            accentColor: legalToneColor(context, metric.tone),
            onTap: () => Navigator.pushNamed(context, metric.route),
          ),
      ],
    );
  }
}

class LegalKpiCard extends StatelessWidget {
  final LegalMetric metric;

  const LegalKpiCard({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    return MetricActionCard(
      item: MetricActionItem(
        icon: metric.icon,
        value: metric.value,
        title: metric.label,
        subtitle: metric.delta,
        accentColor: legalToneColor(context, metric.tone),
        onTap: () => Navigator.pushNamed(context, metric.route),
      ),
    );
  }
}

class LegalMediaFrame extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String badge;
  final IconData fallbackIcon;
  final double aspectRatio;
  final bool compact;

  const LegalMediaFrame({
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
              webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
              fit: BoxFit.cover,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
                  wasSynchronouslyLoaded || frame != null
                      ? child
                      : _LegalFallback(icon: fallbackIcon),
              errorBuilder: (_, __, ___) => _LegalFallback(icon: fallbackIcon),
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

class _LegalFallback extends StatelessWidget {
  final IconData icon;

  const _LegalFallback({required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(gradient: colors.cardGradient),
      child: Center(child: Icon(icon, color: colors.goldDark, size: 28)),
    );
  }
}

class LegalTaskRail extends StatelessWidget {
  final List<LegalTask> tasks;

  const LegalTaskRail({super.key, required this.tasks});

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
                cineToneFromColor(context, legalToneColor(context, task.tone)),
            onTap: () => Navigator.pushNamed(context, task.route),
          ),
      ],
    );
  }
}

class LegalInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const LegalInfoRow({
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

class LegalTaskTile extends StatelessWidget {
  final LegalTask task;
  final VoidCallback onComplete;
  final VoidCallback onSnooze;

  const LegalTaskTile({
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
          tone: cineToneFromColor(context, legalToneColor(context, task.tone)),
          onTap: () => Navigator.pushNamed(context, task.route),
        ),
      ),
    );
  }
}

class LegalStatusChip extends StatelessWidget {
  final LegalStatus status;

  const LegalStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      label: legalStatusLabel(status),
      color: legalStatusColor(context, status),
    );
  }
}

class LegalSearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hintText;

  const LegalSearchField({
    super.key,
    required this.onChanged,
    this.hintText = 'Search contracts, templates, clients...',
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
