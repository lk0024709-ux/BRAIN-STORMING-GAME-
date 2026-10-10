import 'dart:math';

import '../models/age_band.dart';
import '../models/math_level.dart';
import '../models/question.dart';

/// Procedural, age-adaptive quiz generator. Questions scale with campaign level.
class QuestionGenerator {
  QuestionGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  GeneratedQuestion generate(int age, {int level = 1}) {
    final safeAge = age.clamp(6, 60).toInt();
    final stage = MathLevelInfo.forAge(safeAge, level);
    final band = stage.band;
    final difficulty = stage.difficulty;
    final built = switch (stage.topic) {
      MathLevelTopic.addition =>
        _kidsAddition(safeAge, difficulty: difficulty),
      MathLevelTopic.subtraction =>
        _kidsSubtraction(safeAge, difficulty: difficulty),
      MathLevelTopic.mixedArithmetic =>
        _kids(safeAge, difficulty: difficulty),
      MathLevelTopic.multiplication =>
        _multiplication(safeAge, difficulty: difficulty),
      MathLevelTopic.bodmas => _basicBodmas(difficulty: difficulty),
      MathLevelTopic.numberSeries =>
        _series(simple: true, difficulty: difficulty),
      MathLevelTopic.mixedTeen => _teens(safeAge, difficulty: difficulty),
      MathLevelTopic.complexBodmas => _complexBodmas(difficulty: difficulty),
      MathLevelTopic.advancedSeries =>
        _series(simple: false, difficulty: difficulty),
      MathLevelTopic.decimals => _decimals(difficulty: difficulty),
      MathLevelTopic.mixedAdult => _adults(difficulty: difficulty),
    };
    return _seal(built, band);
  }

  _Draft _kids(int age, {required int difficulty}) {
    final subtraction = _random.nextInt(2) == 0;
    if (subtraction) {
      return _kidsSubtraction(age, difficulty: difficulty);
    }
    return _kidsAddition(age, difficulty: difficulty);
  }

  _Draft _kidsAddition(int age, {required int difficulty}) {
    final young = age < 8;
    final cap = young ? 5 + difficulty * 4 : 15 + difficulty * 8;
    final a = 1 + _random.nextInt(cap);
    final b = 1 + _random.nextInt(cap);
    final answer = a + b;
    return _Draft(
      display: '$a + $b',
      answer: answer,
      hint: young
          ? 'Start at $a and count $b more.'
          : 'Add the ones, then the tens. $a + $b.',
      kind: QuestionKind.arithmetic,
      extraWrongs: [answer + 10, (a - b).abs()],
      nonNegative: true,
    );
  }

  _Draft _kidsSubtraction(int age, {required int difficulty}) {
    final young = age < 8;
    final cap = young ? 4 + difficulty * 3 : 10 + difficulty * 8;
    final b = 1 + _random.nextInt(cap);
    final a = b + 1 + _random.nextInt(cap);
    final answer = a - b;
    return _Draft(
      display: '$a - $b',
      answer: answer,
      hint: 'Count up from $b until you reach $a.',
      kind: QuestionKind.arithmetic,
      extraWrongs: [a + b, answer + b],
      nonNegative: true,
    );
  }

  _Draft _teens(int age, {required int difficulty}) {
    switch (_random.nextInt(3)) {
      case 0:
        return _multiplication(age, difficulty: difficulty);
      case 1:
        return _basicBodmas(difficulty: difficulty);
      default:
        return _series(simple: true, difficulty: difficulty);
    }
  }

  _Draft _adults({required int difficulty}) {
    switch (_random.nextInt(3)) {
      case 0:
        return _complexBodmas(difficulty: difficulty);
      case 1:
        return _series(simple: false, difficulty: difficulty);
      default:
        return _decimals(difficulty: difficulty);
    }
  }

  _Draft _multiplication(int age, {required int difficulty}) {
    final older = age >= 13;
    final a = older
        ? 8 + _random.nextInt(11 + difficulty * 2)
        : 2 + _random.nextInt(6 + difficulty);
    final b = older
        ? 2 + _random.nextInt(3 + difficulty ~/ 2)
        : 2 + _random.nextInt(6 + difficulty);
    final answer = a * b;
    return _Draft(
      display: '$a × $b',
      answer: answer,
      hint: '$a × $b is $a added $b times.',
      kind: QuestionKind.arithmetic,
      extraWrongs: [answer + a, answer - b, a * (b + 1)],
      nonNegative: true,
    );
  }

