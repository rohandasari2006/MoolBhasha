import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../../worksheet_generation/models/enums.dart';
import '../models/flashcard.dart';
import '../models/flashcard_topic.dart';

/// Loads the bundled flashcard datasets. Each (domain, grade) pair is a
/// separate JSON asset (assets/flashcards/data/<domain>/<grade>.json),
/// mirroring the folder-per-grade layout already used for the worksheet
/// content bank. Files are loaded lazily and cached per pair so a low-end
/// device never holds the full flashcard set in memory unless it is
/// actually browsed.
class FlashcardRepository {
  final Map<String, List<Flashcard>> _cache = {};

  String _assetPath(Domain domain, Grade grade) =>
      'assets/flashcards/data/${domain.assetKey}/${grade.assetKey}.json';

  Future<List<Flashcard>> _load(
      Domain domain,
      Grade grade,
      ) async {
    final key = '${domain.assetKey}_${grade.assetKey}';

    final cached = _cache[key];

    if (cached != null) {
      return cached;
    }

    final path =
        'assets/flashcards/data/'
        '${domain.assetKey}/'
        '${grade.assetKey}.json';

    print('========================================');
    print('FLASHCARD ASSET PATH: $path');
    print('DOMAIN: ${domain.assetKey}');
    print('GRADE: ${grade.assetKey}');
    print('========================================');

    final raw = await rootBundle.loadString(path);

    final json = jsonDecode(raw) as Map<String, dynamic>;

    final cards = (json['flashcards'] as List)
        .map(
          (e) => Flashcard.fromJson(
        e as Map<String, dynamic>,
      ),
    )
        .toList(growable: false);

    _cache[key] = cards;

    return cards;
  }

  Future<List<Flashcard>> cardsFor({
    required Domain domain,
    required Grade grade,
    FlashcardTopic? topic,
  }) async {
    final all = await _load(domain, grade);
    if (topic == null) return all;
    return all.where((c) => c.topic == topic).toList();
  }

  Future<Flashcard?> byId(String id, {required Domain domain, required Grade grade}) async {
    final all = await _load(domain, grade);
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Searches across every grade for a given domain — used when only an id
  /// is known (e.g. a deep link) and the grade isn't. More expensive than
  /// [byId]; avoid calling this in a tight loop.
  Future<Flashcard?> findById(String id) async {
    for (final domain in Domain.values) {
      for (final grade in Grade.values) {
        final match = await byId(id, domain: domain, grade: grade);
        if (match != null) return match;
      }
    }
    return null;
  }
}
