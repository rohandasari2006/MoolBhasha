import 'package:uuid/uuid.dart';

import '../models/enums.dart';
import '../models/question.dart';
import '../models/worksheet.dart';
import 'pdf_processor.dart';
import 'question_planner.dart';
import 'translation_provider.dart';
import 'worksheet_validator.dart';

/// Result of the Santali translation step.
///
/// success     = every generated question was translated.
/// unavailable = the translation model could not be loaded.
/// partial     = some questions/fields were translated but some failed.
enum TranslationOutcome {
  success,
  unavailable,
  partial,
}

/// Final result returned by WorksheetBuilder.
class WorksheetGenerationResult {
  final Worksheet worksheet;
  final TranslationOutcome translationOutcome;
  final List<ValidationIssue> issues;

  const WorksheetGenerationResult({
    required this.worksheet,
    required this.translationOutcome,
    required this.issues,
  });

  bool get isBilingualComplete =>
      translationOutcome == TranslationOutcome.success;
}

/// ===============================================================
/// WORKSHEET BUILDER
/// ===============================================================
///
/// Pipeline:
///
/// PDF
///  ↓
/// PDF text/content extraction
///  ↓
/// Question planning
///  ↓
/// Hindi question generation
///  ↓
/// Hindi worksheet created
///  ↓
/// Hindi → Santali translation
///  ↓
/// Bilingual Hindi + Santali worksheet
///  ↓
/// Validation
///
/// IMPORTANT:
/// The uploaded PDF is NEVER translated into Santali.
///
/// Only the generated worksheet content is translated.
/// ===============================================================

class WorksheetBuilder {
  final QuestionPlanner planner;
  final TranslationProvider translationProvider;
  final WorksheetValidator validator;

  final Uuid _uuid = const Uuid();

  WorksheetBuilder({
    required this.planner,
    required this.translationProvider,
    WorksheetValidator? validator,
  }) : validator = validator ?? WorksheetValidator();

  /// Generates a worksheet from the supplied form and PDF content.
  ///
  /// The order is intentionally:
  ///
  /// 1. Extract PDF information
  /// 2. Generate Hindi questions
  /// 3. Translate generated questions to Santali
  /// 4. Create bilingual worksheet
  /// 5. Validate worksheet
  Future<WorksheetGenerationResult> generate({
    required Grade grade,
    required WorksheetType worksheetType,
    required QuestionType requestedType,
    required int questionCount,
    PdfProcessingResult? pdfResult,
    int maxRetriesPerSlot = 3,
  }) async {
    assert(kAllowedQuestionCounts.contains(questionCount));

    // =============================================================
    // STEP 1: PLAN QUESTIONS
    // =============================================================
    //
    // pdfResult is only used as source material.
    // Nothing is translated here.
    //
    final plan = await planner.plan(
      grade: grade,
      worksheetType: worksheetType,
      requestedType: requestedType,
      questionCount: questionCount,
      pdfResult: pdfResult,
    );

    // =============================================================
    // STEP 2: GENERATE HINDI QUESTIONS
    // =============================================================
    //
    // At this stage all questions are Hindi-only.
    //
    final questions = <Question>[];

    for (var i = 0; i < plan.slots.length; i++) {
      Question? question;

      for (
      var attempt = 0;
      attempt < maxRetriesPerSlot && question == null;
      attempt++
      ) {
        final candidateIndex =
            i + attempt * plan.slots.length;

        question = await planner.realizeSlot(
          slot: plan.slots[i],
          slotIndex: candidateIndex,
          questionId:
          'q${(i + 1).toString().padLeft(3, '0')}',
          candidateOutcomes: plan.outcomes,
          topics: plan.topics,
          worksheetType: plan.worksheetType,
        );
      }

      if (question != null) {
        questions.add(question);
      }
    }

    // =============================================================
    // STEP 3: TOP UP IF NECESSARY
    // =============================================================

    final topUp = await _topUpToExactCount(
      current: questions,
      targetCount: questionCount,
      plan: plan,
      requestedType: requestedType,
    );

    questions
      ..clear()
      ..addAll(topUp);

    // =============================================================
    // STEP 4: TRANSLATE GENERATED QUESTIONS
    // =============================================================
    //
    // IMPORTANT:
    //
    // We DO NOT translate pdfResult.
    //
    // We translate only:
    //
    //   Hindi instruction
    //   Hindi question
    //   Hindi options
    //   Hindi answers
    //   Hindi match items
    //
    final translationOutcome =
    await _translate(questions);

    // =============================================================
    // STEP 5: CREATE FINAL BILINGUAL WORKSHEET
    // =============================================================

    final worksheet = Worksheet(
      worksheetId: _uuid.v4(),
      grade: grade,
      worksheetType: worksheetType,
      questionType: requestedType,

      source: WorksheetSource(
        type: pdfResult != null
            ? 'nipun_plus_pdf'
            : 'nipun_only',
        documentName:
        pdfResult?.documentName,
      ),

      nipun: WorksheetNipunSummary(
        domain: plan.outcomes.isNotEmpty
            ? plan.outcomes.first.domain
            : Domain.literacy,

        competencies: plan.outcomes
            .map((o) => o.competency)
            .toSet()
            .toList(),

        learningOutcomeIds:
        plan.outcomes.map((o) => o.id).toList(),
      ),

      questions: questions,
    );

    // =============================================================
    // STEP 6: VALIDATE STRUCTURE
    // =============================================================

    final structuralResult =
    validator.validateWorksheet(
      worksheet,
      expectedQuestionCount: questionCount,
      expectedQuestionType: requestedType,
    );

    final issues = [
      ...structuralResult.issues,
    ];

    // =============================================================
    // STEP 7: VALIDATE NIPUN REFERENCES
    // =============================================================

    final nipunResult =
    await validator.validateNipunReferences(
      worksheet,
      planner.nipunRepository,
    );

    issues.addAll(nipunResult.issues);

    // =============================================================
    // STEP 8: PDF CONTENT WARNING
    // =============================================================

    if (pdfResult != null &&
        plan.topics.isNotEmpty &&
        questions.length < questionCount) {
      issues.add(
        const ValidationIssue(
          'worksheet',
          'PDF topics were extracted but did not match '
              'enough compatible content-bank items for this '
              'grade/domain. The requested question count could '
              'not be fully generated from syllabus-relevant '
              'content alone.',
        ),
      );
    }

    // =============================================================
    // STEP 9: VALIDATE BILINGUAL CONTENT
    // =============================================================

    if (translationOutcome ==
        TranslationOutcome.success) {
      final bilingualResult =
      validator.validateBilingualConsistency(
        worksheet,
      );

      issues.addAll(
        bilingualResult.issues,
      );
    }

    // =============================================================
    // FINAL RESULT
    // =============================================================

    return WorksheetGenerationResult(
      worksheet: worksheet,
      translationOutcome: translationOutcome,
      issues: issues,
    );
  }

