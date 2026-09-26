import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// One row in the language list: a colored initial badge, the language
/// name in English + its native script, and a checkmark when selected.
///
/// Kept as its own tiny widget (rather than inlined in the screen) so it
/// can be reused anywhere else a language needs to be picked, and so its
/// size always adapts to whatever width the parent gives it — no fixed
/// widths/heights that could overflow on a narrow screen.
class LanguageTile extends StatelessWidget {
  final String name;
  final String nativeName;
  final String badgeText;
  final Color badgeColor;
  final Color badgeTextColor;
  final bool selected;
  final VoidCallback onTap;

  const LanguageTile({
    super.key,
    required this.name,
    required this.nativeName,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.green : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Badge sizes itself in fixed device-independent pixels but
            // the text inside scales down via FittedBox so a longer
            // script/initial never overflows the circle.
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Expanded so the text column always takes exactly the
            // remaining row width and wraps/truncates instead of
            // pushing the checkmark off-screen.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nativeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: selected
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.green,
                      key: ValueKey('selected'),
                    )
                  : const Icon(
                      Icons.circle_outlined,
                      color: Color(0xFFD8D3C4),
                      key: ValueKey('unselected'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
