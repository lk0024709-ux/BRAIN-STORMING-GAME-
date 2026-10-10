import 'dart:math';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/question.dart';
import '../models/reward.dart';
import '../services/banter_service.dart';
import '../services/question_generator.dart';
import '../services/reward_engine.dart';
import 'profile_controller.dart';

enum RoundPhase { playing, resolved }

enum ToolOutcome { applied, notEnoughCoins, alreadyUsed, unavailable }

class GameController extends ChangeNotifier {
  GameController({
    required this.profile,
    QuestionGenerator? generator,
    RewardEngine? rewards,
    BanterService? banter,
    Random? random,
  })  : generator = generator ?? QuestionGenerator(),
        rewards = rewards ?? const RewardEngine(),
        banter = banter ?? BanterService(),
        _random = random ?? Random();

  final ProfileController profile;
  final QuestionGenerator generator;
  final RewardEngine rewards;
  final BanterService banter;
  final Random _random;

  final ValueNotifier<Duration> elapsed = ValueNotifier(Duration.zero);
  final Stopwatch _watch = Stopwatch();

  GeneratedQuestion? question;
  RoundPhase phase = RoundPhase.playing;
  int? selectedIndex;
  bool hintVisible = false;
  final Set<int> removed = <int>{};
  RewardResult? reward;
  bool failed = false;
  bool secondChanceUsed = false;
  bool _toolInFlight = false;
  bool _roundSettled = false;
  String heroLine = '';
  String rivalLine = '';
  int sessionRound = 1;

  bool get inputEnabled => phase == RoundPhase.playing && !_toolInFlight;

  bool get toolsBusy => _toolInFlight;

  bool get canAffordSecondChance =>
      profile.profile.chanceTokens > 0 ||
      profile.coins >= AppConfig.secondChanceCost;

  bool get hasPendingSecondChance =>
      failed &&
      phase == RoundPhase.resolved &&
      !secondChanceUsed &&
      !_roundSettled;

  void startSession() {
    sessionRound = 1;
    _loadRound();
  }

  void onTick() {
    if (_watch.isRunning) {
      elapsed.value = _watch.elapsed;
    }
  }

  /// Correct and final-wrong answers stop the stopwatch immediately. If a
  /// second chance is affordable, the first miss leaves it running while the
  /// player decides whether to spend the token/coins and try once more.
  Future<void> submit(int index) async {
    final current = question;
    if (current == null || !inputEnabled || removed.contains(index)) return;

    selectedIndex = index;
    if (index == current.correctIndex) {
      _watch.stop();
      elapsed.value = _watch.elapsed;
      await _resolveCorrect();
      return;
    }

    if (!secondChanceUsed && canAffordSecondChance) {
      failed = true;
      reward = null;
      phase = RoundPhase.resolved;
      _speak(BanterEvent.chance);
      notifyListeners();
      return;
    }

    _watch.stop();
    elapsed.value = _watch.elapsed;
    await _resolveWrong();
  }

  /// [💡 Hint] booster (Costs 10 coins): Opens yellow banner inside thought cloud.
  Future<ToolOutcome> useHint() async {
    if (hintVisible || phase == RoundPhase.resolved) {
      return ToolOutcome.alreadyUsed;
    }
    if (_toolInFlight) return ToolOutcome.alreadyUsed;

    _toolInFlight = true;
    notifyListeners();
    try {
      if (profile.profile.hintTokens > 0) {
        final spent = await profile.consumeHintToken();
        if (!spent) return ToolOutcome.notEnoughCoins;
      } else if (!await profile.trySpend(AppConfig.hintCost)) {
        return ToolOutcome.notEnoughCoins;
      }
      hintVisible = true;
      _speak(BanterEvent.hint);
      return ToolOutcome.applied;
    } finally {
      _toolInFlight = false;
      notifyListeners();
    }
  }

