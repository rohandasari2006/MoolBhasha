import 'enums.dart';

/// A data-driven template loaded from assets/templates/*.json.
/// `templateHi` uses {{placeholder}} tokens filled from a ContentConcept
/// (via `answerSource`) by the QuestionTemplateEngine.
class QuestionTemplateModel {
  final String templateId;
  final QuestionType type;
  final List<Grade> grades;
  final List<Domain> domains;
  final String templateHi;
  final String answerSource; // e.g. "content_bank"

  const QuestionTemplateModel({
    required this.templateId,
    required this.type,
    required this.grades,
    required this.domains,
    required this.templateHi,
    required this.answerSource,
  });

  factory QuestionTemplateModel.fromJson(Map<String, dynamic> json) {
    return QuestionTemplateModel(
      templateId: json['template_id'] as String,
      type: QuestionType.values
          .firstWhere((t) => t.assetKey == json['type'] as String),
      grades: (json['grades'] as List)
          .cast<String>()
          .map(Grade.fromAssetKey)
          .toList(),
      domains: (json['domains'] as List)
          .cast<String>()
          .map((d) => Domain.values.firstWhere((x) => x.assetKey == d))
          .toList(),
      templateHi: json['template_hi'] as String,
      answerSource: json['answer_source'] as String,
    );
  }

  String render(Map<String, String> fillValues) {
    var text = templateHi;
    fillValues.forEach((key, value) {
      text = text.replaceAll('{{$key}}', value);
    });
    return text;
  }
}
