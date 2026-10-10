import 'dart:math';

import 'package:brain_speed_iq/config/app_config.dart';
import 'package:brain_speed_iq/models/age_band.dart';
import 'package:brain_speed_iq/models/math_level.dart';
import 'package:brain_speed_iq/models/question.dart';
import 'package:brain_speed_iq/services/question_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every age band builds four unique choices with a real answer', () {
    const ages = [6, 7, 9, 10, 12, 13, 16, 17, 18, 28, 60];
    for (final age in ages) {
      final generator = QuestionGenerator(random: Random(age * 91));
      for (var i = 0; i < 80; i++) {
        final question = generator.generate(age);
        expect(question.options, hasLength(4));
        expect(question.options.toSet(), hasLength(4));
        expect(question.correctIndex, inInclusiveRange(0, 3));
        expect(question.correctOption, question.formattedAnswer);
        expect(question.hint.trim(), isNotEmpty);
        expect(question.display.trim(), isNotEmpty);
        expect(question.band, ageBandFor(age));
        if (age < 13) {
          expect(question.kind, QuestionKind.arithmetic);
          expect(question.display, matches(RegExp(r'^\d+ [+-] \d+$')));
          for (final option in question.options) {
            expect(int.parse(option), greaterThanOrEqualTo(0));
          }
        }
      }
    }
  });

  test('all 120 levels generate age-appropriate questions', () {
    const ages = [6, 12, 13, 17, 18];
    for (final age in ages) {
      for (var level = 1; level <= MathLevelInfo.campaignLength; level++) {
        final stage = MathLevelInfo.forAge(age, level);
        final question = QuestionGenerator(
          random: Random(age * 1000 + level),
        ).generate(age, level: level);

        expect(question.options, hasLength(4), reason: 'age $age level $level');
        expect(question.options.toSet(), hasLength(4));
        expect(question.correctOption, question.formattedAnswer);
        expect(question.band, ageBandFor(age));

        if (age < 13) {
          expect(question.kind, QuestionKind.arithmetic);
          expect(question.display, matches(RegExp(r'^\d+ [+-] \d+$')));
        } else if (stage.topic == MathLevelTopic.numberSeries ||
            stage.topic == MathLevelTopic.advancedSeries) {
          expect(question.kind, QuestionKind.series);
        } else if (stage.topic == MathLevelTopic.decimals) {
          expect(question.kind, QuestionKind.decimal);
        } else if (stage.topic == MathLevelTopic.bodmas ||
            stage.topic == MathLevelTopic.complexBodmas) {
          expect(question.kind, QuestionKind.bodmas);
        }
      }
    }
  });

  test('age gates match the kid, teen, and adult tracks', () {
    expect(ageBandFor(12), AgeBand.kids);
    expect(ageBandFor(13), AgeBand.teens);
    expect(ageBandFor(17), AgeBand.teens);
    expect(ageBandFor(18), AgeBand.adults);
    expect(isCoppaChild(12), isTrue);
    expect(isCoppaChild(13), isFalse);
  });

  test('the 120-level chapters change with the selected age band', () {
    final kids = List.generate(
      MathLevelInfo.campaignLength,
      (index) => MathLevelInfo.forAge(8, index + 1).topic,
    );
    final teens = List.generate(
      MathLevelInfo.campaignLength,
      (index) => MathLevelInfo.forAge(14, index + 1).topic,
    );
    final adults = List.generate(
      MathLevelInfo.campaignLength,
      (index) => MathLevelInfo.forAge(21, index + 1).topic,
    );

    expect(kids[0], MathLevelTopic.addition);
    expect(kids[30], MathLevelTopic.subtraction);
    expect(kids[60], MathLevelTopic.mixedArithmetic);
    expect(teens[0], MathLevelTopic.multiplication);
    expect(teens[30], MathLevelTopic.bodmas);
    expect(teens[60], MathLevelTopic.numberSeries);
    expect(adults[0], MathLevelTopic.complexBodmas);
    expect(adults[30], MathLevelTopic.advancedSeries);
    expect(adults[60], MathLevelTopic.decimals);
    expect(MathLevelInfo.forAge(21, 121).number, 121);
    expect(MathLevelInfo.forAge(21, 121).difficulty, greaterThan(10));
  });

  test('same seed is stable', () {
    final first = QuestionGenerator(random: Random(7)).generate(21);
    final second = QuestionGenerator(random: Random(7)).generate(21);
    expect(second.display, first.display);
    expect(second.options, first.options);
    expect(second.correctIndex, first.correctIndex);
  });
}
