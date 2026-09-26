import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The bottom navigation bar shown in the reference design.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.menu_book_rounded, label: 'Lessons'),
      (icon: Icons.mic_rounded, label: 'Voice'),
      (icon: Icons.edit_note_rounded, label: 'Worksheets'),
      (icon: Icons.settings_rounded, label: 'Settings'),
    ];

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.green,
      unselectedItemColor: AppColors.textMuted,
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      items: [
        for (final item in items)
          BottomNavigationBarItem(
            icon: Icon(item.icon),
            label: item.label,
          ),
      ],
    );
  }
}
