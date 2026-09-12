import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    icon: LucideIcons.sparkles300,
    iconBg: Color(0xFF4A5D23),
    title: 'Gema Snap content is ready',
    subtitle: 'Video script and captions are ready for your last upload',
    time: '2m ago',
    unread: true,
  ),
  AppNotification(
    icon: LucideIcons.megaphone300,
    iconBg: Color(0xFFFFD700),
    title: 'Livestream starts in 30 minutes',
    subtitle: 'Your Gema Live session “Raya Collection” is scheduled',
    time: '30m ago',
    unread: true,
  ),
  AppNotification(
    icon: LucideIcons.messageCircle300,
    iconBg: Color(0xFF4A5D23),
    title: 'Gema Live questions are waiting',
    subtitle: 'Three viewer questions have been matched with AI host replies',
    time: '1h ago',
    unread: true,
  ),
];
