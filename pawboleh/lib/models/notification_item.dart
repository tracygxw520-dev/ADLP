import 'package:flutter/material.dart';

/// A single notification row shown in the notifications panel.
class AppNotification {
  const AppNotification({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.time,
    this.unread = false,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String time;
  final bool unread;

  AppNotification copyWith({bool? unread}) {
    return AppNotification(
      icon: icon,
      iconBg: iconBg,
      title: title,
      subtitle: subtitle,
      time: time,
      unread: unread ?? this.unread,
    );
  }
}

/// Demo notification feed. Replace with API data when the backend is ready.
const List<AppNotification> sampleNotifications = [
  AppNotification(
    icon: Icons.auto_awesome_rounded,
    iconBg: Color(0xFF14B8A6),
    title: 'Paw Snap content is ready',
    subtitle: 'Video script and captions are ready for your last upload',
    time: '2m ago',
    unread: true,
  ),
  AppNotification(
    icon: Icons.podcasts_rounded,
    iconBg: Color(0xFFF59E0B),
    title: 'Livestream starts in 30 minutes',
    subtitle: 'Your Paw Live session “Raya Collection” is scheduled',
    time: '30m ago',
    unread: true,
  ),
  AppNotification(
    icon: Icons.forum_rounded,
    iconBg: Color(0xFF0F766E),
    title: 'Paw Live questions are waiting',
    subtitle: 'Three viewer questions have been matched with AI host replies',
    time: '1h ago',
    unread: true,
  ),
];
