import 'dart:math';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/question.dart';
import '../models/reward.dart';
import '../services/ad_service.dart';
import '../services/banter_service.dart';
import '../services/question_generator.dart';
import '../services/reward_engine.dart';
import 'profile_controller.dart';

enum RoundPhase { playing, wrongChoice, resolved }

enum ToolOutcome { applied, notEnoughCoins, alreadyUsed, unavailable }

class GameController extends ChangeNotifier {
  GameController({
    required this.profile,
    required this.ads,
    QuestionGenerator? generator,
    RewardEngine? rewards,
    BanterService? banter,
    Random? random,
  })  : generator = generator ?? QuestionGenerator(),
        rewards = rewards ?? const RewardEngine(),
        banter = banter ?? BanterService(),
        _random = random ?? Random();

  final ProfileController profile;
  final AdService ads;
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
  bool secondChanceUsed = false;
  RewardResult? reward;
  bool failed = false;
  String heroLine = '';
  String rivalLine = '';
  int sessionRound = 1;

  bool get inputEnabled => phase == RoundPhase.playing;

  void startSession() {
    sessionRound = 1;
    _loadRound();
  }

  void onTick() {
    if (_watch.isRunning) {
      elapsed.value = _watch.elapsed;
    }
  }

  Future<void> submit(int index) async {
    final current = question;
    if (current == null || !inputEnabled || removed.contains(index)) return;
    selectedIndex = index;
    if (index == current.correctIndex) {
      await _resolveCorrect();
      return;
    }
    phase = RoundPhase.wrongChoice;
    _speak(BanterEvent.wrong);
    notifyListeners();
  }

  Future<ToolOutcome> useHint() async {
    if (hintVisible || phase == RoundPhase.resolved) {
      return ToolOutcome.alreadyUsed;
    }
    if (profile.profile.hintTokens > 0) {
      final spent = await profile.consumeHintToken();
      if (!spent) return ToolOutcome.notEnoughCoins;
    } else if (!await profile.trySpend(AppConfig.hintCost)) {
      return ToolOutcome.notEnoughCoins;
    }
    hintVisible = true;
    _speak(BanterEvent.hint);
    notifyListeners();
    return ToolOutcome.applied;
  }

  void grantFreeHint() {
    if (hintVisible || phase == RoundPhase.resolved) return;
    hintVisible = true;
    _speak(BanterEvent.hint);
    notifyListeners();
  }

  Future<ToolOutcome> useFifty() async {
    if (phase == RoundPhase.resolved) return ToolOutcome.unavailable;
    final current = question;
    if (current == null) return ToolOutcome.unavailable;
    final wrongs = <int>[
      for (var i = 0; i < current.options.length; i++)
        if (i != current.correctIndex && !removed.contains(i)) i,
    ];
    if (wrongs.length < 2) return ToolOutcome.alreadyUsed;
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
    notifyListeners();
    return ToolOutcome.applied;
  }

  Future<ToolOutcome> useSecondChance() async {
    if (phase != RoundPhase.wrongChoice || secondChanceUsed) {
      return ToolOutcome.unavailable;
    }
    if (profile.profile.chanceTokens > 0) {
      final spent = await profile.consumeChanceToken();
      if (!spent) return ToolOutcome.notEnoughCoins;
    } else if (!await profile.trySpend(AppConfig.secondChanceCost)) {
      return ToolOutcome.notEnoughCoins;
    }
    secondChanceUsed = true;
    final wrong = selectedIndex;
    if (wrong != null) removed.add(wrong);
    selectedIndex = null;
    phase = RoundPhase.playing;
    _speak(BanterEvent.chance);
    notifyListeners();
    return ToolOutcome.applied;
  }

  Future<void> declineSecondChance() async {
    if (phase != RoundPhase.wrongChoice) return;
    _watch.stop();
    elapsed.value = _watch.elapsed;
    failed = true;
    reward = null;
    phase = RoundPhase.resolved;
    await profile.applyMiss();
    notifyListeners();
  }

  /// Shows the every-3-levels interstitial before the next stopwatch starts.
  Future<void> nextRound() async {
    final completed = reward != null;
    final levels = profile.profile.levelsCompleted;
    if (completed) {
      await ads.maybeShowInterstitial(levels);
    }
    sessionRound += 1;
    _loadRound();
  }

  Future<void> _resolveCorrect() async {
    _watch.stop();
    elapsed.value = _watch.elapsed;
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
    final event = switch (result.band) {
      SpeedBand.lightning => BanterEvent.fast,
      SpeedBand.sharp => BanterEvent.sharp,
      SpeedBand.good => BanterEvent.good,
      SpeedBand.solved => BanterEvent.solved,
    };
    _speak(event);
    notifyListeners();
  }

  void _loadRound() {
    question = generator.generate(profile.userAge);
    phase = RoundPhase.playing;
    selectedIndex = null;
    hintVisible = false;
    removed.clear();
    secondChanceUsed = false;
    reward = null;
    failed = false;
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
