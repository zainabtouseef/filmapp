import 'package:flutter/material.dart';

import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';
import '../mock_data/shared_mock_data.dart';
import '../models/shared_models.dart';
import '../widgets/core_widgets.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  int _tab = 0;
  late List<CoreNotification> _notifications =
      List.of(SharedMockData.notifications);

  List<CoreNotification> get _filtered {
    if (_tab == 0) return _notifications;
    final category = CoreNotificationCategory.values[_tab - 1];
    return _notifications.where((item) => item.category == category).toList();
  }

  @override
  Widget build(BuildContext context) {
    return CoreScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CoreAppHeader(
            title: 'Notification Center',
            subtitle: 'Bookings, payments, contracts and system updates.',
            icon: Icons.notifications_none_rounded,
            actions: [
              CoreIconButton(
                icon: Icons.done_all_rounded,
                tooltip: 'Mark all as read',
                onTap: () {
                  setState(() {
                    _notifications = _notifications
                        .map(
                          (item) => CoreNotification(
                            icon: item.icon,
                            title: item.title,
                            message: item.message,
                            time: item.time,
                            category: item.category,
                            routeName: item.routeName,
                            unread: false,
                          ),
                        )
                        .toList();
                  });
                  showCoreSnack(context, 'All notifications marked as read');
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _tabChip('All', 0),
                _tabChip('Bookings', 1),
                _tabChip('Payments', 2),
                _tabChip('Contracts', 3),
                _tabChip('System', 4),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_filtered.isEmpty)
            const CoreEmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'No notifications',
              message: 'You are all caught up for this category.',
            )
          else
            ..._filtered.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NotificationCard(
                  notification: item,
                  onTap: () => Navigator.pushNamed(context, item.routeName),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tabChip(String label, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: CoreChip(
        label: label,
        selected: _tab == index,
        onTap: () => setState(() => _tab = index),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final CoreNotification notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final category = notification.category.name;
    return GestureDetector(
      onTap: onTap,
      child: CoreGlassCard(
        selected: notification.unread,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.goldMid.withValues(alpha: 0.12),
                  ),
                  child: Icon(notification.icon, color: colors.goldMid),
                ),
                if (notification.unread)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.success,
                        border: Border.all(color: colors.background, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.label.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        notification.time,
                        style: AppTextStyles.caption
                            .copyWith(color: colors.textTertiary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.message,
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StatusBadge(label: category, tone: CoreStatusTone.info),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.iconMuted),
          ],
        ),
      ),
    );
  }
}
