import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'notifications_screen.dart';
import 'paw_live_screen.dart';
import 'paw_snap_screen.dart';
import 'profile_panel.dart';
import '../widgets/slide_in_panel.dart';

/// Owns the single persistent bottom navigation bar and keeps all three
/// tabs alive in an [IndexedStack] so scroll position / carousel state
/// isn't lost when switching tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _goToTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final isLiveTab = _index == 1;

    return Scaffold(
      extendBody: !isLiveTab,
      body: Container(
        decoration: BoxDecoration(
          gradient: isLiveTab ? null : AppColors.backgroundGradient,
          color: isLiveTab ? Colors.black : null,
        ),
        child: IndexedStack(
          index: _index,
          children: [
            DashboardView(
              onNavigate: _goToTab,
              onNotifications: () => showSlideInPanel(context, const NotificationsPanel()),
              onProfile: () => showSlideInPanel(
                context,
                ProfilePanel(
                  onSignOut: () {
                    Navigator.of(context).pop();
                    widget.onSignOut();
                  },
                ),
              ),
            ),
            PawLiveView(onExit: () => _goToTab(0)),
            const PawSnapView(),
          ],
        ),
      ),
      bottomNavigationBar: isLiveTab
          ? null
          : _PawBottomNav(currentIndex: _index, onTap: _goToTab, isDark: isLiveTab),
    );
  }
}

class _PawBottomNav extends StatelessWidget {
  const _PawBottomNav({required this.currentIndex, required this.onTap, required this.isDark});

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;

  static const _items = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.podcasts_rounded, label: 'Paw Live'),
    (icon: Icons.camera_alt_rounded, label: 'Paw Snap'),
  ];

  @override
  Widget build(BuildContext context) {
    final barColor = isDark ? Colors.black.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.85);
    final inactiveColor = isDark ? Colors.white54 : AppColors.textPrimary.withValues(alpha: 0.4);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        height: 68,
        decoration: BoxDecoration(
          color: barColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            final active = i == currentIndex;
            final activeGradient = i == 2 ? AppColors.tealGradient : AppColors.orangeGradient;

            return Expanded(
              child: Semantics(
                button: true,
                selected: active,
                label: item.label,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(gradient: active ? activeGradient : null, shape: BoxShape.circle),
                        child: Icon(item.icon, size: 20, color: active ? Colors.white : inactiveColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? (isDark ? Colors.white : AppColors.textPrimary) : inactiveColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
