import '../models/enums.dart';
import '../models/question.dart';
import '../models/worksheet.dart';
import '../repositories/nipun_repository.dart';

class ValidationIssue {
  final String questionId;
  final String message;
  const ValidationIssue(this.questionId, this.message);
  @override
  String toString() => '[$questionId] $message';
}

class ValidationResult {
  final bool isValid;
  final List<ValidationIssue> issues;
  const ValidationResult({required this.isValid, required this.issues});
}

/// Matches Ol Chiki Unicode block (U+1C50–U+1C7F).
final _olChikiPattern = RegExp(r'[\u1C50-\u1C7F]');

class WorksheetValidator {
  ValidationResult validateWorksheet(
    Worksheet worksheet, {
    required int expectedQuestionCount,
    required QuestionType expectedQuestionType,
  }) {
    final issues = <ValidationIssue>[];

    if (worksheet.questions.length != expectedQuestionCount) {
      issues.add(ValidationIssue(
        'worksheet',
        'Expected exactly $expectedQuestionCount questions, got '
            '${worksheet.questions.length}',
      ));
    }

    final seenIds = <String>{};
    for (final q in worksheet.questions) {
      if (!seenIds.add(q.id)) {
        issues.add(ValidationIssue(q.id, 'Duplicate question id'));
      }
      if (q.grade != worksheet.grade) {
        issues.add(ValidationIssue(q.id, 'Grade mismatch'));
      }
      if (expectedQuestionType != QuestionType.mixed &&
          q.type != expectedQuestionType) {
        issues.add(ValidationIssue(q.id, 'Question type mismatch'));
      }
      if (q.nipunOutcomeId.isEmpty) {
        issues.add(ValidationIssue(q.id, 'Missing NIPUN outcome reference'));
      }
      issues.addAll(_validateQuestionShape(q));
    }

    // Duplicate content detection (same rendered Hindi question text twice)
    final seenContent = <String>{};
    for (final q in worksheet.questions) {
      final key = _questionContentKey(q);
      if (key != null && !seenContent.add(key)) {
        issues.add(ValidationIssue(q.id, 'Duplicate question content'));
      }
    }

    return ValidationResult(isValid: issues.isEmpty, issues: issues);
  }

  List<ValidationIssue> _validateQuestionShape(Question q) {
    final issues = <ValidationIssue>[];

    if (q is McqQuestion) {
      if (q.options.length < 3) {
        issues.add(ValidationIssue(
          q.id,
          'MCQ has fewer than 3 options (${q.options.length}) — needs 3 or '
              '4 meaningful options',
        ));
      }
      if (!q.options.any((o) => o.id == q.correctOptionId)) {
        issues.add(ValidationIssue(q.id, 'MCQ correct_option not in options'));
      }
      final seenOptionText = <String>{};
      for (final o in q.options) {
        final key = o.text.hindi.trim();
        if (key.isEmpty) {
          issues.add(ValidationIssue(q.id, 'MCQ option ${o.id} is empty'));
        } else if (!seenOptionText.add(key)) {
          issues.add(ValidationIssue(q.id, 'MCQ has duplicate option text'));
        }
        if (_isPlaceholderOption(key)) {
          issues.add(ValidationIssue(
            q.id,
            'MCQ option ${o.id} looks like a placeholder ("$key") rather '
                'than real content',
          ));
        }
      }
    } else if (q is FillBlankQuestion) {
      if (q.answer.hindi.trim().isEmpty) {
        issues.add(ValidationIssue(q.id, 'Fill-blank missing answer'));
      }
      if (!q.question.hindi.contains('____')) {
        issues.add(ValidationIssue(q.id, 'Fill-blank sentence has no blank marker'));
      }
    } else if (q is MatchFollowingQuestion) {
      if (q.left.length < 2 || q.right.length < 2) {
        issues.add(ValidationIssue(
          q.id,
          'Match-following needs at least 2 meaningful pairs',
        ));
      }
      for (final leftItem in q.left) {
        final target = q.answers[leftItem.id];
        if (target == null || !q.right.any((r) => r.id == target)) {
          issues.add(ValidationIssue(q.id, 'Invalid match mapping for ${leftItem.id}'));
        }
      }
      final leftIds = q.left.map((l) => l.id).toSet();
      if (leftIds.length != q.left.length) {
        issues.add(ValidationIssue(q.id, 'Match-following has duplicate left-side IDs'));
      }
      final rightIds = q.right.map((r) => r.id).toSet();
      if (rightIds.length != q.right.length) {
        issues.add(ValidationIssue(q.id, 'Match-following has duplicate right-side IDs'));
      }
      final rightText = q.right.map((r) => r.text.hindi.trim()).toList();
      if (rightText.toSet().length != rightText.length) {
        issues.add(ValidationIssue(
          q.id,
          'Match-following has duplicate/trivial right-side entries',
        ));
      }
    } else if (q is ShortAnswerQuestion) {
      if (q.expectedAnswer.hindi.trim().isEmpty) {
        issues.add(ValidationIssue(q.id, 'Short answer missing expected answer'));
      }
    }
    // TrueFalseQuestion has no extra shape constraints beyond base checks.

    return issues;
  }

