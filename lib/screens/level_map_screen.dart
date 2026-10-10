import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/age_band.dart';
import '../models/math_level.dart';
import '../theme/cyber_palette.dart';
import '../theme/manga_theme.dart';
import '../widgets/cyber_widgets.dart';
import 'gameplay_screen.dart';

/// Shows all 120 age-specific campaign levels and the player's unlock state.
class LevelMapScreen extends StatelessWidget {
  const LevelMapScreen({super.key});

  void _startNextLevel(BuildContext context, ProfileController profile) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => GameController(profile: profile)..startSession(),
          child: const GameplayScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final data = profile.profile;
    final currentLevel = data.levelsCompleted + 1;
    final currentInfo = MathLevelInfo.forAge(data.userAge, currentLevel);
    final completed =
        data.levelsCompleted.clamp(0, MathLevelInfo.campaignLength).toInt();

    return Scaffold(
      backgroundColor: CyberPalette.background,
      body: CyberBackdrop(
        child: SafeArea(
          child: DojoFrame(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 12, 8),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: CyberPalette.text),
                      ),
                      const Expanded(
                        child: Text(
                          'MATH QUEST · LEVEL MAP',
                          style: TextStyle(
                            color: CyberPalette.text,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        '${data.userAge} YRS',
                        style: const TextStyle(
                          color: CyberPalette.cyan,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                    children: [
                      CyberPanel(
                        accent: CyberPalette.cyan,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentInfo.levelLabel,
                              style: const TextStyle(
                                color: CyberPalette.text,
                                fontWeight: FontWeight.w900,
                                fontSize: 21,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${currentInfo.band.label} TRACK · ${currentInfo.title}',
                              style: const TextStyle(
                                color: CyberPalette.muted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 9),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: LinearProgressIndicator(
                                value: completed / MathLevelInfo.campaignLength,
                                minHeight: 8,
                                color: CyberPalette.cyan,
                                backgroundColor: const Color(0xFF27324A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$completed / ${MathLevelInfo.campaignLength} CORE LEVELS COMPLETE',
                              style: const TextStyle(
                                color: CyberPalette.cyan,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Clear a question to unlock the next level. A miss keeps your current level open.',
                        style: TextStyle(
                          color: CyberPalette.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          _MapLegend(color: CyberPalette.mint, label: 'Complete'),
                          _MapLegend(color: CyberPalette.pink, label: 'Current'),
                          _MapLegend(color: CyberPalette.edge, label: 'Locked'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      for (var chapter = 1; chapter <= 4; chapter++) ...[
                        _LevelChapter(
                          age: data.userAge,
                          firstLevel:
                              (chapter - 1) * MathLevelInfo.levelsPerChapter + 1,
                          completedLevels: data.levelsCompleted,
                        ),
                        const SizedBox(height: 14),
                      ],
                      CyberPanel(
                        accent: CyberPalette.gold,
                        child: const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: CyberPalette.gold, size: 24),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'After level 120, Master Mode keeps going with tougher questions.',
                                style: TextStyle(
                                  color: CyberPalette.text,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      CyberPrimaryButton(
                        label: 'PLAY LEVEL $currentLevel',
                        subtitle: currentInfo.title,
                        icon: Icons.play_arrow,
                        onPressed: () => _startNextLevel(context, profile),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelChapter extends StatelessWidget {
  const _LevelChapter({
    required this.age,
    required this.firstLevel,
    required this.completedLevels,
  });

  final int age;
  final int firstLevel;
  final int completedLevels;

  @override
  Widget build(BuildContext context) {
    final chapter = MathLevelInfo.forAge(age, firstLevel);
    final lastLevel = firstLevel + MathLevelInfo.levelsPerChapter - 1;

    return CyberPanel(
      accent: chapter.chapter.isOdd ? CyberPalette.blue : CyberPalette.pink,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHAPTER ${chapter.chapter} · LEVELS $firstLevel–$lastLevel',
            style: const TextStyle(
              color: CyberPalette.muted,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 0.4,
            ),
          ),
          Text(
            chapter.title,
            style: const TextStyle(
              color: CyberPalette.text,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: MathLevelInfo.levelsPerChapter,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 7,
              crossAxisSpacing: 7,
              childAspectRatio: 1.08,
            ),
            itemBuilder: (context, index) {
              final level = firstLevel + index;
              final isComplete = level <= completedLevels;
              final isCurrent = level == completedLevels + 1;
              final fill = isComplete
                  ? const Color(0xFF10352F)
                  : isCurrent
                      ? const Color(0xFF27203E)
                      : CyberPalette.panelDeep;
              final accent = isComplete
                  ? CyberPalette.mint
                  : isCurrent
                      ? CyberPalette.pink
                      : const Color(0xFF39445A);
              final icon = isComplete
                  ? Icons.check
                  : isCurrent
                      ? Icons.play_arrow
                      : Icons.lock_outline;
              final ink = isComplete || isCurrent
                  ? CyberPalette.text
                  : CyberPalette.muted.withValues(alpha: 0.55);

              return Container(
                decoration: BoxDecoration(
                  color: fill,
                  border: Border.all(
                    color: accent.withValues(alpha: isCurrent ? 0.95 : 0.65),
                    width: isCurrent ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.3),
                            blurRadius: 9,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 15, color: accent),
                    Text(
                      '$level',
                      style: TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

        ],
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: color.withValues(alpha: 0.75), width: 1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: CyberPalette.muted,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
