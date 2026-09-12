import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../models/actor_talent_models.dart';

Color actorToneColor(BuildContext context, ActorTone tone) {
  final colors = context.appColors;
  return switch (tone) {
    ActorTone.gold => colors.goldMid,
    ActorTone.blue => colors.infoBlue,
    ActorTone.green => colors.success,
    ActorTone.purple => colors.infoPurple,
    ActorTone.danger => colors.danger,
    ActorTone.neutral => colors.textSecondary,
  };
}

Color actorStatusColor(BuildContext context, ActorBookingStatus status) {
  final colors = context.appColors;
  return switch (status) {
    ActorBookingStatus.secured ||
    ActorBookingStatus.closed ||
    ActorBookingStatus.termsApproved =>
      colors.success,
    ActorBookingStatus.paymentPending ||
    ActorBookingStatus.underVerification ||
    ActorBookingStatus.contractPending =>
      colors.goldMid,
    ActorBookingStatus.disputed => colors.danger,
    _ => colors.infoBlue,
  };
}

String actorStatusLabel(ActorBookingStatus status) {
  return switch (status) {
    ActorBookingStatus.sent => 'Sent',
    ActorBookingStatus.underNegotiation => 'Negotiating',
    ActorBookingStatus.termsApproved => 'Terms approved',
    ActorBookingStatus.contractPending => 'Contract pending',
    ActorBookingStatus.paymentPending => 'Payment pending',
    ActorBookingStatus.underVerification => 'Under verification',
    ActorBookingStatus.secured => 'Secured',
    ActorBookingStatus.closed => 'Closed',
    ActorBookingStatus.disputed => 'Disputed',
  };
}

void actorSnack(BuildContext context, String message) {
  showCoreSnack(context, message);
}

Future<void> showActorSheet(
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
                                letterSpacing: 1.6,
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

class ActorSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final String? actionText;
  final VoidCallback? onActionTap;
  final bool selected;
  final ActorTone tone;

  const ActorSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.actionText,
    this.onActionTap,
    this.selected = false,
    this.tone = ActorTone.gold,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = actorToneColor(context, tone);
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

/// A single collapsible profile section — lets a long form (identity, bio,
/// physical details, social links...) be edited one focused group at a
/// time instead of scrolling through every field at once.
class ActorCollapsibleSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final Widget child;
  final bool initiallyExpanded;
  final ActorTone tone;

  const ActorCollapsibleSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.initiallyExpanded = false,
    this.tone = ActorTone.gold,
  });

  @override
  State<ActorCollapsibleSection> createState() =>
      _ActorCollapsibleSectionState();
}

class _ActorCollapsibleSectionState extends State<ActorCollapsibleSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = actorToneColor(context, widget.tone);
    return GlassSectionCard(
      radius: 18,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Row(
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
                  Icon(widget.icon, color: accent, size: 19),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardTitle.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colors.iconMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 14, 16),
              child: widget.child,
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 160),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}

class ActorResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minWidth;
  final double gap;

  const ActorResponsiveGrid({
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

class ActorTwoColumn extends StatelessWidget {
  final Widget left;
  final Widget right;

  const ActorTwoColumn({
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

class ActorKpiRail extends StatelessWidget {
  final List<ActorMetric> metrics;

  const ActorKpiRail({super.key, required this.metrics});

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
            accentColor: actorToneColor(context, metric.tone),
            onTap: () => Navigator.pushNamed(context, metric.route),
          ),
      ],
    );
  }
}

class ActorKpiCard extends StatelessWidget {
  final ActorMetric metric;

  const ActorKpiCard({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    return MetricActionCard(
      item: MetricActionItem(
        icon: metric.icon,
        value: metric.value,
        title: metric.label,
        subtitle: metric.delta,
        accentColor: actorToneColor(context, metric.tone),
        onTap: () => Navigator.pushNamed(context, metric.route),
      ),
    );
  }
}

class ActorTaskRail extends StatelessWidget {
  final List<ActorTask> tasks;

  const ActorTaskRail({super.key, required this.tasks});

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
                cineToneFromColor(context, actorToneColor(context, task.tone)),
            onTap: () => Navigator.pushNamed(context, task.route),
          ),
      ],
    );
  }
}

class ActorProgressMeter extends StatelessWidget {
  final int value;

  const ActorProgressMeter({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final healthy = value >= 80;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Profile completeness',
                style: AppTextStyles.cardLabel.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            Text(
              '$value%',
              style: AppTextStyles.smallMetricNumber.copyWith(
                color: healthy ? colors.success : colors.goldMid,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 8,
            backgroundColor: colors.border,
            color: healthy ? colors.success : colors.goldMid,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          healthy
              ? 'Your profile is boosted in director search.'
              : 'Profiles under 80% receive fewer matches.',
          style: AppTextStyles.smallMeta.copyWith(
            color: healthy ? colors.success : colors.goldMid,
          ),
        ),
      ],
    );
  }
}

