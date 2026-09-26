import 'dart:math';

import '../models/bilingual_text.dart';
import '../models/content_concept.dart';
import '../models/enums.dart';
import '../models/nipun_outcome.dart';
import '../models/question.dart';
import '../models/question_template.dart';

/// Turns a (template, content concept, distractor pool) tuple into a
/// concrete [Question] instance, in Hindi only — translation happens in a
/// later pipeline stage. Selection is deterministic: given the same inputs
/// in the same order, the same question is produced every time (spec
/// section 11: "Do NOT use uncontrolled random selection").
class QuestionTemplateEngine {
  /// Seeded RNG used ONLY for stable, reproducible distractor ordering —
  /// not for choosing *which* content is used.
  final Random _rng;

  QuestionTemplateEngine({int seed = 42}) : _rng = Random(seed);

  Question build({
    required String questionId,
    required QuestionTemplateModel template,
    required NipunOutcome outcome,
    required ContentConcept concept,
    required List<ContentConcept> distractorPool,
    WorksheetType worksheetType = WorksheetType.practice,
  }) {
    switch (template.type) {
      case QuestionType.mcq:
        return _buildMcq(
            questionId, template, outcome, concept, distractorPool, worksheetType);
      case QuestionType.fillBlank:
        return _buildFillBlank(questionId, template, outcome, concept, worksheetType);
      case QuestionType.matchFollowing:
        return _buildMatchFollowing(
            questionId, template, outcome, concept, distractorPool, worksheetType);
      case QuestionType.trueFalse:
        return _buildTrueFalse(
            questionId, template, outcome, concept, distractorPool, worksheetType);
      case QuestionType.shortAnswer:
        return _buildShortAnswer(questionId, template, outcome, concept, worksheetType);
      case QuestionType.mixed:
        throw ArgumentError('Mixed is a distribution strategy, not a leaf type');
      case QuestionType.mcq:
        // TODO: Handle this case.
        throw UnimplementedError();
      case QuestionType.fillBlank:
        // TODO: Handle this case.
        throw UnimplementedError();
      case QuestionType.matchFollowing:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  /// Worksheet-type-driven instruction phrasing (spec section 13). The
  /// underlying question/content selection is identical across types — the
  /// starter template/content-bank schema carries no per-item difficulty or
  /// hint metadata to branch on yet — but the instruction line's scaffolding
  /// level genuinely changes per type, which is the part of section 13 that
  /// is achievable without inventing new content data:
  ///   practice/homework  -> guided, reassuring phrasing ("try it, it's ok
  ///                         to think it through")
  ///   revision            -> explicit recall framing ("remember what you
  ///                         learned")
  ///   assessment          -> plain, unscaffolded instruction, no hints
  ///   activity            -> activity-style framing for match/sort items
  String _scaffold(String baseHindi, WorksheetType worksheetType) {
    switch (worksheetType) {
      case WorksheetType.practice:
        return '$baseHindi (सोचिए और कोशिश कीजिए)';
      case WorksheetType.homework:
        return '$baseHindi (घर पर स्वयं करें)';
      case WorksheetType.revision:
        return '$baseHindi (जो सीखा है उसे याद कीजिए)';
      case WorksheetType.assessment:
        return baseHindi; // no scaffolding hint — independent response
      case WorksheetType.activity:
        return '$baseHindi (गतिविधि)';
    }
  }

  McqQuestion _buildMcq(
    String id,
    QuestionTemplateModel template,
    NipunOutcome outcome,
    ContentConcept concept,
    List<ContentConcept> distractorPool,
    WorksheetType worksheetType,
  ) {
    final distractors = _pickDistractors(concept, distractorPool, count: 3);
    final allOptions = [concept, ...distractors];
    // Deterministic shuffle: sort by concept id hash mixed with a fixed
    // seed so the correct answer position varies across questions but is
    // reproducible.
    allOptions.shuffle(_rng);

    final options = <QuestionOption>[];
    String correctId = 'A';
    for (var i = 0; i < allOptions.length; i++) {
      final optId = String.fromCharCode('A'.codeUnitAt(0) + i);
      options.add(QuestionOption(
        id: optId,
        text: BilingualText(hindi: allOptions[i].hindiWord),
      ));
      if (allOptions[i].conceptId == concept.conceptId) correctId = optId;
    }

    return McqQuestion(
      id: id,
      grade: outcome.grade,
      domain: outcome.domain,
      nipunOutcomeId: outcome.id,
      competency: outcome.competency,
      learningOutcome: outcome.learningOutcome,
      instruction:
          BilingualText(hindi: _scaffold('सही उत्तर चुनिए।', worksheetType)),
      question: BilingualText(hindi: template.render({
        'sentence': concept.hindiSentence ?? concept.hindiWord,
      })),
      options: options,
      correctOptionId: correctId,
    );
  }

  FillBlankQuestion _buildFillBlank(
    String id,
    QuestionTemplateModel template,
    NipunOutcome outcome,
    ContentConcept concept,
    WorksheetType worksheetType,
  ) {
    final sentence = concept.hindiSentence ?? concept.hindiWord;
    final blanked = _blankOutWord(sentence, concept.hindiWord);
    return FillBlankQuestion(
      id: id,
      grade: outcome.grade,
      domain: outcome.domain,
      nipunOutcomeId: outcome.id,
      competency: outcome.competency,
      learningOutcome: outcome.learningOutcome,
      instruction: BilingualText(
          hindi: _scaffold('खाली जगह में सही शब्द भरिए।', worksheetType)),
      question: BilingualText(hindi: blanked),
      answer: BilingualText(hindi: concept.hindiWord),
    );
  }

  MatchFollowingQuestion _buildMatchFollowing(
    String id,
    QuestionTemplateModel template,
    NipunOutcome outcome,
    ContentConcept concept,
    List<ContentConcept> distractorPool,
    WorksheetType worksheetType,
  ) {
    final companions = _pickDistractors(concept, distractorPool, count: 3);
    final all = [concept, ...companions];

    final left = <MatchItem>[];
    final right = <MatchItem>[];
    final answers = <String, String>{};

    final rightOrder = List<int>.generate(all.length, (i) => i)..shuffle(_rng);

    for (var i = 0; i < all.length; i++) {
      final leftId = String.fromCharCode('A'.codeUnitAt(0) + i);
      left.add(MatchItem(id: leftId, text: BilingualText(hindi: all[i].hindiWord)));
    }
    for (var i = 0; i < all.length; i++) {
      final rightId = '${i + 1}';
      right.add(MatchItem(
        id: rightId,
        text: BilingualText(hindi: all[rightOrder[i]].hindiSentence ?? all[rightOrder[i]].hindiWord),
      ));
      final matchingLeftIndex = rightOrder[i];
      final leftId = String.fromCharCode('A'.codeUnitAt(0) + matchingLeftIndex);
      answers[leftId] = rightId;
    }

    final baseInstruction = worksheetType == WorksheetType.activity
        ? 'सही जोड़ी मिलाइए — यह एक गतिविधि है, चित्र/शब्द जोड़िए।'
        : template.render(const {});

    return MatchFollowingQuestion(
      id: id,
      grade: outcome.grade,
      domain: outcome.domain,
      nipunOutcomeId: outcome.id,
      competency: outcome.competency,
      learningOutcome: outcome.learningOutcome,
      instruction: BilingualText(hindi: _scaffold(baseInstruction, worksheetType)),
      left: left,
      right: right,
      answers: answers,
    );
  }

  /// Builds a True/False question. Content-bank sentences are authored to
  /// be factually true, so a "true" statement is just the sentence
  /// rendered as-is. A "false" statement is produced by a *controlled*
  /// transformation — substituting the concept's own subject word for a
  /// different concept's subject word inside the same sentence template —
  /// never by hard-coding `answer: true` for every card (spec section 8).
  ///
  /// Whether a given slot renders true or false is derived deterministically
  /// from the trailing digits of [id] (e.g. "q007" -> 7), so the same slot
  /// always produces the same polarity, and true/false statements alternate
  /// across a worksheet rather than the worksheet being all-true.
  ///
  /// A false variant is only produced when there is a distractor available
  /// AND the concept has a sentence containing its own word to substitute
  /// into (otherwise producing a "false" statement would be ambiguous or
  /// nonsensical, which spec section 8 also forbids) — in that situation we
  /// fall back to the true statement rather than fabricate a bad false one.
  TrueFalseQuestion _buildTrueFalse(
    String id,
    QuestionTemplateModel template,
    NipunOutcome outcome,
    ContentConcept concept,
    List<ContentConcept> distractorPool,
    WorksheetType worksheetType,
  ) {
    final trueSentence = concept.hindiSentence ?? concept.hindiWord;
    final wantsFalse = _idParity(id) == 1;

    var statementSentence = trueSentence;
    var answer = true;

    if (wantsFalse) {
      final falseCandidate = _buildFalseStatement(concept, trueSentence, distractorPool);
      if (falseCandidate != null) {
        statementSentence = falseCandidate;
        answer = false;
      }
      // else: no safe false transformation available for this concept —
      // keep the true statement (better than an ambiguous false one).
    }

    return TrueFalseQuestion(
      id: id,
      grade: outcome.grade,
      domain: outcome.domain,
      nipunOutcomeId: outcome.id,
      competency: outcome.competency,
      learningOutcome: outcome.learningOutcome,
      instruction:
          BilingualText(hindi: _scaffold('सही या गलत लिखिए।', worksheetType)),
      statement:
          BilingualText(hindi: template.render({'sentence': statementSentence})),
      answer: answer,
    );
  }

  /// Extracts the trailing run of digits from a question id like "q007" and
  /// returns it mod 2, so polarity is stable for a given slot/id but
  /// alternates across the worksheet. Defaults to 0 (true) if no digits.
  int _idParity(String id) {
    final match = RegExp(r'(\d+)$').firstMatch(id);
    if (match == null) return 0;
    final n = int.tryParse(match.group(1)!) ?? 0;
    return n % 2;
  }

  /// Produces a controlled false statement by swapping [concept]'s own word
  /// for a distractor's word inside the true sentence — e.g.
  /// "गाय दूध देती है।" (true) -> "कुत्ता दूध देती है।" (false). Prefers a
  /// same-category distractor so the swap stays grammatically plausible.
  /// Returns null if no sentence/word substitution is possible.
  String? _buildFalseStatement(
    ContentConcept concept,
    String trueSentence,
    List<ContentConcept> distractorPool,
  ) {
    if (!trueSentence.contains(concept.hindiWord)) return null;

    final others = distractorPool
        .where((c) => c.conceptId != concept.conceptId)
        .toList();
    if (others.isEmpty) return null;

    final sameCategory = others.where((c) => c.category == concept.category).toList();
    final pool = sameCategory.isNotEmpty ? sameCategory : others;
    // Deterministic pick — same concept always swaps with the same
    // distractor, so output stays reproducible.
    final replacement = pool[concept.conceptId.hashCode.abs() % pool.length];
    if (replacement.hindiWord == concept.hindiWord) return null;

    return trueSentence.replaceFirst(concept.hindiWord, replacement.hindiWord);
  }

  ShortAnswerQuestion _buildShortAnswer(
    String id,
    QuestionTemplateModel template,
    NipunOutcome outcome,
    ContentConcept concept,
    WorksheetType worksheetType,
  ) {
    final isNumeric = concept.extra != null && concept.extra!.containsKey('result');
    final questionText = template.render({
      'sentence': concept.hindiSentence ?? concept.hindiWord,
    });
    final answer = isNumeric
        ? '${concept.extra!['result']}'
        : concept.hindiWord;

    return ShortAnswerQuestion(
      id: id,
      grade: outcome.grade,
      domain: outcome.domain,
      nipunOutcomeId: outcome.id,
      competency: outcome.competency,
      learningOutcome: outcome.learningOutcome,
      instruction:
          BilingualText(hindi: _scaffold('संक्षेप में उत्तर दीजिए।', worksheetType)),
      question: BilingualText(hindi: questionText),
      expectedAnswer: BilingualText(hindi: answer),
    );
  }

  List<ContentConcept> _pickDistractors(
    ContentConcept correct,
    List<ContentConcept> pool,
    {required int count}
  ) {
    final others = pool.where((c) => c.conceptId != correct.conceptId).toList()
      ..shuffle(_rng);
    if (others.length >= count) return others.take(count).toList();
    // Not enough distractors in the pool — return what's available rather
    // than crashing; validator will flag if this drops below usable count.
    return others;
  }

  String _blankOutWord(String sentence, String word) {
    if (!sentence.contains(word)) return '$sentence ____';
    return sentence.replaceFirst(word, '____');
  }
}
