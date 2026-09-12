import 'package:flutter/material.dart';

/// Opens a compact panel that slides in from the right without leaving the
/// current dashboard context.
Future<T?> showSlideInPanel<T>(BuildContext context, Widget child) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss panel',
    barrierColor: Colors.black.withValues(alpha: 0.32),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, _, _) => Align(
      alignment: Alignment.centerRight,
      child: Material(color: Colors.transparent, child: child),
    ),
    transitionBuilder: (_, animation, _, child) {
      final offset = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      );
      return SlideTransition(position: offset, child: child);
    },
  );
}
