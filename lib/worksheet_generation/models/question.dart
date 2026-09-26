import 'bilingual_text.dart';
import 'enums.dart';

/// Base fields shared by every question type. Concrete subclasses add
/// type-specific structured content so the template engine, validator and
/// PDF renderer can each work with a strongly-typed shape instead of a
/// loosely-typed map.
///
/// Instances are built once in Hindi by the QuestionTemplateEngine, then
/// each subtype's `applyTranslation(...)` is called exactly once by
/// WorksheetBuilder to fill in the Santali fields. Outside of that single
/// translation step, instances should be treated as read-only.
abstract class Question {
  final String id;
  final QuestionType type;
  final Grade grade;
  final Domain domain;
  final String nipunOutcomeId;
  final String competency;
  final String learningOutcome;
  BilingualText instruction;
  final int marks;

  Question({
    required this.id,
    required this.type,
    required this.grade,
    required this.domain,
    required this.nipunOutcomeId,
    required this.competency,
    required this.learningOutcome,
    required this.instruction,
    this.marks = 1,
  });

  /// True once every bilingual field on this question has Santali content.
  bool get isFullyTranslated;

  Map<String, dynamic> toJson();
}

class QuestionOption {
  final String id; // "A", "B", "C", "D"
  final BilingualText text;

  const QuestionOption({required this.id, required this.text});

  QuestionOption withTranslatedText(String santali) =>
      QuestionOption(id: id, text: text.withSantali(santali));

  Map<String, dynamic> toJson() => {'id': id, ...text.toJson()};
}

class McqQuestion extends Question {
  BilingualText question;
  List<QuestionOption> options;
  final String correctOptionId;

  McqQuestion({
    required super.id,
    required super.grade,
    required super.domain,
    required super.nipunOutcomeId,
    required super.competency,
    required super.learningOutcome,
    required super.instruction,
    required this.question,
    required this.options,
    required this.correctOptionId,
    super.marks,
  }) : super(type: QuestionType.mcq);

  void applyTranslation({
    required BilingualText instruction,
    required BilingualText question,
    required List<QuestionOption> options,
  }) {
    this.instruction = instruction;
    this.question = question;
    this.options = options;
  }

  @override
  bool get isFullyTranslated =>
      instruction.isTranslated &&
      question.isTranslated &&
      options.every((o) => o.text.isTranslated);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.assetKey,
        'instruction': instruction.toJson(),
        'question': question.toJson(),
        'options': options.map((o) => o.toJson()).toList(),
        'correct_option': correctOptionId,
        'marks': marks,
      };
}

class FillBlankQuestion extends Question {
  BilingualText question; // contains a ___ placeholder
  BilingualText answer;

  FillBlankQuestion({
    required super.id,
    required super.grade,
    required super.domain,
    required super.nipunOutcomeId,
    required super.competency,
    required super.learningOutcome,
    required super.instruction,
    required this.question,
    required this.answer,
    super.marks,
  }) : super(type: QuestionType.fillBlank);

  void applyTranslation({
    required BilingualText instruction,
    required BilingualText question,
    required BilingualText answer,
  }) {
    this.instruction = instruction;
    this.question = question;
    this.answer = answer;
  }

  @override
  bool get isFullyTranslated =>
      instruction.isTranslated && question.isTranslated && answer.isTranslated;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.assetKey,
        'instruction': instruction.toJson(),
        'question': question.toJson(),
        'answer': answer.toJson(),
        'marks': marks,
      };
}

class MatchItem {
  final String id;
  final BilingualText text;
  const MatchItem({required this.id, required this.text});

  MatchItem withTranslatedText(String santali) =>
      MatchItem(id: id, text: text.withSantali(santali));

  Map<String, dynamic> toJson() => {'id': id, ...text.toJson()};
}

class MatchFollowingQuestion extends Question {
  List<MatchItem> left;
  List<MatchItem> right;
  final Map<String, String> answers; // left.id -> right.id

  MatchFollowingQuestion({
    required super.id,
    required super.grade,
    required super.domain,
    required super.nipunOutcomeId,
    required super.competency,
    required super.learningOutcome,
    required super.instruction,
    required this.left,
    required this.right,
    required this.answers,
    super.marks,
  }) : super(type: QuestionType.matchFollowing);

  void applyTranslation({
    required BilingualText instruction,
    required List<MatchItem> left,
    required List<MatchItem> right,
  }) {
    this.instruction = instruction;
    this.left = left;
    this.right = right;
  }

  @override
  bool get isFullyTranslated =>
      instruction.isTranslated &&
      left.every((i) => i.text.isTranslated) &&
      right.every((i) => i.text.isTranslated);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.assetKey,
        'instruction': instruction.toJson(),
        'left': left.map((i) => i.toJson()).toList(),
        'right': right.map((i) => i.toJson()).toList(),
        'answers': answers,
        'marks': marks,
      };
}

class TrueFalseQuestion extends Question {
  BilingualText statement;
  final bool answer;

  TrueFalseQuestion({
    required super.id,
    required super.grade,
    required super.domain,
    required super.nipunOutcomeId,
    required super.competency,
    required super.learningOutcome,
    required super.instruction,
    required this.statement,
    required this.answer,
    super.marks,
  }) : super(type: QuestionType.trueFalse);

  void applyTranslation({
    required BilingualText instruction,
    required BilingualText statement,
  }) {
    this.instruction = instruction;
    this.statement = statement;
  }

  @override
  bool get isFullyTranslated =>
      instruction.isTranslated && statement.isTranslated;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.assetKey,
        'instruction': instruction.toJson(),
        'statement': statement.toJson(),
        'answer': answer,
        'marks': marks,
      };
}

class ShortAnswerQuestion extends Question {
  BilingualText question;
  BilingualText expectedAnswer;

  ShortAnswerQuestion({
    required super.id,
    required super.grade,
    required super.domain,
    required super.nipunOutcomeId,
    required super.competency,
    required super.learningOutcome,
    required super.instruction,
    required this.question,
    required this.expectedAnswer,
    super.marks,
  }) : super(type: QuestionType.shortAnswer);

  void applyTranslation({
    required BilingualText instruction,
    required BilingualText question,
    required BilingualText expectedAnswer,
  }) {
    this.instruction = instruction;
    this.question = question;
    this.expectedAnswer = expectedAnswer;
  }

  @override
  bool get isFullyTranslated =>
      instruction.isTranslated &&
      question.isTranslated &&
      expectedAnswer.isTranslated;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.assetKey,
        'instruction': instruction.toJson(),
        'question': question.toJson(),
        'answer': expectedAnswer.toJson(),
        'marks': marks,
      };
}
