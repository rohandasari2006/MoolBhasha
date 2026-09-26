// import '../../worksheet_generator/models/bilingual_text.dart';
// import '../../worksheet_generator/models/enums.dart' show Grade, Domain;
import '../../worksheet_generation/models/bilingual_text.dart';
import '../../worksheet_generation/models/enums.dart';
import 'flashcard_topic.dart';

/// A single bilingual flashcard, loaded from the bundled JSON datasets in
/// assets/flashcards/data/{numeracy,literacy}/. Matches the schema used by
/// the Worksheet Generator's content bank: a `word` plus an optional
/// `description` sentence, each carrying paired Hindi/Santali text.
class Flashcard {
  final String id;
  final Grade grade;
  final Domain domain;
  final FlashcardTopic topic;
  final BilingualText word;
  final BilingualText? description;
  final String? imageAsset; // e.g. assets/flashcards/images/animals/cow.webp
  final String nipunOutcomeId; // references NipunRepository's outcome ids

  /// Optional free-form sub-grouping within [topic], e.g. the AnimacySize
  /// image set's "big_animate" / "big_inanimate" / "small_animate" /
  /// "small_inanimate" classes. Null for cards that don't need one — this
  /// is additive and never required by [FlashcardValidator].
  final String? category;

  const Flashcard({
    required this.id,
    required this.grade,
    required this.domain,
    required this.topic,
    required this.word,
    this.description,
    this.imageAsset,
    required this.nipunOutcomeId,
    this.category,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    final hindi = json['hindi'] as Map<String, dynamic>;
    final santali = json['santali'] as Map<String, dynamic>?;

    return Flashcard(
      id: json['id'] as String,
      grade: Grade.fromAssetKey(json['grade'] as String),
      domain: Domain.values.firstWhere((d) => d.assetKey == json['domain']),
      topic: FlashcardTopic.fromAssetKey(json['topic'] as String),
      word: BilingualText(
        hindi: hindi['word'] as String,
        santali: santali?['word'] as String?,
      ),
      description: hindi['description'] != null
          ? BilingualText(
              hindi: hindi['description'] as String,
              santali: santali?['description'] as String?,
            )
          : null,
      imageAsset: json['image_asset'] as String?,
      nipunOutcomeId:
          (json['nipun'] as Map<String, dynamic>?)?['internal_outcome_id']
                  as String? ??
              '',
      category: json['category'] as String?,
    );
  }

  /// Returns a copy with Santali text merged in — used by
  /// FlashcardTranslationService after a cache miss produces a fresh
  /// translation. Only [word]/[description] change; everything else
  /// (including any cached Santali already present) is preserved unless
  /// explicitly overridden.
  Flashcard withTranslatedText({BilingualText? word, BilingualText? description}) {
    return Flashcard(
      id: id,
      grade: grade,
      domain: domain,
      topic: topic,
      word: word ?? this.word,
      description: description ?? this.description,
      imageAsset: imageAsset,
      nipunOutcomeId: nipunOutcomeId,
      category: category,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'grade': grade.assetKey,
        'domain': domain.assetKey,
        'topic': topic.assetKey,
        if (category != null) 'category': category,
        if (imageAsset != null) 'image_asset': imageAsset,
        'hindi': {
          'word': word.hindi,
          if (description != null) 'description': description!.hindi,
        },
        if (word.isTranslated || (description?.isTranslated ?? false))
          'santali': {
            if (word.santali != null) 'word': word.santali,
            if (description?.santali != null)
              'description': description!.santali,
          },
        'nipun': {'internal_outcome_id': nipunOutcomeId},
      };
}
