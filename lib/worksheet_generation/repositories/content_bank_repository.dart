import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/content_concept.dart';
import '../models/enums.dart';

class ContentBankRepository {
  static const _assetPath = 'assets/content_bank/content_bank.json';

  List<ContentConcept>? _cache;

  Future<List<ContentConcept>> _load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _cache = (json['concepts'] as List)
        .map((e) => ContentConcept.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return _cache!;
  }

  Future<List<ContentConcept>> conceptsFor({
    required Grade grade,
    required Domain domain,
    String? category,
  }) async {
    final all = await _load();
    return all.where((c) {
      final gradeMatch = c.grades.contains(grade);
      final domainMatch = c.domain == domain;
      final categoryMatch = category == null || c.category == category;
      return gradeMatch && domainMatch && categoryMatch;
    }).toList();
  }

  /// Concepts whose category or word/sentence loosely matches PDF topics.
  ///
  /// When no topics are supplied (no PDF, or a PDF with nothing extractable)
  /// this returns the full grade/domain content set — that is not a
  /// "fallback", it is simply unconstrained generation. But when topics
  /// WERE supplied (a PDF was uploaded and text/topics were extracted from
  /// it) and none of them match anything in the content bank, we must NOT
  /// silently hand back the full unrelated catalog — spec section 4 requires
  /// that this surface as a generation/validation issue instead of quietly
  /// producing questions unconnected to the uploaded syllabus. Callers
  /// (QuestionPlanner.realizeSlot) already treat an empty concept list as
  /// "this slot cannot be realized", which propagates into
  /// WorksheetValidator's question-count mismatch check.
  Future<List<ContentConcept>> conceptsMatchingTopics({
    required Grade grade,
    required Domain domain,
    required List<String> topics,
  }) async {
    final base = await conceptsFor(grade: grade, domain: domain);
    if (topics.isEmpty) return base;
    final lowerTopics = topics.map((t) => t.toLowerCase()).toList();
    final matched = base.where((c) {
      final haystack = '${c.category} ${c.hindiWord}'.toLowerCase();
      return lowerTopics.any((t) => haystack.contains(t) || t.contains(c.category));
    }).toList();
    return matched;
  }
}
