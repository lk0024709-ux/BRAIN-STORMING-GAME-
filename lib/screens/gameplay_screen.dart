import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../controllers/game_controller.dart';
import '../models/question.dart';
import '../controllers/profile_controller.dart';
import '../services/ad_service.dart';
import '../theme/manga_colors.dart';
import '../theme/manga_theme.dart';
import '../widgets/comic_popup.dart';
import '../widgets/dialogue_strip.dart';
import '../widgets/dialogs.dart';
import '../widgets/neo_widgets.dart';
import '../widgets/thought_cloud.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  Timer? _ticker;
  bool _advancing = false;
  bool _adBusy = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      context.read<GameController>().onTick();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _click() {
    final soundOn = context.read<ProfileController>().profile.soundOn;
    if (!soundOn) return;
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.selectionClick();
  }

  Future<void> _leave() async {
    final game = context.read<GameController>();
    if (game.phase == RoundPhase.resolved && !_advancing) {
      Navigator.pop(context);
      return;
    }
    final leave = await showConfirmDialog(
      context: context,
      title: 'LEAVE THE ROUND?',
      body: 'The stopwatch dies if you walk out. No reward for a half-solve.',
      confirmLabel: 'LEAVE',
    );
    if (leave && mounted) Navigator.pop(context);
  }

  Future<void> _submit(int index) async {
    final game = context.read<GameController>();
    if (!game.inputEnabled) return;
    _click();
    await game.submit(index);
    if (!mounted) return;
    final soundOn = context.read<ProfileController>().profile.soundOn;
    if (!soundOn) return;
    if (game.phase == RoundPhase.resolved) {
      HapticFeedback.mediumImpact();
    } else if (game.phase == RoundPhase.wrongChoice) {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _shortage({
    required int cost,
    required bool offerFreeHint,
    required Future<void> Function() retry,
    void Function()? onFreeHint,
  }) async {
    final ads = context.read<AdService>();
    final profile = context.read<ProfileController>();
    while (mounted && profile.coins < cost) {
      final choice = await showCoinShortageDialog(
        context: context,
        cost: cost,
        balance: profile.coins,
        canWatchAd: ads.rewardedAllowed,
        offerFreeHint: offerFreeHint && onFreeHint != null,
      );
      if (!mounted || choice == null) return;
      setState(() => _adBusy = true);
      final earned = await ads.showRewarded();
      if (mounted) setState(() => _adBusy = false);
      if (!mounted) return;
      if (!earned) {
        _toast('Ad not available right now.');
        return;
      }
      if (choice == ShortageChoice.freeHint) {
        onFreeHint?.call();
        return;
      }
      await profile.addCoins(AppConfig.rewardedCoinPayout);
    }
    if (!mounted) return;
    if (profile.coins >= cost) await retry();
  }

  Future<void> _hint() async {
    final game = context.read<GameController>();
    _click();
    final outcome = await game.useHint();
    if (!mounted || outcome != ToolOutcome.notEnoughCoins) return;
    await _shortage(
      cost: AppConfig.hintCost,
      offerFreeHint: true,
      retry: game.useHint,
      onFreeHint: game.grantFreeHint,
    );
  }

  Future<void> _fifty() async {
    final game = context.read<GameController>();
    _click();
    final outcome = await game.useFifty();
    if (!mounted || outcome != ToolOutcome.notEnoughCoins) return;
    await _shortage(
      cost: AppConfig.fiftyCost,
      offerFreeHint: false,
      retry: game.useFifty,
    );
  }

  Future<void> _chance() async {
    final game = context.read<GameController>();
    _click();
    final outcome = await game.useSecondChance();
    if (!mounted || outcome != ToolOutcome.notEnoughCoins) return;
    await _shortage(
      cost: AppConfig.secondChanceCost,
      offerFreeHint: false,
      retry: game.useSecondChance,
    );
  }

  Future<void> _next() async {
    if (_advancing) return;
    setState(() => _advancing = true);
    await context.read<GameController>().nextRound();
    if (mounted) setState(() => _advancing = false);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: MangaColors.ink,
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final profile = context.watch<ProfileController>().profile;
    final question = game.question;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        body: HalftoneBackground(
          child: SafeArea(
            child: DojoFrame(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 6, 12, 4),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _leave,
                              icon: const Icon(Icons.close, color: MangaColors.ink),
                            ),
                            Expanded(
                              child: Text(
                                'ROUND ${game.sessionRound}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            if (profile.streak > 1)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Text(
                                  '🔥${profile.streak}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ValueListenableBuilder<Duration>(
                              valueListenable: game.elapsed,
                              builder: (context, duration, _) {
                                return NeoBox(
                                  color: MangaColors.ink,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  offset: const Offset(2, 2),
                                  borderWidth: 2,
                                  child: Text(
                                    '⏱️ ${formatStopwatch(duration)}s',
                                    style: const TextStyle(
                                      color: MangaColors.yellow,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                            CoinChip(coins: profile.coins, compact: true),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DialogueStrip(
                          heroName: profile.nickname.isEmpty
                              ? 'HERO'
                              : profile.nickname.toUpperCase(),
                          heroLine: game.heroLine,
                          rivalLine: game.rivalLine,
                          pro: profile.isProUser,
                          nameplate: profile.equippedNameplate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: question == null
                              ? const SizedBox.shrink()
                              : ThoughtCloud(
                                  label: question.kind.cloudLabel,
                                  formula: question.display,
                                  hint: game.hintVisible ? question.hint : null,
                                ),
                        ),
                      ),
                      if (question != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                          child: _OptionGrid(
                            options: question.options,
                            correctIndex: question.correctIndex,
                            selectedIndex: game.selectedIndex,
                            removed: game.removed,
                            reveal: game.phase == RoundPhase.resolved,
                            enabled: game.inputEnabled,
                            onPick: _submit,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: MangaButton(
                                label: game.hintVisible
                                    ? 'HINT USED'
                                    : profile.hintTokens > 0
                                        ? '💡 HINT · x${profile.hintTokens}'
                                        : '💡 HINT · ${AppConfig.hintCost}',
                                color: MangaColors.yellow,
                                onPressed: game.hintVisible ||
                                        game.phase == RoundPhase.resolved
                                    ? null
                                    : _hint,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: MangaButton(
                                label: profile.fiftyTokens > 0
                                    ? '⚖️ 50/50 · x${profile.fiftyTokens}'
                                    : '⚖️ 50/50 · ${AppConfig.fiftyCost}',
                                color: MangaColors.blue,
                                onPressed: game.phase == RoundPhase.resolved
                                    ? null
                                    : _fifty,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                        child: MangaButton(
                          label: profile.chanceTokens > 0
                              ? '🛡️ SECOND CHANCE · TOKEN'
                              : '🛡️ SECOND CHANCE · ${AppConfig.secondChanceCost}',
                          subtitle: game.phase == RoundPhase.wrongChoice
                              ? 'Timer is still running'
                              : 'Arms only after a miss',
                          color: MangaColors.mint,
                          onPressed: game.phase == RoundPhase.wrongChoice &&
                                  !game.secondChanceUsed
                              ? _chance
                              : null,
                        ),
                      ),
                    ],
                  ),
                  if (game.phase == RoundPhase.resolved && game.reward != null)
                    Positioned.fill(
                      child: ComicPopup(
                        reward: game.reward!,
                        onNext: _advancing ? () {} : _next,
                      ),
                    ),
                  if (game.phase == RoundPhase.resolved && game.failed)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: NeoBox(
                        color: MangaColors.white,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Missed it. Green was the answer.',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 8),
                            MangaButton(
                              label: _advancing ? 'LOADING...' : 'NEXT CLOUD',
                              color: MangaColors.pink,
                              onPressed: _advancing ? null : _next,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_adBusy)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Color(0x88111111),
                        child: Center(
                          child: NeoBox(
                            color: MangaColors.yellow,
                            child: Text(
                              'LOADING AD...',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionGrid extends StatelessWidget {
  const _OptionGrid({
    required this.options,
    required this.correctIndex,
    required this.selectedIndex,
    required this.removed,
    required this.reveal,
    required this.enabled,
    required this.onPick,
  });

  final List<String> options;
  final int correctIndex;
  final int? selectedIndex;
  final Set<int> removed;
  final bool reveal;
  final bool enabled;
  final Future<void> Function(int index) onPick;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 64,
      ),
      itemBuilder: (context, index) {
        final gone = removed.contains(index);
        final picked = selectedIndex == index;
        final showCorrect = reveal && index == correctIndex;
        Color fill = MangaColors.optionFills[index];
        if (gone) fill = MangaColors.disabled;
        if (showCorrect) fill = MangaColors.green;
        if (picked && !showCorrect && reveal) fill = MangaColors.red;
        if (picked && !reveal && !enabled) fill = MangaColors.red;
        final letter = String.fromCharCode(65 + index);
        return MangaButton(
          label: gone ? '$letter   —' : '$letter   ${options[index]}',
          color: fill,
          onPressed: !enabled || gone ? null : () => onPick(index),
        );
      },
    );
  }
}
