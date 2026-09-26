import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/language_tile.dart';
import 'home_screen.dart';

/// Data model for one selectable app-interface language.
class AppLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String badgeText;
  final Color badgeColor;
  final Color badgeTextColor;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeTextColor,
  });
}

/// Language selection screen.
class LanguageSelectionScreen extends StatefulWidget {
  final String? initialCode;
  final ValueChanged<AppLanguage>? onLanguageSelected;

  const LanguageSelectionScreen({
    super.key,
    this.initialCode,
    this.onLanguageSelected,
  });

  static const List<AppLanguage> languages = [
    AppLanguage(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      badgeText: 'A',
      badgeColor: AppColors.cardMint,
      badgeTextColor: AppColors.iconMintText,
    ),
    AppLanguage(
      code: 'hi',
      name: 'Hindi',
      nativeName: 'हिन्दी',
      badgeText: 'अ',
      badgeColor: AppColors.cardPeach,
      badgeTextColor: AppColors.iconPeachText,
    ),
    AppLanguage(
      code: 'sat',
      name: 'Santhali',
      nativeName: 'ᱥᱟᱱᱛᱟᱲᱤ',
      badgeText: 'ᱚᱲ',
      badgeColor: AppColors.cardSand,
      badgeTextColor: AppColors.iconSandText,
    ),
    AppLanguage(
      code: 'mar',
      name: 'Marathi',
      nativeName: 'मराठी',
      badgeText: 'अ',
      badgeColor: AppColors.cardLilac,
      badgeTextColor: AppColors.iconLilacText,
    ),
    AppLanguage(
      code: 'unr',
      name: 'Mundari',
      nativeName: 'Mundari',
      badgeText: 'Mu',
      badgeColor: AppColors.cardMint,
      badgeTextColor: AppColors.iconMintText,
    ),
    AppLanguage(
      code: 'bn',
      name: 'Bengali',
      nativeName: 'বাংলা',
      badgeText: 'ব',
      badgeColor: AppColors.cardPeach,
      badgeTextColor: AppColors.iconPeachText,
    ),
    AppLanguage(
      code: 'or',
      name: 'Odia',
      nativeName: 'ଓଡ଼ିଆ',
      badgeText: 'ଓ',
      badgeColor: AppColors.cardSand,
      badgeTextColor: AppColors.iconSandText,
    ),
  ];

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  late String _selectedCode;

  @override
  void initState() {
    super.initState();
    _selectedCode = widget.initialCode ?? 'en';
  }

  void _confirm() {
    final selectedLanguage = LanguageSelectionScreen.languages.firstWhere(
          (language) => language.code == _selectedCode,
    );

    // Return the selected language if a callback is provided.
    widget.onLanguageSelected?.call(selectedLanguage);

    // Open HomeScreen after confirmation.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textDark,
          ),
          onPressed: () {
            Navigator.of(context).maybePop();
          },
        ),
        title: const Text(
          'App Language',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                4,
                20,
                12,
              ),
              child: Text(
                'Choose the language you want to use across the app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
            ),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  12,
                ),
                itemCount: LanguageSelectionScreen.languages.length,
                separatorBuilder: (_, __) {
                  return const SizedBox(height: 12);
                },
                itemBuilder: (context, index) {
                  final language =
                  LanguageSelectionScreen.languages[index];

                  return LanguageTile(
                    name: language.name,
                    nativeName: language.nativeName,
                    badgeText: language.badgeText,
                    badgeColor: language.badgeColor,
                    badgeTextColor: language.badgeTextColor,
                    selected: _selectedCode == language.code,
                    onTap: () {
                      setState(() {
                        _selectedCode = language.code;
                      });
                    },
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                0,
                20,
                20,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}