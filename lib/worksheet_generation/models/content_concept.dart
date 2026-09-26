import 'enums.dart';

/// A single foundational concept from the local content bank
/// (e.g. "animal_cow" -> word: गाय, sentence: गाय दूध देती है.)
class ContentConcept {
  final String conceptId;
  final List<Grade> grades;
  final Domain domain;
  final String category; // e.g. "animals", "counting", "shapes"
  final String hindiWord;
  final String? hindiSentence;
  final Map<String, dynamic>? extra; // numeric values, shape names, etc.

  const ContentConcept({
    required this.conceptId,
    required this.grades,
    required this.domain,
    required this.category,
    required this.hindiWord,
    this.hindiSentence,
    this.extra,
  });

  factory ContentConcept.fromJson(Map<String, dynamic> json) {
    final hindi = json['hindi'] as Map<String, dynamic>;
    return ContentConcept(
      conceptId: json['concept_id'] as String,
      grades: (json['grade'] as List)
          .cast<String>()
          .map(Grade.fromAssetKey)
          .toList(),
      domain: Domain.values.firstWhere((d) => d.assetKey == json['domain']),
      category: json['category'] as String,
      hindiWord: hindi['word'] as String,
      hindiSentence: hindi['sentence'] as String?,
      extra: json['extra'] as Map<String, dynamic>?,
    );
  }
}
