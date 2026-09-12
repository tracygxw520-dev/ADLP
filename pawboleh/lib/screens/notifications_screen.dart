import 'package:flutter/material.dart';
import '../models/notification_item.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

/// Notification feed shown as a dashboard-adjacent slide-in panel.
class NotificationsPanel extends StatefulWidget {
  const NotificationsPanel({super.key});

  @override
  State<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<NotificationsPanel> {
  late List<AppNotification> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = List.of(sampleNotifications);
  }

  int get _unreadCount => _notifications.where((item) => item.unread).length;

  void _markAllRead() => setState(() {
        _notifications = [
          for (final notification in _notifications) notification.copyWith(unread: false),
        ];
      });

  void _openNotification(int index) {
    if (_notifications[index].unread) {
      setState(() => _notifications[index] = _notifications[index].copyWith(unread: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width.clamp(320, 420).toDouble(),
      height: double.infinity,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('Notifications', style: AppTextStyles.cardTitle),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                if (_unreadCount > 0)
                  Row(
                    children: [
                      Text('$_unreadCount new updates', style: AppTextStyles.subtitle.copyWith(fontSize: 13)),
                      const Spacer(),
                      TextButton(
                        onPressed: _markAllRead,
                        child: Text('Mark all read', style: AppTextStyles.chipLabel.copyWith(color: AppColors.tealStart)),
                      ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) => _NotificationCard(
                      notification: _notifications[index],
                      onTap: () => _openNotification(index),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(AppSpacing.md),
      tintOpacity: notification.unread ? 0.3 : 0.16,
      semanticLabel: '${notification.unread ? 'Unread: ' : ''}${notification.title}',
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: notification.iconBg.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(notification.icon, color: notification.iconBg, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: AppTextStyles.sectionLabel.copyWith(
                    fontWeight: notification.unread ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(notification.subtitle, style: AppTextStyles.cardSubtitle),
                const SizedBox(height: 7),
                Text(
                  notification.time,
                  style: AppTextStyles.chipLabel.copyWith(color: AppColors.textPrimary.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          if (notification.unread)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(left: AppSpacing.sm, top: 5),
              decoration: const BoxDecoration(color: AppColors.tealStart, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}