  _Draft _basicBodmas({required int difficulty}) {
    switch (_random.nextInt(4)) {
      case 0:
        final a = 2 + _random.nextInt(18 + difficulty * 3);
        final b = 2 + _random.nextInt(8 + difficulty);
        final c = 2 + _random.nextInt(8 + difficulty);
        final answer = a + b * c;
        return _Draft(
          display: '$a + $b × $c',
          answer: answer,
          hint: 'Multiply first: $b × $c = ${b * c}.',
          kind: QuestionKind.bodmas,
          extraWrongs: [(a + b) * c, a + b + c],
          nonNegative: true,
        );
      case 1:
        final a = 2 + _random.nextInt(12 + difficulty * 2);
        final b = 2 + _random.nextInt(12 + difficulty * 2);
        final c = 2 + _random.nextInt(6 + difficulty ~/ 2);
        final answer = (a + b) * c;
        return _Draft(
          display: '($a + $b) × $c',
          answer: answer,
          hint: 'Brackets first: $a + $b = ${a + b}.',
          kind: QuestionKind.bodmas,
          extraWrongs: [a + b * c, a * c + b],
          nonNegative: true,
        );
      case 2:
        final b = 2 + _random.nextInt(8 + difficulty);
        final a = 2 + _random.nextInt(9 + difficulty * 2);
        final product = a * b;
        final sub = 1 + _random.nextInt(product - 1);
        final answer = product - sub;
        return _Draft(
          display: '$a × $b - $sub',
          answer: answer,
          hint: 'Multiply first: $a × $b = $product.',
          kind: QuestionKind.bodmas,
          extraWrongs: [(a - sub) * b, product + sub],
          nonNegative: true,
        );
      default:
        final c = 1 + _random.nextInt(6 + difficulty ~/ 2);
        final b = c + 2 + _random.nextInt(8 + difficulty);
        final a = 2 + _random.nextInt(9 + difficulty * 2);
        final answer = a * (b - c);
        return _Draft(
          display: '$a × ($b - $c)',
          answer: answer,
          hint: 'Brackets first: $b - $c = ${b - c}.',
          kind: QuestionKind.bodmas,
          extraWrongs: [a * b - c, a * b - a * c + a],
          nonNegative: true,
        );
    }
  }

  _Draft _complexBodmas({required int difficulty}) {
    switch (_random.nextInt(4)) {
      case 0:
        final a = 6 + _random.nextInt(18 + difficulty * 2);
        final b = 4 + _random.nextInt(14 + difficulty);
        final c = 2 + _random.nextInt(6 + difficulty ~/ 2);
        final product = (a + b) * c;
        final d = 1 + _random.nextInt(min(18 + difficulty, product));
        final answer = product - d;
        return _Draft(
          display: '($a + $b) × $c - $d',
          answer: answer,
          hint: 'Brackets first: $a + $b = ${a + b}. Then multiply by $c.',
          kind: QuestionKind.bodmas,
          extraWrongs: [a + b * c - d, (a + b) * c + d],
          nonNegative: true,
        );
      case 1:
        final a = 3 + _random.nextInt(8 + difficulty);
        final b = 3 + _random.nextInt(8 + difficulty);
        final c = 2 + _random.nextInt(7 + difficulty ~/ 2);
        final d = 2 + _random.nextInt(7 + difficulty ~/ 2);
        final answer = a * b + c * d;
        return _Draft(
          display: '$a × $b + $c × $d',
          answer: answer,
          hint: 'Multiply both pairs: $a × $b = ${a * b}, $c × $d = ${c * d}.',
          kind: QuestionKind.bodmas,
          extraWrongs: [(a * b + c) * d, a * (b + c) * d],
          nonNegative: true,
        );
      case 2:
        final b = 2 + _random.nextInt(7 + difficulty ~/ 2);
        final c = 2 + _random.nextInt(8 + difficulty);
        final a = 4 + _random.nextInt(20 + difficulty * 2);
        final d = 2 + _random.nextInt(15 + difficulty);
        final answer = a + b * c - d;
        if (answer < 0) {
          final fixedA = d + 2;
          final fixed = fixedA + b * c - d;
          return _Draft(
            display: '$fixedA + $b × $c - $d',
            answer: fixed,
            hint: 'Multiply first: $b × $c = ${b * c}.',
            kind: QuestionKind.bodmas,
            extraWrongs: [(fixedA + b) * c - d, fixedA + b + c - d],
            nonNegative: true,
          );
        }
        return _Draft(
          display: '$a + $b × $c - $d',
          answer: answer,
          hint: 'Multiply first: $b × $c = ${b * c}.',
          kind: QuestionKind.bodmas,
          extraWrongs: [(a + b) * c - d, a + b + c - d],
          nonNegative: true,
        );
      default:
        final a = 4 + _random.nextInt(8 + difficulty);
        final b = 4 + _random.nextInt(8 + difficulty);
        final product = a * b;
        final c = 1 + _random.nextInt(product - 1);
        final d = 3 + _random.nextInt(16 + difficulty);
        final answer = product - c + d;
        return _Draft(
          display: '($a × $b - $c) + $d',
          answer: answer,
          hint: 'Inside the brackets: $a × $b = $product, then subtract $c.',
          kind: QuestionKind.bodmas,
          extraWrongs: [a * b - (c + d), a * (b - c) + d],
          nonNegative: true,
        );
    }
  }

