import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../models/role_portal_models.dart';

class PortalPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final String? actionText;
  final VoidCallback? onActionTap;

  const PortalPanel({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
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
      treatment: SectionTreatment.open,
      child: child,
    );
  }
}

class PortalResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minWidth;
  final double gap;

  const PortalResponsiveGrid({
    super.key,
    required this.children,
    this.minWidth = 260,
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

class PortalTwoColumn extends StatelessWidget {
  final Widget left;
  final Widget right;

  const PortalTwoColumn({
    super.key,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return Column(
            children: [left, const SizedBox(height: 12), right],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class PortalMetricCard extends StatelessWidget {
  final PortalMetric metric;

  const PortalMetricCard({
    super.key,
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    final color = portalToneColor(context, metric.tone);
    return MetricActionCard(
      item: MetricActionItem(
        icon: metric.icon,
        value: metric.value,
        title: metric.label,
        subtitle: metric.delta,
        accentColor: color,
      ),
    );
  }
}

class PortalRecordCard extends StatelessWidget {
  final PortalRecord record;
  final bool shortlisted;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final VoidCallback onShortlist;

  const PortalRecordCard({
    super.key,
    required this.record,
    required this.shortlisted,
    required this.onPrimary,
    required this.onSecondary,
    required this.onShortlist,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      selected: shortlisted,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(record.icon, color: colors.goldDark, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  record.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: shortlisted ? 'Remove shortlist' : 'Add shortlist',
                visualDensity: VisualDensity.compact,
                onPressed: onShortlist,
                icon: Icon(
                  shortlisted ? Icons.favorite : Icons.favorite_border,
                  color: shortlisted ? colors.infoPurple : colors.iconMuted,
                  size: 19,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            record.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              lifecycleChip(context, label: record.status),
              StatusChip(label: record.amount, color: colors.goldMid),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Question',
                  onTap: onSecondary,
                  compact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.check_rounded,
                  label: 'Action',
                  onTap: onPrimary,
                  compact: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PortalSearchFilterBar extends StatelessWidget {
  final String query;
  final ValueChanged<String> onQueryChanged;
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const PortalSearchFilterBar({
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
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            onChanged: onQueryChanged,
            style: AppTextStyles.body.copyWith(color: colors.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search records, projects, people...',
              hintStyle: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
              ),
              prefixIcon:
                  Icon(Icons.search_rounded, color: colors.goldDark, size: 20),
              filled: true,
              fillColor: colors.surface.withValues(alpha: 0.28),
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
                      onTap: () => onFilterChanged(filter),
                      child: StatusChip(
                        label: filter,
                        color: selectedFilter == filter
                            ? colors.goldMid
                            : colors.textSecondary,
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

class PortalLifecycleTimeline extends StatelessWidget {
  final List<PortalWorkflowItem> items;
  final int activeIndex;

  const PortalLifecycleTimeline({
    super.key,
    required this.items,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        for (var index = 0; index < items.length; index++)
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
                    color: index <= activeIndex
                        ? colors.goldMid
                        : colors.surface.withValues(alpha: 0.36),
                    border: Border.all(color: colors.border),
                  ),
                  child: Icon(
                    index <= activeIndex ? Icons.check_rounded : Icons.circle,
                    color:
                        index <= activeIndex ? colors.onGold : colors.iconMuted,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items[index].title,
                        style: AppTextStyles.cardLabel.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${items[index].owner} · ${items[index].timestamp}',
                        style: AppTextStyles.smallMeta.copyWith(
                          color: colors.textSecondary,
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

Color portalToneColor(BuildContext context, PortalMetricTone tone) {
  final colors = context.appColors;
  return switch (tone) {
    PortalMetricTone.blue => colors.infoBlue,
    PortalMetricTone.purple => colors.infoPurple,
    PortalMetricTone.gold => colors.goldMid,
    PortalMetricTone.green => colors.success,
    PortalMetricTone.danger => colors.danger,
    PortalMetricTone.neutral => colors.textSecondary,
  };
}

Widget lifecycleChip(BuildContext context, {required String label}) {
  final colors = context.appColors;
  final color = label.contains('SECURED') || label.contains('CLOSED')
      ? colors.success
      : label.contains('DISPUTED') || label.contains('CANCELLED')
          ? colors.infoPurple
          : label.contains('PAYMENT') || label.contains('CONTRACT')
              ? colors.goldMid
              : colors.infoBlue;
  return StatusChip(label: label, color: color);
}

String lifecycleLabel(BookingLifecycleStatus status) {
  return switch (status) {
    BookingLifecycleStatus.draft => 'DRAFT',
    BookingLifecycleStatus.sent => 'SENT',
    BookingLifecycleStatus.underNegotiation => 'UNDER NEGOTIATION',
    BookingLifecycleStatus.termsApproved => 'TERMS APPROVED',
    BookingLifecycleStatus.contractPendingSignature =>
      'CONTRACT PENDING SIGNATURE',
    BookingLifecycleStatus.paymentPending => 'PAYMENT PENDING',
    BookingLifecycleStatus.paymentUnderVerification =>
      'PAYMENT UNDER VERIFICATION',
    BookingLifecycleStatus.securedBooking => 'SECURED BOOKING',
    BookingLifecycleStatus.inProgress => 'IN PROGRESS',
    BookingLifecycleStatus.completionReview => 'COMPLETION REVIEW',
    BookingLifecycleStatus.closed => 'CLOSED',
    BookingLifecycleStatus.disputed => 'DISPUTED',
    BookingLifecycleStatus.cancelled => 'CANCELLED',
  };
}