class ActorMediaFrame extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String badge;
  final IconData fallbackIcon;
  final double aspectRatio;
  final bool compact;

  const ActorMediaFrame({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.badge,
    required this.fallbackIcon,
    this.aspectRatio = 16 / 9,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = compact ? 12.0 : 16.0;
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
                      : _MediaFallback(icon: fallbackIcon),
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
                    Colors.black.withValues(alpha: 0.58),
                  ],
                ),
              ),
            ),
            Positioned(
              left: compact ? 8 : 12,
              right: compact ? 8 : 12,
              bottom: compact ? 8 : 12,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 110) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: StatusChip(label: badge, color: colors.goldMid),
                      ),
                    );
                  }
                  return Row(
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
                            child:
                                StatusChip(label: badge, color: colors.goldMid),
                          ),
                        ),
                      ),
                    ],
                  );
                },
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
      child: Center(
        child: Icon(icon, color: colors.goldDark, size: 28),
      ),
    );
  }
}

class ActorTaskRow extends StatelessWidget {
  final ActorTask task;
  final VoidCallback onComplete;
  final VoidCallback onSnooze;

  const ActorTaskRow({
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
          tone: cineToneFromColor(context, actorToneColor(context, task.tone)),
          onTap: () => Navigator.pushNamed(context, task.route),
        ),
      ),
    );
  }
}

class ActorOpportunityCard extends StatelessWidget {
  final ActorOpportunity opportunity;
  final ActorBookingStatus status;
  final VoidCallback onOpen;
  final VoidCallback onHold;

  const ActorOpportunityCard({
    super.key,
    required this.opportunity,
    required this.status,
    required this.onOpen,
    required this.onHold,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ActorMediaFrame(
            imageUrl: opportunity.imageUrl,
            title: opportunity.projectTitle,
            badge: opportunity.expiry,
            fallbackIcon: Icons.movie_filter_outlined,
            aspectRatio: 16 / 9,
            compact: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  opportunity.role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusChip(
                label: actorStatusLabel(status),
                color: actorStatusColor(context, status),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${opportunity.producer} - ${opportunity.city} - ${opportunity.dates}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(label: opportunity.fee, color: colors.goldMid),
              StatusChip(
                label:
                    '${opportunity.directorRating.toStringAsFixed(1)} rating',
                color: colors.infoBlue,
              ),
              StatusChip(
                  label: _typeLabel(opportunity.type),
                  color: colors.infoPurple),
            ],
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 132,
                child: CoreSecondaryButton(
                  icon: Icons.calendar_today_outlined,
                  label: 'Hold dates',
                  compact: true,
                  onTap: onHold,
                ),
              ),
              SizedBox(
                width: 132,
                child: CorePrimaryButton(
                  icon: Icons.rate_review_outlined,
                  label: 'Review offer',
                  compact: true,
                  onTap: onOpen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _typeLabel(ActorOpportunityType type) {
    return switch (type) {
      ActorOpportunityType.directOffer => 'DIRECT',
      ActorOpportunityType.auditionInvite => 'AUDITION',
      ActorOpportunityType.castingCall => 'CASTING',
    };
  }
}

class ActorSearchFilterBar extends StatelessWidget {
  final String query;
  final ValueChanged<String> onQueryChanged;
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const ActorSearchFilterBar({
    super.key,
    required this.query,
    required this.onQueryChanged,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          TextField(
            onChanged: onQueryChanged,
            style: AppTextStyles.body.copyWith(color: colors.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search offers, roles, producers...',
              hintStyle: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
              ),
              prefixIcon:
                  Icon(Icons.search_rounded, color: colors.goldDark, size: 20),
              filled: true,
              fillColor: colors.surface.withValues(alpha: 0.36),
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
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onFilterChanged(filter),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Center(
                          child: StatusChip(
                            label: filter,
                            color: selectedFilter == filter
                                ? colors.goldMid
                                : colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ActorInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ActorInfoRow({
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

class ActorTimeline extends StatelessWidget {
  final List<(String, ActorBookingStatus)> items;

  const ActorTimeline({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: actorStatusColor(context, item.$2)
                        .withValues(alpha: colors.isLight ? 0.14 : 0.18),
                    border: Border.all(
                      color: actorStatusColor(context, item.$2)
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: actorStatusColor(context, item.$2),
                    size: 15,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: AppTextStyles.cardLabel.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        actorStatusLabel(item.$2),
                        style: AppTextStyles.smallMeta.copyWith(
                          color: actorStatusColor(context, item.$2),
                        ),
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
}