  /// [⚖️ 50/50] booster (Costs 25 coins): Disables 2 incorrect options.
  Future<ToolOutcome> useFifty() async {
    if (phase == RoundPhase.resolved) return ToolOutcome.unavailable;
    if (_toolInFlight) return ToolOutcome.alreadyUsed;
    final current = question;
    if (current == null) return ToolOutcome.unavailable;
    final wrongs = <int>[
      for (var i = 0; i < current.options.length; i++)
        if (i != current.correctIndex && !removed.contains(i)) i,
    ];
    if (wrongs.length < 2) return ToolOutcome.alreadyUsed;

    _toolInFlight = true;
    notifyListeners();
    try {
      if (profile.profile.fiftyTokens > 0) {
        final spent = await profile.consumeFiftyToken();
        if (!spent) return ToolOutcome.notEnoughCoins;
      } else if (!await profile.trySpend(AppConfig.fiftyCost)) {
        return ToolOutcome.notEnoughCoins;
      }
      wrongs.shuffle(_random);
      removed
        ..add(wrongs[0])
        ..add(wrongs[1]);
      _speak(BanterEvent.fifty);
      return ToolOutcome.applied;
    } finally {
      _toolInFlight = false;
      notifyListeners();
    }
  }

  /// Buys the one retry allowed after a miss. It resumes the existing
  /// stopwatch rather than resetting it; there is no second retry.
  Future<ToolOutcome> useSecondChance() async {
    if (!hasPendingSecondChance) return ToolOutcome.unavailable;
    if (_toolInFlight) return ToolOutcome.alreadyUsed;

    _toolInFlight = true;
    notifyListeners();
    try {
      final spent = profile.profile.chanceTokens > 0
          ? await profile.consumeChanceToken()
          : await profile.trySpend(AppConfig.secondChanceCost);
      if (!spent) return ToolOutcome.notEnoughCoins;

      secondChanceUsed = true;
      failed = false;
      selectedIndex = null;
      phase = RoundPhase.playing;
      if (!_watch.isRunning) _watch.start();
      _speak(BanterEvent.chance);
      return ToolOutcome.applied;
    } finally {
      _toolInFlight = false;
      notifyListeners();
    }
  }

  Future<void> nextRound() async {
    if (_toolInFlight) return;
    if (failed && !_roundSettled) await finalizeMiss();
    sessionRound += 1;
    _loadRound();
  }

  /// Records a miss when the player leaves the second-chance panel or moves on.
  Future<void> finalizeMiss() async {
    if (!failed || _roundSettled) return;
    _watch.stop();
    elapsed.value = _watch.elapsed;
    await profile.applyMiss();
    _roundSettled = true;
    _speak(BanterEvent.wrong);
    notifyListeners();
  }

  Future<void> _resolveCorrect() async {
    final result = rewards.evaluate(
      elapsed: _watch.elapsed,
      isPro: profile.isProUser,
    );
    reward = result;
    failed = false;
    phase = RoundPhase.resolved;
    await profile.applyCorrect(
      reward: result,
      timeMs: _watch.elapsedMilliseconds,
    );
    _roundSettled = true;
    final event = switch (result.band) {
      SpeedBand.lightning => BanterEvent.fast,
      SpeedBand.sharp => BanterEvent.sharp,
      SpeedBand.good => BanterEvent.good,
      SpeedBand.solved => BanterEvent.solved,
    };
    _speak(event);
    notifyListeners();
  }

  Future<void> _resolveWrong() async {
    failed = true;
    reward = null;
    phase = RoundPhase.resolved;
    await profile.applyMiss();
    _roundSettled = true;
    _speak(BanterEvent.wrong);
    notifyListeners();
  }

  void _loadRound() {
    question = generator.generate(profile.userAge);
    phase = RoundPhase.playing;
    selectedIndex = null;
    hintVisible = false;
    removed.clear();
    reward = null;
    failed = false;
    secondChanceUsed = false;
    _roundSettled = false;
    _toolInFlight = false;
    _speak(BanterEvent.intro);
    _watch
      ..reset()
      ..start();
    elapsed.value = Duration.zero;
    notifyListeners();
  }

  void _speak(BanterEvent event) {
    final pair = banter.line(event, profile.userAge);
    heroLine = pair.hero;
    rivalLine = pair.rival;
  }

  @override
  void dispose() {
    _watch.stop();
    elapsed.dispose();
    super.dispose();
  }
}
