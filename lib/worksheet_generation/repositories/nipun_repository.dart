import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/enums.dart';
import '../models/nipun_outcome.dart';

/// Loads the bundled NIPUN Bharat / FLN outcome dataset once and serves it
/// from an in-memory index. No network access — asset-only.
class NipunRepository {
  static const _assetPath = 'assets/nipun/nipun_outcomes.json';

  List<NipunOutcome>? _cache;

  Future<List<NipunOutcome>> _load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final list = (json['outcomes'] as List)
        .map((e) => NipunOutcome.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    _cache = list;
    return list;
  }

  Future<List<NipunOutcome>> outcomesForGrade(Grade grade) async {
    final all = await _load();
    return all.where((o) => o.grade == grade).toList();
  }

  Future<List<NipunOutcome>> outcomesForGradeAndDomain(
    Grade grade,
    Domain domain,
  ) async {
    final all = await _load();
    return all.where((o) => o.grade == grade && o.domain == domain).toList();
  }

  /// Match free-text PDF topics/concepts to NIPUN outcomes for the given
  /// grade. Matching is local, deterministic substring/keyword matching —
  /// no ML/embedding model — so it stays cheap on low-end devices.
  Future<List<NipunOutcome>> matchTopics(
    Grade grade,
    List<String> topics,
  ) async {
    if (topics.isEmpty) return outcomesForGrade(grade);
    final candidates = await outcomesForGrade(grade);
    final lowerTopics = topics.map((t) => t.toLowerCase()).toList();

    final matched = candidates.where((o) {
      final haystack = ([
        o.competency,
        o.learningOutcome,
        ...o.skills,
      ].join(' ')).toLowerCase();
      return lowerTopics.any((t) => haystack.contains(t) || t.contains(o.domain.assetKey));
    }).toList();

    // If nothing matched, fall back to the full grade set rather than
    // returning empty — see spec section 48 ("don't generate unrelated
    // questions simply because they're in the dataset" governs *content*
    // selection downstream, not outcome availability here).
    return matched.isNotEmpty ? matched : candidates;
  }

  /// Whether the bundled dataset is the verified official NIPUN Bharat / FLN
  /// framework, or just the internal illustrative starter set. Surfaced so
  /// no part of the app can claim "NIPUN compliant" while this is false
  /// (spec sections 11 & 23).
  Future<bool> isCompleteOfficialDataset() async {
    await _load();
    return false;
  }

  /// Validates that [outcomeId] is a real outcome in the local repository
  /// (not merely a non-empty string) and that it actually matches the given
  /// grade/domain/question type. Returns the matching [NipunOutcome] on
  /// success. A `null` return means the reference does not exist or is
  /// incompatible — callers must treat that as a validation failure, never
  /// as "assume valid" (spec section 10).
  Future<NipunOutcome?> validateReference({
    required String outcomeId,
    required Grade grade,
    required Domain domain,
    QuestionType? questionType,
  }) async {
    final all = await _load();
    NipunOutcome? found;
    for (final o in all) {
      if (o.id == outcomeId) {
        found = o;
        break;
      }
    }
    if (found == null) return null;
    if (found.grade != grade || found.domain != domain) return null;
    if (questionType != null &&
        !found.allowedQuestionTypes.contains(questionType)) {
      return null;
    }
    return found;
  }
}
