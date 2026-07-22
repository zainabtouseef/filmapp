import 'package:flutter/material.dart';

import '../../trust_safety/trust_safety_controller.dart';
import '../../trust_safety/trust_safety_models.dart';
import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../core_routes.dart';
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
  bool _loadedLive = false;
  bool _loadingLive = false;
  String? _notice;
  late List<CoreNotification> _notifications = List.of(
    SharedMockData.notifications,
  );

  List<CoreNotification> get _filtered {
    if (_tab == 0) return _notifications;
    final category = CoreNotificationCategory.values[_tab - 1];
    return _notifications.where((item) => item.category == category).toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedLive) {
      _loadedLive = true;
      _loadLiveNotifications();
    }
  }

  Future<void> _loadLiveNotifications() async {
    final trustSafety = TrustSafetyScope.maybeOf(context);
    if (trustSafety == null) return;
    setState(() {
      _loadingLive = true;
      _notice = null;
    });
    try {
      final data = await trustSafety.notifications(force: true);
      if (!mounted) return;
      setState(() {
        if (data.notifications.isNotEmpty) {
          _notifications = data.notifications.map(_mapNotification).toList();
          _notice = '${data.unreadCount} unread live notifications loaded.';
        } else {
          _notice = 'No live notifications yet — showing preview examples.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notice = 'Live notifications unavailable — showing preview examples.';
      });
    } finally {
      if (mounted) setState(() => _loadingLive = false);
    }
  }

  CoreNotification _mapNotification(NotificationDto item) {
    final category = switch (item.category) {
      'booking' || 'bookings' || 'reviews' => CoreNotificationCategory.bookings,
      'payment' || 'payments' => CoreNotificationCategory.payments,
      'contract' || 'contracts' => CoreNotificationCategory.contracts,
      _ => CoreNotificationCategory.system,
    };
    return CoreNotification(
      icon: switch (category) {
        CoreNotificationCategory.bookings => Icons.event_available_outlined,
        CoreNotificationCategory.payments =>
          Icons.account_balance_wallet_outlined,
        CoreNotificationCategory.contracts => Icons.description_outlined,
        CoreNotificationCategory.system => Icons.notifications_none_rounded,
      },
      title: item.title,
      message: item.body,
      time: item.publicId,
      category: category,
      routeName: item.routeName ?? CoreRoutes.notifications,
      unread: item.unread,
    );
  }

  Future<void> _markAllRead() async {
    final trustSafety = TrustSafetyScope.maybeOf(context);
    try {
      if (trustSafety != null) {
        await trustSafety.markAllNotificationsRead();
        await _loadLiveNotifications();
      } else {
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
      }
      if (mounted) showCoreSnack(context, 'All notifications marked as read');
    } catch (_) {
      if (mounted) showCoreSnack(context, 'Could not update notifications');
    }
  }

  Future<void> _openNotification(CoreNotification item) async {
    final trustSafety = TrustSafetyScope.maybeOf(context);
    if (trustSafety != null && item.unread && item.time.startsWith('NTF-')) {
      try {
        await trustSafety.markNotificationRead(item.time);
      } catch (_) {
        // Opening the destination is still useful if the read receipt fails.
      }
    }
    if (!mounted) return;
    Navigator.pushNamed(context, item.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return CoreScreenScaffold(
      scrollable: false,
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
                onTap: _markAllRead,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loadingLive)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (_notice != null) ...[
            InlineNotice(
              message: _notice!,
              tone: _notice!.startsWith('Live')
                  ? CoreStatusTone.warning
                  : CoreStatusTone.info,
            ),
            const SizedBox(height: 12),
          ],
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
          Expanded(
            child: filtered.isEmpty
                ? const CoreEmptyState(
                    icon: Icons.notifications_off_outlined,
                    title: 'No notifications',
                    message: 'You are all caught up for this category.',
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return NotificationCard(
                        key: ValueKey(item.title + item.time),
                        notification: item,
                        onTap: () => _openNotification(item),
                      );
                    },
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

String _categoryLabel(CoreNotificationCategory category) {
  return switch (category) {
    CoreNotificationCategory.bookings => 'Bookings',
    CoreNotificationCategory.payments => 'Payments',
    CoreNotificationCategory.contracts => 'Contracts',
    CoreNotificationCategory.system => 'System',
  };
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
    final category = _categoryLabel(notification.category);
    return CardShell(
      onTap: onTap,
      selected: notification.unread,
      tone: notification.unread ? CineTone.information : CineTone.neutral,
      density: CardDensity.compact,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconBadge(
                icon: notification.icon,
                tone: notification.unread
                    ? CineTone.information
                    : CineTone.neutral,
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
                      style: AppTextStyles.caption.copyWith(
                        color: colors.textTertiary,
                      ),
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
        ],
      ),
    );
  }
}
