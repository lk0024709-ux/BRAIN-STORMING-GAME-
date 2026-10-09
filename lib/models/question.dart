import 'age_band.dart';

enum QuestionKind { arithmetic, bodmas, series, decimal }

extension QuestionKindCopy on QuestionKind {
  String get cloudLabel => switch (this) {
        QuestionKind.arithmetic => 'SOLVE',
        QuestionKind.bodmas => 'BODMAS',
        QuestionKind.series => 'NEXT NUMBER',
        QuestionKind.decimal => 'DECIMALS',
      };
}

class GeneratedQuestion {
  const GeneratedQuestion({
    required this.display,
    required this.options,
    required this.correctIndex,
    required this.formattedAnswer,
    required this.hint,
    required this.kind,
    required this.band,
  });

  final String display;
  final List<String> options;
  final int correctIndex;
  final String formattedAnswer;
  final String hint;
  final QuestionKind kind;
  final AgeBand band;

  String get correctOption => options[correctIndex];
}
