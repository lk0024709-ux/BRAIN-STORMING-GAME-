import 'age_band.dart';

enum MathLevelTopic {
  addition,
  subtraction,
  mixedArithmetic,
  multiplication,
  bodmas,
  numberSeries,
  mixedTeen,
  complexBodmas,
  advancedSeries,
  decimals,
  mixedAdult,
}

/// A procedural quiz stage. The first 120 levels are four age-specific chapters;
/// later stages continue in a progressively harder master loop.
class MathLevelInfo {
  const MathLevelInfo({
    required this.number,
    required this.band,
    required this.topic,
    required this.title,
    required this.difficulty,
    required this.chapter,
  });

  static const int campaignLength = 120;
  static const int levelsPerChapter = 30;

  final int number;
  final AgeBand band;
  final MathLevelTopic topic;
  final String title;
  final int difficulty;
  final int chapter;

  String get levelLabel => number <= campaignLength
      ? 'LEVEL $number / $campaignLength'
      : 'MASTER LEVEL $number';

  factory MathLevelInfo.forAge(int age, int number) {
    final safeNumber = number < 1 ? 1 : number;
    final safeAge = age.clamp(6, 60).toInt();
    final band = ageBandFor(safeAge);
    final cycleLevel = ((safeNumber - 1) % campaignLength) + 1;
    final cycle = (safeNumber - 1) ~/ campaignLength;
    final chapter = (cycleLevel - 1) ~/ levelsPerChapter;
    final chapterLevel = ((cycleLevel - 1) % levelsPerChapter) + 1;
    final difficulty =
        (1 + (chapterLevel - 1) ~/ 3 + cycle * 10).clamp(1, 18).toInt();

    final (topic, title) = switch (band) {
      AgeBand.kids => switch (chapter) {
          0 => (MathLevelTopic.addition, 'Addition Foundations'),
          1 => (MathLevelTopic.subtraction, 'Subtraction Mission'),
          2 => (MathLevelTopic.mixedArithmetic, 'Mixed Add & Subtract'),
          _ => (MathLevelTopic.mixedArithmetic, 'Arithmetic Mastery'),
        },
      AgeBand.teens => switch (chapter) {
          0 => (MathLevelTopic.multiplication, 'Multiplication Challenge'),
          1 => (MathLevelTopic.bodmas, 'BODMAS & Brackets'),
          2 => (MathLevelTopic.numberSeries, 'Number Patterns'),
          _ => (MathLevelTopic.mixedTeen, 'Mixed Math Mastery'),
        },
      AgeBand.adults => switch (chapter) {
          0 => (MathLevelTopic.complexBodmas, 'Advanced BODMAS'),
          1 => (MathLevelTopic.advancedSeries, 'Advanced Sequences'),
          2 => (MathLevelTopic.decimals, 'Decimal Operations'),
          _ => (MathLevelTopic.mixedAdult, 'Mixed Math Mastery'),
        },
    };

    return MathLevelInfo(
      number: safeNumber,
      band: band,
      topic: topic,
      title: title,
      difficulty: difficulty,
      chapter: chapter + 1 + cycle * 4,
    );
  }
}
