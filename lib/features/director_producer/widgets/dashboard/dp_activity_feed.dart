import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/director_producer_demo_data.dart';
import '../../routes/director_producer_routes.dart';

/// Team and Communication Activity — a compact read of the production
/// room feed (chat + file log), surfaced on the dashboard instead of
/// living only behind the Room tab.
class DPActivityFeed extends StatelessWidget {
  const DPActivityFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final items = DirectorProducerDemoData.roomItems.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in items)
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
                      entry[0].isNotEmpty ? entry[0][0].toUpperCase() : '?',
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
                          entry[0],
                          style: AppTextStyles.cardLabel
                              .copyWith(color: colors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry[1],
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
                    entry[2],
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
