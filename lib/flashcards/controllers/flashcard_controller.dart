import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../worksheet_generation/models/enums.dart';
import '../../worksheet_generation/services/santali_mt_onnx_provider.dart';
import '../../worksheet_generation/services/translation_provider.dart';

import '../models/flashcard.dart';
import '../models/flashcard_topic.dart';
import '../repositories/flashcard_repository.dart';
import '../services/flashcard_translation_service.dart';
import 'flashcard_viewer_cursor.dart';

enum FlashcardLoadStatus { idle, loading, ready, error }

class FlashcardViewerState {
  final FlashcardLoadStatus status;
  final FlashcardViewerCursor? cursor;

  /// True if this batch's cards were shown without Santali because the
  /// local model was unavailable (mirrors WorksheetBuilder's
  /// TranslationOutcome.unavailable — never a silent substitution).
  final bool translationUnavailable;
  final String? error;

  const FlashcardViewerState({
    this.status = FlashcardLoadStatus.idle,
    this.cursor,
    this.translationUnavailable = false,
    this.error,
  });

  FlashcardViewerState copyWith({
    FlashcardLoadStatus? status,
    FlashcardViewerCursor? cursor,
    bool? translationUnavailable,
    String? error,
  }) =>
      FlashcardViewerState(
        status: status ?? this.status,
        cursor: cursor ?? this.cursor,
        translationUnavailable: translationUnavailable ?? this.translationUnavailable,
        error: error,
      );
}

final flashcardViewerProvider =
    StateNotifierProvider<FlashcardController, FlashcardViewerState>(
  (ref) => FlashcardController(),
);

class FlashcardController extends StateNotifier<FlashcardViewerState> {
  FlashcardController() : super(const FlashcardViewerState());

  final _repository = FlashcardRepository();
  final TranslationProvider _translationProvider = SanthaliMtOnnxProvider();
  late final _translationService =
      FlashcardTranslationService(translationProvider: _translationProvider);

  Future<void> load({
    required Domain domain,
    required Grade grade,
    FlashcardTopic? topic,
  }) async {
    state = state.copyWith(status: FlashcardLoadStatus.loading);
    try {
      final cards = await _repository.cardsFor(
        domain: domain,
        grade: grade,
        topic: topic,
      );
      if (cards.isEmpty) {
        state = FlashcardViewerState(
          status: FlashcardLoadStatus.error,
          error: 'No flashcards found for this selection.',
        );
        return;
      }

      List<Flashcard> withSantali;
      var unavailable = false;
      try {
        withSantali = await _translationService.withSantali(cards);
      } on TranslationUnavailableException {
        withSantali = cards;
        unavailable = true;
      }

      state = FlashcardViewerState(
        status: FlashcardLoadStatus.ready,
        cursor: FlashcardViewerCursor(withSantali),
        translationUnavailable: unavailable,
      );
    } catch (e) {
      state = FlashcardViewerState(
        status: FlashcardLoadStatus.error,
        error: e.toString(),
      );
    }
  }

  void next() {
    state.cursor?.next();
    state = state.copyWith(cursor: state.cursor);
  }

  void previous() {
    state.cursor?.previous();
    state = state.copyWith(cursor: state.cursor);
  }
}
