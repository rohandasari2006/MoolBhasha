import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

// import '../../worksheet_generator/services/translation_provider.dart';
import '../../worksheet_generation/models/enums.dart';
import '../../worksheet_generation/services/translation_provider.dart';
import '../models/flashcard.dart';

/// Translates a flashcard's Hindi text to Santali on demand and persists
/// the result to a small local JSON cache file so the model is never
/// invoked again for the same card (spec section 5: "Do not call MT every
/// time the user opens a card if cached data exists").
///
/// Cache file: <app documents dir>/flashcard_translation_cache.json
///   { "<flashcardId>": { "word": "...", "description": "..." }, ... }
///
/// Entirely local (path_provider + dart:io), no new package required.
class FlashcardTranslationService {
  final TranslationProvider translationProvider;

  /// Resolves the on-disk cache file. Defaults to a file in the app's
  /// documents directory (via path_provider); tests inject a resolver
  /// pointing at a temp file instead of mocking the path_provider
  /// platform channel.
  final Future<File> Function() _cacheFileResolver;
  Map<String, Map<String, String>>? _cache;
  File? _cacheFile;

  FlashcardTranslationService({
    required this.translationProvider,
    Future<File> Function()? cacheFileResolver,
  }) : _cacheFileResolver = cacheFileResolver ?? _defaultCacheFileResolver;

  static Future<File> _defaultCacheFileResolver() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/flashcard_translation_cache.json');
  }

  Future<File> _resolveCacheFile() async {
    if (_cacheFile != null) return _cacheFile!;
    _cacheFile = await _cacheFileResolver();
    return _cacheFile!;
  }

  Future<Map<String, Map<String, String>>> _loadCache() async {
    if (_cache != null) return _cache!;
    final file = await _resolveCacheFile();
    if (!await file.exists()) {
      _cache = {};
      return _cache!;
    }
    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _cache = decoded.map(
        (k, v) => MapEntry(k, Map<String, String>.from(v as Map)),
      );
    } catch (_) {
      // Corrupt cache file — never crash the flashcard viewer over it,
      // just start fresh (entries will be retranslated and rewritten).
      _cache = {};
    }
    return _cache!;
  }

  Future<void> _persistCache() async {
    final file = await _resolveCacheFile();
    await file.writeAsString(jsonEncode(_cache ?? {}));
  }

  /// Returns [cards] with Santali text filled in wherever it is missing,
  /// using the cache first and the local model only for cache misses.
  /// Cards that already carry Santali (e.g. hand-authored in the bundled
  /// JSON) are left untouched and never re-translated.
  ///
  /// If the model is unavailable, cards are returned with whatever
  /// Santali they already had (possibly none) rather than throwing — the
  /// flashcard viewer must keep working offline even without translation
  /// (same "never crash, degrade visibly" rule as the worksheet pipeline).
  Future<List<Flashcard>> withSantali(List<Flashcard> cards) async {
    final cache = await _loadCache();
    final needsTranslation = cards.where((c) {
      final cached = cache[c.id];
      final wordMissing = !c.word.isTranslated && cached?['word'] == null;
      final descMissing = c.description != null &&
          !c.description!.isTranslated &&
          cached?['description'] == null;
      return wordMissing || descMissing;
    }).toList();

    if (needsTranslation.isNotEmpty) {
      try {
        await translationProvider.ensureLoaded();
      } on TranslationUnavailableException {
        return _applyCacheOnly(cards, cache);
      }

      var cacheDirty = false;
      for (final card in needsTranslation) {
        final entry = cache.putIfAbsent(card.id, () => {});
        try {
          if (!card.word.isTranslated && entry['word'] == null) {
            entry['word'] = await translationProvider.translate(
              text: card.word.hindi,
              sourceLanguage: kSourceLang,
              targetLanguage: kTargetLang,
            );
            cacheDirty = true;
          }
          if (card.description != null &&
              !card.description!.isTranslated &&
              entry['description'] == null) {
            entry['description'] = await translationProvider.translate(
              text: card.description!.hindi,
              sourceLanguage: kSourceLang,
              targetLanguage: kTargetLang,
            );
            cacheDirty = true;
          }
        } on TranslationUnavailableException {
          // Leave this card's cache entry as-is (word/description may be
          // partially filled); move on rather than aborting the batch.
        }
      }

      await translationProvider.release();
      if (cacheDirty) await _persistCache();
    }

    return _applyCacheOnly(cards, cache);
  }

  List<Flashcard> _applyCacheOnly(
    List<Flashcard> cards,
    Map<String, Map<String, String>> cache,
  ) {
    return cards.map((card) {
      final entry = cache[card.id];
      if (entry == null) return card;

      final word = !card.word.isTranslated && entry['word'] != null
          ? card.word.withSantali(entry['word']!)
          : card.word;
      final description =
          card.description != null &&
                  !card.description!.isTranslated &&
                  entry['description'] != null
              ? card.description!.withSantali(entry['description']!)
              : card.description;

      if (identical(word, card.word) && identical(description, card.description)) {
        return card;
      }
      return card.withTranslatedText(word: word, description: description);
    }).toList();
  }

  /// Clears the on-disk cache entirely. Exposed for tests / a future
  /// "reset translations" dev action; never called from normal app flow.
  Future<void> clearCache() async {
    _cache = {};
    final file = await _resolveCacheFile();
    if (await file.exists()) await file.delete();
  }
}
