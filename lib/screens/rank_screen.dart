import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/profile_controller.dart';
import '../theme/manga_colors.dart';
import '../theme/manga_theme.dart';
import '../widgets/manga_avatar.dart';
import '../widgets/neo_widgets.dart';
import '../widgets/rank_widgets.dart';

class RankScreen extends StatelessWidget {
  const RankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final data = profile.profile;
    final tier = data.forgedTier;
    final next = data.nextTier;
    final progress = tier.progress(data.totalXp);

    // Format: "3,400 / 5,000 XP to Gold"
    final targetLabel = next == null
        ? '${formatXp(data.totalXp)} XP · DIAMOND MASTER'
        : '${formatXp(data.totalXp)} / ${formatXp(next.minXp)} XP to ${next.label[0]}${next.label.substring(1).toLowerCase()}';

    return Scaffold(
      body: HalftoneBackground(
        child: SafeArea(
          child: DojoFrame(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      // Top Bar
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: MangaColors.ink,
                              size: 26,
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              'RANK PROGRESSION',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          CoinChip(coins: data.coins, compact: true),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Player Identification Card
                      NeoBox(
                        color: MangaColors.white,
                        offset: const Offset(4, 4),
                        borderWidth: 2.5,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            MangaAvatar(
                              rival: false,
                              pro: data.isProUser,
                              size: 56,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        data.nickname.isEmpty
                                            ? 'HERO'
                                            : data.nickname.toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (data.isProUser) ...[
                                        const SizedBox(width: 6),
                                        const ProBadge(compact: true),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${tier.label} RANK  ·  ${formatXp(data.totalXp)} Total XP',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: MangaColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Massive 2D Rank Medal
                      Center(
                        child: RankBadge(
                          tier: tier,
                          size: 220,
                          glow: data.isProUser,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Tier Motto
                      Text(
                        tier.motto,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Pure XP Progress Bar (e.g., "3,400 / 5,000 XP to Gold")
                      XpProgressBar(
                        progress: progress,
                        tier: next ?? tier,
                        label: targetLabel,
                      ),
                      const SizedBox(height: 16),

                      // "Evolve Rank" Action Button
                      if (data.canEvolve)
                        MangaButton(
                          label: '⚡ EVOLVE RANK',
                          subtitle: 'Forge ${next?.label} Medal Now',
                          color: MangaColors.gold,
                          icon: Icons.auto_awesome,
                          onPressed: () async {
                            if (data.soundOn) {
                              HapticFeedback.heavyImpact();
                              SystemSound.play(SystemSoundType.click);
                            }
                            final forged = await profile.evolve();
                            if (forged == null || !context.mounted) return;
                            await showForgeCelebration(
                              context,
                              forged,
                              isPro: data.isProUser,
                            );
                          },
                        )
                      else
                        NeoBox(
                          color: MangaColors.paperDeep,
                          offset: const Offset(3, 3),
                          borderWidth: 2,
                          child: Text(
                            next == null
                                ? 'Diamond holds. Peak dojo rank achieved. There is no higher medal.'
                                : 'Cross ${formatXp(next.minXp)} XP, then forge ${next.label}. Rank does not climb until you tap Evolve.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),

                      const SizedBox(height: 14),

                      // Dojo Training Statistics
                      NeoBox(
                        color: MangaColors.white,
                        offset: const Offset(4, 4),
                        borderWidth: 2.5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionTitle('Dojo Records'),
                            const SizedBox(height: 8),
                            _Stat(
                              'Solved clouds',
                              '${data.levelsCompleted}',
                            ),
                            _Stat(
                              'Accuracy',
                              data.questionsSettled == 0
                                  ? '—'
                                  : '${(data.accuracy * 100).round()}%',
                            ),
                            _Stat(
                              'Best time',
                              data.bestTimeMs == 0
                                  ? '—'
                                  : '${(data.bestTimeMs / 1000).toStringAsFixed(1)}s',
                            ),
                            _Stat('Best streak', '${data.bestStreak}'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Evolution Tiers Guide
                      NeoBox(
                        color: MangaColors.paperDeep,
                        offset: const Offset(3, 3),
                        borderWidth: 2,
                        child: Column(
                          children: [
                            const Text(
                              'EVOLUTION TIERS',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '🥉 Bronze (0–1k XP)   ·   🥈 Silver (1k–5k XP)\n'
                              '🥇 Gold (5k–20k XP)   ·   💎 Diamond (20k+ XP)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
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

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
