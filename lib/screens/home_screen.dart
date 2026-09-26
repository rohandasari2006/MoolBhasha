import 'package:flutter/material.dart';
import 'package:sih_2026/screens/Vocabulary_Varnamala_Screen.dart';
import 'package:sih_2026/screens/text_translator.dart';
import 'package:sih_2026/screens/voice_translator.dart';
import 'package:sih_2026/screens/worksheet_generation.dart';
import '../flashcards/screens/flashcard_selection_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/lesson_card.dart';
import '../widgets/feature_card.dart';
import '../widgets/bottom_nav.dart';
import 'drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  void _onNavTap(int index) {
    setState(() => _navIndex = index);
    if(index==0){
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    }else if(index==1){
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VocabularyVarnamalaScreen(),
        ),
      );
    }
     else if(index==3){
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const WorksheetGeneratorScreen(),
        ),
      );
    }

    // TODO: hook up navigation to Lessons / Voice / Worksheets / Settings
    // screens here, e.g. using Navigator or an IndexedStack.
  }

  void _startLesson() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VocabularyVarnamalaScreen(),
      ),
    );
  }

  void _openFeature(String feature) {

    // void _openFeature(String feature) {
      if (feature == 'Text Translator') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TextTranslatorScreen(),
          ),
        );
      } else if (feature == 'Voice Translator') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const VoiceTranslatorScreen(),
          ),
        );
      }else if (feature == 'Worksheet Generator') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WorksheetGeneratorScreen(),
          ),
        );
      }
      else if (feature == 'Flashcard Sets') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FlashcardSelectionScreen(),
          ),
        );
      }
    }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MoolBhashaDrawer(),
      appBar: const HomeAppBar(),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: _onNavTap,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: const [
                  Text('Hello ', style: TextStyle(fontSize: 20)),
                  Text('👋', style: TextStyle(fontSize: 20)),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                "Let's continue learning today",
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),

              // Today's Lesson hero card
              LessonCard(
                title: 'Letter Recognition — Ka, Kha, Ga',
                // meta: '3 activities · 12 min',
                meta: "",
                onStart: _startLesson,
              ),

              const SizedBox(height: 28),
              const Text(
                'Translate anything',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 14),

              // 2x2 feature grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.35,
                children: [
                  FeatureCard(
                    icon: Icons.text_fields_rounded,
                    label: 'Text Translator',
                    backgroundColor: AppColors.cardMint,
                    iconColor: AppColors.iconMintText,
                    textColor: AppColors.iconMintText,
                    onTap: () => _openFeature('Text Translator'),
                  ),
                  FeatureCard(
                    icon: Icons.mic_rounded,
                    label: 'Voice Translator',
                    backgroundColor: AppColors.cardPeach,
                    iconColor: AppColors.iconPeachText,
                    textColor: AppColors.iconPeachText,
                    onTap: () => _openFeature('Voice Translator'),
                  ),
                  FeatureCard(
                    icon: Icons.edit_note_rounded,
                    label: 'Worksheet Generator',
                    backgroundColor: AppColors.cardSand,
                    iconColor: AppColors.iconSandText,
                    textColor: AppColors.iconSandText,
                    onTap: () => _openFeature('Worksheet Generator'),
                  ),
                  FeatureCard(
                    icon: Icons.style_rounded,
                    label: 'Flashcard Sets',
                    backgroundColor: AppColors.cardLilac,
                    iconColor: AppColors.iconLilacText,
                    textColor: AppColors.iconLilacText,
                    onTap: () => _openFeature('Flashcard Sets'),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Works fully offline · Optimized for low-end Android ·\nNIPUN Bharat aligned',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
