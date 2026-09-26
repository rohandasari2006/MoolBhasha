import 'package:flutter/services.dart' show rootBundle;

import '../../worksheet_generation/repositories/nipun_repository.dart';
import '../models/flashcard.dart';

class FlashcardValidationIssue {
  final String cardId;
  final String message;
  const FlashcardValidationIssue(this.cardId, this.message);
  @override
  String toString() => '[$cardId] $message';
}

class FlashcardValidationResult {
  final bool isValid;
  final List<FlashcardValidationIssue> issues;
  const FlashcardValidationResult({required this.isValid, required this.issues});
}

/// Matches Ol Chiki Unicode block (U+1C50-U+1C7F) — same pattern used by
/// WorksheetValidator so Santali-script checks stay consistent across
/// features.
final _olChikiPattern = RegExp(r'[\u1C50-\u1C7F]');

class FlashcardValidator {
  /// When true (production), a card missing Santali or a required image
  /// asset FAILS validation. Development fixtures may set this to false so
  /// they can intentionally omit Santali while content is authored (spec
  /// section 14: "Development fixtures may intentionally omit Santali, but
  /// production validation must not").
  final bool strict;
  final NipunRepository? nipunRepository;

  FlashcardValidator({this.strict = true, this.nipunRepository});

  Future<FlashcardValidationResult> validateSet(List<Flashcard> cards) async {
    final issues = <FlashcardValidationIssue>[];
    final seenIds = <String>{};
    final seenSemanticKeys = <String>{};

    for (final card in cards) {
      if (!seenIds.add(card.id)) {
        issues.add(FlashcardValidationIssue(card.id, 'Duplicate flashcard id'));
      }

      // Duplicate semantic content: same word, in the same grade/domain/
      // topic slot, authored twice under different ids.
      final semanticKey =
          '${card.grade.assetKey}|${card.domain.assetKey}|${card.topic.assetKey}|'
          '${card.word.hindi.trim().toLowerCase()}';
      if (!seenSemanticKeys.add(semanticKey)) {
        issues.add(FlashcardValidationIssue(
          card.id,
          'Duplicate flashcard content (same word/grade/domain/topic as '
              'another card)',
        ));
      }

      issues.addAll(await _validateCard(card));
    }

    return FlashcardValidationResult(isValid: issues.isEmpty, issues: issues);
  }

  Future<List<FlashcardValidationIssue>> _validateCard(Flashcard card) async {
    final issues = <FlashcardValidationIssue>[];

    if (card.word.hindi.trim().isEmpty) {
      issues.add(FlashcardValidationIssue(card.id, 'Missing Hindi word'));
    }
    if (card.topic.domain != card.domain) {
      issues.add(FlashcardValidationIssue(
        card.id,
        'Topic ${card.topic.assetKey} does not belong to domain ${card.domain.assetKey}',
      ));
    }

    // NIPUN reference must actually exist in the local repository, not
    // merely be a non-empty string (spec section 10, applied to flashcards
    // per section 14).
    if (card.nipunOutcomeId.isEmpty) {
      issues.add(FlashcardValidationIssue(card.id, 'Missing NIPUN outcome reference'));
    } else if (nipunRepository != null) {
      final match = await nipunRepository!.validateReference(
        outcomeId: card.nipunOutcomeId,
        grade: card.grade,
        domain: card.domain,
      );
      if (match == null) {
        issues.add(FlashcardValidationIssue(
          card.id,
          'NIPUN outcome "${card.nipunOutcomeId}" does not exist in the '
              'local repository, or is not compatible with this card\'s '
              'grade/domain',
        ));
      }
    }

    final santali = card.word.santali;
    final hasSantali = santali != null && santali.trim().isNotEmpty;
    if (!hasSantali && strict) {
      issues.add(FlashcardValidationIssue(
        card.id,
        'Missing Santali word (required in production)',
      ));
    } else if (hasSantali && !_olChikiPattern.hasMatch(santali)) {
      issues.add(FlashcardValidationIssue(
        card.id,
        'Santali word does not contain Ol Chiki script characters',
      ));
    }

    final descSantali = card.description?.santali;
    if (card.description != null &&
        strict &&
        (descSantali == null || descSantali.trim().isEmpty)) {
      issues.add(FlashcardValidationIssue(
        card.id,
        'Missing Santali description (required in production when a '
            'description is present)',
      ));
    }

    // Broken/missing local image asset. A card that declares an image
    // asset path must actually have that asset bundled — a missing image
    // for a card that requires one is a hard failure in production, never
    // a silent substitution (spec section 16). Cards with no imageAsset at
    // all are treated as "image optional" and are not flagged.
    if (card.imageAsset != null) {
      final exists = await _assetExists(card.imageAsset!);
      if (!exists) {
        issues.add(FlashcardValidationIssue(
          card.id,
          'Referenced image asset "${card.imageAsset}" does not exist in '
              'the bundle',
        ));
      }
    }

    return issues;
  }

  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }
}
