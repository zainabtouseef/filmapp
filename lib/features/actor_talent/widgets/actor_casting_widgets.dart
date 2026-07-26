import 'package:flutter/material.dart';

import '../../../core/casting/casting_models.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import 'actor_talent_components.dart';

class ActorCastingRoleCard extends StatelessWidget {
  final CastingRole role;
  final VoidCallback onOpen;
  final VoidCallback onSave;

  const ActorCastingRoleCard({
    super.key,
    required this.role,
    required this.onOpen,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final imageUrl = role.project.coverFile?.publicUrl ?? '';
    return GlassSectionCard(
      radius: 16,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: colors.goldMid,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ActorMediaFrame(
                  imageUrl: imageUrl,
                  title: role.project.title,
                  badge: _deadline(role.applicationDueAt),
                  fallbackIcon: Icons.movie_filter_outlined,
                  compact: true,
                ),
                const SizedBox(height: 11),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.cardTitle.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${role.project.ownerName} · ${role.project.city?.name ?? 'Pakistan'}',
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
                    IconButton(
                      tooltip: role.saved ? 'Remove saved role' : 'Save role',
                      onPressed: onSave,
                      icon: Icon(
                        role.saved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: role.saved ? colors.goldDark : colors.iconMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    StatusChip(label: role.feeLabel, color: colors.goldMid),
                    StatusChip(
                      label: _dateRange(role.startDate, role.endDate),
                      color: colors.infoBlue,
                    ),
                    if ((role.auditionMode ?? '').isNotEmpty)
                      StatusChip(
                        label: _titleCase(role.auditionMode!),
                        color: colors.infoPurple,
                      ),
                    if (role.verifiedOnly)
                      StatusChip(
                        label: 'Verified profiles only',
                        color: colors.success,
                      ),
                  ],
                ),
                if ((role.summary ?? '').isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Text(
                    role.summary!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.smallMeta.copyWith(
                      color: colors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: CorePrimaryButton(
                    icon: role.applicationId == null
                        ? Icons.description_outlined
                        : Icons.assignment_turned_in_outlined,
                    label: role.applicationId == null
                        ? 'View role'
                        : _titleCase(role.applicationStatus ?? 'submitted'),
                    compact: true,
                    onTap: onOpen,
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

class ActorCastingApplicationCard extends StatelessWidget {
  final CastingApplication application;
  final VoidCallback onOpen;

  const ActorCastingApplicationCard({
    super.key,
    required this.application,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tone = _statusColor(context, application.status);
    return GlassSectionCard(
      radius: 14,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: tone,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        application.role.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(
                      label: application.statusLabel,
                      color: tone,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  application.role.project.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      application.isAudition
                          ? Icons.video_camera_front_outlined
                          : Icons.update_rounded,
                      size: 18,
                      color: tone,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        _nextAction(application),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.smallMeta.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Open application',
                      onPressed: onOpen,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color actorCastingStatusColor(BuildContext context, String status) {
  return _statusColor(context, status);
}

String actorCastingTitleCase(String value) => _titleCase(value);

String actorCastingDate(DateTime? value) {
  if (value == null) return 'Not scheduled';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = value.hour == 0
      ? 12
      : value.hour > 12
          ? value.hour - 12
          : value.hour;
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '${months[value.month - 1]} ${value.day}, ${value.year} · $hour:${value.minute.toString().padLeft(2, '0')} $suffix';
}

Color _statusColor(BuildContext context, String status) {
  final colors = context.appColors;
  return switch (status) {
    'selected' || 'offer_received' => colors.success,
    'shortlisted' || 'callback' => colors.infoPurple,
    'audition_requested' || 'self_tape_requested' => colors.infoBlue,
    'rejected' || 'withdrawn' => colors.danger,
    'draft' => colors.textSecondary,
    _ => colors.goldMid,
  };
}

String _nextAction(CastingApplication item) {
  return switch (item.status) {
    'draft' => 'Finish and submit your application',
    'self_tape_requested' when item.selfTapeFile == null =>
      'Upload the requested self-tape',
    'audition_requested' when item.audition.confirmedAt == null =>
      'Confirm your audition attendance',
    'callback' => 'Review callback details and confirm your availability',
    'offer_received' => 'Review the booking offer and contract terms',
    'selected' => 'Check your booking schedule and contract',
    'rejected' => item.rejectionReason ?? 'Application closed',
    'withdrawn' => 'You withdrew this application',
    _ => 'No action required while the production reviews your submission',
  };
}

String _deadline(DateTime? value) {
  if (value == null) return 'Open';
  final days = value.difference(DateTime.now()).inDays;
  if (days < 0) return 'Closed';
  if (days == 0) return 'Due today';
  return '$days days left';
}

String _dateRange(DateTime? start, DateTime? end) {
  if (start == null && end == null) return 'Dates TBD';
  if (start == null) return 'By ${actorCastingDate(end).split(' ·').first}';
  if (end == null) return 'From ${actorCastingDate(start).split(' ·').first}';
  return '${actorCastingDate(start).split(',').first} - ${actorCastingDate(end).split(',').first}';
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
