import 'dart:math';

import '../models/age_band.dart';
import '../models/question.dart';

/// Procedural, age-adaptive drill generator. Nothing is hardcoded as a quiz bank.
class QuestionGenerator {
  QuestionGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  GeneratedQuestion generate(int age) {
    final safeAge = age.clamp(6, 60);
    final band = ageBandFor(safeAge);
    final built = switch (band) {
      AgeBand.kids => _kids(safeAge),
      AgeBand.teens => _teens(safeAge),
      AgeBand.adults => _adults(),
    };
    return _seal(built, band);
  }

  _Draft _kids(int age) {
    final subtraction = _random.nextInt(10) < 4;
    if (subtraction) return _kidsSubtraction(age);
    return _kidsAddition(age);
  }

  _Draft _kidsAddition(int age) {
    final young = age < 8;
    final a = young ? 1 + _random.nextInt(9) : 4 + _random.nextInt(36);
    final b = young ? 1 + _random.nextInt(9) : 2 + _random.nextInt(28);
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

  _Draft _kidsSubtraction(int age) {
    final young = age < 8;
    final b = young ? 1 + _random.nextInt(8) : 2 + _random.nextInt(24);
    final a = b + (young ? 1 + _random.nextInt(8) : 3 + _random.nextInt(28));
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

  _Draft _teens(int age) {
    switch (_random.nextInt(3)) {
      case 0:
        return _multiplication(age);
      case 1:
        return _basicBodmas();
      default:
        return _series(simple: true);
    }
  }

  _Draft _adults() {
    switch (_random.nextInt(3)) {
      case 0:
        return _complexBodmas();
      case 1:
        return _series(simple: false);
      default:
        return _decimals();
    }
  }

  _Draft _multiplication(int age) {
    final older = age >= 13;
    final a = older ? 11 + _random.nextInt(18) : 2 + _random.nextInt(11);
    final b = older ? 3 + _random.nextInt(7) : 2 + _random.nextInt(11);
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

  _Draft _basicBodmas() {
    switch (_random.nextInt(4)) {
      case 0:
        final a = 2 + _random.nextInt(18);
        final b = 2 + _random.nextInt(8);
        final c = 2 + _random.nextInt(8);
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
        final a = 2 + _random.nextInt(12);
        final b = 2 + _random.nextInt(12);
        final c = 2 + _random.nextInt(6);
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
        final b = 2 + _random.nextInt(8);
        final c = 2 + _random.nextInt(8);
        final a = 2 + _random.nextInt(9);
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
        final c = 1 + _random.nextInt(6);
        final b = c + 2 + _random.nextInt(8);
        final a = 2 + _random.nextInt(9);
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

  _Draft _complexBodmas() {
    switch (_random.nextInt(4)) {
      case 0:
        final a = 6 + _random.nextInt(18);
        final b = 4 + _random.nextInt(14);
        final c = 2 + _random.nextInt(6);
        final product = (a + b) * c;
        final d = 1 + _random.nextInt(min(18, product));
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
        final a = 3 + _random.nextInt(8);
        final b = 3 + _random.nextInt(8);
        final c = 2 + _random.nextInt(7);
        final d = 2 + _random.nextInt(7);
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
        final b = 2 + _random.nextInt(7);
        final c = 2 + _random.nextInt(8);
        final a = 4 + _random.nextInt(20);
        final d = 2 + _random.nextInt(15);
        final answer = a + b * c - d;
        // Keep the drill fair: if subtraction would go negative, flip the sign visually
        // by rebuilding a larger starting number. We already allow a small a, so clamp.
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
        final a = 4 + _random.nextInt(8);
        final b = 4 + _random.nextInt(8);
        final product = a * b;
        final c = 1 + _random.nextInt(product - 1);
        final d = 3 + _random.nextInt(16);
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

  _Draft _series({required bool simple}) {
    final geometric = !simple && _random.nextBool();
    if (geometric) return _geometricSeries();
    final alternating = !simple && _random.nextInt(3) == 0;
    if (alternating) return _alternatingSeries();

    final start = simple ? 1 + _random.nextInt(12) : 2 + _random.nextInt(20);
    final step = simple ? 2 + _random.nextInt(5) : 4 + _random.nextInt(9);
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

  _Draft _geometricSeries() {
    final start = 2 + _random.nextInt(4);
    final terms = <int>[start];
    for (var i = 0; i < 3; i++) {
      terms.add(terms.last * 2);
    }
    final answer = terms.last * 2;
    return _Draft(
      display: '${terms.join(', ')}, ?',
      answer: answer,
      hint: 'Each number is doubled.',
      kind: QuestionKind.series,
      extraWrongs: [answer + start, terms.last + start, answer ~/ 2 + start],
      nonNegative: true,
    );
  }

  _Draft _alternatingSeries() {
    final start = 4 + _random.nextInt(12);
    final up = 4 + _random.nextInt(5);
    final down = 1 + _random.nextInt(3);
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

  _Draft _decimals() {
    if (_random.nextBool()) {
      final a = 5 + _random.nextInt(35);
      final b = 5 + _random.nextInt(35);
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
    final a = 5 + _random.nextInt(20);
    final b = 5 + _random.nextInt(20);
    final c = 2 + _random.nextInt(4);
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
