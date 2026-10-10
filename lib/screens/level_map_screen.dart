import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/age_band.dart';
import '../models/math_level.dart';
import '../theme/manga_colors.dart';
import '../theme/manga_theme.dart';
import '../widgets/neo_widgets.dart';
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
      body: HalftoneBackground(
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
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const Expanded(
                        child: Text(
                          'MATH QUEST · LEVEL MAP',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        '${data.userAge} YRS',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                    children: [
                      NeoBox(
                        color: MangaColors.yellow,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentInfo.levelLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 21,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${currentInfo.band.label} TRACK · ${currentInfo.title}',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 7),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: completed / MathLevelInfo.campaignLength,
                                minHeight: 8,
                                color: MangaColors.ink,
                                backgroundColor: MangaColors.white,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '$completed / ${MathLevelInfo.campaignLength} CORE LEVELS COMPLETE',
                              style: const TextStyle(
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
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      const Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          _MapLegend(color: MangaColors.green, label: 'Complete'),
                          _MapLegend(color: MangaColors.yellow, label: 'Current'),
                          _MapLegend(color: MangaColors.disabled, label: 'Locked'),
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
                      NeoBox(
                        color: MangaColors.white,
                        child: const Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 24),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'After level 120, Master Mode keeps going with tougher questions.',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      MangaButton(
                        label: 'PLAY LEVEL $currentLevel',
                        subtitle: currentInfo.title,
                        color: MangaColors.pink,
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

    return NeoBox(
      color: MangaColors.white,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHAPTER ${chapter.chapter} · LEVELS $firstLevel–$lastLevel',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 0.4,
            ),
          ),
          Text(
            chapter.title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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
                  ? MangaColors.green
                  : isCurrent
                      ? MangaColors.yellow
                      : MangaColors.disabled;
              final icon = isComplete
                  ? Icons.check
                  : isCurrent
                      ? Icons.play_arrow
                      : Icons.lock_outline;
              final ink = isComplete || isCurrent
                  ? MangaColors.ink
                  : MangaColors.disabledInk;

              return Container(
                decoration: BoxDecoration(
                  color: fill,
                  border: Border.all(color: MangaColors.ink, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: MangaColors.ink,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 15, color: ink),
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
            border: Border.all(color: MangaColors.ink, width: 1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
        ),
      ],
    );
  }
}
