import '../models/content_concept.dart';
import '../models/enums.dart';
import '../models/nipun_outcome.dart';
import '../models/question.dart';
import '../models/question_template.dart';
import '../repositories/content_bank_repository.dart';
import '../repositories/nipun_repository.dart';
import '../repositories/template_repository.dart';
import 'pdf_processor.dart';
import 'question_template_engine.dart';

/// One planned slot: which leaf question type to produce and which NIPUN
/// outcome it should be aligned to. The planner resolves the full list of
/// slots up front so the exact requested count is always honored (spec
/// section 9 — "Never 9. Never 11.").
class PlannedQuestionSlot {
  final QuestionType leafType;
  final Domain domain;
  const PlannedQuestionSlot({required this.leafType, required this.domain});
}

class QuestionPlan {
  final Grade grade;
  final WorksheetType worksheetType;
  final List<PlannedQuestionSlot> slots;
  final List<NipunOutcome> outcomes;
  final PdfProcessingResult? pdfResult;

  /// The extracted PDF topics/concepts that produced [outcomes] and that
  /// must also constrain content-bank selection in [realizeSlot] — the
  /// planner previously computed this correctly but then discarded it
  /// before content selection, which was the root cause of PDF topics
  /// being ignored during generation (spec section 4).
  final List<String> topics;

  const QuestionPlan({
    required this.grade,
    required this.worksheetType,
    required this.slots,
    required this.outcomes,
    this.pdfResult,
    this.topics = const [],
  });
}

class QuestionPlanner {
  final NipunRepository nipunRepository;
  final ContentBankRepository contentBankRepository;
  final TemplateRepository templateRepository;
  final QuestionTemplateEngine templateEngine;

  QuestionPlanner({
    required this.nipunRepository,
    required this.contentBankRepository,
    required this.templateRepository,
    QuestionTemplateEngine? templateEngine,
  }) : templateEngine = templateEngine ?? QuestionTemplateEngine();

  /// Step 1-5 of spec section 32: resolve grade, NIPUN outcomes, PDF topics,
  /// match them, and build the exact-count question plan.
  Future<QuestionPlan> plan({
    required Grade grade,
    required WorksheetType worksheetType,
    required QuestionType requestedType,
    required int questionCount,
    PdfProcessingResult? pdfResult,
  }) async {
    assert(kAllowedQuestionCounts.contains(questionCount));

    final topics = pdfResult?.topics ?? const <String>[];
    final outcomes = await nipunRepository.matchTopics(grade, topics);

    final slots = _buildSlots(requestedType, questionCount, outcomes);

    return QuestionPlan(
      grade: grade,
      worksheetType: worksheetType,
      slots: slots,
      outcomes: outcomes,
      pdfResult: pdfResult,
      topics: topics,
    );
  }

  /// Deterministic slot distribution. For Mixed, round-robins the five leaf
  /// types so counts are as even as possible (spec section 11). Domain per
  /// slot alternates between literacy/numeracy based on which domains have
  /// outcomes available, also deterministically.
  List<PlannedQuestionSlot> _buildSlots(
    QuestionType requestedType,
    int count,
    List<NipunOutcome> outcomes,
  ) {
    final availableDomains = outcomes.map((o) => o.domain).toSet().toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final domains = availableDomains.isNotEmpty
        ? availableDomains
        : [Domain.literacy, Domain.numeracy];

    final leafTypes = requestedType == QuestionType.mixed
        ? QuestionType.leafTypes
        : [requestedType];

    final slots = <PlannedQuestionSlot>[];
    for (var i = 0; i < count; i++) {
      final leaf = leafTypes[i % leafTypes.length];
      final domain = domains[i % domains.length];
      slots.add(PlannedQuestionSlot(leafType: leaf, domain: domain));
    }
    return slots;
  }

  /// Realizes a single planned slot into a concrete Question, selecting a
  /// NIPUN outcome, a template, and content-bank concepts deterministically
  /// by index so the same plan always produces the same worksheet.
  Future<Question?> realizeSlot({
    required PlannedQuestionSlot slot,
    required int slotIndex,
    required String questionId,
    required List<NipunOutcome> candidateOutcomes,
    List<String> topics = const [],
    WorksheetType worksheetType = WorksheetType.practice,
  }) async {
    final outcomesForDomain = candidateOutcomes
        .where((o) =>
            o.domain == slot.domain &&
            o.allowedQuestionTypes.contains(slot.leafType))
        .toList();
    if (outcomesForDomain.isEmpty) return null;
    final outcome = outcomesForDomain[slotIndex % outcomesForDomain.length];

    final templates = await templateRepository.templatesFor(
      grade: outcome.grade,
      domain: outcome.domain,
      type: slot.leafType,
    );
    if (templates.isEmpty) return null;
    final template = templates[slotIndex % templates.length];

    final concepts = await contentBankRepository.conceptsMatchingTopics(
      grade: outcome.grade,
      domain: outcome.domain,
      topics: topics,
    );
    if (concepts.isEmpty) return null;
    final concept = concepts[slotIndex % concepts.length];

    return templateEngine.build(
      questionId: questionId,
      template: template,
      outcome: outcome,
      concept: concept,
      distractorPool: concepts,
      worksheetType: worksheetType,
    );
  }
}
