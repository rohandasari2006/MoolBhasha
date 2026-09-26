

import '../../worksheet_generation/models/enums.dart';

/// Flashcard topics, grouped under the two domains reused from the
/// Worksheet Generator feature (Numeracy / Literacy sections).
enum FlashcardTopic {
  // Numeracy
  numbers,
  counting,
  numberComparison,
  addition,
  subtraction,
  shapes,
  patterns,
  measurement,
  // Literacy
  letters,
  sounds,
  words,
  vocabulary,
  reading,
  oralLanguage;

  String get assetKey => switch (this) {
        FlashcardTopic.numbers => 'numbers',
        FlashcardTopic.counting => 'counting',
        FlashcardTopic.numberComparison => 'number_comparison',
        FlashcardTopic.addition => 'addition',
        FlashcardTopic.subtraction => 'subtraction',
        FlashcardTopic.shapes => 'shapes',
        FlashcardTopic.patterns => 'patterns',
        FlashcardTopic.measurement => 'measurement',
        FlashcardTopic.letters => 'letters',
        FlashcardTopic.sounds => 'sounds',
        FlashcardTopic.words => 'words',
        FlashcardTopic.vocabulary => 'vocabulary',
        FlashcardTopic.reading => 'reading',
        FlashcardTopic.oralLanguage => 'oral_language',
      };

  String get label => switch (this) {
        FlashcardTopic.numbers => 'Numbers',
        FlashcardTopic.counting => 'Counting',
        FlashcardTopic.numberComparison => 'Number Comparison',
        FlashcardTopic.addition => 'Addition',
        FlashcardTopic.subtraction => 'Subtraction',
        FlashcardTopic.shapes => 'Shapes',
        FlashcardTopic.patterns => 'Patterns',
        FlashcardTopic.measurement => 'Measurement',
        FlashcardTopic.letters => 'Letters',
        FlashcardTopic.sounds => 'Sounds',
        FlashcardTopic.words => 'Words',
        FlashcardTopic.vocabulary => 'Vocabulary',
        FlashcardTopic.reading => 'Reading',
        FlashcardTopic.oralLanguage => 'Oral Language',
      };

  Domain get domain => switch (this) {
        FlashcardTopic.numbers ||
        FlashcardTopic.counting ||
        FlashcardTopic.numberComparison ||
        FlashcardTopic.addition ||
        FlashcardTopic.subtraction ||
        FlashcardTopic.shapes ||
        FlashcardTopic.patterns ||
        FlashcardTopic.measurement =>
          Domain.numeracy,
        FlashcardTopic.letters ||
        FlashcardTopic.sounds ||
        FlashcardTopic.words ||
        FlashcardTopic.vocabulary ||
        FlashcardTopic.reading ||
        FlashcardTopic.oralLanguage =>
          Domain.literacy,
      };

  static FlashcardTopic fromAssetKey(String key) =>
      FlashcardTopic.values.firstWhere((t) => t.assetKey == key);

  static List<FlashcardTopic> forDomain(Domain domain) =>
      values.where((t) => t.domain == domain).toList(growable: false);
}