  _Draft _series({required bool simple, required int difficulty}) {
    final geometric = !simple && _random.nextBool();
    if (geometric) return _geometricSeries(difficulty: difficulty);
    final alternating = !simple && _random.nextInt(3) == 0;
    if (alternating) return _alternatingSeries(difficulty: difficulty);

    final start = simple
        ? 1 + _random.nextInt(12 + difficulty * 3)
        : 2 + _random.nextInt(20 + difficulty * 4);
    final step = simple
        ? 2 + _random.nextInt(5 + difficulty)
        : 4 + _random.nextInt(9 + difficulty * 2);
    final terms = List<int>.generate(4, (i) => start + step * i);
    final answer = start + step * 4;
    final hideMiddle = !simple && _random.nextBool();
    if (hideMiddle) {
      final missing = terms[2];
      final shown = [terms[0], terms[1], terms[3], terms[3] + step];
      return _Draft(
        display: '${shown[0]}, ${shown[1]}, ?, ${shown[2]}, ${shown[3]}',
        answer: missing,
        hint: 'The gap between numbers is $step.',
        kind: QuestionKind.series,
        extraWrongs: [missing + step, missing - step, shown[1] + 1],
        nonNegative: true,
      );
    }
    return _Draft(
      display: '${terms.join(', ')}, ?',
      answer: answer,
      hint: 'Each step adds $step.',
      kind: QuestionKind.series,
      extraWrongs: [answer + step, answer - step, answer + 1],
      nonNegative: true,
    );
  }

  _Draft _geometricSeries({required int difficulty}) {
    final start = 2 + _random.nextInt(4 + difficulty ~/ 4);
    final ratio = difficulty < 8 ? 2 : 2 + _random.nextInt(2);
    final terms = <int>[start];
    for (var i = 0; i < 3; i++) {
      terms.add(terms.last * ratio);
    }
    final answer = terms.last * ratio;
    return _Draft(
      display: '${terms.join(', ')}, ?',
      answer: answer,
      hint: 'Each number is multiplied by $ratio.',
      kind: QuestionKind.series,
      extraWrongs: [answer + start, terms.last + start, answer ~/ ratio + start],
      nonNegative: true,
    );
  }

  _Draft _alternatingSeries({required int difficulty}) {
    final start = 4 + _random.nextInt(12 + difficulty * 2);
    final up = 4 + _random.nextInt(5 + difficulty);
    final down = 1 + _random.nextInt(min(3, 1 + difficulty ~/ 3));
    final terms = <int>[start];
    for (var i = 0; i < 4; i++) {
      final delta = i.isEven ? up : -down;
      terms.add(terms.last + delta);
    }
    final answer = terms.removeLast();
    return _Draft(
      display: '${terms.join(', ')}, ?',
      answer: answer,
      hint: 'The pattern alternates: +$up, then -$down.',
      kind: QuestionKind.series,
      extraWrongs: [answer + up, answer - down, terms.last + up],
      nonNegative: true,
    );
  }

