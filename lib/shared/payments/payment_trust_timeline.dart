import 'package:flutter/material.dart';

import '../../core/payments/payment_models.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_chip.dart';

enum PaymentTimelineAudience { producer, provider }

class PaymentTrustTimeline extends StatelessWidget {
  final List<PaymentScheduleDto> schedules;
  final PaymentTimelineAudience audience;
  final int maxSchedules;

  const PaymentTrustTimeline({
    super.key,
    required this.schedules,
    this.audience = PaymentTimelineAudience.producer,
    this.maxSchedules = 4,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (schedules.isEmpty) {
      return GlassContainer(
        borderColor: colors.border,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(audience: audience),
            const SizedBox(height: 12),
            Text(
              'Payment timelines appear after a booking has a live payment schedule.',
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    final visibleSchedules = schedules.take(maxSchedules).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(audience: audience),
        const SizedBox(height: 10),
        for (var index = 0; index < visibleSchedules.length; index++) ...[
          _ScheduleTimelineCard(
            schedule: visibleSchedules[index],
            audience: audience,
          ),
          if (index != visibleSchedules.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final PaymentTimelineAudience audience;

  const _Header({required this.audience});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.timeline_outlined, color: colors.goldDark, size: 22),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment trust timeline',
                style: AppTextStyles.cardTitle.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                audience == PaymentTimelineAudience.producer
                    ? 'Track when funds are locked, payable, approved and released.'
                    : 'See when your booking is locked, shoot payment clears and payout can release.',
                style: AppTextStyles.smallMeta.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScheduleTimelineCard extends StatelessWidget {
  final PaymentScheduleDto schedule;
  final PaymentTimelineAudience audience;

  const _ScheduleTimelineCard({
    required this.schedule,
    required this.audience,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final steps = _stepsFor(schedule, audience);
    return GlassContainer(
      borderColor: colors.border,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Booking ${schedule.bookingId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(
                label: schedule.status.replaceAll('_', ' '),
                color: _statusColor(context, schedule.status),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${schedule.totalLabel} · ${schedule.milestones.length} live milestone${schedule.milestones.length == 1 ? '' : 's'}',
            style: AppTextStyles.caption.copyWith(
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 680;
              if (compact) {
                return Column(
                  children: [
                    for (var index = 0; index < steps.length; index++)
                      _TimelineStepTile(
                        step: steps[index],
                        isLast: index == steps.length - 1,
                        compact: true,
                      ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < steps.length; index++)
                    Expanded(
                      child: _TimelineStepTile(
                        step: steps[index],
                        isLast: index == steps.length - 1,
                        compact: false,
                      ),
                    ),
                ],
              );
            },
          ),
          if (schedule.milestones.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final milestone in schedule.milestones)
                  StatusChip(
                    label:
                        '${milestone.name}: ${milestone.status.replaceAll('_', ' ')}',
                    color: _statusColor(context, milestone.status),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineStepTile extends StatelessWidget {
  final _TrustStep step;
  final bool isLast;
  final bool compact;

  const _TimelineStepTile({
    required this.step,
    required this.isLast,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = _stateColor(context, step.state);
    final icon = switch (step.state) {
      _TrustStepState.complete => Icons.check_circle_rounded,
      _TrustStepState.current => Icons.radio_button_checked_rounded,
      _TrustStepState.attention => Icons.error_outline_rounded,
      _TrustStepState.upcoming => Icons.radio_button_unchecked_rounded,
    };
    final content = Expanded(
      child: Column(
        crossAxisAlignment:
            compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Text(
            step.title,
            textAlign: compact ? TextAlign.start : TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            step.subtitle,
            textAlign: compact ? TextAlign.start : TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: colors.textSecondary,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
    if (compact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(icon, color: color, size: 22),
              if (!isLast)
                Container(
                  width: 2,
                  height: 42,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: color.withValues(alpha: 0.35),
                ),
            ],
          ),
          const SizedBox(width: 10),
          content,
        ],
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 2,
                color: Colors.transparent,
              ),
            ),
            Icon(icon, color: color, size: 24),
            Expanded(
              child: Container(
                height: 2,
                color:
                    isLast ? Colors.transparent : color.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }
}

List<_TrustStep> _stepsFor(
  PaymentScheduleDto schedule,
  PaymentTimelineAudience audience,
) {
  final milestones = [...schedule.milestones]
    ..sort((a, b) => a.sequence.compareTo(b.sequence));
  final shoot = _findMilestone(milestones, const ['shoot', 'day']) ??
      (milestones.length > 1 ? milestones[1] : null);
  final deliverable = _findMilestone(
        milestones,
        const ['deliverable', 'delivery', 'approval', 'final'],
      ) ??
      (milestones.isNotEmpty ? milestones.last : null);
  final lockMilestone = milestones.isNotEmpty ? milestones.first : null;
  final anyStarted = milestones.any((item) => !_isUpcoming(item.status));
  final anyRejected = milestones.any((item) => item.status == 'rejected');
  final allPaid = milestones.isNotEmpty && milestones.every(_isReleased);

  return [
    _TrustStep(
      title: 'Booking lock',
      subtitle: lockMilestone == null
          ? 'Waiting for schedule'
          : '${lockMilestone.amountLabel} ${_statusText(lockMilestone.status)}',
      state: anyStarted || schedule.status != 'draft'
          ? _TrustStepState.complete
          : _TrustStepState.current,
    ),
    _TrustStep(
      title: 'Shoot day',
      subtitle: shoot == null
          ? 'Shoot milestone pending'
          : '${_dateLabel(shoot.dueAt)} · ${_statusText(shoot.status)}',
      state: shoot == null
          ? _TrustStepState.upcoming
          : shoot.status == 'rejected'
              ? _TrustStepState.attention
              : _isReleased(shoot)
                  ? _TrustStepState.complete
                  : !_isUpcoming(shoot.status)
                      ? _TrustStepState.current
                      : _TrustStepState.upcoming,
    ),
    _TrustStep(
      title: 'Deliverable approval',
      subtitle: deliverable == null
          ? 'Approval milestone pending'
          : '${deliverable.name} · ${_statusText(deliverable.status)}',
      state: anyRejected
          ? _TrustStepState.attention
          : deliverable == null
              ? _TrustStepState.upcoming
              : _isReleased(deliverable)
                  ? _TrustStepState.complete
                  : !_isUpcoming(deliverable.status)
                      ? _TrustStepState.current
                      : _TrustStepState.upcoming,
    ),
    _TrustStep(
      title: 'Payout release',
      subtitle: audience == PaymentTimelineAudience.producer
          ? (allPaid ? 'Released to provider' : 'Releases after approval')
          : (allPaid ? 'Released to you' : 'Held safely until approvals clear'),
      state:
          allPaid || {'released', 'completed', 'paid'}.contains(schedule.status)
              ? _TrustStepState.complete
              : anyRejected
                  ? _TrustStepState.attention
                  : anyStarted
                      ? _TrustStepState.current
                      : _TrustStepState.upcoming,
    ),
  ];
}

PaymentMilestoneDto? _findMilestone(
  List<PaymentMilestoneDto> milestones,
  List<String> words,
) {
  for (final milestone in milestones) {
    final haystack =
        '${milestone.name} ${milestone.releaseCondition ?? ''}'.toLowerCase();
    if (words.any(haystack.contains)) return milestone;
  }
  return null;
}

bool _isUpcoming(String status) {
  return {'due', 'pending', 'scheduled', 'draft'}.contains(status);
}

bool _isReleased(PaymentMilestoneDto milestone) {
  return {'verified', 'released', 'paid'}.contains(milestone.status) ||
      milestone.transactions.any(
        (transaction) => {'succeeded', 'paid', 'verified'}.contains(
          transaction.status,
        ),
      );
}

String _statusText(String status) => status.replaceAll('_', ' ');

String _dateLabel(DateTime? date) {
  if (date == null) return 'Date TBD';
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

Color _statusColor(BuildContext context, String status) {
  final colors = context.appColors;
  return switch (status) {
    'verified' || 'released' || 'paid' || 'completed' => colors.success,
    'proof_submitted' || 'processing' || 'active' => colors.infoBlue,
    'rejected' || 'failed' || 'cancelled' => colors.danger,
    _ => colors.goldDark,
  };
}

Color _stateColor(BuildContext context, _TrustStepState state) {
  final colors = context.appColors;
  return switch (state) {
    _TrustStepState.complete => colors.success,
    _TrustStepState.current => colors.goldDark,
    _TrustStepState.attention => colors.danger,
    _TrustStepState.upcoming => colors.textTertiary,
  };
}

class _TrustStep {
  final String title;
  final String subtitle;
  final _TrustStepState state;

  const _TrustStep({
    required this.title,
    required this.subtitle,
    required this.state,
  });
}

enum _TrustStepState { complete, current, upcoming, attention }
