import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/enums.dart';
import '../models/question_template.dart';

class TemplateRepository {
  static const _assetPath = 'assets/templates/templates.json';

  List<QuestionTemplateModel>? _cache;

  Future<List<QuestionTemplateModel>> _load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _cache = (json['templates'] as List)
        .map((e) => QuestionTemplateModel.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return _cache!;
  }

  Future<List<QuestionTemplateModel>> templatesFor({
    required Grade grade,
    required Domain domain,
    required QuestionType type,
  }) async {
    final all = await _load();
    return all
        .where((t) =>
            t.type == type &&
            t.grades.contains(grade) &&
            t.domains.contains(domain))
        .toList();
  }
}
