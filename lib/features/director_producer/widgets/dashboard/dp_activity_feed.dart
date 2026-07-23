import 'package:flutter/material.dart';

import '../../../../core/director/director_dashboard_models.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../routes/director_producer_routes.dart';

/// Team and Communication Activity — a compact read of the production
/// room feed (chat + file log), surfaced on the dashboard instead of
/// living only behind the Room tab.
class DPActivityFeed extends StatelessWidget {
  final List<DirectorActivityItem> items;

  const DPActivityFeed({super.key, this.items = const []});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final previewItems = items.take(6).toList();
    if (previewItems.isEmpty) {
      return Text(
        'No live room activity yet.',
        style: AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in previewItems)
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  Navigator.pushNamed(context, DirectorProducerRoutes.room),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.goldGlow,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      entry.title.isNotEmpty
                          ? entry.title[0].toUpperCase()
                          : '?',
                      style: AppTextStyles.caption.copyWith(
                        color: colors.goldDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: AppTextStyles.cardLabel
                              .copyWith(color: colors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            entry.projectTitle,
                            if ((entry.body ?? '').isNotEmpty) entry.body!,
                          ].join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.smallMeta
                              .copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _activityAge(entry.createdAt),
                    style: AppTextStyles.caption
                        .copyWith(color: colors.textTertiary),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

String _activityAge(DateTime? value) {
  if (value == null) return 'Now';
  final difference = DateTime.now().difference(value.toLocal());
  if (difference.inMinutes < 1) return 'Now';
  if (difference.inHours < 1) return '${difference.inMinutes}m';
  if (difference.inDays < 1) return '${difference.inHours}h';
  return '${difference.inDays}d';
}
