import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Top bar with the hamburger menu, "AdiVaani" brand title, and the two
/// circular action icons (language / profile) seen in the reference design.
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
             _circleIconButton(icon: Icons.menu, onTap: () {
               Scaffold.of(context).openDrawer();
             }),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: 'Mool',
                            style: TextStyle(color: Color(0xFFCC7A2E)),
                          ),
                          TextSpan(
                            text: 'Bhasha',
                            style: TextStyle(color: AppColors.green),
                          ),
                        ],
                      ),
                    ),

                  const Text(
                    'TRANSLATOR FOR TRIBAL LANGUAGES',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 0.5,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // _circleIconButton(icon: Icons.public, onTap: () {}),
            const SizedBox(width: 8),
            _circleIconButton(
              icon: Icons.person,
              onTap: () {},
              filled: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? AppColors.green : Colors.white,
        ),
        child: Icon(
          icon,
          size: 20,
          color: filled ? Colors.white : AppColors.textDark,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
