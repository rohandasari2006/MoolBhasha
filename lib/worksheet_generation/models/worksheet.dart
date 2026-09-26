import 'enums.dart';
import 'question.dart';

class WorksheetSource {
  final String type; // "nipun_only" | "nipun_plus_pdf"
  final String? documentName;
  const WorksheetSource({required this.type, this.documentName});

  Map<String, dynamic> toJson() => {
        'type': type,
        if (documentName != null) 'document_name': documentName,
      };
}

class WorksheetNipunSummary {
  final Domain domain;
  final List<String> competencies;
  final List<String> learningOutcomeIds;
  const WorksheetNipunSummary({
    required this.domain,
    required this.competencies,
    required this.learningOutcomeIds,
  });

  Map<String, dynamic> toJson() => {
        'domain': domain.assetKey,
        'competency': competencies.join('; '),
        'learning_outcomes': learningOutcomeIds,
      };
}

/// Final assembled worksheet — matches the schema in spec section 49.
class Worksheet {
  final String worksheetId;
  final Grade grade;
  final WorksheetType worksheetType;
  final QuestionType questionType;
  final WorksheetSource source;
  final WorksheetNipunSummary nipun;
  final List<Question> questions;

  const Worksheet({
    required this.worksheetId,
    required this.grade,
    required this.worksheetType,
    required this.questionType,
    required this.source,
    required this.nipun,
    required this.questions,
  });

  bool get isFullyTranslated => questions.every((q) => q.isFullyTranslated);

  Map<String, dynamic> toJson() => {
        'worksheet_id': worksheetId,
        'grade': grade.assetKey,
        'worksheet_type': worksheetType.assetKey,
        'question_type': questionType.assetKey,
        'language_pair': {'source': kSourceLang, 'target': kTargetLang},
        'source': source.toJson(),
        'nipun': nipun.toJson(),
        'questions': questions.map((q) => q.toJson()).toList(),
      };
}
