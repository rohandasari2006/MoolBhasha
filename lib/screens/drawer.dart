import 'package:flutter/material.dart';
import 'package:sih_2026/screens/about_screen.dart';
import '../theme/app_theme.dart';
import '../screens/language_selection_screen.dart';

/// App-wide navigation drawer, opened from the hamburger icon in
/// [HomeAppBar]. Visuals reuse the same green/cream/accent palette as
/// the rest of the app (see [AppColors]) rather than one-off hex values,
/// so re-skinning the app still only means editing `app_theme.dart`.
class MoolBhashaDrawer extends StatelessWidget {
  const MoolBhashaDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Cap the drawer width sensibly on tablets/large screens instead of
    // always taking 82% of a potentially very wide viewport.
    final width = MediaQuery.of(context).size.width * 0.82;

    return Drawer(
      backgroundColor: AppColors.background,
      width: width.clamp(280, 360),
      child: SafeArea(
        child: Column(
          children: [
            // =====================================================
            // HEADER
            // =====================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                24,
                24,
                24,
                26,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.green,
                    AppColors.greenDark,
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =================================================
                  // LOGO
                  // =================================================
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.20),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.translate_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =================================================
                  // APP NAME
                  // =================================================
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Mool',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        TextSpan(
                          text: 'Bhasha',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentOnDark,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 5),

                  // =================================================
                  // TAGLINE
                  // =================================================
                  const Text(
                    'Translator for Tribal Languages',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // =================================================
                  // SMALL BRAND LINE
                  // =================================================
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 2,
                        decoration: BoxDecoration(
                          color: AppColors.accentOnDark,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      const SizedBox(width: 7),

                      const Text(
                        'Connecting languages • Preserving culture',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white60,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // =====================================================
            // MENU ITEMS
            // =====================================================
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _DrawerItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Profile',
                    subtitle: 'Your account and progress',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Open Profile screen
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.language_rounded,
                    title: 'Change Language',
                    subtitle: 'Select your language',
                    onTap: () {
                      // Capture the navigator before popping the drawer,
                      // then push the real language screen so this menu
                      // item actually does something end-to-end.
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => const LanguageSelectionScreen(),
                        ),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.menu_book_rounded,
                    title: 'My Learning',
                    subtitle: 'Lessons and learning progress',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Open My Learning screen
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.star_outline_rounded,
                    title: 'Favorites',
                    subtitle: 'Your saved words and phrases',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Open Favorites screen
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(color: AppColors.divider),
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'App preferences',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Open Settings screen
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline_rounded,
                    title: 'About MoolBhasha',
                    subtitle: 'About the application',
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context)=>AboutScreen()
                          ),
                      );
                      // TODO: Open About screen
                    },
                  ),
                ],
              ),
            ),

            // =====================================================
            // FOOTER
            // =====================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  Container(height: 1, color: AppColors.divider),
                  const SizedBox(height: 14),
                  const Text(
                    'MoolBhasha',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Connecting languages • Preserving culture',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================================================================
// DRAWER ITEM
// ===================================================================

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.green, size: 23),
                ),
                const SizedBox(width: 14),
                // Expanded + maxLines/ellipsis: same overflow-safe pattern
                // used in FeatureCard and LanguageTile, so a long title
                // or a narrow drawer (small phone, large font-scale
                // accessibility setting) truncates instead of overflowing.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
