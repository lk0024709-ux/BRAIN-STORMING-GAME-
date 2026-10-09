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

enum RoundPhase { playing, resolved }

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

  /// Tapping an answer button immediately stops the stopwatch engine.
  Future<void> submit(int index) async {
    final current = question;
    if (current == null || !inputEnabled || removed.contains(index)) return;

    // Immediately stop stopwatch on answer tap!
    _watch.stop();
    elapsed.value = _watch.elapsed;
    selectedIndex = index;

    if (index == current.correctIndex) {
      await _resolveCorrect();
    } else {
      await _resolveWrong();
    }
  }

  /// [💡 Hint] booster (Costs 10 coins): Opens yellow banner inside thought cloud.
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

  /// Grants a free hint without coin deduction (e.g. from Rewarded Ad callback).
  void grantFreeHint() {
    if (hintVisible || phase == RoundPhase.resolved) return;
    hintVisible = true;
    _speak(BanterEvent.hint);
    notifyListeners();
  }

  /// [⚖️ 50/50] booster (Costs 25 coins): Disables 2 incorrect options.
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

  /// Grants free 50/50 without coin deduction (e.g. from Rewarded Ad callback).
  void grantFreeFifty() {
    if (phase == RoundPhase.resolved) return;
    final current = question;
    if (current == null) return;
    final wrongs = <int>[
      for (var i = 0; i < current.options.length; i++)
        if (i != current.correctIndex && !removed.contains(i)) i,
    ];
    if (wrongs.length < 2) return;
    wrongs.shuffle(_random);
    removed
      ..add(wrongs[0])
      ..add(wrongs[1]);
    _speak(BanterEvent.fifty);
    notifyListeners();
  }

  /// Interstitial Ads trigger automatically after every 3 completed levels.
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

  Future<void> _resolveWrong() async {
    failed = true;
    reward = null;
    phase = RoundPhase.resolved;
    await profile.applyMiss();
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
