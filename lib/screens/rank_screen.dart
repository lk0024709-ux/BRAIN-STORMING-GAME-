import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/profile_controller.dart';
import '../theme/manga_colors.dart';
import '../theme/manga_theme.dart';
import '../widgets/banner_ad_slot.dart';
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
    final label = next == null
        ? '${data.totalXp} XP · peak rank'
        : '${data.totalXp} / ${next.minXp} XP';
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
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                          ),
                          const Expanded(
                            child: Text(
                              'RANK',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 28,
                              ),
                            ),
                          ),
                          CoinChip(coins: data.coins, compact: true),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: RankBadge(
                          tier: tier,
                          size: 220,
                          glow: data.isProUser,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tier.motto,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 14),
                      XpProgressBar(
                        progress: progress,
                        tier: next ?? tier,
                        label: label,
                      ),
                      const SizedBox(height: 14),
                      if (data.canEvolve)
                        MangaButton(
                          label: 'EVOLVE RANK',
                          subtitle: 'Forge ${next?.label ?? ''}',
                          color: MangaColors.gold,
                          icon: Icons.auto_awesome,
                          onPressed: () async {
                            if (data.soundOn) {
                              HapticFeedback.heavyImpact();
                            }
                            final forged = await profile.evolve();
                            if (forged == null || !context.mounted) return;
                            await showForgeCelebration(context, forged);
                          },
                        )
                      else
                        NeoBox(
                          color: MangaColors.white,
                          child: Text(
                            next == null
                                ? 'Diamond holds. There is no higher medal.'
                                : 'Cross ${next.minXp} XP, then forge ${next.label}. Rank does not climb until you tap Evolve.',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      const SizedBox(height: 12),
                      NeoBox(
                        color: MangaColors.paperDeep,
                        child: Column(
                          children: [
                            _Stat('Solved levels', '${data.levelsCompleted}'),
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
                      const Text(
                        'Bronze 0–1k · Silver 1k–5k · Gold 5k–20k · Diamond 20k+',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const BannerAdSlot(),
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
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
