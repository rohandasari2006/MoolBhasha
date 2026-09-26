import '../models/flashcard.dart';

/// One-at-a-time navigation over an ordered, already-loaded list of
/// flashcards. Deliberately framework-free (no Riverpod/Flutter import) so
/// it can be unit tested directly and reused by whichever UI layer wraps
/// it later.
///
/// Index is 1-based to match the "current / total" display in the spec
/// (e.g. "3 / 20") — [index] never drops below 1 or exceeds [total].
class FlashcardViewerCursor {
  final List<Flashcard> cards;
  int _index = 1;

  FlashcardViewerCursor(this.cards) {
    if (cards.isEmpty) {
      throw ArgumentError('FlashcardViewerCursor requires a non-empty list');
    }
  }

  int get index => _index;
  int get total => cards.length;
  Flashcard get current => cards[_index - 1];
  bool get hasNext => _index < total;
  bool get hasPrevious => _index > 1;

  void next() {
    if (hasNext) _index++;
  }

  void previous() {
    if (hasPrevious) _index--;
  }

  void jumpTo(int index) {
    if (index < 1 || index > total) {
      throw RangeError.range(index, 1, total, 'index');
    }
    _index = index;
  }

  String get progressLabel => '$_index / $total';
}
