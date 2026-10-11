import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../controllers/game_controller.dart';
import '../controllers/music_controller.dart';
import '../controllers/profile_controller.dart';
import '../services/reward_engine.dart';
import '../theme/cyber_palette.dart';
import '../theme/manga_colors.dart';
import '../theme/manga_theme.dart';
import '../widgets/battle_dojo_widgets.dart';
import '../widgets/comic_popup.dart';
import '../widgets/cyber_widgets.dart';
import '../widgets/dialogs.dart';
import '../widgets/neo_widgets.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  Timer? _ticker;
  bool _advancing = false;
  MusicController? _music;

  @override
  void initState() {
    super.initState();
    _music = context.read<MusicController>();
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      context.read<GameController>().onTick();
    });
    // Start the battle track after the first frame, so the route is on screen
    // before audio begins. Battle startup does not wait for audio.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _music?.enterBattle(this);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _music?.exitBattle(this);
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
    if (game.toolsBusy || _advancing) return;
    if (game.phase == RoundPhase.resolved) {
      try {
        if (game.failed) await game.finalizeMiss();
        if (mounted) Navigator.pop(context);
      } catch (_) {
        if (mounted) _toast('Could not save this round. Try again.');
      }
      return;
    }
    final leave = await showConfirmDialog(
      context: context,
      title: 'LEAVE THIS LEVEL?',
      body: 'The stopwatch stops if you walk out. This level stays open until you solve it.',
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
    if (game.reward != null) {
      HapticFeedback.mediumImpact();
    } else {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _hint() async {
    final game = context.read<GameController>();
    _click();
    final outcome = await game.useHint();
    if (!mounted) return;
    if (outcome == ToolOutcome.notEnoughCoins) {
      _toast(
        'Not enough coins for a hint. Solve rounds to earn coins or pick up a hint pack in the Shop.',
      );
    }
  }

  Future<void> _fifty() async {
    final game = context.read<GameController>();
    _click();
    final outcome = await game.useFifty();
    if (!mounted) return;
    if (outcome == ToolOutcome.notEnoughCoins) {
      _toast(
        'Not enough coins for 50/50. Solve rounds to earn coins or pick up a token pack in the Shop.',
      );
    }
  }

  Future<void> _secondChance() async {
    final outcome = await context.read<GameController>().useSecondChance();
    if (!mounted) return;
    if (outcome == ToolOutcome.notEnoughCoins) {
      _toast('Not enough coins for a second chance.');
    }
  }

  Future<void> _next() async {
    if (_advancing) return;
    setState(() => _advancing = true);
    try {
      await context.read<GameController>().nextRound();
    } catch (_) {
      if (mounted) _toast('Could not save this round. Try again.');
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: MangaColors.ink,
        behavior: SnackBarBehavior.floating,
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: MangaColors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final profile = context.watch<ProfileController>().profile;
    final music = context.watch<MusicController>();
    final question = game.question;

    // Max XP the player can still earn this round (fastest band, Pro-doubled).
    final maxPreviewXp = const RewardEngine()
        .evaluate(elapsed: Duration.zero, isPro: profile.isProUser)
        .xp;
    final String xpText;
    if (game.phase == RoundPhase.resolved) {
      xpText = '+${game.reward?.xp ?? 0} IQ XP';
    } else {
      xpText = 'UP TO +$maxPreviewXp IQ XP';
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: CyberPalette.background,
        body: CyberBackdrop(
          child: Stack(
            children: [
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: BattleGridFloorPainter()),
                ),
              ),
              SafeArea(
                child: DojoFrame(
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          // Header: close, music toggle, streak, timer, coins.
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: _leave,
                                  icon: const Icon(
                                    Icons.close,
                                    color: CyberPalette.text,
                                    size: 26,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: music.enabled
                                      ? 'Turn battle music off'
                                      : 'Turn battle music on',
                                  onPressed: () =>
                                      music.setEnabled(!music.enabled),
                                  icon: Icon(
                                    music.enabled
                                        ? Icons.music_note_rounded
                                        : Icons.music_off_rounded,
                                    color: CyberPalette.text,
                                    size: 22,
                                  ),
                                ),
                                if (profile.streak > 1)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: CyberPalette.pink
                                            .withValues(alpha: 0.18),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                          color: CyberPalette.pink,
                                        ),
                                      ),
                                      child: Text(
                                        '🔥 ${profile.streak}',
                                        style: const TextStyle(
                                          color: CyberPalette.text,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                // Running elapsed stopwatch.
                                ValueListenableBuilder<Duration>(
                                  valueListenable: game.elapsed,
                                  builder: (context, duration, _) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: CyberPalette.panelDeep,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                          color: CyberPalette.cyan,
                                        ),
                                      ),
                                      child: Text(
                                        '⏱️ ${formatStopwatch(duration)}s',
                                        style: const TextStyle(
                                          color: CyberPalette.gold,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                CoinChip(coins: profile.coins, compact: true),
                              ],
                            ),
                          ),

                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final cloudHeight =
                                    (constraints.maxHeight * 0.30)
                                        .clamp(150.0, 240.0)
                                        .toDouble();
                                return SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    4,
                                    12,
                                    12,
                                  ),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight:
                                          (constraints.maxHeight - 16)
                                              .clamp(0.0, double.infinity)
                                              .toDouble(),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const BattleDojoTitle(),

                                        // Level pill, copied from the game state.
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: CyberPalette.gold
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: CyberPalette.gold,
                                                ),
                                              ),
                                              child: Text(
                                                game.levelInfo.levelLabel,
                                                style: const TextStyle(
                                                  color: CyberPalette.gold,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 0.5,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                '${game.levelInfo.title} · CHAPTER ${game.levelInfo.chapter}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: CyberPalette.muted,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Hero avatar with LIVE tag and stats.
                                        BattleHeroChip(
                                          tierLabel: profile.forgedTier.label,
                                          level: game.levelNumber,
                                          totalXp: profile.totalXp,
                                          pro: profile.isProUser,
                                        ),

                                        // Purple thought cloud with the question.
                                        if (question != null)
                                          SizedBox(
                                            height: cloudHeight,
                                            child: BattleCloud(
                                              label: question.kind.cloudLabel,
                                              formula: question.display,
                                              xpText: xpText,
                                              hint: game.hintVisible
                                                  ? question.hint
                                                  : null,
                                            ),
                                          ),

                                        // Compact neon banter, since the mock has none.
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            BattleBanterLine(
                                              speaker: 'HERO',
                                              text: game.heroLine,
                                              color: CyberPalette.cyan,
                                            ),
                                            const SizedBox(height: 6),
                                            BattleBanterLine(
                                              speaker: 'RIVAL',
                                              text: game.rivalLine,
                                              color: CyberPalette.pink,
                                            ),
                                          ],
                                        ),

                                        // 2x2 neon answer cards.
                                        if (question != null)
                                          _OptionGrid(
                                            options: question.options,
                                            correctIndex: question.correctIndex,
                                            selectedIndex: game.selectedIndex,
                                            removed: game.removed,
                                            reveal: game.phase ==
                                                RoundPhase.resolved,
                                            enabled: game.inputEnabled,
                                            onPick: _submit,
                                          ),

                                        // Boosters: hint and 50/50.
                                        Row(
                                          children: [
                                            Expanded(
                                              child: BattleActionButton(
                                                label: game.hintVisible
                                                    ? 'HINT ACTIVE'
                                                    : profile.hintTokens > 0
                                                        ? 'HINT · x${profile.hintTokens}'
                                                        : 'HINT · ${AppConfig.hintCost}',
                                                subtitle: 'Opens a gold banner',
                                                accent: CyberPalette.gold,
                                                icon: Icons.lightbulb_outline,
                                                onPressed: game.hintVisible ||
                                                        game.phase ==
                                                            RoundPhase.resolved ||
                                                        game.toolsBusy
                                                    ? null
                                                    : _hint,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: BattleActionButton(
                                                label: game.removed.isNotEmpty
                                                    ? '50/50 USED'
                                                    : profile.fiftyTokens > 0
                                                        ? '50/50 · x${profile.fiftyTokens}'
                                                        : '50/50 · ${AppConfig.fiftyCost}',
                                                subtitle: 'Disables 2 wrongs',
                                                accent: CyberPalette.cyan,
                                                icon: Icons.balance,
                                                onPressed: game.removed
                                                            .isNotEmpty ||
                                                        game.phase ==
                                                            RoundPhase.resolved ||
                                                        game.toolsBusy
                                                    ? null
                                                    : _fifty,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      // Solved popup with exact time and speed reward (unchanged).
                      if (game.phase == RoundPhase.resolved &&
                          game.reward != null)
                        Positioned.fill(
                          child: ComicPopup(
                            reward: game.reward!,
                            levelNumber: game.levelNumber,
                            onNext: _advancing ? () {} : _next,
                          ),
                        ),

                      // Wrong-answer card, restyled to the neon theme.
                      if (game.phase == RoundPhase.resolved && game.failed)
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 16,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: CyberPalette.panel,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: CyberPalette.pink,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: CyberPalette.pink
                                      .withValues(alpha: 0.4),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      '❌',
                                      style: TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'MISSED IT!',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 18,
                                              color: CyberPalette.pink,
                                            ),
                                          ),
                                          Text(
                                            'Correct answer was: ${question?.correctOption ?? ""}',
                                            style: const TextStyle(
                                              color: CyberPalette.text,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (game.hasPendingSecondChance) ...[
                                  const SizedBox(height: 12),
                                  BattleActionButton(
                                    label: profile.chanceTokens > 0
                                        ? 'SECOND CHANCE · USE TOKEN'
                                        : 'SECOND CHANCE · ${AppConfig.secondChanceCost} COINS',
                                    subtitle:
                                        'One retry · stopwatch keeps running',
                                    accent: CyberPalette.gold,
                                    icon: Icons.replay,
                                    onPressed: game.toolsBusy || _advancing
                                        ? null
                                        : _secondChance,
                                  ),
                                ],
                                const SizedBox(height: 12),
                                BattleActionButton(
                                  label: _advancing
                                      ? 'LOADING...'
                                      : 'RETRY LEVEL',
                                  subtitle:
                                      'Solve this level to unlock the next',
                                  accent: CyberPalette.pink,
                                  icon: Icons.refresh,
                                  onPressed: _advancing || game.toolsBusy
                                      ? null
                                      : _next,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 2x2 grid of neon answer cards: A and C purple, B and D cyan.
/// Reveals correct (mint) and wrong (pink) after an answer.
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

  static const _accents = [
    CyberPalette.purple,
    CyberPalette.cyan,
    CyberPalette.purple,
    CyberPalette.cyan,
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 72,
      ),
      itemBuilder: (context, index) {
        final gone = removed.contains(index);
        final isSelected = selectedIndex == index;
        final isCorrect = index == correctIndex;

        var state = gone ? BattleAnswerState.removed : BattleAnswerState.idle;
        if (reveal) {
          if (isCorrect) {
            state = BattleAnswerState.correct;
          } else if (isSelected) {
            state = BattleAnswerState.wrong;
          } else {
            state = BattleAnswerState.dimmed;
          }
        }

        return BattleAnswerCard(
          letter: String.fromCharCode(65 + index),
          answer: gone ? '—' : options[index],
          accent: _accents[index],
          state: state,
          onPressed: !enabled || gone ? null : () => onPick(index),
        );
      },
    );
  }
}
