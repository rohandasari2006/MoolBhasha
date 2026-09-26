import 'enums.dart';

/// A single NIPUN Bharat / Foundational Literacy & Numeracy learning outcome.
///
/// `id` may be an official NIPUN code where the source material provides a
/// machine-readable one, or an internal id (prefixed `internal_`) where it
/// does not — see `source` for provenance. Internal ids are NEVER presented
/// to the user as official government codes.
class NipunOutcome {
  final String id;
  final bool isInternalId;
  final Grade grade;
  final Domain domain;
  final String competency;
  final String learningOutcome;
  final List<String> skills;
  final List<QuestionType> allowedQuestionTypes;
  final String source;

  /// True only when the dataset explicitly marked this outcome as verified
  /// against the official Government of India NIPUN Bharat / FLN outcome
  /// codes. Internal/illustrative outcomes (the current starter dataset)
  /// must report false here — never presented to the user as an official
  /// government reference (spec sections 10, 11 & 23).
  final bool isOfficialVerified;

  const NipunOutcome({
    required this.id,
    required this.isInternalId,
    required this.grade,
    required this.domain,
    required this.competency,
    required this.learningOutcome,
    required this.skills,
    required this.allowedQuestionTypes,
    required this.source,
    this.isOfficialVerified = false,
  });

  factory NipunOutcome.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final isInternal = id.startsWith('internal_');
    final officialVerified = json['is_official_verified'] as bool? ?? false;
    // Defensive check: an id that isn't marked internal but also isn't
    // explicitly verified official must not be trusted as official either —
    // absence of the flag is never treated as "official by default".
    return NipunOutcome(
      id: id,
      isInternalId: isInternal,
      grade: Grade.fromAssetKey(json['grade'] as String),
      domain: Domain.values.firstWhere((d) => d.assetKey == json['domain']),
      competency: json['competency'] as String,
      learningOutcome: json['learning_outcome'] as String,
      skills: (json['skills'] as List).cast<String>(),
      allowedQuestionTypes: (json['allowed_question_types'] as List)
          .cast<String>()
          .map((s) => QuestionType.values.firstWhere((t) => t.assetKey == s))
          .toList(),
      source: json['source'] as String,
      isOfficialVerified: !isInternal && officialVerified,
    );
  }
}
