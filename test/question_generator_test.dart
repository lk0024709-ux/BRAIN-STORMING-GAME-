import 'dart:math';

import 'package:brain_speed_iq/models/age_band.dart';
import 'package:brain_speed_iq/models/question.dart';
import 'package:brain_speed_iq/services/question_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every age band builds four unique choices with a real answer', () {
    const ages = [6, 7, 9, 10, 13, 16, 17, 28, 60];
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
        if (age < 10) {
          expect(question.kind, QuestionKind.arithmetic);
          expect(question.display, matches(RegExp(r'^\d+ [+-] \d+$')));
          for (final option in question.options) {
            expect(int.parse(option), greaterThanOrEqualTo(0));
          }
        }
      }
    }
  });

  test('same seed is stable', () {
    final first = QuestionGenerator(random: Random(7)).generate(21);
    final second = QuestionGenerator(random: Random(7)).generate(21);
    expect(second.display, first.display);
    expect(second.options, first.options);
    expect(second.correctIndex, first.correctIndex);
  });
}