  // ===============================================================
  // TOP UP QUESTIONS
  // ===============================================================

  Future<List<Question>> _topUpToExactCount({
    required List<Question> current,
    required int targetCount,
    required QuestionPlan plan,
    required QuestionType requestedType,
  }) async {
    if (current.length >= targetCount) {
      return current
          .take(targetCount)
          .toList();
    }

    final result = [...current];

    var extraIndex = 1000;

    // If user selected Mixed Questions,
    // use all five question types.
    //
    // Otherwise, use ONLY the selected question type.
    final leafTypes =
    requestedType == QuestionType.mixed
        ? QuestionType.leafTypes
        : [requestedType];

    final domains = [
      Domain.literacy,
      Domain.numeracy,
    ];

    while (result.length < targetCount) {
      final leaf =
      leafTypes[
      extraIndex % leafTypes.length];

      final domain =
      domains[
      extraIndex % domains.length];

      final slot = PlannedQuestionSlot(
        leafType: leaf,
        domain: domain,
      );

      final question =
      await planner.realizeSlot(
        slot: slot,
        slotIndex: extraIndex,
        questionId:
        'q${(result.length + 1).toString().padLeft(3, '0')}',
        candidateOutcomes:
        plan.outcomes,
        topics: plan.topics,
        worksheetType:
        plan.worksheetType,
      );

      if (question != null) {
        result.add(question);
      }

      extraIndex++;

      // Safety protection against infinite loops.
      if (extraIndex > 5000) {
        break;
      }
    }

    return result
        .take(targetCount)
        .toList();
  }

  // ===============================================================
  // TRANSLATION
  // ===============================================================
  //
  // IMPORTANT:
  //
  // This method receives GENERATED QUESTIONS.
  //
  // It does NOT receive:
  //
  //   PdfProcessingResult
  //
  // Therefore the PDF is never translated.
  // ===============================================================

