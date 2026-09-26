import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../worksheet_generation/models/enums.dart';
import '../models/flashcard_topic.dart';
import '../controllers/flashcard_controller.dart';
import 'flashcard_viewer_screen.dart';

class FlashcardSelectionScreen extends StatefulWidget {
  const FlashcardSelectionScreen({super.key});

  @override
  State<FlashcardSelectionScreen> createState() =>
      _FlashcardSelectionScreenState();
}

class _FlashcardSelectionScreenState
    extends State<FlashcardSelectionScreen> {
  Domain? _selectedDomain;
  Grade? _selectedGrade;
  FlashcardTopic? _selectedTopic;
  bool _isLoading = false;
  List<FlashcardTopic> get _availableTopics {
    if (_selectedDomain == null) {
      return [];
    }

    return FlashcardTopic.forDomain(_selectedDomain!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Flashcard Sets',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.cardLilac,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ---------------------------------------------------------
              // INTRODUCTION
              // ---------------------------------------------------------

              const Text(
                'Choose what you want to learn',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Select a domain, grade and topic to start learning with flashcards.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              // ---------------------------------------------------------
              // DOMAIN
              // ---------------------------------------------------------

              _sectionTitle('1. Select Domain'),

              const SizedBox(height: 12),

              Row(
                children: [

                  // Literacy
                  Expanded(
                    child: _selectionCard(
                      icon: Icons.auto_stories_rounded,
                      title: 'Literacy',
                      subtitle: 'Letters, words & reading',
                      selected: _selectedDomain == Domain.literacy,
                      color: AppColors.cardMint,
                      iconColor: AppColors.iconMintText,
                      onTap: () {
                        setState(() {
                          _selectedDomain = Domain.literacy;
                          _selectedTopic = null;
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Numeracy
                  Expanded(
                    child: _selectionCard(
                      icon: Icons.calculate_rounded,
                      title: 'Numeracy',
                      subtitle: 'Numbers & mathematics',
                      selected: _selectedDomain == Domain.numeracy,
                      color: AppColors.cardPeach,
                      iconColor: AppColors.iconPeachText,
                      onTap: () {
                        setState(() {
                          _selectedDomain = Domain.numeracy;
                          _selectedTopic = null;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ---------------------------------------------------------
              // GRADE
              // ---------------------------------------------------------

              _sectionTitle('2. Select Grade'),

              const SizedBox(height: 12),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: Grade.values.map((grade) {
                  final selected = _selectedGrade == grade;

                  return ChoiceChip(
                    label: Text(grade.label),
                    selected: selected,

                    onSelected: (_) {
                      setState(() {
                        _selectedGrade = grade;
                      });
                    },

                    selectedColor: AppColors.cardLilac,
                    backgroundColor: Colors.white,

                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.textDark
                          : AppColors.textMuted,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),

                    side: BorderSide(
                      color: selected
                          ? AppColors.cardLilac
                          : Colors.grey.shade300,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 28),

              // ---------------------------------------------------------
              // TOPIC
              // ---------------------------------------------------------

              _sectionTitle('3. Select Topic'),

              const SizedBox(height: 12),

              if (_selectedDomain == null)
                _disabledMessage(
                  'Select a domain first to see available topics.',
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableTopics.map((topic) {
                    final selected = _selectedTopic == topic;

                    return ChoiceChip(
                      label: Text(topic.label),
                      selected: selected,

                      onSelected: (_) {
                        setState(() {
                          _selectedTopic = topic;
                        });
                      },

                      selectedColor: AppColors.cardSand,
                      backgroundColor: Colors.white,

                      labelStyle: TextStyle(
                        color: selected
                            ? AppColors.textDark
                            : AppColors.textMuted,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),

                      side: BorderSide(
                        color: selected
                            ? AppColors.cardSand
                            : Colors.grey.shade300,
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 36),

              // ---------------------------------------------------------
              // START BUTTON
              // ---------------------------------------------------------

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _canStart && !_isLoading
                      ? _startFlashcards
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.iconLilacText,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.iconLilacText,
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.style_rounded),
                      SizedBox(width: 10),
                      Text(
                        'Start Flashcards',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // CHECK WHETHER USER CAN START
  // =====================================================================

  bool get _canStart {
    return _selectedDomain != null &&
        _selectedGrade != null &&
        _selectedTopic != null;
  }

  // =====================================================================
  // LOAD FLASHCARDS AND OPEN VIEWER
  // =====================================================================

  Future<void> _startFlashcards() async {
    if (!_canStart) return;

    final controller = FlashcardController();

    try {
      // ---------------------------------------------------------------
      // LOAD FLASHCARDS
      // ---------------------------------------------------------------

      await controller.load(
        domain: _selectedDomain!,
        grade: _selectedGrade!,
        topic: _selectedTopic!,
      );

      // ---------------------------------------------------------------
      // CHECK WHETHER SCREEN IS STILL MOUNTED
      // ---------------------------------------------------------------

      if (!mounted) {
        controller.dispose();
        return;
      }

      // ---------------------------------------------------------------
      // CHECK FOR LOADING ERROR
      // ---------------------------------------------------------------

      if (controller.state.status == FlashcardLoadStatus.error) {
        final message =
            controller.state.error ??
                'Unable to load flashcards.';

        controller.dispose();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );

        return;
      }

      // ---------------------------------------------------------------
      // GET LOADED CARDS
      // ---------------------------------------------------------------

      final cursor = controller.state.cursor;

      if (cursor == null || cursor.cards.isEmpty) {
        controller.dispose();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No flashcards available.',
            ),
          ),
        );

        return;
      }

      // ---------------------------------------------------------------
      // SAVE CARDS BEFORE DISPOSING CONTROLLER
      // ---------------------------------------------------------------

      final cards = cursor.cards;

      controller.dispose();

      // ---------------------------------------------------------------
      // OPEN FLASHCARD VIEWER
      // ---------------------------------------------------------------

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FlashcardViewerScreen(
            cards: cards,
          ),
        ),
      );
    } catch (e) {
      controller.dispose();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load flashcards: $e',
          ),
        ),
      );
    }
  }

  // =====================================================================
  // SECTION TITLE
  // =====================================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  // =====================================================================
  // DOMAIN SELECTION CARD
  // =====================================================================

  Widget _selectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 180,
        ),

        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: color,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(
            color: selected
                ? iconColor
                : Colors.transparent,
            width: selected ? 2 : 0,
          ),
        ),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            CircleAvatar(
              radius: 23,

              backgroundColor:
              Colors.white.withValues(
                alpha: 0.7,
              ),

              child: Icon(
                icon,
                color: iconColor,
                size: 25,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // DISABLED MESSAGE
  // =====================================================================

  Widget _disabledMessage(String message) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.grey.shade100,

        borderRadius: BorderRadius.circular(12),
      ),

      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}