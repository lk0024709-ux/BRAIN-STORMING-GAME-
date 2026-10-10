import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../controllers/game_controller.dart';
import '../controllers/music_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/question.dart';
import '../theme/cyber_palette.dart';
import '../theme/manga_colors.dart';
import '../theme/manga_theme.dart';
import '../widgets/comic_popup.dart';
import '../widgets/cyber_widgets.dart';
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: CyberPalette.background,
        body: CyberBackdrop(
          child: SafeArea(
            child: DojoFrame(
              child: Stack(
                children: [
                  Column(
                    children: [
                      // Header Navigation Bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 6, 12, 4),
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    game.levelInfo.levelLabel,
                                    style: const TextStyle(
                                      color: CyberPalette.text,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    '${game.levelInfo.title} · CHAPTER ${game.levelInfo.chapter}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: CyberPalette.muted,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: music.enabled
                                  ? 'Turn battle music off'
                                  : 'Turn battle music on',
                              onPressed: () => music.setEnabled(!music.enabled),
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
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: MangaColors.pink,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: MangaColors.ink,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    '🔥 ${profile.streak}',
                                    style: const TextStyle(
                                      color: MangaColors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            // Running Elapsed Stopwatch Engine: ⏱️ 00.0s
                            ValueListenableBuilder<Duration>(
                              valueListenable: game.elapsed,
                              builder: (context, duration, _) {
                                return NeoBox(
                                  color: MangaColors.ink,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  offset: const Offset(2, 2),
                                  borderWidth: 2,
                                  child: Text(
                                    '⏱️ ${formatStopwatch(duration)}s',
                                    style: const TextStyle(
                                      color: MangaColors.yellow,
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

                      // Character Header (Boy and Rival with Manga chat bubbles)
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

                      const SizedBox(height: 6),

                      // Central Thought Cloud displaying math puzzle
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

                      // Interactive Grid: 2x2 Large Buttons for answers
                      if (question != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
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

                      // In-Game Boosters: [💡 Hint] (10 coins) & [⚖️ 50/50] (25 coins)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: MangaButton(
                                label: game.hintVisible
                                    ? 'HINT ACTIVE'
                                    : profile.hintTokens > 0
                                        ? '💡 HINT · x${profile.hintTokens}'
                                        : '💡 HINT · ${AppConfig.hintCost}',
                                subtitle: 'Opens yellow banner',
                                color: MangaColors.yellow,
                                onPressed: game.hintVisible ||
                                        game.phase == RoundPhase.resolved ||
                                        game.toolsBusy
                                    ? null
                                    : _hint,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: MangaButton(
                                label: game.removed.isNotEmpty
                                    ? '50/50 USED'
                                    : profile.fiftyTokens > 0
                                        ? '⚖️ 50/50 · x${profile.fiftyTokens}'
                                        : '⚖️ 50/50 · ${AppConfig.fiftyCost}',
                                subtitle: 'Disables 2 wrongs',
                                color: MangaColors.blue,
                                onPressed: game.removed.isNotEmpty ||
                                        game.phase == RoundPhase.resolved ||
                                        game.toolsBusy
                                    ? null
                                    : _fifty,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Solved Comic-Style Popup Badge with exact time and speed reward
                  if (game.phase == RoundPhase.resolved && game.reward != null)
                    Positioned.fill(
                      child: ComicPopup(
                        reward: game.reward!,
                        levelNumber: game.levelNumber,
                        onNext: _advancing ? () {} : _next,
                      ),
                    ),

                  // Wrong Answer Comic Card
                  if (game.phase == RoundPhase.resolved && game.failed)
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 16,
                      child: NeoBox(
                        color: MangaColors.white,
                        offset: const Offset(6, 6),
                        borderWidth: 3,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Text('❌', style: TextStyle(fontSize: 24)),
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
                                          color: MangaColors.red,
                                        ),
                                      ),
                                      Text(
                                        'Correct answer was: ${question?.correctOption ?? ""}',
                                        style: const TextStyle(
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
                              MangaButton(
                                label: profile.chanceTokens > 0
                                    ? 'SECOND CHANCE · USE TOKEN'
                                    : 'SECOND CHANCE · ${AppConfig.secondChanceCost} COINS',
                                subtitle: 'One retry · stopwatch keeps running',
                                color: MangaColors.yellow,
                                icon: Icons.replay,
                                onPressed: game.toolsBusy || _advancing
                                    ? null
                                    : _secondChance,
                              ),
                            ],
                            const SizedBox(height: 12),
                            MangaButton(
                              label: _advancing ? 'LOADING...' : 'RETRY LEVEL',
                              subtitle: 'Solve this level to unlock the next',
                              color: MangaColors.pink,
                              icon: Icons.refresh,
                              onPressed: _advancing || game.toolsBusy ? null : _next,
                            ),
                          ],
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

/// 2x2 Interactive Grid of Answer Buttons.
/// Turn Green on correct, Red on wrong!
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
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 70,
      ),
      itemBuilder: (context, index) {
        final gone = removed.contains(index);
        final isSelected = selectedIndex == index;
        final isCorrect = index == correctIndex;

        Color fill = MangaColors.optionFills[index];
        Color textColor = MangaColors.ink;

        if (gone) {
          fill = MangaColors.disabled;
          textColor = MangaColors.disabledInk;
        }

        // Color states: Green on correct, Red on wrong!
        if (reveal) {
          if (isCorrect) {
            fill = MangaColors.green;
            textColor = MangaColors.white;
          } else if (isSelected) {
            fill = MangaColors.red;
            textColor = MangaColors.white;
          } else {
            fill = MangaColors.disabled;
            textColor = MangaColors.disabledInk;
          }
        }

        final letter = String.fromCharCode(65 + index);
        final label = gone ? '$letter  —' : '$letter  ${options[index]}';

        return MangaOptionButton(
          label: label,
          color: fill,
          textColor: textColor,
          onPressed: !enabled || gone ? null : () => onPick(index),
        );
      },
    );
  }
}

class MangaOptionButton extends StatefulWidget {
  const MangaOptionButton({
    super.key,
    required this.label,
    required this.color,
    required this.textColor,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onPressed;

  @override
  State<MangaOptionButton> createState() => _MangaOptionButtonState();
}

class _MangaOptionButtonState extends State<MangaOptionButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final shift = _down && enabled ? const Offset(3, 3) : Offset.zero;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: enabled
          ? (_) {
              setState(() => _down = false);
              widget.onPressed?.call();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        transform: Matrix4.translationValues(shift.dx, shift.dy, 0),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: MangaColors.ink, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: MangaColors.ink,
              offset: _down && enabled ? Offset.zero : const Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          widget.label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: widget.textColor,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
