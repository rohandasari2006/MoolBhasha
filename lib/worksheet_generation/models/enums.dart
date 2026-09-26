/// Grade stages.
enum Grade {
  balvatika,
  grade1,
  grade2,
  grade3;

  String get assetKey => switch (this) {
    Grade.balvatika => 'balvatika',
    Grade.grade1 => 'grade_1',
    Grade.grade2 => 'grade_2',
    Grade.grade3 => 'grade_3',
  };

  String get label => switch (this) {
    Grade.balvatika => 'Balvatika',
    Grade.grade1 => 'Grade 1',
    Grade.grade2 => 'Grade 2',
    Grade.grade3 => 'Grade 3',
  };

  static Grade fromAssetKey(String key) =>
      Grade.values.firstWhere((g) => g.assetKey == key);
}

enum WorksheetType {
  practice,
  revision,
  assessment,
  homework,
  activity;

  String get assetKey => name;

  String get label => switch (this) {
    WorksheetType.practice => 'Practice Worksheet',
    WorksheetType.revision => 'Revision Worksheet',
    WorksheetType.assessment => 'Assessment',
    WorksheetType.homework => 'Homework',
    WorksheetType.activity => 'Activity Worksheet',
  };
}

enum QuestionType {
  mcq,
  fillBlank,
  matchFollowing,
  trueFalse,
  shortAnswer,
  mixed;

  String get assetKey => switch (this) {
    QuestionType.mcq => 'mcq',
    QuestionType.fillBlank => 'fill_blank',
    QuestionType.matchFollowing => 'match_following',
    QuestionType.trueFalse => 'true_false',
    QuestionType.shortAnswer => 'short_answer',
    QuestionType.mixed => 'mixed',
  };

  String get label => switch (this) {
    QuestionType.mcq => 'Multiple Choice Questions',
    QuestionType.fillBlank => 'Fill in the Blanks',
    QuestionType.matchFollowing => 'Match the Following',
    QuestionType.trueFalse => 'True / False',
    QuestionType.shortAnswer => 'Short Answer',
    QuestionType.mixed => 'Mixed Questions',
  };

  /// Concrete question types used by Mixed Questions.
  static const List<QuestionType> leafTypes = [
    QuestionType.mcq,
    QuestionType.fillBlank,
    QuestionType.matchFollowing,
    QuestionType.trueFalse,
    QuestionType.shortAnswer,
  ];
}

enum Domain {
  literacy,
  numeracy;

  String get assetKey => name;
}

const List<int> kAllowedQuestionCounts = [
  5,
  10,
  15,
  20,
  25,
  30,
];

const String kSourceLang = 'hin_Deva';
const String kTargetLang = 'sat_Olck';