  /// Flags generic filler like "विकल्प-2" / "Option 2" that indicates a
  /// template failed to substitute real content bank data (spec section 8).
  final _placeholderOptionPattern =
      RegExp(r'^(विकल्प|option)[\s\-_]*\d*$', caseSensitive: false);

  bool _isPlaceholderOption(String text) =>
      _placeholderOptionPattern.hasMatch(text.trim());

  String? _questionContentKey(Question q) {
    if (q is McqQuestion) return 'mcq:${q.question.hindi}';
    if (q is FillBlankQuestion) return 'fb:${q.question.hindi}';
    if (q is TrueFalseQuestion) return 'tf:${q.statement.hindi}';
    if (q is ShortAnswerQuestion) return 'sa:${q.question.hindi}';
    return null; // match-following pairs vary too much to key simply
  }

  /// Confirms every question's `nipunOutcomeId` actually exists in the local
  /// NIPUN repository and is compatible with that question's grade/domain/
  /// type — not merely non-empty (spec section 10). Async because it reads
  /// the bundled NIPUN dataset.
  Future<ValidationResult> validateNipunReferences(
    Worksheet worksheet,
    NipunRepository nipunRepository,
  ) async {
    final issues = <ValidationIssue>[];
    for (final q in worksheet.questions) {
      final match = await nipunRepository.validateReference(
        outcomeId: q.nipunOutcomeId,
        grade: q.grade,
        domain: q.domain,
        questionType: q.type,
      );
      if (match == null) {
        issues.add(ValidationIssue(
          q.id,
          'NIPUN outcome "${q.nipunOutcomeId}" does not exist in the local '
              'repository, or is not compatible with this question\'s grade/'
              'domain/type',
        ));
      } else if (match.isInternalId && !match.isOfficialVerified) {
        // Not an error — internal ids are a legitimate placeholder scheme —
        // but the worksheet's NIPUN summary must never claim this is an
        // official government-verified outcome.
      }
    }
    return ValidationResult(isValid: issues.isEmpty, issues: issues);
  }

  /// Bilingual consistency checks (spec section 34). Only meaningful once
  /// translation has been attempted — call after the translation pass.
  ValidationResult validateBilingualConsistency(Worksheet worksheet) {
    final issues = <ValidationIssue>[];

    for (final q in worksheet.questions) {
      if (!q.isFullyTranslated) {
        issues.add(ValidationIssue(q.id, 'Missing Santali translation for one or more fields'));
        continue;
      }

      if (q is McqQuestion) {
        for (final o in q.options) {
          _checkScript(issues, q.id, o.text.santali);
        }
        if (!q.options.any((o) => o.id == q.correctOptionId)) {
          issues.add(ValidationIssue(q.id, 'correct_option id lost after translation'));
        }
      } else if (q is MatchFollowingQuestion) {
        for (final leftItem in q.left) {
          _checkScript(issues, q.id, leftItem.text.santali);
        }
        for (final rightItem in q.right) {
          _checkScript(issues, q.id, rightItem.text.santali);
        }
        for (final leftItem in q.left) {
          final target = q.answers[leftItem.id];
          if (target == null || !q.right.any((r) => r.id == target)) {
            issues.add(ValidationIssue(q.id, 'Answer mapping changed after translation'));
          }
        }
      } else if (q is FillBlankQuestion) {
        _checkScript(issues, q.id, q.answer.santali);
      } else if (q is TrueFalseQuestion) {
        _checkScript(issues, q.id, q.statement.santali);
      } else if (q is ShortAnswerQuestion) {
        _checkScript(issues, q.id, q.expectedAnswer.santali);
      }
    }

    return ValidationResult(isValid: issues.isEmpty, issues: issues);
  }

  void _checkScript(List<ValidationIssue> issues, String questionId, String? santali) {
    if (santali == null || santali.trim().isEmpty) {
      issues.add(ValidationIssue(questionId, 'Empty Santali field'));
      return;
    }
    if (!_olChikiPattern.hasMatch(santali)) {
      issues.add(ValidationIssue(
        questionId,
        'Santali field does not contain Ol Chiki script characters',
      ));
    }
    if (santali.contains('{{') || santali.contains('}}')) {
      issues.add(ValidationIssue(questionId, 'Untranslated placeholder remains'));
    }
  }
}
