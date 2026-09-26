import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../models/flashcard.dart';
import '../controllers/flashcard_viewer_cursor.dart';

class FlashcardViewerScreen extends StatefulWidget {
  final List<Flashcard> cards;

  const FlashcardViewerScreen({
    super.key,
    required this.cards,
  });

  @override
  State<FlashcardViewerScreen> createState() =>
      _FlashcardViewerScreenState();
}

class _FlashcardViewerScreenState
    extends State<FlashcardViewerScreen> {
  late final FlashcardViewerCursor _cursor;

  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();

    if (widget.cards.isEmpty) {
      throw ArgumentError('FlashcardViewerScreen requires cards.');
    }

    _cursor = FlashcardViewerCursor(widget.cards);
  }

  Flashcard get _currentCard => _cursor.current;

  void _nextCard() {
    if (!_cursor.hasNext) return;

    setState(() {
      _cursor.next();
      _showAnswer = false;
    });
  }

  void _previousCard() {
    if (!_cursor.hasPrevious) return;

    setState(() {
      _cursor.previous();
      _showAnswer = false;
    });
  }

  void _toggleAnswer() {
    setState(() {
      _showAnswer = !_showAnswer;
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = _currentCard;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Flashcards',
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
        child: Column(
          children: [
            _buildProgress(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  children: [
                    _buildFlashcard(card),

                    const SizedBox(height: 20),

                    _buildAnswerButton(),

                    const SizedBox(height: 24),

                    _buildNavigation(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Flashcard',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
          Text(
            _cursor.progressLabel,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcard(Flashcard card) {
    return GestureDetector(
      onTap: _toggleAnswer,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        constraints: const BoxConstraints(
          minHeight: 420,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardLilac,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.iconLilacText.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: _showAnswer
            ? _buildAnswerSide(card)
            : _buildQuestionSide(card),
      ),
    );
  }

  Widget _buildQuestionSide(Flashcard card) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (card.imageAsset != null) ...[
          _buildCardImage(card.imageAsset!),
          const SizedBox(height: 24),
        ],

        const Text(
          'Hindi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          card.word.hindi,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),

        if (card.description?.hindi != null &&
            card.description!.hindi.trim().isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            card.description!.hindi,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
        ],

        const SizedBox(height: 28),

        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
            SizedBox(width: 6),
            Text(
              'Tap to reveal Santali',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnswerSide(Flashcard card) {
    final santaliWord = card.word.santali;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (card.imageAsset != null) ...[
          _buildCardImage(card.imageAsset!),
          const SizedBox(height: 20),
        ],

        const Text(
          'Santali',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          santaliWord != null && santaliWord.trim().isNotEmpty
              ? santaliWord
              : 'Santali translation unavailable',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: santaliWord != null &&
                santaliWord.trim().isNotEmpty
                ? AppColors.textDark
                : AppColors.textMuted,
          ),
        ),

        if (card.description?.santali != null &&
            card.description!.santali!.trim().isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            card.description!.santali!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
        ],

        const SizedBox(height: 24),

        const Text(
          'Tap to see Hindi',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildCardImage(String assetPath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        assetPath,
        width: 150,
        height: 150,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.image_not_supported_outlined,
              size: 50,
              color: AppColors.textMuted,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnswerButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _toggleAnswer,
        icon: Icon(
          _showAnswer
              ? Icons.visibility_off_rounded
              : Icons.visibility_rounded,
        ),
        label: Text(
          _showAnswer ? 'Show Hindi' : 'Show Santali',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.iconLilacText,
          side: const BorderSide(
            color: AppColors.iconLilacText,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigation() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed:
            _cursor.hasPrevious ? _previousCard : null,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Previous'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textDark,
              disabledForegroundColor: Colors.grey.shade400,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: ElevatedButton.icon(
            onPressed: _cursor.hasNext ? _nextCard : null,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.iconLilacText,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade500,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}