  Future<TranslationOutcome> _translate(
      List<Question> questions,
      ) async {
    if (questions.isEmpty) {
      return TranslationOutcome.success;
    }

    // -------------------------------------------------------------
    // Load local Hindi → Santali model
    // -------------------------------------------------------------

    try {
      await translationProvider.ensureLoaded();
    } on TranslationUnavailableException {
      return TranslationOutcome.unavailable;
    }

    var anyFailure = false;

    try {
      // Translate each generated question independently.
      for (final question in questions) {
        try {
          await _translateQuestion(
            question,
          );
        } on TranslationUnavailableException {
          anyFailure = true;
        } catch (_) {
          // A bad individual translation should not crash
          // the complete worksheet generation.
          anyFailure = true;
        }
      }
    } finally {
      // Always release ONNX resources after translation.
      await translationProvider.release();
    }

    if (anyFailure) {
      return TranslationOutcome.partial;
    }

    return TranslationOutcome.success;
  }

  // ===============================================================
  // TRANSLATE ONE GENERATED QUESTION
  // ===============================================================

  Future<void> _translateQuestion(
      Question question,
      ) async {
    // -------------------------------------------------------------
    // Helper for Hindi → Santali
    // -------------------------------------------------------------

    Future<String> translateHindi(
        String hindi,
        ) {
      return translationProvider.translate(
        text: hindi,
        sourceLanguage: kSourceLang,
        targetLanguage: kTargetLang,
      );
    }

    // =============================================================
    // MCQ
    // =============================================================

    if (question is McqQuestion) {
      // Translate instruction.
      final santaliInstruction =
      await translateHindi(
        question.instruction.hindi,
      );

      // Translate question.
      final santaliQuestion =
      await translateHindi(
        question.question.hindi,
      );

      // Translate EVERY option.
      final translatedOptions =
      <QuestionOption>[];

      for (final option
      in question.options) {
        final santaliOption =
        await translateHindi(
          option.text.hindi,
        );

        translatedOptions.add(
          option.withTranslatedText(
            santaliOption,
          ),
        );
      }

      question.applyTranslation(
        instruction:
        question.instruction.withSantali(
          santaliInstruction,
        ),
        question:
        question.question.withSantali(
          santaliQuestion,
        ),
        options: translatedOptions,
      );

      return;
    }

    // =============================================================
    // FILL IN THE BLANK
    // =============================================================

    if (question is FillBlankQuestion) {
      final santaliInstruction =
      await translateHindi(
        question.instruction.hindi,
      );

      final santaliQuestion =
      await translateHindi(
        question.question.hindi,
      );

      final santaliAnswer =
      await translateHindi(
        question.answer.hindi,
      );

      question.applyTranslation(
        instruction:
        question.instruction.withSantali(
          santaliInstruction,
        ),
        question:
        question.question.withSantali(
          santaliQuestion,
        ),
        answer:
        question.answer.withSantali(
          santaliAnswer,
        ),
      );

      return;
    }

    // =============================================================
    // MATCH THE FOLLOWING
    // =============================================================

    if (question is MatchFollowingQuestion) {
      final santaliInstruction =
      await translateHindi(
        question.instruction.hindi,
      );

      final translatedLeft =
      <MatchItem>[];

      for (final item
      in question.left) {
        final santali =
        await translateHindi(
          item.text.hindi,
        );

        translatedLeft.add(
          item.withTranslatedText(
            santali,
          ),
        );
      }

      final translatedRight =
      <MatchItem>[];

      for (final item
      in question.right) {
        final santali =
        await translateHindi(
          item.text.hindi,
        );

        translatedRight.add(
          item.withTranslatedText(
            santali,
          ),
        );
      }

      question.applyTranslation(
        instruction:
        question.instruction.withSantali(
          santaliInstruction,
        ),
        left: translatedLeft,
        right: translatedRight,
      );

      return;
    }

    // =============================================================
    // TRUE / FALSE
    // =============================================================

    if (question is TrueFalseQuestion) {
      final santaliInstruction =
      await translateHindi(
        question.instruction.hindi,
      );

      final santaliStatement =
      await translateHindi(
        question.statement.hindi,
      );

      question.applyTranslation(
        instruction:
        question.instruction.withSantali(
          santaliInstruction,
        ),
        statement:
        question.statement.withSantali(
          santaliStatement,
        ),
      );

      return;
    }

    // =============================================================
    // SHORT ANSWER
    // =============================================================

    if (question is ShortAnswerQuestion) {
      final santaliInstruction =
      await translateHindi(
        question.instruction.hindi,
      );

      final santaliQuestion =
      await translateHindi(
        question.question.hindi,
      );

      final santaliAnswer =
      await translateHindi(
        question.expectedAnswer.hindi,
      );

      question.applyTranslation(
        instruction:
        question.instruction.withSantali(
          santaliInstruction,
        ),
        question:
        question.question.withSantali(
          santaliQuestion,
        ),
        expectedAnswer:
        question.expectedAnswer.withSantali(
          santaliAnswer,
        ),
      );

      return;
    }
  }
}