  _Draft _decimals({required int difficulty}) {
    if (_random.nextBool()) {
      final a = 5 + _random.nextInt(35 + difficulty * 8);
      final b = 5 + _random.nextInt(35 + difficulty * 8);
      final sum = a + b;
      return _Draft(
        display: '${_tenths(a)} + ${_tenths(b)}',
        answerLabel: _tenths(sum),
        hint: 'Line up the decimal. ${_tenths(a)} + ${_tenths(b)}.',
        kind: QuestionKind.decimal,
        extraWrongLabels: [
          _tenths(sum + 1),
          _tenths(sum + 10),
          _tenths((a - b).abs()),
        ],
      );
    }
    final a = 5 + _random.nextInt(20 + difficulty * 4);
    final b = 5 + _random.nextInt(20 + difficulty * 4);
    final c = 2 + _random.nextInt(4 + difficulty ~/ 3);
    final sum = a + b;
    final product = sum * c;
    return _Draft(
      display: '(${_tenths(a)} + ${_tenths(b)}) × $c',
      answerLabel: _tenths(product),
      hint: 'Add the tenths first: ${_tenths(a)} + ${_tenths(b)} = ${_tenths(sum)}.',
      kind: QuestionKind.decimal,
      extraWrongLabels: [
        _tenths(a * c + b),
        _tenths(product + c),
        _tenths(sum + c),
      ],
    );
  }

  GeneratedQuestion _seal(_Draft draft, AgeBand band) {
    final answerLabel = draft.answerLabel ?? draft.answer.toString();
    final options = <String>{answerLabel};
    final extras = <String>[
      ...draft.extraWrongLabels,
      ...draft.extraWrongs.map((value) => value.toString()),
      if (draft.answer != null) ..._numericTraps(draft.answer!, draft.nonNegative),
    ];
    for (final candidate in extras) {
      if (candidate.isEmpty || candidate == answerLabel) continue;
      if (draft.nonNegative && candidate.startsWith('-')) continue;
      options.add(candidate);
      if (options.length == 4) break;
    }
    var bump = 1;
    while (options.length < 4 && bump < 40) {
      final fallback = draft.answer != null
          ? (draft.answer! + bump * 3).toString()
          : _shiftLabel(answerLabel, bump);
      if (fallback != answerLabel &&
          !(draft.nonNegative && fallback.startsWith('-'))) {
        options.add(fallback);
      }
      bump++;
    }
    final list = options.toList();
    if (list.length < 4 || !list.contains(answerLabel)) {
      throw StateError(
        'Could not build four choices for ${draft.display} ($answerLabel).',
      );
    }
    list.shuffle(_random);
    final correctIndex = list.indexOf(answerLabel);
    return GeneratedQuestion(
      display: draft.display,
      options: list,
      correctIndex: correctIndex,
      formattedAnswer: answerLabel,
      hint: draft.hint,
      kind: draft.kind,
      band: band,
    );
  }

  List<String> _numericTraps(int answer, bool nonNegative) {
    final traps = <int>[
      answer + 1,
      answer - 1,
      answer + 2,
      answer - 2,
      answer + 10,
      answer - 10,
    ];
    return [
      for (final value in traps)
        if (!nonNegative || value >= 0) value.toString(),
    ];
  }

  String _shiftLabel(String label, int bump) {
    if (!label.contains('.')) {
      final parsed = int.tryParse(label);
      if (parsed == null) return '$label$bump';
      return (parsed + bump).toString();
    }
    final tenths = _parseTenths(label);
    return _tenths(tenths + bump);
  }

  int _parseTenths(String label) {
    final negative = label.startsWith('-');
    final raw = negative ? label.substring(1) : label;
    final parts = raw.split('.');
    final whole = int.parse(parts[0]);
    final frac = parts.length == 1 ? 0 : int.parse(parts[1]);
    final tenths = whole * 10 + frac;
    return negative ? -tenths : tenths;
  }

  String _tenths(int tenths) {
    final negative = tenths < 0;
    final abs = tenths.abs();
    final whole = abs ~/ 10;
    final frac = abs % 10;
    final body = frac == 0 ? '$whole' : '$whole.$frac';
    return negative ? '-$body' : body;
  }
}

class _Draft {
  _Draft({
    required this.display,
    required this.hint,
    required this.kind,
    this.answer,
    this.answerLabel,
    this.extraWrongs = const [],
    this.extraWrongLabels = const [],
    this.nonNegative = false,
  });

  final String display;
  final String hint;
  final QuestionKind kind;
  final int? answer;
  final String? answerLabel;
  final List<int> extraWrongs;
  final List<String> extraWrongLabels;
  final bool nonNegative;
}
